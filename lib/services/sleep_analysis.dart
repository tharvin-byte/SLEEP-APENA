import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:http/http.dart' as http;

// ─── Response Model ──────────────────────────────────────────────────────────

class EventDetail {
  final double start;
  final double end;
  final double duration;

  const EventDetail({
    required this.start,
    required this.end,
    required this.duration,
  });

  factory EventDetail.fromJson(Map<String, dynamic> json) => EventDetail(
        start: (json['start'] as num).toDouble(),
        end: (json['end'] as num).toDouble(),
        duration: (json['duration'] as num).toDouble(),
      );
}

class AnalysisResult {
  final bool apnea;
  final int events;
  final double eventsPerHour;
  final String risk;
  final String advice;
  final List<EventDetail> eventsDetail;

  const AnalysisResult({
    required this.apnea,
    required this.events,
    required this.eventsPerHour,
    required this.risk,
    required this.advice,
    required this.eventsDetail,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => AnalysisResult(
        apnea: json['apnea'] as bool,
        events: (json['events'] as num).toInt(),
        eventsPerHour: (json['events_per_hour'] as num).toDouble(),
        risk: json['risk'] as String,
        advice: json['advice'] as String,
        eventsDetail: (json['events_detail'] as List<dynamic>)
            .map((e) => EventDetail.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ─── Service ─────────────────────────────────────────────────────────────────

class SleepAnalysisService {
  // 🔥 CHANGE THIS ONLY BASED ON DEVICE
  static const String _baseUrl = 'http://localhost:8000';
  // For mobile use: http://192.168.X.X:8000

  static const String _endpoint = '$_baseUrl/analyze';
  static const Duration _timeout = Duration(seconds: 120);

  Future<AnalysisResult> analyze({
    File? file,
    Uint8List? bytes,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_endpoint));

      if (kIsWeb) {
        // ✅ WEB (Chrome)
        if (bytes == null) {
          throw Exception("Bytes required for web");
        }

        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: 'audio.wav',
          ),
        );
      } else {
        // ✅ MOBILE
        if (file == null) {
          throw Exception("File required for mobile");
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
          ),
        );
      }

      print("Sending request...");

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      print("Response: ${response.statusCode}");

      if (response.statusCode != 200) {
        throw SleepAnalysisException(
          'Server error: ${response.statusCode}',
        );
      }

      final Map<String, dynamic> json =
          jsonDecode(response.body) as Map<String, dynamic>;

      return AnalysisResult.fromJson(json);
    } on SocketException catch (e) {
      throw SleepAnalysisException(
        'Network error: ${e.message}',
      );
    } on FormatException catch (e) {
      throw SleepAnalysisException(
        'Invalid response: ${e.message}',
      );
    } catch (e) {
      throw SleepAnalysisException(
        'Unexpected error: $e',
      );
    }
  }
}

// ─── Exception ───────────────────────────────────────────────────────────────

class SleepAnalysisException implements Exception {
  final String message;
  const SleepAnalysisException(this.message);

  @override
  String toString() => message;
}