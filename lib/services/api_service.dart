import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class ApiService {
  // Gmail gửi OTP
  static const String senderEmail = 'nguyennquoctuann1122@gmail.com';
  static const String appPassword = 'dirlcglxnrmktjed';

  // MockAPI base URL
  static const String baseUrl =
      'https://695dbd7e2556fd22f6764a66.mockapi.io/users';

  // Cloudinary cho upload avatar
  static const String cloudinaryCloudName = 'dbbejdp8a';
  static const String cloudinaryUploadPreset = 'flutter_avatar_upload';

  static final smtpServer = gmail(senderEmail, appPassword);

  // Gửi OTP qua email
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
        <div style="font-family: Arial; padding: 20px; text-align: center;">
          <h2>Xác thực tài khoản</h2>
          <p>Mã OTP của bạn:</p>
          <h1 style="color: #4CAF50; font-size: 48px; letter-spacing: 10px;">$otp</h1>
          <p>Mã này có hiệu lực trong 5 phút. Không chia sẻ với bất kỳ ai.</p>
          <p>Trân trọng,<br>Auth App Team</p>
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

  // So sánh OTP (demo client-side)
  bool verifyOtp(String inputOtp, String realOtp) => inputOtp.trim() == realOtp;

  // Kiểm tra username đã tồn tại chưa
  Future<bool> isUsernameTaken(String username) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl?username=$username'));
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

  // Đăng ký user (hash password + lưu thông tin bổ sung)
  Future<bool> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
    String? dateOfBirth,
    String? phoneNumber,
  }) async {
    final hashedPassword = BCrypt.hashpw(
      password,
      BCrypt.gensalt(logRounds: 10),
    );

    final body = {
      'email': email.trim(),
      'username': username.trim(),
      'password': hashedPassword,
      if (fullName != null && fullName.trim().isNotEmpty)
        'fullName': fullName.trim(),
      if (dateOfBirth != null && dateOfBirth.trim().isNotEmpty)
        'dateOfBirth': dateOfBirth.trim(),
      if (phoneNumber != null && phoneNumber.trim().isNotEmpty)
        'phoneNumber': phoneNumber.trim(),
    };

    final res = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    return res.statusCode == 201;
  }

  // Đăng nhập (so sánh hash)
  Future<User?> login(String username, String password) async {
    final res = await http.get(Uri.parse('$baseUrl?username=$username'));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      if (data.isNotEmpty) {
        final storedHash = data[0]['password'] as String;
        if (BCrypt.checkpw(password, storedHash)) {
          final user = User.fromJson(data[0]);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', user.id);
          return user;
        }
      }
    }
    return null;
  }

  // Lấy thông tin user hiện tại từ MockAPI
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return null;

    final res = await http.get(Uri.parse('$baseUrl/$userId'));
    if (res.statusCode == 200) {
      return User.fromJson(jsonDecode(res.body));
    }
    return null;
  }

  // Upload ảnh lên Cloudinary (unsigned)
  Future<String?> uploadAvatar(File imageFile) async {
    try {
      print('Starting upload for file: ${imageFile.path}');
      print('File exists: ${await imageFile.exists()}');

      final cloudinary = CloudinaryPublic(
        cloudinaryCloudName,
        cloudinaryUploadPreset,
        cache: false,
      );

      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      final uploadedUrl = response.secureUrl;
      print('Avatar uploaded to Cloudinary: $uploadedUrl');
      return uploadedUrl;
    } catch (e) {
      print('Cloudinary upload error: $e');
      // Trả về URL placeholder để test flow
      print('Error details: ${e.toString()}');
      if (e.toString().contains('400')) {
        print('Bad request - check Cloudinary upload preset configuration');
        print('Upload preset should be "unsigned" in Cloudinary dashboard');
      }
      return null;
    }
  }

  // Cập nhật avatar: upload lên Cloudinary rồi lưu URL vào MockAPI
  // Nếu Cloudinary thất bại, lưu base64 vào MockAPI
  Future<bool> updateAvatar(String userId, File imageFile) async {
    String avatarData;

    // Thử upload lên Cloudinary trước
    final cloudinaryUrl = await uploadAvatar(imageFile);

    if (cloudinaryUrl != null) {
      avatarData = cloudinaryUrl;
    } else {
      // Fallback: Convert to base64 and save directly
      print('Falling back to base64 storage...');
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      avatarData = 'data:image/jpeg;base64,$base64Image';
      print('Image converted to base64, size: ${base64Image.length} chars');
    }

    final res = await http.put(
      Uri.parse('$baseUrl/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'avatar': avatarData}),
    );

    if (res.statusCode == 200) {
      print('Avatar updated successfully in MockAPI');
      return true;
    } else {
      print('Failed to update avatar in MockAPI: ${res.statusCode}');
      return false;
    }
  }

  // Cập nhật thông tin profile
  Future<bool> updateProfile(
    String userId, {
    String? fullName,
    String? dateOfBirth,
    String? phoneNumber,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (dateOfBirth != null) body['dateOfBirth'] = dateOfBirth;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;

    if (body.isEmpty) return false;

    final res = await http.put(
      Uri.parse('$baseUrl/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    return res.statusCode == 200;
  }

  // Đổi mật khẩu (hash mật khẩu mới)
  Future<bool> changePassword(String userId, String newPassword) async {
    final hashedNewPassword = BCrypt.hashpw(
      newPassword,
      BCrypt.gensalt(logRounds: 10),
    );

    final res = await http.put(
      Uri.parse('$baseUrl/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': hashedNewPassword}),
    );

    return res.statusCode == 200;
  }
}
