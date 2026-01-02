import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  String? _sentOtp;
  bool _isLoading = false;

  final _api = ApiService();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _api.getCurrentUser();
    setState(() => _currentUser = user);
  }

  Future<void> _sendOtp() async {
    if (_currentUser == null) {
      Fluttertoast.showToast(msg: 'Không tìm thấy thông tin người dùng');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final otp = await _api.sendOtp(_currentUser!.email);
      setState(() {
        _sentOtp = otp;
        _isLoading = false;
      });
      Fluttertoast.showToast(msg: 'Đã gửi OTP về email của bạn');
    } catch (e) {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  Future<void> _changePassword() async {
    if (_sentOtp == null) {
      Fluttertoast.showToast(msg: 'Vui lòng gửi OTP trước');
      return;
    }

    // Kiểm tra mật khẩu trên 6 ký tự
    final newPassword = _newPasswordCtrl.text;
    if (newPassword.length < 6) {
      Fluttertoast.showToast(msg: 'Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }

    if (newPassword != _confirmPasswordCtrl.text) {
      Fluttertoast.showToast(msg: 'Mật khẩu xác nhận không khớp');
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

    if (_currentUser == null) return;

    setState(() => _isLoading = true);

    final success = await _api.changePassword(
      _currentUser!.id,
      _newPasswordCtrl.text,
    );

    setState(() => _isLoading = false);

    if (success) {
      Fluttertoast.showToast(msg: 'Đổi mật khẩu thành công');
      Navigator.pop(context);
    } else {
      Fluttertoast.showToast(msg: 'Đổi mật khẩu thất bại');
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
          'Đổi mật khẩu',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card thông tin
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
                              Icons.lock_reset_rounded,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Mật khẩu mới',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _newPasswordCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu mới (tối thiểu 6 ký tự)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lock_rounded),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmPasswordCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Xác nhận mật khẩu mới',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _sentOtp == null && !_isLoading ? _sendOtp : null,
                icon: const Icon(Icons.send_rounded),
                label: Text(
                  _sentOtp == null ? 'Gửi OTP xác nhận' : 'OTP đã gửi',
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
                  onPressed: _isLoading ? null : _changePassword,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text(
                    'Xác nhận đổi mật khẩu',
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
}
