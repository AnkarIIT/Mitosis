import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/services/email_service.dart';

void main() {
  test('buildPayload returns a complete Resend payload', () {
    final service = EmailService();

    final payload = service.buildPayload(
      to: 'student@example.com',
      subject: 'Welcome to NEET Mitos',
      html: '<p>Hello there</p>',
      text: 'Hello there',
      from: 'noreply@mitosis.app',
    );

    expect(payload['to'], 'student@example.com');
    expect(payload['subject'], 'Welcome to NEET Mitos');
    expect(payload['html'], '<p>Hello there</p>');
    expect(payload['text'], 'Hello there');
    expect(payload['from'], 'noreply@mitosis.app');
  });
}
