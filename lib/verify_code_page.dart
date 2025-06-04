import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'auth_service.dart';
import 'dart:async';
import 'app_theme.dart';

class VerifyCodePage extends StatefulWidget {
  final String email;
  final bool isSignUp;

  const VerifyCodePage({
    Key? key,
    required this.email,
    this.isSignUp = true,
  }) : super(key: key);

  @override
  _VerifyCodePageState createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  final AuthService _authService = AuthService();
  final TextEditingController _pinController = TextEditingController();

  bool _isLoading = false;
  bool _isResending = false;
  String _errorMessage = '';
  int _remainingTime = 300;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        _timer.cancel();
      }
    });
  }

  Future<void> _verifyCode() async {
    if (_pinController.text.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final isValid = await _authService.verifyCode(
        widget.email,
        _pinController.text,
      );

      if (isValid) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home'); // ✅ direct to home
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Invalid verification code. Please try again.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error verifying code: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    if (_remainingTime > 0) return;

    setState(() {
      _isResending = true;
      _errorMessage = '';
    });

    try {
      await _authService.sendVerificationCode(widget.email);

      if (mounted) {
        setState(() {
          _isResending = false;
          _remainingTime = 300;
          _startTimer();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code resent')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error sending code: ${e.toString()}';
          _isResending = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _pinController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        elevation: 0,
        backgroundColor: AppTheme.primaryBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              'Verification Code',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Please enter the 6-digit code sent to ${widget.email}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _pinController,
                onChanged: (value) {
                  if (_errorMessage.isNotEmpty) {
                    setState(() {
                      _errorMessage = '';
                    });
                  }
                },
                onCompleted: (_) => _verifyCode(),
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(8),
                  fieldHeight: 50,
                  fieldWidth: 40,
                  activeFillColor: Colors.white,
                  inactiveFillColor: Colors.white,
                  selectedFillColor: Colors.white,
                  activeColor: AppTheme.primaryBlue,
                  inactiveColor: Colors.grey.shade300,
                  selectedColor: AppTheme.primaryBlue,
                ),
                keyboardType: TextInputType.number,
                enableActiveFill: true,
                animationType: AnimationType.fade,
              ),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Code expires in: '),
                Text(
                  _formatTime(_remainingTime),
                  style: TextStyle(
                    color: _remainingTime < 60 ? Colors.red : AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyCode,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: AppTheme.primaryBlue,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Verify'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _remainingTime > 0 || _isResending ? null : _resendCode,
              child: _isResending
                  ? const Text('Sending...')
                  : Text(
                _remainingTime > 0
                    ? 'Resend code in ${_formatTime(_remainingTime)}'
                    : 'Resend code',
              ),
            ),
          ],
        ),
      ),
    );
  }
}