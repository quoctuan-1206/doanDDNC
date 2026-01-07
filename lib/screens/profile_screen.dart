import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../models/user.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();
  User? _user;
  bool _isLoading = true;
  bool _isUpdating = false;
  File? _pickedImage; // Ảnh tạm thời để preview trước khi lưu

  final _fullNameCtrl = TextEditingController();
  final _dateOfBirthCtrl = TextEditingController();
  final _phoneNumberCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _api.getCurrentUser();
    if (!mounted) return;

    setState(() {
      _user = user;
      _isLoading = false;
      if (user != null) {
        _fullNameCtrl.text = user.fullName ?? '';
        _dateOfBirthCtrl.text = user.dateOfBirth ?? '';
        _phoneNumberCtrl.text = user.phoneNumber ?? '';
      }
    });
  }

  Future<void> _pickAndUpdateAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null || _user == null) return;

    setState(() {
      _pickedImage = File(pickedFile.path);
      _isUpdating = true;
    });

    final success = await _api.updateAvatar(_user!.id, _pickedImage!);

    if (!mounted) return;

    setState(() => _isUpdating = false);

    if (success) {
      Fluttertoast.showToast(msg: 'Đã cập nhật ảnh đại diện');
      await _loadUser(); // Reload để lấy URL mới từ server
    } else {
      Fluttertoast.showToast(msg: 'Cập nhật ảnh thất bại');
      setState(() => _pickedImage = null); // Reset preview nếu thất bại
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('vi', 'VN'),
    );

    if (picked != null && mounted) {
      setState(() {
        _dateOfBirthCtrl.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_user == null) return;

    final fullName = _fullNameCtrl.text.trim();
    final dob = _dateOfBirthCtrl.text.trim();
    final phone = _phoneNumberCtrl.text.trim();

    // Validate phone
    if (phone.isNotEmpty) {
      if (phone.length != 10) {
        Fluttertoast.showToast(msg: 'Số điện thoại phải đủ 10 số');
        return;
      }
      if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
        Fluttertoast.showToast(msg: 'Số điện thoại chỉ được chứa chữ số');
        return;
      }
    }

    // Validate DOB (đơn giản)
    if (dob.isNotEmpty && !RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(dob)) {
      Fluttertoast.showToast(msg: 'Ngày sinh không đúng định dạng dd/mm/yyyy');
      return;
    }

    setState(() => _isUpdating = true);

    final success = await _api.updateProfile(
      _user!.id,
      fullName: fullName.isEmpty ? null : fullName,
      dateOfBirth: dob.isEmpty ? null : dob,
      phoneNumber: phone.isEmpty ? null : phone,
    );

    if (!mounted) return;

    setState(() => _isUpdating = false);

    if (success) {
      Fluttertoast.showToast(msg: 'Cập nhật thông tin thành công');
      await _loadUser();
    } else {
      Fluttertoast.showToast(msg: 'Cập nhật thất bại');
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Không tìm thấy thông tin người dùng'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _logout,
                child: const Text('Đăng nhập lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text(
          'Hồ sơ cá nhân',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header gradient
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue, Colors.blue.shade300],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _isUpdating ? null : _pickAndUpdateAvatar,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 65,
                            backgroundImage: _pickedImage != null
                                ? FileImage(_pickedImage!)
                                : (_user!.avatar.isNotEmpty
                                      ? NetworkImage(_user!.avatar)
                                      : null),
                            backgroundColor: Colors.blue.shade100,
                            child: _pickedImage == null && _user!.avatar.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 65,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                        if (_isUpdating)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                ),
                              ),
                            ),
                          )
                        else
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _user!.fullName ?? _user!.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.email_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _user!.email,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),

            // Form chỉnh sửa
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
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
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Thông tin cá nhân',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _fullNameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Họ và tên',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _dateOfBirthCtrl,
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            decoration: InputDecoration(
                              labelText: 'Ngày sinh',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.cake_rounded),
                              suffixIcon: const Icon(
                                Icons.calendar_today_rounded,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _phoneNumberCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Số điện thoại',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.phone_rounded),
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
                    icon: _isUpdating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: const Text(
                      'Lưu thông tin',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                    ),
                    onPressed: _isUpdating ? null : _updateProfile,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.lock_reset_rounded),
                    label: const Text(
                      'Đổi mật khẩu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _dateOfBirthCtrl.dispose();
    _phoneNumberCtrl.dispose();
    super.dispose();
  }
}
