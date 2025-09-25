// lib/pages/bookings_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Change if your backend host is different for emulator/device
const String BASE_URL = 'http://10.0.2.2:8080';

class BookingsPage extends StatefulWidget {
  @override
  _BookingsPageState createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  List<dynamic> orgs = [];
  int? selectedOrgId;
  String selectedOrgName = '';
  List<dynamic> departments = [];
  int? selectedDeptId;
  List<dynamic> users = [];
  int? selectedUserId;

  DateTime selectedDate = DateTime.now();
  List<dynamic> bookings = [];
  String statusMessage = 'Please set org id (select an organization)';

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();

  bool loadingOrgs = false;
  bool loadingBookings = false;
  bool creatingBooking = false;

  @override
  void initState() {
    super.initState();
    loadOrgs();
  }

  Future<void> loadOrgs() async {
    setState(() {
      loadingOrgs = true;
      statusMessage = 'Loading organizations...';
    });
    try {
      final r = await http.get(Uri.parse('$BASE_URL/organizations')).timeout(Duration(seconds: 10));
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body);
        final data = body['organizations'] ?? body['orgs'] ?? body['rows'] ?? body;
        List list;
        if (data is List) list = data;
        else if (data is Map && data['data'] is List) list = data['data'];
        else list = [];
        setState(() {
          orgs = list;
          statusMessage = orgs.isEmpty ? 'No organizations found' : 'Select an organization';
        });
      } else {
        setState(() => statusMessage = 'Failed to load organizations: HTTP ${r.statusCode}');
      }
    } catch (e) {
      setState(() => statusMessage = 'Error loading organizations: $e');
    } finally {
      setState(() => loadingOrgs = false);
    }
  }

  Future<void> loadOrgRelated(int orgId) async {
    setState(() {
      departments = [];
      users = [];
      selectedDeptId = null;
      selectedUserId = null;
      statusMessage = 'Loading org details...';
    });
    try {
      final r1 = await http.get(Uri.parse('$BASE_URL/departments?org_id=$orgId')).timeout(Duration(seconds: 8));
      if (r1.statusCode == 200) {
        final b = jsonDecode(r1.body);
        setState(() {
          departments = b['departments'] ?? b['rows'] ?? (b is List ? b : []);
        });
      }
    } catch (_) {}
    try {
      final r2 = await http.get(Uri.parse('$BASE_URL/users?org_id=$orgId')).timeout(Duration(seconds: 8));
      if (r2.statusCode == 200) {
        final b = jsonDecode(r2.body);
        setState(() {
          users = b['users'] ?? b['rows'] ?? (b is List ? b : []);
        });
      }
    } catch (_) {}
    setState(() { statusMessage = 'Ready'; });
    await loadBookings();
  }

  Future<void> loadBookings() async {
    if (selectedOrgId == null) {
      setState(() => statusMessage = 'Select an organization first.');
      return;
    }
    setState(() {
      loadingBookings = true;
      statusMessage = 'Loading bookings...';
      bookings = [];
    });
    final dateStr = '${selectedDate.year.toString().padLeft(4, '0')}-'
        '${selectedDate.month.toString().padLeft(2, '0')}-'
        '${selectedDate.day.toString().padLeft(2, '0')}';
    try {
      final r = await http.get(Uri.parse('$BASE_URL/bookings?org_id=$selectedOrgId&date=$dateStr')).timeout(Duration(seconds: 10));
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        final data = b['bookings'] ?? b['rows'] ?? (b is List ? b : []);
        setState(() {
          bookings = data;
          statusMessage = bookings.isEmpty ? 'No bookings for $dateStr' : 'Loaded ${bookings.length} bookings';
        });
      } else {
        setState(() => statusMessage = 'Failed to fetch bookings: HTTP ${r.statusCode}');
      }
    } catch (e) {
      setState(() => statusMessage = 'Failed to fetch bookings: $e');
    } finally {
      setState(() => loadingBookings = false);
    }
  }

  Future<void> createBooking() async {
    if (selectedOrgId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Select organization first')));
      return;
    }
    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please provide customer name and phone')));
      return;
    }

    setState(() => creatingBooking = true);
    try {
      final payload = {
        'org_id': selectedOrgId,
        'user_name': name,
        'user_phone': phone,
        'department': selectedDeptId,
        'assigned_user_id': selectedUserId
      };
      final r = await http.post(Uri.parse('$BASE_URL/bookings'),
          headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload)).timeout(Duration(seconds: 10));

      if (r.statusCode == 200 || r.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking created')));
        nameCtrl.clear();
        phoneCtrl.clear();
        await loadBookings();
      } else {
        String err = r.body;
        try {
          final jb = jsonDecode(r.body);
          err = (jb['error'] ?? jb['message'] ?? jb).toString();
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Create failed: HTTP ${r.statusCode} — $err')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Create failed: $e')));
    } finally {
      setState(() => creatingBooking = false);
    }
  }

  Widget buildOrgDropdown() {
    if (loadingOrgs) return CircularProgressIndicator();
    if (orgs.isEmpty) return Text('No organizations found');

    return DropdownButtonFormField<int>(
      isExpanded: true,
      decoration: InputDecoration(labelText: 'Organization'),
      value: selectedOrgId,
      items: orgs.map<DropdownMenuItem<int>>((o) {
        final id = (o is Map && o['id'] != null) ? o['id'] : (o['org_id'] ?? o['id']);
        final name = (o is Map && o['name'] != null) ? o['name'] : (o['org_name'] ?? o.toString());
        return DropdownMenuItem<int>(value: id is int ? id : int.tryParse(id.toString()), child: Text(name ?? id.toString()));
      }).toList(),
      onChanged: (v) async {
        setState(() {
          selectedOrgId = v;
          selectedOrgName = orgs.firstWhere((o) => ((o is Map ? o['id'] : o) == v) || ((o is Map && o['id'] == v)), orElse: ()=>null)?['name'] ?? '';
        });
        if (v != null) await loadOrgRelated(v);
      },
    );
  }

  Widget buildDeptDropdown() {
    return DropdownButtonFormField<int>(
      isExpanded: true,
      decoration: InputDecoration(labelText: 'Department'),
      value: selectedDeptId,
      items: departments.map<DropdownMenuItem<int>>((d) {
        final id = (d is Map && d['id'] != null) ? d['id'] : (d['department_id'] ?? d);
        final name = (d is Map && d['name'] != null) ? d['name'] : (d['department_name'] ?? d.toString());
        return DropdownMenuItem<int>(value: id is int ? id : int.tryParse(id.toString()), child: Text(name ?? id.toString()));
      }).toList(),
      onChanged: (v) => setState(() => selectedDeptId = v),
    );
  }

  Widget buildUserDropdown() {
    return DropdownButtonFormField<int>(
      isExpanded: true,
      decoration: InputDecoration(labelText: 'Assigned user'),
      value: selectedUserId,
      items: users.map<DropdownMenuItem<int>>((u) {
        final id = (u is Map && u['id'] != null) ? u['id'] : (u['user_id'] ?? u);
        final name = (u is Map && u['name'] != null) ? u['name'] : (u['full_name'] ?? u['email'] ?? u.toString());
        return DropdownMenuItem<int>(value: id is int ? id : int.tryParse(id.toString()), child: Text(name ?? id.toString()));
      }).toList(),
      onChanged: (v) => setState(() => selectedUserId = v),
    );
  }

  Widget buildBookingsList() {
    if (loadingBookings) return Center(child: CircularProgressIndicator());
    if (bookings.isEmpty) return Text(statusMessage);

    return ListView.separated(
      itemCount: bookings.length,
      separatorBuilder: (_, __) => Divider(),
      itemBuilder: (ctx, i) {
        final b = bookings[i];
        final token = (b is Map && (b['token'] ?? b['token_no'] ?? b['booking_number']) != null)
            ? (b['token'] ?? b['token_no'] ?? b['booking_number']).toString()
            : '';
        final customer = (b is Map && (b['customer_name'] ?? b['user_name'] ?? b['name']) != null)
            ? (b['customer_name'] ?? b['user_name'] ?? b['name']).toString()
            : 'Customer';
        final phone = (b is Map && (b['customer_phone'] ?? b['user_phone'] ?? b['phone']) != null)
            ? (b['customer_phone'] ?? b['user_phone'] ?? b['phone']).toString()
            : '';
        final status = (b is Map && b['status'] != null) ? b['status'].toString() : '';

        return ListTile(
          title: Text(customer),
          subtitle: Text('Token: $token • $phone'),
          trailing: Text(status, style: TextStyle(color: status == 'served' ? Colors.green : Colors.black54)),
        );
      },
    );
  }

  Future<void> pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (d != null) {
      setState(() => selectedDate = d);
      await loadBookings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: buildOrgDropdown()),
                SizedBox(width: 8),
                ElevatedButton(onPressed: loadOrgs, child: Text('Reload orgs')),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: buildDeptDropdown()),
                SizedBox(width: 8),
                Expanded(child: buildUserDropdown()),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(onPressed: pickDate, child: Text('Pick date')),
                SizedBox(width: 8),
                ElevatedButton(onPressed: loadBookings, child: Text('Reload')),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: creatingBooking ? null : createBooking,
                  child: creatingBooking ? Row(children: [CircularProgressIndicator(), SizedBox(width:8), Text('Creating...')]) : Text('Create booking (demo)'),
                ),
              ],
            ),
            SizedBox(height: 8),
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Customer name')),
            SizedBox(height: 4),
            TextField(controller: phoneCtrl, decoration: InputDecoration(labelText: 'Customer phone')),
            SizedBox(height: 8),
            Expanded(child: buildBookingsList()),
            SizedBox(height: 6),
            Text(statusMessage, style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }
}
