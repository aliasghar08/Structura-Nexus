import 'dart:async';
import 'package:flutter/foundation.dart';
import 'structural_api_service.dart';

class VoiceCopilotService {
  static final VoiceCopilotService instance = VoiceCopilotService._();
  VoiceCopilotService._();

  final StructuralApiService _apiService = StructuralApiService();

  bool _isListening = false;
  bool get isListening => _isListening;

  String _lastTranscript = "";
  String get lastTranscript => _lastTranscript;

  String _lastSpokenFeedback = "";
  String get lastSpokenFeedback => _lastSpokenFeedback;

  final _transcriptController = StreamController<String>.broadcast();
  Stream<String> get transcriptStream => _transcriptController.stream;

  final _feedbackController = StreamController<String>.broadcast();
  Stream<String> get feedbackStream => _feedbackController.stream;

  // Spatial Action Callbacks registered by WorkstationScreen
  VoidCallback? onAddChevronBracing;
  Function(double mph, String exposure)? onApplyWindLoads;
  Function(List<String> memberIds)? onHighlightMembers;
  VoidCallback? onRunAutoSizer;
  VoidCallback? onSolveModel;

  void toggleListening({Map<String, dynamic>? currentModelState}) {
    if (_isListening) {
      stopListening();
    } else {
      startListening(currentModelState: currentModelState);
    }
  }

  void startListening({Map<String, dynamic>? currentModelState}) {
    _isListening = true;
    _lastTranscript = "Listening...";
    _transcriptController.add(_lastTranscript);
  }

  void stopListening() {
    _isListening = false;
    _transcriptController.add(_lastTranscript);
  }

  /// Programmatic test and verification hook.
  /// Simulates voice speech capture without requiring physical microphone access.
  Future<Map<String, dynamic>> simulateVoiceCommand(
    String command, {
    Map<String, dynamic>? currentModelState,
  }) async {
    _isListening = true;
    _lastTranscript = command;
    _transcriptController.add(command);

    try {
      final res = await _apiService.sendVoiceCommand(
        command,
        currentModel: currentModelState,
      );

      final action = res['action'] as String? ?? '';
      final feedback = res['spoken_feedback'] as String? ?? '';
      _lastSpokenFeedback = feedback;
      _feedbackController.add(feedback);

      // Execute Spatial Actions
      if (action == 'add_chevron_bracing') {
        onAddChevronBracing?.call();
      } else if (action == 'apply_wind_loads') {
        final params = res['parameters'] as Map<String, dynamic>? ?? {};
        final mph = (params['wind_speed_mph'] as num?)?.toDouble() ?? 145.0;
        final exp = params['exposure_category'] as String? ?? 'D';
        onApplyWindLoads?.call(mph, exp);
      } else if (action == 'highlight_members') {
        final rawIds = (res['highlight_member_ids'] as List?)?.map((e) => e.toString()).toList() ?? [];
        onHighlightMembers?.call(rawIds);
      } else if (action == 'run_auto_sizer') {
        onRunAutoSizer?.call();
      } else if (action == 'solve_model') {
        onSolveModel?.call();
      }

      _isListening = false;
      return res;
    } catch (e) {
      _isListening = false;
      _lastSpokenFeedback = "Voice processing error: $e";
      _feedbackController.add(_lastSpokenFeedback);
      return {'status': 'ERROR', 'message': e.toString()};
    }
  }

  void dispose() {
    _transcriptController.close();
    _feedbackController.close();
  }
}

