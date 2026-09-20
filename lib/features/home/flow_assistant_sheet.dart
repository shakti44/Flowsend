import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../models/flow_assistant_intent.dart';
import '../../services/flow_assistant_intent_parser.dart';
import '../../routes/app_router.dart';

class FlowAssistantSheet extends StatefulWidget {
  const FlowAssistantSheet({super.key});

  @override
  State<FlowAssistantSheet> createState() => _FlowAssistantSheetState();
}

class _FlowAssistantSheetState extends State<FlowAssistantSheet> {
  final _speech = stt.SpeechToText();
  final _textController = TextEditingController();
  final _parser = const FlowAssistantIntentParser();
  bool _initialized = false;
  bool _listening = false;
  String _recognizedText = '';
  String? _error;
  FlowAssistantIntent? _intent;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _speech.stop();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    final microphone = await Permission.microphone.request();
    if (!microphone.isGranted) {
      if (mounted) setState(() => _error = 'Microphone access is needed to understand your command.');
      return;
    }
    final available = await _speech.initialize(
      onStatus: (status) {
        if (mounted) setState(() => _listening = status == 'listening');
      },
      onError: (error) {
        if (mounted) setState(() => _error = error.errorMsg);
      },
    );
    if (!available) {
      if (mounted) setState(() => _error = 'Speech recognition is not available on this device.');
      return;
    }
    if (!mounted) return;
    setState(() {
      _initialized = true;
      _listening = true;
      _error = null;
    });
    await _speech.listen(onResult: (result) {
      if (!mounted) return;
      setState(() {
        _recognizedText = result.recognizedWords;
        _textController.text = _recognizedText;
        if (result.finalResult) _listening = false;
      });
      if (result.finalResult) _understand(_recognizedText);
    });
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (mounted) setState(() => _listening = false);
  }

  void _understand(String text) {
    final intent = _parser.parse(text);
    setState(() => _intent = intent);
  }

  Future<void> _submitText() async {
    await _stopListening();
    _understand(_textController.text);
  }

  Future<void> _execute() async {
    final intent = _intent;
    if (intent == null) return;
    Navigator.pop(context);
    if (!mounted) return;
    switch (intent.type) {
      case FlowAssistantIntentType.collectMode:
        context.push(AppRoutes.collect);
      case FlowAssistantIntentType.showTransfers:
        context.push(AppRoutes.history);
      case FlowAssistantIntentType.sendFiles ||
            FlowAssistantIntentType.sendRecentPhotos ||
            FlowAssistantIntentType.sendFileType ||
            FlowAssistantIntentType.sendToDevice ||
            FlowAssistantIntentType.sendToMultipleDevices ||
            FlowAssistantIntentType.moveToNewPhone:
        context.push(AppRoutes.selectFiles);
      case FlowAssistantIntentType.unsupported:
        _showUnsupported(context);
    }
  }

  void _showUnsupported(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('I can help you send, receive, find and manage FlowSend transfers.')),
    );
  }

  String get _intentSummary {
    final intent = _intent;
    if (intent == null) return '';
    if (intent.type == FlowAssistantIntentType.collectMode) return 'Open a collection for nearby contributors';
    if (intent.type == FlowAssistantIntentType.showTransfers) return 'Show recent FlowSend transfers';
    if (intent.deviceName != null && intent.deviceName!.isNotEmpty) return 'Prepare files for ${intent.deviceName}';
    if (intent.fileType != null) return 'Prepare ${intent.fileType} files for transfer';
    if (intent.type == FlowAssistantIntentType.sendRecentPhotos) return 'Prepare recent photos for transfer';
    return 'Prepare selected files for transfer';
  }

  @override
  Widget build(BuildContext context) {
    final hasIntent = _intent != null && _intent!.type != FlowAssistantIntentType.unsupported;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.outlineVariant, borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: AppSpacing.md),
            Text('Flow Assistant', style: AppTypography.headlineSm.copyWith(color: AppColors.onSurface)),
            const SizedBox(height: AppSpacing.xs),
            Text('What would you like to do?', style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: GestureDetector(
                onTap: _listening ? _stopListening : (_initialized ? _startListening : null),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: _listening ? 76 : 64,
                  height: _listening ? 76 : 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _listening ? AppColors.primaryContainer : AppColors.surfaceContainerHigh,
                    boxShadow: _listening ? [BoxShadow(color: AppColors.secondaryContainer.withValues(alpha: 0.35), blurRadius: 22)] : null,
                  ),
                  child: Icon(_listening ? Icons.stop : Icons.mic, color: _listening ? AppColors.onPrimaryContainer : AppColors.secondary, size: 28),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _textController,
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitText(),
              decoration: InputDecoration(
                hintText: 'Type instead',
                prefixIcon: const Icon(Icons.keyboard_outlined),
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(_error!, style: AppTypography.bodySm.copyWith(color: AppColors.error)),
            ],
            if (_recognizedText.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('Recognized: "$_recognizedText"', style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
            ],
            if (hasIntent) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Ready to continue', style: AppTypography.labelLg.copyWith(color: AppColors.onSurface)),
                  const SizedBox(height: 4),
                  Text(_intentSummary, style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant)),
                ]),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => setState(() => _intent = null), child: const Text('Cancel'))),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: FilledButton(onPressed: _execute, child: const Text('Continue'))),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}
