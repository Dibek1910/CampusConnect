import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_connect/providers/auth_provider.dart';
import 'package:campus_connect/models/profile_model.dart';
import 'package:campus_connect/widgets/input_field.dart';
import 'package:campus_connect/widgets/button_widget.dart';
import 'package:campus_connect/widgets/otp_verification_widget.dart';
import 'package:campus_connect/config/route.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({Key? key}) : super(key: key);

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
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
    _profile = ProfileModel(
      id: authProvider.studentProfile!.id,
      name: authProvider.studentProfile!.name,
      email: authProvider.user!.email,
      phoneNumber: authProvider.studentProfile!.phoneNumber,
      course: authProvider.studentProfile!.course,
      branch: authProvider.studentProfile!.branch,
      currentYear: authProvider.studentProfile!.currentYear,
      currentSemester: authProvider.studentProfile!.currentSemester,
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
      final updated = await authProvider.updateStudentProfile(_profile, otp);

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
        title: const Text('Student Profile'),
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
                                : 'S',
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
                            course: _profile.course,
                            branch: _profile.branch,
                            currentYear: _profile.currentYear,
                            currentSemester: _profile.currentSemester,
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
                            course: _profile.course,
                            branch: _profile.branch,
                            currentYear: _profile.currentYear,
                            currentSemester: _profile.currentSemester,
                          ),
                        ),
                        const SizedBox(height: 16),
                        InputField(
                          label: 'Course',
                          hint: 'Enter your course',
                          controller: TextEditingController(
                              text: _profile.course ?? ''),
                          enabled: _isEditing,
                          onChanged: (value) => _profile = ProfileModel(
                            id: _profile.id,
                            name: _profile.name,
                            email: _profile.email,
                            phoneNumber: _profile.phoneNumber,
                            course: value,
                            branch: _profile.branch,
                            currentYear: _profile.currentYear,
                            currentSemester: _profile.currentSemester,
                          ),
                        ),
                        const SizedBox(height: 16),
                        InputField(
                          label: 'Branch',
                          hint: 'Enter your branch',
                          controller: TextEditingController(
                              text: _profile.branch ?? ''),
                          enabled: _isEditing,
                          onChanged: (value) => _profile = ProfileModel(
                            id: _profile.id,
                            name: _profile.name,
                            email: _profile.email,
                            phoneNumber: _profile.phoneNumber,
                            course: _profile.course,
                            branch: value,
                            currentYear: _profile.currentYear,
                            currentSemester: _profile.currentSemester,
                          ),
                        ),
                        const SizedBox(height: 16),
                        InputField(
                          label: 'Current Year',
                          hint: 'Enter your current year',
                          controller: TextEditingController(
                            text: _profile.currentYear != null
                                ? _profile.currentYear.toString()
                                : '',
                          ),
                          enabled: _isEditing,
                          keyboardType: TextInputType.number,
                          onChanged: (value) => _profile = ProfileModel(
                            id: _profile.id,
                            name: _profile.name,
                            email: _profile.email,
                            phoneNumber: _profile.phoneNumber,
                            course: _profile.course,
                            branch: _profile.branch,
                            currentYear: int.tryParse(value),
                            currentSemester: _profile.currentSemester,
                          ),
                        ),
                        const SizedBox(height: 16),
                        InputField(
                          label: 'Current Semester',
                          hint: 'Enter your current semester',
                          controller: TextEditingController(
                            text: _profile.currentSemester != null
                                ? _profile.currentSemester.toString()
                                : '',
                          ),
                          enabled: _isEditing,
                          keyboardType: TextInputType.number,
                          onChanged: (value) => _profile = ProfileModel(
                            id: _profile.id,
                            name: _profile.name,
                            email: _profile.email,
                            phoneNumber: _profile.phoneNumber,
                            course: _profile.course,
                            branch: _profile.branch,
                            currentYear: _profile.currentYear,
                            currentSemester: int.tryParse(value),
                          ),
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
