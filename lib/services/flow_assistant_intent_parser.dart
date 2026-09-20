import '../models/flow_assistant_intent.dart';

class FlowAssistantIntentParser {
  const FlowAssistantIntentParser();

  FlowAssistantIntent parse(String input) {
    final text = input.trim().toLowerCase();
    if (text.isEmpty) return FlowAssistantIntent(type: FlowAssistantIntentType.unsupported, rawText: input);

    if (text.contains('collect photos') || text.contains('collect files') || text.contains('collect from everyone')) {
      return FlowAssistantIntent(type: FlowAssistantIntentType.collectMode, rawText: input);
    }
    if (text.contains('recent transfers') || text.contains('failed transfers') || text.contains('transfer history')) {
      return FlowAssistantIntent(type: FlowAssistantIntentType.showTransfers, rawText: input);
    }
    if ((text.contains('nearby') || text.contains('near by')) &&
        (text.contains('device') || text.contains('phone') || text.contains('laptop')) ||
        text.contains('search devices') || text.contains('find devices')) {
      return FlowAssistantIntent(type: FlowAssistantIntentType.showNearbyDevices, rawText: input);
    }
    if (text.contains('new phone') || text.contains('missing files')) {
      return FlowAssistantIntent(type: FlowAssistantIntentType.moveToNewPhone, rawText: input);
    }
    if (text.contains('all nearby devices') || text.contains('multiple devices')) {
      return FlowAssistantIntent(type: FlowAssistantIntentType.sendToMultipleDevices, rawText: input);
    }

    final photoMatch = RegExp(r'(?:latest|recent)\s+(\d+)?\s*photos?').firstMatch(text);
    if (photoMatch != null) {
      return FlowAssistantIntent(
        type: FlowAssistantIntentType.sendRecentPhotos,
        rawText: input,
        photoCount: int.tryParse(photoMatch.group(1) ?? ''),
      );
    }

    final deviceMatch = RegExp(r"(?:to|on)\s+(.+?)(?:\s+phone|\s+laptop|\s+tablet)?$").firstMatch(text);
    final deviceName = deviceMatch?.group(1)?.trim();
    if (text.contains('send') && text.contains('apk')) {
      return FlowAssistantIntent(type: FlowAssistantIntentType.sendFileType, rawText: input, fileType: 'APK', deviceName: deviceName);
    }
    if (text.contains('send') && text.contains('pdf')) {
      return FlowAssistantIntent(type: FlowAssistantIntentType.sendFileType, rawText: input, fileType: 'PDF', deviceName: deviceName);
    }
    if (text.contains('send')) {
      return FlowAssistantIntent(type: FlowAssistantIntentType.sendFiles, rawText: input, deviceName: deviceName);
    }

    return FlowAssistantIntent(type: FlowAssistantIntentType.unsupported, rawText: input);
  }
}
