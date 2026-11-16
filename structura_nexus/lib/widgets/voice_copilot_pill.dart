import 'package:flutter/material.dart';
import '../services/voice_copilot_service.dart';
import 'glass_pod.dart';

class VoiceCopilotPill extends StatefulWidget {
  final Map<String, dynamic>? Function()? getCurrentModelState;

  const VoiceCopilotPill({
    super.key,
    this.getCurrentModelState,
  });

  @override
  State<VoiceCopilotPill> createState() => _VoiceCopilotPillState();
}

class _VoiceCopilotPillState extends State<VoiceCopilotPill> with SingleTickerProviderStateMixin {
  final _copilot = VoiceCopilotService.instance;

  bool _isExpanded = false;
  String _currentTranscript = "Voice Co-Pilot Ready";
  String _feedbackMessage = "Say or tap a spatial command";

  late AnimationController _waveAnim;

  final List<String> _quickCommands = [
    "Add chevron bracing to the core bays",
    "Apply 145 mph Exposure D wind loads",
    "Highlight columns with DCR above 0.85 or B2 above 1.15",
    "Run auto-sizer",
  ];

  @override
  void initState() {
    super.initState();
    _waveAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _copilot.transcriptStream.listen((text) {
      if (mounted) {
        setState(() {
          _currentTranscript = text;
          if (_copilot.isListening) {
            if (!_waveAnim.isAnimating) _waveAnim.repeat(reverse: true);
          } else {
            _waveAnim.stop();
            _waveAnim.reset();
          }
        });
      }
    });

    _copilot.feedbackStream.listen((feedback) {
      if (mounted) {
        setState(() {
          _feedbackMessage = feedback;
          if (!_copilot.isListening) {
            _waveAnim.stop();
            _waveAnim.reset();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _waveAnim.dispose();
    super.dispose();
  }

  void _triggerCommand(String cmd) {
    _copilot.simulateVoiceCommand(
      cmd,
      currentModelState: widget.getCurrentModelState?.call(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isListening = _copilot.isListening;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      constraints: BoxConstraints(
        maxWidth: _isExpanded ? 460 : 320,
      ),
      child: GlassPod(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar: Mic Button + Waveform + Transcript + Expand/Collapse
            Row(
              children: [
                // Glowing Mic Button
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    _copilot.toggleListening(
                      currentModelState: widget.getCurrentModelState?.call(),
                    );
                    if (_copilot.isListening) {
                      _waveAnim.repeat(reverse: true);
                    } else {
                      _waveAnim.stop();
                      _waveAnim.reset();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isListening
                          ? const Color(0xFFFF0055).withValues(alpha: 0.25)
                          : const Color(0xFF00E5FF).withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isListening ? const Color(0xFFFF0055) : const Color(0xFF00E5FF),
                        width: 1.5,
                      ),
                      boxShadow: isListening
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFF0055).withValues(alpha: 0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ]
                          : [],
                    ),
                    child: Icon(
                      isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: isListening ? const Color(0xFFFF0055) : const Color(0xFF00E5FF),
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Animated Waveform Bars
                AnimatedBuilder(
                  animation: _waveAnim,
                  builder: (context, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(4, (index) {
                        final val = isListening
                            ? (_waveAnim.value * (index + 1) * 0.25 + 0.35).clamp(0.2, 1.0)
                            : 0.25;
                        return Container(
                          width: 3,
                          height: 16 * val,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: isListening ? const Color(0xFFFF0055) : const Color(0xFF00E5FF),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    );
                  },
                ),
                const SizedBox(width: 10),

                // Transcript Ticker Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isListening ? const Color(0xFFFF0055) : const Color(0xFF00E676),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              isListening ? "STREAMING AUDIO" : "GEMINI LIVE COPILOT",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: isListening ? const Color(0xFFFF0055) : const Color(0xFF00E5FF),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentTranscript,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Expand/Collapse Toggle
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            // Expanded Tray: Spoken Feedback & Quick Spatial Actions
            if (_isExpanded) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.record_voice_over_rounded, size: 14, color: Color(0xFF00E5FF)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _feedbackMessage,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _quickCommands.map((cmd) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => _triggerCommand(cmd),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        cmd,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00E5FF),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
