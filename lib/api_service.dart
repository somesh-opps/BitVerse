import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Centralised API client for the CropIntel Flask backend.
/// Base URL
class ApiService {
  static const String _base = 'http://10.35.146.180:5000';
  static const String _geminiBase = 'http://10.35.146.180:8001';
  static const Duration _timeout = Duration(seconds: 15);

  // ─────────────────────────────────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────────────────────────────────

  static Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Executes [call] and wraps network / timeout errors into a uniform map.
  static Future<Map<String, dynamic>> _safe(
      Future<Map<String, dynamic>> Function() call) async {
    try {
      return await call();
    } on SocketException {
      return {
        'status': 'error',
        'message': 'Unable to reach server. Check your internet connection.',
      };
    } on TimeoutException {
      return {
        'status': 'error',
        'message': 'Request timed out. Please try again.',
      };
    } on http.ClientException catch (e) {
      return {'status': 'error', 'message': 'Network error: ${e.message}'};
    } on FormatException {
      return {
        'status': 'error',
        'message': 'Unexpected server response. Please try again.',
      };
    } catch (e) {
      return {'status': 'error', 'message': 'Something went wrong. Please try again.'};
    }
  }

  /// Safely parses the HTTP response body as JSON.
  /// Returns an error map instead of throwing if the body is not valid JSON.
  static Map<String, dynamic> _parse(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      // Wrap non-map JSON (arrays, primitives) in an error
      return {'status': 'error', 'message': 'Unexpected response format.'};
    } on FormatException {
      // Server returned HTML / plain-text (e.g. a 404/500 page)
      if (res.statusCode >= 500) {
        return {'status': 'error', 'message': 'Server error (${res.statusCode}). Please try again later.'};
      }
      if (res.statusCode == 404) {
        return {'status': 'error', 'message': 'API endpoint not found. Check server configuration.'};
      }
      return {'status': 'error', 'message': 'Unexpected server response (HTTP ${res.statusCode}).' };
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Registration
  // ─────────────────────────────────────────────────────────────────────────

  /// POST /send-otp  – sends an OTP to [email] for new-account verification.
  static Future<Map<String, dynamic>> sendOtp(String email) =>
      _safe(() async {
        final res = await http
            .post(
              Uri.parse('$_base/send-otp'),
              headers: _jsonHeaders,
              body: jsonEncode({'email': email}),
            )
            .timeout(_timeout);
        return _parse(res);
      });

  /// POST /register  – creates a new account after OTP verification.
  static Future<Map<String, dynamic>> register({
    required String name,
    required String userId,
    required String email,
    required String password,
    required String otp,
  }) =>
      _safe(() async {
        final res = await http
            .post(
              Uri.parse('$_base/register'),
              headers: _jsonHeaders,
              body: jsonEncode({
                'name': name,
                'user_id': userId,
                'email': email,
                'password': password,
                'otp': otp,
              }),
            )
            .timeout(_timeout);
        return _parse(res);
      });

  // ─────────────────────────────────────────────────────────────────────────
  //  Login
  // ─────────────────────────────────────────────────────────────────────────

  /// POST /login  – accepts email or username as [identifier].
  /// On success returns `{'status':'success','user':{'name','user_id','email'}}`.
  static Future<Map<String, dynamic>> login(
          String identifier, String password) =>
      _safe(() async {
        final res = await http
            .post(
              Uri.parse('$_base/login'),
              headers: _jsonHeaders,
              body: jsonEncode({
                'identifier': identifier,
                'password': password,
              }),
            )
            .timeout(_timeout);
        return _parse(res);
      });

  // ─────────────────────────────────────────────────────────────────────────
  //  Password reset (3-step)
  // ─────────────────────────────────────────────────────────────────────────

  /// POST /reset-password/send-otp  – email must already be registered.
  static Future<Map<String, dynamic>> resetSendOtp(String email) =>
      _safe(() async {
        final res = await http
            .post(
              Uri.parse('$_base/reset-password/send-otp'),
              headers: _jsonHeaders,
              body: jsonEncode({'email': email}),
            )
            .timeout(_timeout);
        return _parse(res);
      });

  /// POST /reset-password/verify-otp
  static Future<Map<String, dynamic>> resetVerifyOtp(
          String email, String otp) =>
      _safe(() async {
        final res = await http
            .post(
              Uri.parse('$_base/reset-password/verify-otp'),
              headers: _jsonHeaders,
              body: jsonEncode({'email': email, 'otp': otp}),
            )
            .timeout(_timeout);
        return _parse(res);
      });

  /// POST /reset-password/reset
  static Future<Map<String, dynamic>> resetPassword(
          String email, String newPassword) =>
      _safe(() async {
        final res = await http
            .post(
              Uri.parse('$_base/reset-password/reset'),
              headers: _jsonHeaders,
              body: jsonEncode({
                'email': email,
                'new_password': newPassword,
              }),
            )
            .timeout(_timeout);
        return _parse(res);
      });

  // ─────────────────────────────────────────────────────────────────────────
  //  Personalization
  // ─────────────────────────────────────────────────────────────────────────

  /// POST /personalization  – saves farmer profile details.
  static Future<Map<String, dynamic>> savePersonalization({
    String? email,
    String? userId,
    required String gender,
    required int age,
    String? cropType,
    String? region,
    String? soilType,
  }) =>
      _safe(() async {
        final body = <String, dynamic>{
          if (email != null) 'email': email,
          if (userId != null) 'user_id': userId,
          'gender': gender,
          'age': age,
          if (cropType != null) 'crop_type': cropType,
          if (region != null && region.isNotEmpty) 'region': region,
          if (soilType != null) 'soil_type': soilType,
        };
        final res = await http
            .post(
              Uri.parse('$_base/personalization'),
              headers: _jsonHeaders,
              body: jsonEncode(body),
            )
            .timeout(_timeout);
        return _parse(res);
      });

  /// GET /personalization
  static Future<Map<String, dynamic>> getPersonalization({
    String? email,
    String? userId,
  }) =>
      _safe(() async {
        final params = <String, String>{};
        if (email != null) params['email'] = email;
        if (userId != null) params['user_id'] = userId;
        final uri =
            Uri.parse('$_base/personalization').replace(queryParameters: params);
        final res = await http.get(uri, headers: _jsonHeaders).timeout(_timeout);
        return _parse(res);
      });

  // ─────────────────────────────────────────────────────────────────────────
  //  Profile
  // ─────────────────────────────────────────────────────────────────────────

  /// POST /profile/update  – updates the user's display name.
  static Future<Map<String, dynamic>> updateProfile({
    String? email,
    String? userId,
    required String name,
  }) =>
      _safe(() async {
        final res = await http
            .post(
              Uri.parse('$_base/profile/update'),
              headers: _jsonHeaders,
              body: jsonEncode({
                if (email != null) 'email': email,
                if (userId != null) 'user_id': userId,
                'name': name,
              }),
            )
            .timeout(_timeout);
        return _parse(res);
      });

  /// POST /profile/upload-image  – multipart form upload.
  /// Returns `{'status':'success','data':{'url':..., 'filename':...}}`
  static Future<Map<String, dynamic>> uploadProfileImage({
    String? email,
    String? userId,
    required File imageFile,
  }) =>
      _safe(() async {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$_base/profile/upload-image'),
        );
        if (email != null) request.fields['email'] = email;
        if (userId != null) request.fields['user_id'] = userId;
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
        final streamed = await request.send().timeout(_timeout);
        final res = await http.Response.fromStream(streamed);
        return _parse(res);
      });

  /// Builds the full URL for a profile image path returned by the server.
  static String profileImageUrl(String path) {
    if (path.startsWith('http')) return path;
    return '$_base$path';
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Gemini-based AI Feed & Chat
  // ─────────────────────────────────────────────────────────────────────────

  /// POST /news-feed – fetches a personalized news feed from the Gemini server.
  static Future<Map<String, dynamic>> getNewsFeed({
    String region = 'General',
    String weatherData = '',
    String soilData = '',
    List<String> plantsOfInterest = const [],
  }) =>
      _safe(() async {
        final res = await http
            .post(
              Uri.parse('$_geminiBase/news-feed'),
              headers: _jsonHeaders,
              body: jsonEncode({
                'region': region,
                'weather_data': weatherData,
                'soil_data': soilData,
                'plants_of_interest': plantsOfInterest,
              }),
            )
            .timeout(const Duration(seconds: 90)); // Gemini can take up to 60-90s under load
        return _parse(res);
      });

  /// POST /plant-chat – chats with the Gemini plant expert.
  static Future<Map<String, dynamic>> chatWithGemini({
    required String query,
    String weatherData = '',
    String soilData = '',
  }) =>
      _safe(() async {
        final res = await http
            .post(
              Uri.parse('$_geminiBase/plant-chat'),
              headers: _jsonHeaders,
              body: jsonEncode({
                'query': query,
                'weather_data': weatherData,
                'soil_data': soilData,
              }),
            )
            .timeout(_timeout);
        return _parse(res);
      });
}
