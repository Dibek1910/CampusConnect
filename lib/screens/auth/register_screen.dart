import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campus_connect/config/route.dart';
import 'package:campus_connect/providers/auth_provider.dart';
import 'package:campus_connect/widgets/button_widget.dart';
import 'package:campus_connect/widgets/input_field.dart';
import 'package:campus_connect/services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  final String role;

  const RegisterScreen({
    Key? key,
    required this.role,
  }) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _courseController = TextEditingController();
  String? _selectedBranch;
  final _currentYearController = TextEditingController();
  final _currentSemesterController = TextEditingController();
  String? _selectedDepartment;
  final _otpController = TextEditingController();

  bool _otpSent = false;
  String? _email;

  List<String> _branchOptions = [];
  List<String> _departmentOptions = [];
  bool _isLoading = true;
  String? _fetchError;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoading = true;
      _fetchError = null;
    });

    try {
      if (widget.role == 'student') {
        // Fetch branches for student
        final response = await ApiService.get('/auth/branches');
        if (response.statusCode == 200 && response.data != null) {
          setState(() {
            _branchOptions = List<String>.from(response.data['data']);
          });
        } else {
          setState(() {
            _fetchError = response.error ?? 'Failed to load branch options';
          });
        }
      } else {
        // Fetch departments for faculty
        final response = await ApiService.get('/auth/departments');
        if (response.statusCode == 200 && response.data != null) {
          setState(() {
            _departmentOptions = List<String>.from(response.data['data']);
          });
        } else {
          setState(() {
            _fetchError = response.error ?? 'Failed to load department options';
          });
        }
      }
    } catch (e) {
      setState(() {
        _fetchError = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _registrationNumberController.dispose();
    _courseController.dispose();
    _currentYearController.dispose();
    _currentSemesterController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      Map<String, dynamic> userData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phoneNumber': _phoneNumberController.text,
      };

      if (widget.role == 'student') {
        userData.addAll({
          'registrationNumber': _registrationNumberController.text,
          'course': _courseController.text,
          'branch': _selectedBranch,
          'currentYear': int.parse(_currentYearController.text),
          'currentSemester': int.parse(_currentSemesterController.text),
        });
      } else {
        userData.addAll({
          'department': _selectedDepartment,
        });
      }

      dynamic result;
      if (widget.role == 'student') {
        result = await authProvider.registerStudent(userData);
      } else {
        result = await authProvider.registerFaculty(userData);
      }

      if (result != null) {
        setState(() {
          _otpSent = true;
          _email = _emailController.text;
        });
        _showSnackBar('OTP sent to your email');
      } else {
        _showSnackBar(authProvider.error ?? 'Registration failed');
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.verifyRegistrationOtp(
        _email!,
        _otpController.text,
      );

      if (success) {
        if (widget.role == 'student') {
          Navigator.of(context)
              .pushReplacementNamed(AppRouter.studentHomeRoute);
        } else {
          Navigator.of(context)
              .pushReplacementNamed(AppRouter.facultyDashboardRoute);
        }
      } else {
        _showSnackBar(authProvider.error ?? 'Invalid OTP');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Custom dropdown widget to handle long text and different screen sizes
  Widget _buildResponsiveDropdown({
    required String label,
    required String hint,
    required List<String> items,
    required String? value,
    required Function(String?) onChanged,
    required Function(String?) validator,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: constraints.maxWidth,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                ),
                value: value,
                validator: (val) => validator(val),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
                dropdownColor: Colors.white,
                menuMaxHeight: MediaQuery.of(context).size.height *
                    0.5, // Limit dropdown height
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Tooltip(
                      message: item, // Show full text on long press
                      child: Text(
                        item,
                        overflow: TextOverflow.ellipsis, // Handle text overflow
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.role.capitalize()} Registration'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _fetchError != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Text(
                            'Error: $_fetchError',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadOptions,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenSize.width * 0.05, // Responsive padding
                      vertical: 24.0,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!_otpSent) ...[
                            Text(
                              'Create Account',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please fill in the details below',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            InputField(
                              label: 'Full Name',
                              hint: 'Enter your full name',
                              controller: _nameController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            InputField(
                              label: 'Email',
                              hint: widget.role == 'student'
                                  ? 'Enter your email (e.g., student@muj.manipal.edu)'
                                  : 'Enter your email',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                if (widget.role == 'student' &&
                                    !value.endsWith('@muj.manipal.edu')) {
                                  return 'Student email must end with @muj.manipal.edu';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            InputField(
                              label: 'Phone Number',
                              hint: 'Enter your 10-digit phone number',
                              controller: _phoneNumberController,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                if (value.length != 10 ||
                                    !RegExp(r'^\d{10}$').hasMatch(value)) {
                                  return 'Please enter a valid 10-digit phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            if (widget.role == 'student') ...[
                              InputField(
                                label: 'Registration Number',
                                hint: 'Enter your registration number',
                                controller: _registrationNumberController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your registration number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              InputField(
                                label: 'Course',
                                hint: 'Enter your course (e.g., B.Tech)',
                                controller: _courseController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your course';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildResponsiveDropdown(
                                label: 'Branch',
                                hint: 'Select your branch',
                                items: _branchOptions,
                                value: _selectedBranch,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedBranch = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select your branch';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: InputField(
                                      label: 'Current Year',
                                      hint: 'Year',
                                      controller: _currentYearController,
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        final year = int.tryParse(value);
                                        if (year == null ||
                                            year < 1 ||
                                            year > 5) {
                                          return 'Invalid year';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: InputField(
                                      label: 'Current Semester',
                                      hint: 'Semester',
                                      controller: _currentSemesterController,
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Required';
                                        }
                                        final semester = int.tryParse(value);
                                        if (semester == null ||
                                            semester < 1 ||
                                            semester > 10) {
                                          return 'Invalid semester';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              _buildResponsiveDropdown(
                                label: 'Department',
                                hint: 'Select your department',
                                items: _departmentOptions,
                                value: _selectedDepartment,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDepartment = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select your department';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ] else ...[
                            Text(
                              'Verify OTP',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter the OTP sent to your email',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            InputField(
                              label: 'OTP',
                              hint: 'Enter OTP',
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter OTP';
                                }
                                if (value.length < 6) {
                                  return 'OTP must be 6 digits';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed:
                                      authProvider.isLoading ? null : _register,
                                  child: const Text('Resend OTP'),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 32),
                          ButtonWidget(
                            text: _otpSent ? 'Verify & Register' : 'Register',
                            onPressed: _otpSent ? _verifyOtp : _register,
                            isLoading: authProvider.isLoading,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account?'),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pushReplacementNamed(
                                    AppRouter.loginRoute,
                                    arguments: {'role': widget.role},
                                  );
                                },
                                child: const Text('Login'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
