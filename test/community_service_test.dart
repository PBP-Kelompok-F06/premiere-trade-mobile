import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:pbp_django_auth/pbp_django_auth.dart';
import 'package:premiere_trade/community/services/community_service.dart';

// Manual Mock for CookieRequest
class MockCookieRequest extends CookieRequest {
  String? lastUrl;
  dynamic lastBody;
  bool usePostJson = false;

  @override
  Future<dynamic> postJson(String url, dynamic data) async {
    lastUrl = url;
    lastBody = data;
    usePostJson = true;
    return {"status": "success", "message": "Mock Success"};
  }

  @override
  Future<dynamic> post(String url, dynamic data) async {
    lastUrl = url;
    lastBody = data;
    usePostJson = false; // Flag to detect if wrong method was used
    return {"status": "success"};
  }
}

void main() {
  group('CommunityService Tests', () {
    late MockCookieRequest mockRequest;
    late CommunityService service;

    setUp(() {
      mockRequest = MockCookieRequest();
      service = CommunityService(mockRequest);
    });

    test('addReply sends correct JSON using postJson', () async {
      await service.addReply(1, "Hello World");

      expect(mockRequest.usePostJson, isTrue); // Must use postJson
      expect(mockRequest.lastUrl, contains('/community/reply-flutter/1/'));
      
      final decodedBody = jsonDecode(mockRequest.lastBody);
      expect(decodedBody['content'], "Hello World");
    });

    test('addNestedReply sends correct JSON using postJson (CRITICAL FIX CHECK)', () async {
      // Ini test paling penting untuk memverifikasi bug fix sebelumnya
      await service.addNestedReply(100, "Nested Reply Content");

      expect(mockRequest.usePostJson, isTrue, reason: "addNestedReply MESTI pakai postJson, bukan post biasa!");
      expect(mockRequest.lastUrl, contains('/community/nested-reply-flutter/100/'));
      
      final decodedBody = jsonDecode(mockRequest.lastBody);
      expect(decodedBody['content'], "Nested Reply Content");
    });
  });
}
