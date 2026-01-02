import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _dateOfBirthCtrl = TextEditingController();
  final _phoneNumberCtrl = TextEditingController();

  String? _sentOtp;
  bool _isLoading = false;
  bool _isCheckingUsername = false;

  final _api = ApiService();

  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      Fluttertoast.showToast(msg: 'Vui lòng nhập email');
      return;
    }

    // Kiểm tra email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      Fluttertoast.showToast(msg: 'Email không đúng định dạng');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final otp = await _api.sendOtp(email);
      if (mounted) {
        setState(() {
          _sentOtp = otp;
          _isLoading = false;
        });
        Fluttertoast.showToast(msg: 'Đã gửi OTP về email của bạn');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      Fluttertoast.showToast(msg: 'Không thể gửi OTP: $e');
    }
  }

  Future<bool> _checkUsernameAvailability(String username) async {
    if (username.isEmpty) return true;

    setState(() => _isCheckingUsername = true);
    final isTaken = await _api.isUsernameTaken(username.trim());
    if (mounted) {
      setState(() => _isCheckingUsername = false);
    }
    return !isTaken;
  }

  Future<void> _register() async {
    if (_sentOtp == null) {
      Fluttertoast.showToast(msg: 'Vui lòng gửi OTP trước');
      return;
    }

    // Kiểm tra OTP không rỗng
    final otp = _otpCtrl.text.trim();
    if (otp.isEmpty) {
      Fluttertoast.showToast(msg: 'Vui lòng nhập mã OTP');
      return;
    }

    if (!_api.verifyOtp(otp, _sentOtp!)) {
      Fluttertoast.showToast(msg: 'Mã OTP không đúng');
      return;
    }

    final username = _usernameCtrl.text.trim();
    if (username.isEmpty) {
      Fluttertoast.showToast(msg: 'Vui lòng nhập tên đăng nhập');
      return;
    }

    // Kiểm tra mật khẩu trên 6 ký tự
    final password = _passwordCtrl.text;
    if (password.length < 6) {
      Fluttertoast.showToast(msg: 'Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }

    // Kiểm tra số điện thoại nếu có nhập
    final phoneNumber = _phoneNumberCtrl.text.trim();
    if (phoneNumber.isNotEmpty && phoneNumber.length != 10) {
      Fluttertoast.showToast(msg: 'Số điện thoại phải đủ 10 số');
      return;
    }
    if (phoneNumber.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(phoneNumber)) {
      Fluttertoast.showToast(msg: 'Số điện thoại chỉ được chứa chữ số');
      return;
    }

    // Kiểm tra username có tồn tại chưa
    final isAvailable = await _checkUsernameAvailability(username);
    if (!isAvailable) {
      Fluttertoast.showToast(
        msg: 'Tên đăng nhập đã được sử dụng, vui lòng chọn tên khác',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _api.register(
        _emailCtrl.text.trim(),
        username,
        _passwordCtrl.text,
        fullName: _fullNameCtrl.text.trim().isEmpty
            ? null
            : _fullNameCtrl.text.trim(),
        dateOfBirth: _dateOfBirthCtrl.text.trim().isEmpty
            ? null
            : _dateOfBirthCtrl.text.trim(),
        phoneNumber: _phoneNumberCtrl.text.trim().isEmpty
            ? null
            : _phoneNumberCtrl.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (success) {
        Fluttertoast.showToast(msg: 'Đăng ký thành công! Hãy đăng nhập');
        if (mounted) Navigator.pop(context);
      } else {
        Fluttertoast.showToast(msg: 'Đăng ký thất bại. Vui lòng thử lại');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      Fluttertoast.showToast(msg: 'Lỗi đăng ký: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text(
          'Đăng ký',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card thông tin bắt buộc
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.person_add_rounded,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Thông tin bắt buộc',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _emailCtrl,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.email_rounded),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _usernameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Tên đăng nhập',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.account_circle_rounded),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          suffixIcon: _isCheckingUsername
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu (tối thiểu 6 ký tự)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lock_rounded),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        enabled: !_isLoading,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Card thông tin tùy chọn
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.info_outline_rounded,
                              color: Colors.grey.shade700,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Thông tin tùy chọn',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _fullNameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Họ và tên',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _dateOfBirthCtrl,
                        decoration: InputDecoration(
                          labelText: 'Ngày sinh (dd/mm/yyyy)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.cake_rounded),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _phoneNumberCtrl,
                        decoration: InputDecoration(
                          labelText: 'Số điện thoại (10 số)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.phone_rounded),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        keyboardType: TextInputType.phone,
                        enabled: !_isLoading,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: (_sentOtp == null && !_isLoading) ? _sendOtp : null,
                icon: const Icon(Icons.send_rounded),
                label: Text(
                  _sentOtp == null ? 'Gửi OTP' : 'OTP đã gửi',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: _sentOtp == null ? Colors.blue : Colors.grey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                ),
              ),

              if (_sentOtp != null) ...[
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  color: Colors.green.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.mark_email_read_rounded,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'OTP đã được gửi đến email của bạn',
                                style: TextStyle(
                                  color: Colors.green.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _otpCtrl,
                          decoration: InputDecoration(
                            labelText: 'Nhập mã OTP',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.pin_rounded),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                          enabled: !_isLoading,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _register,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text(
                    'Xác nhận & Đăng ký',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _otpCtrl.dispose();
    _fullNameCtrl.dispose();
    _dateOfBirthCtrl.dispose();
    _phoneNumberCtrl.dispose();
    super.dispose();
  }
}
