import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<String> users = [];

  Future<void> fetchUsers() async {
    final response =
        await http.get(Uri.parse('http://192.168.181.73:5000/admin/users'));
    if (response.statusCode == 200) {
      setState(() {
        users = List<String>.from(jsonDecode(response.body));
      });
    }
  }

  Future<void> deleteUser(String user) async {
    final response = await http.delete(
      Uri.parse('http://192.168.181.73:5000/admin/users'),
      body: {'name': user},
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$user deleted successfully!')),
      );
      fetchUsers(); // Refresh user list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Panel')),
      body: users.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(users[index]),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteUser(users[index]),
                  ),
                );
              },
            ),
    );
  }
}
