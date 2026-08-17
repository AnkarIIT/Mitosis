import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum EmailDeliveryMode { clientDirect, backend }

class EmailSendResult {
  final bool success;
  final String message;

  const EmailSendResult({required this.success, required this.message});

  factory EmailSendResult.ok(String message) =>
      EmailSendResult(success: true, message: message);

  factory EmailSendResult.fail(String message) =>
      EmailSendResult(success: false, message: message);
}

class EmailService {
  static const String _secureApiKeyKey = 'resend_api_key_secure';
  static const String _senderPrefsKey = 'resend_sender_email';
  static const String _deliveryModePrefsKey = 'email_delivery_mode';
  static const String _backendUrlPrefsKey = 'email_backend_url';

  String? _apiKey;
  String? _senderEmail;
  EmailDeliveryMode _deliveryMode = EmailDeliveryMode.clientDirect;
  String? _backendUrl;
  final http.Client _client;
  final FlutterSecureStorage _secureStorage;

  EmailService({http.Client? client, FlutterSecureStorage? secureStorage})
      : _client = client ?? http.Client(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  String? get apiKey => _apiKey;
  String? get senderEmail => _senderEmail;
  EmailDeliveryMode get deliveryMode => _deliveryMode;
  String? get backendUrl => _backendUrl;

  bool get isConfigured =>
      _apiKey != null &&
      _apiKey!.trim().isNotEmpty &&
      _senderEmail != null &&
      _senderEmail!.trim().isNotEmpty;

  bool get isBackendConfigured =>
      _deliveryMode == EmailDeliveryMode.backend &&
      _backendUrl != null &&
      _backendUrl!.trim().isNotEmpty;

  Future<void> loadConfig() async {
    _apiKey = (await _secureStorage.read(key: _secureApiKeyKey))?.trim();
    final prefs = await SharedPreferences.getInstance();
    _senderEmail = prefs.getString(_senderPrefsKey)?.trim();
    final savedMode = prefs.getString(_deliveryModePrefsKey);
    _deliveryMode = savedMode == EmailDeliveryMode.backend.name
        ? EmailDeliveryMode.backend
        : EmailDeliveryMode.clientDirect;
    _backendUrl = prefs.getString(_backendUrlPrefsKey)?.trim();
  }

  Future<void> saveApiKey(String apiKey) async {
    final cleaned = apiKey.trim();
    _apiKey = cleaned;
    await _secureStorage.write(key: _secureApiKeyKey, value: cleaned);
  }

  Future<void> saveSenderEmail(String senderEmail) async {
    final prefs = await SharedPreferences.getInstance();
    final cleaned = senderEmail.trim();
    _senderEmail = cleaned;
    await prefs.setString(_senderPrefsKey, cleaned);
  }

  Future<void> saveDeliveryMode(EmailDeliveryMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    _deliveryMode = mode;
    await prefs.setString(_deliveryModePrefsKey, mode.name);
  }

  Future<void> saveBackendUrl(String backendUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final cleaned = backendUrl.trim();
    _backendUrl = cleaned;
    await prefs.setString(_backendUrlPrefsKey, cleaned);
  }

  Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = null;
    _senderEmail = null;
    _deliveryMode = EmailDeliveryMode.clientDirect;
    _backendUrl = null;
    await _secureStorage.delete(key: _secureApiKeyKey);
    await prefs.remove(_senderPrefsKey);
    await prefs.remove(_deliveryModePrefsKey);
    await prefs.remove(_backendUrlPrefsKey);
  }

  Map<String, dynamic> buildPayload({
    required String to,
    required String subject,
    required String html,
    String? text,
    String? from,
  }) {
    return {
      'from': from ?? _senderEmail ?? 'noreply@example.com',
      'to': to,
      'subject': subject,
      'html': html,
      if (text != null && text.isNotEmpty) 'text': text,
    };
  }

  Future<EmailSendResult> _sendViaBackend(Map<String, dynamic> payload) async {
    if (!isBackendConfigured) {
      return EmailSendResult.fail(
        'Backend email mode is enabled, but no backend URL is configured yet.',
      );
    }

    try {
      final response = await _client.post(
        Uri.parse(_backendUrl!),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return EmailSendResult.ok('Email sent successfully via backend.');
      }

      final body = response.body;
      return EmailSendResult.fail(
        'Backend email failed (${response.statusCode}). ${body.isNotEmpty ? body : 'Unknown error'}',
      );
    } catch (e) {
      return EmailSendResult.fail('Backend email failed: $e');
    }
  }

  Future<EmailSendResult> _sendViaResend(Map<String, dynamic> payload) async {
    if (!isConfigured) {
      return EmailSendResult.fail(
        'Configure a Resend API key and sender email in Settings before sending emails.',
      );
    }

    try {
      final response = await _client.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer ${_apiKey!}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return EmailSendResult.ok('Email sent successfully.');
      }

      final body = response.body;
      return EmailSendResult.fail(
        'Email send failed (${response.statusCode}). ${body.isNotEmpty ? body : 'Unknown error'}',
      );
    } catch (e) {
      return EmailSendResult.fail('Email send failed: $e');
    }
  }

  Future<EmailSendResult> sendTransactionalEmail({
    required String to,
    required String subject,
    required String html,
    String? text,
    String? from,
  }) async {
    await loadConfig();

    final payload = buildPayload(
      to: to,
      subject: subject,
      html: html,
      text: text,
      from: from,
    );

    if (_deliveryMode == EmailDeliveryMode.backend) {
      return _sendViaBackend(payload);
    }

    return _sendViaResend(payload);
  }

  Future<EmailSendResult> sendWelcomeEmail({
    required String to,
    required String username,
  }) async {
    final subject = 'Welcome to NEET Mitos!';
    final html =
        '''
      <div style="font-family: Arial, sans-serif; color: #1f2937;">
        <h2 style="color: #2563eb;">Welcome to NEET Mitos, $username!</h2>
        <p>You're all set to start your NEET preparation journey.</p>
        <p>From here, you can track your study progress, revise topics, and use your AI tutor for doubts.</p>
        <p>Need help? Reach out anytime and keep practicing.</p>
        <p style="margin-top: 24px; color: #6b7280;">Best regards,<br/>NEET Mitos Team</p>
      </div>
    ''';

    return sendTransactionalEmail(
      to: to,
      subject: subject,
      html: html,
      text: 'Welcome to NEET Mitos, $username! Start your study journey today.',
    );
  }

  Future<EmailSendResult> sendOtpEmail({
    required String to,
    required String otp,
    required String purpose,
  }) async {
    final subject = 'Your $purpose code';
    final html =
        '''
      <div style="font-family: Arial, sans-serif; color: #1f2937;">
        <h2 style="color: #2563eb;">Your verification code</h2>
        <p>Use this code to complete your $purpose:</p>
        <p style="font-size: 28px; font-weight: 700; letter-spacing: 4px; color: #111827;">$otp</p>
        <p>If you did not request this, you can ignore this message.</p>
      </div>
    ''';

    return sendTransactionalEmail(
      to: to,
      subject: subject,
      html: html,
      text: 'Your $purpose code is $otp',
    );
  }

  Future<EmailSendResult> sendStudyReminderEmail({
    required String to,
    required String username,
    required String topic,
  }) async {
    final subject = 'Study reminder from NEET Mitos';
    final html =
        '''
      <div style="font-family: Arial, sans-serif; color: #1f2937;">
        <h2 style="color: #2563eb;">Hi $username,</h2>
        <p>Just a quick reminder to keep your NEET preparation going.</p>
        <p>Today’s focus topic: <strong>$topic</strong></p>
        <p>Small consistent practice will help you improve faster.</p>
      </div>
    ''';

    return sendTransactionalEmail(
      to: to,
      subject: subject,
      html: html,
      text: 'Hi $username, your focus topic today is $topic.',
    );
  }
}
