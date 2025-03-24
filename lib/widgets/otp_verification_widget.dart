import 'package:flutter/material.dart';
import 'package:campus_connect/widgets/input_field.dart';
import 'package:campus_connect/widgets/button_widget.dart';

class OtpVerificationWidget extends StatefulWidget {
  final String email;
  final Function(String) onVerified;
  final VoidCallback onCancel;

  const OtpVerificationWidget({
    Key? key,
    required this.email,
    required this.onVerified,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<OtpVerificationWidget> createState() => _OtpVerificationWidgetState();
}

class _OtpVerificationWidgetState extends State<OtpVerificationWidget> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Verify OTP',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            InputField(
              label: 'OTP',
              hint: 'Enter OTP sent to your email',
              controller: _otpController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    widget.onVerified(_otpController.text);
                  },
                  child: const Text('Verify'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
