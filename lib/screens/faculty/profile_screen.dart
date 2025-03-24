import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_connect/providers/auth_provider.dart';
import 'package:campus_connect/models/profile_model.dart';
import 'package:campus_connect/widgets/input_field.dart';
import 'package:campus_connect/widgets/button_widget.dart';
import 'package:campus_connect/widgets/otp_verification_widget.dart';
import 'package:campus_connect/config/route.dart';

class FacultyProfileScreen extends StatefulWidget {
  const FacultyProfileScreen({Key? key}) : super(key: key);

  @override
  State<FacultyProfileScreen> createState() => _FacultyProfileScreenState();
}

class _FacultyProfileScreenState extends State<FacultyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late ProfileModel _profile;
  bool _isEditing = false;
  bool _isVerifyingOtp = false;
  String? _verificationEmail;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Get the department name correctly
    String departmentName = '';
    if (authProvider.facultyProfile!.department != null) {
      // Check if department is a Map or a String
      if (authProvider.facultyProfile!.department is Map) {
        departmentName = authProvider.facultyProfile!.department['name'] ?? '';
      } else {
        departmentName = authProvider.facultyProfile!.department.toString();
      }
    }

    _profile = ProfileModel(
      id: authProvider.facultyProfile!.id,
      name: authProvider.facultyProfile!.name,
      email: authProvider.user!.email,
      phoneNumber: authProvider.facultyProfile!.phoneNumber,
      department: departmentName,
    );
  }

  Future<void> _updateProfile(String otp) async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // First verify OTP
    final otpVerified = await authProvider.verifyOtp(_profile.email, otp);

    if (otpVerified) {
      // Then update profile
      final updated = await authProvider.updateFacultyProfile(_profile, otp);

      if (updated) {
        setState(() {
          _isVerifyingOtp = false;
          _isEditing = false;
          _showSnackBar('Profile updated successfully');
        });
      } else {
        _showSnackBar(authProvider.error ?? 'Failed to update profile');
      }
    } else {
      _showSnackBar(authProvider.error ?? 'Invalid OTP');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.cancel : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  _isVerifyingOtp = false;
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Text(
                            _profile.name.isNotEmpty
                                ? _profile.name[0].toUpperCase()
                                : 'F',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        InputField(
                          label: 'Name',
                          hint: 'Enter your name',
                          controller:
                              TextEditingController(text: _profile.name),
                          enabled: _isEditing,
                          onChanged: (value) => _profile = ProfileModel(
                            id: _profile.id,
                            name: value,
                            email: _profile.email,
                            phoneNumber: _profile.phoneNumber,
                            department: _profile.department,
                          ),
                        ),
                        const SizedBox(height: 16),
                        InputField(
                          label: 'Email',
                          hint: 'Enter your email',
                          controller:
                              TextEditingController(text: _profile.email),
                          enabled: false,
                        ),
                        const SizedBox(height: 16),
                        InputField(
                          label: 'Phone Number',
                          hint: 'Enter your phone number',
                          controller:
                              TextEditingController(text: _profile.phoneNumber),
                          enabled: _isEditing,
                          keyboardType: TextInputType.phone,
                          onChanged: (value) => _profile = ProfileModel(
                            id: _profile.id,
                            name: _profile.name,
                            email: _profile.email,
                            phoneNumber: value,
                            department: _profile.department,
                          ),
                        ),
                        const SizedBox(height: 16),
                        InputField(
                          label: 'Department',
                          hint: 'Department',
                          controller: TextEditingController(
                              text: _profile.department ?? ''),
                          enabled: false,
                        ),
                        const SizedBox(height: 32),
                        if (_isEditing && !_isVerifyingOtp)
                          ButtonWidget(
                            text: 'Update Profile',
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  _isVerifyingOtp = true;
                                  _verificationEmail = _profile.email;
                                });

                                // Generate OTP
                                final authProvider = Provider.of<AuthProvider>(
                                    context,
                                    listen: false);
                                authProvider.generateOtp(_profile.email);
                              }
                            },
                          ),
                        if (_isVerifyingOtp)
                          OtpVerificationWidget(
                            email: _verificationEmail!,
                            onVerified: _updateProfile,
                            onCancel: () {
                              setState(() {
                                _isVerifyingOtp = false;
                                _verificationEmail = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
