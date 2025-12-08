import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/primary_button.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentEmail;
  final String currentFirstName;
  final String currentLastName;

  const EditProfileScreen({
    super.key,
    required this.currentEmail,
    required this.currentFirstName,
    required this.currentLastName,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.currentEmail);
    _firstNameController = TextEditingController(text: widget.currentFirstName);
    _lastNameController = TextEditingController(text: widget.currentLastName);
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<CookieRequest>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: "First Name",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: "Last Name",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : PremiereButton(
                    text: "SAVE CHANGES",
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() => _isLoading = true);
                        try {
                          // To connect Android emulator with Django on localhost, use URL http://10.0.2.2:8000
                          // If you using chrome, use URL http://localhost:8000
                          final response = await request.postJson(
                            "http://localhost:8000/accounts/api/profile/edit/",
                            jsonEncode({
                              "email": _emailController.text,
                              "first_name": _firstNameController.text,
                              "last_name": _lastNameController.text,
                            }),
                          );

                          if (context.mounted) {
                            if (response['status'] == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Profile updated!")),
                              );
                              Navigator.pop(context, true);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(response['message'] ?? "Failed")),
                              );
                            }
                          }
                        } catch (e) {
                           // Handle error
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      }
                    },
                  ),
          ],
        ),
      ),
    );
  }
}