import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'package:bcrypt/bcrypt.dart';

class ApiService {
  static const String senderEmail = 'nguyennquoctuann1122@gmail.com';
  static const String appPassword = 'dirlcglxnrmktjed';

  static const String baseUrl = 'https://6957633bf7ea690182d1e524.mockapi.io/';

  static final smtpServer = gmail(senderEmail, appPassword);

  // Gửi OTP thật qua email
  Future<String> sendOtp(String toEmail) async {
    final otp = Random().nextInt(999999).toString().padLeft(6, '0');

    final message = Message()
      ..from = Address(senderEmail, 'Auth App')
      ..recipients.add(toEmail)
      ..subject =
          'Mã OTP xác thực - ${DateTime.now().toString().substring(0, 19)}'
      ..text = 'Mã OTP của bạn là: $otp\nHiệu lực trong 5 phút.'
      ..html =
          '''
        <div style="font-family: Arial; padding: 20px;">
          <h2>Xác thực tài khoản</h2>
          <p>Mã OTP của bạn:</p>
          <h1 style="color: #4CAF50; font-size: 48px; letter-spacing: 10px; text-align: center;">$otp</h1>
          <p>Mã này có hiệu lực trong 5 phút. Không chia sẻ với bất kỳ ai.</p>
          <p>Trân trọng,<br>ABC Team</p>
        </div>
      ''';

    try {
      final sendReport = await send(message, smtpServer);
      print('OTP sent to $toEmail → ${sendReport.toString()}');
      return otp;
    } catch (e) {
      print('Lỗi gửi email: $e');
      throw Exception(
        'Không thể gửi OTP. Kiểm tra thông tin Gmail hoặc kết nối.',
      );
    }
  }

  // Verify OTP
  bool verifyOtp(String inputOtp, String realOtp) => inputOtp == realOtp;
  // Đăng ký - Hash mật khẩu trước khi gửi lên MockAPI
  Future<bool> register(
    String email,
    String username,
    String password, {
    String? fullName,
    String? dateOfBirth,
    String? phoneNumber,
  }) async {
    final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());
    final Map<String, dynamic> userData = {
      'email': email,
      'username': username,
      'password': hashedPassword,
    };

    if (fullName != null && fullName.isNotEmpty)
      userData['fullName'] = fullName;
    if (dateOfBirth != null && dateOfBirth.isNotEmpty)
      userData['dateOfBirth'] = dateOfBirth;
    if (phoneNumber != null && phoneNumber.isNotEmpty)
      userData['phoneNumber'] = phoneNumber;

    final res = await http.post(
      Uri.parse('${baseUrl}users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );
    return res.statusCode == 201;
  }

  // Đăng nhập
  Future<User?> login(String username, String password) async {
    final res = await http.get(Uri.parse('${baseUrl}users'));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);

      // Tìm user có username khớp
      final matchedUsers = data
          .where((u) => u['username'] == username)
          .toList();

      if (matchedUsers.isNotEmpty) {
        final storedHash = matchedUsers[0]['password'] as String;

        // Kiểm tra mật khẩu người dùng nhập có khớp với hash lưu trữ không
        if (BCrypt.checkpw(password, storedHash)) {
          final user = User.fromJson(matchedUsers[0]);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', user.id);
          return user;
        }
      }
    }
    return null;
  }

  // Đổi mật khẩu
  Future<bool> changePassword(String userId, String newPassword) async {
    final hashedNewPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());

    final res = await http.put(
      Uri.parse('${baseUrl}users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': hashedNewPassword}),
    );
    return res.statusCode == 200;
  }

  // Cập nhật avatar (mock URL)
  Future<bool> updateAvatar(String userId, String avatarUrl) async {
    final res = await http.put(
      Uri.parse('${baseUrl}users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'avatar': avatarUrl}),
    );
    return res.statusCode == 200;
  }

  // Cập nhật thông tin cá nhân
  Future<bool> updateProfile(
    String userId, {
    String? fullName,
    String? dateOfBirth,
    String? phoneNumber,
  }) async {
    final Map<String, dynamic> updateData = {};
    if (fullName != null) updateData['fullName'] = fullName;
    if (dateOfBirth != null) updateData['dateOfBirth'] = dateOfBirth;
    if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;

    final res = await http.put(
      Uri.parse('${baseUrl}users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updateData),
    );
    return res.statusCode == 200;
  }

  // Lấy thông tin user hiện tại
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return null;

    final res = await http.get(Uri.parse('${baseUrl}users/$userId'));
    if (res.statusCode == 200) {
      return User.fromJson(jsonDecode(res.body));
    }
    return null;
  }

  Future<bool> isUsernameTaken(String username) async {
    try {
      final res = await http.get(
        Uri.parse('${baseUrl}users?username=$username'),
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.isNotEmpty;
      }
      return false;
    } catch (e) {
      print('Error checking username: $e');
      return false;
    }
  }
}
