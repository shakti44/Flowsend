enum FlowAssistantIntentType {
  sendFiles,
  sendRecentPhotos,
  sendFileType,
  sendToDevice,
  sendToMultipleDevices,
  moveToNewPhone,
  collectMode,
  showTransfers,
  showNearbyDevices,
  unsupported,
}

class FlowAssistantIntent {
  const FlowAssistantIntent({
    required this.type,
    required this.rawText,
    this.deviceName,
    this.fileType,
    this.photoCount,
  });

  final FlowAssistantIntentType type;
  final String rawText;
  final String? deviceName;
  final String? fileType;
  final int? photoCount;

  bool get isSendAction => switch (type) {
        FlowAssistantIntentType.sendFiles ||
        FlowAssistantIntentType.sendRecentPhotos ||
        FlowAssistantIntentType.sendFileType ||
        FlowAssistantIntentType.sendToDevice ||
        FlowAssistantIntentType.sendToMultipleDevices ||
        FlowAssistantIntentType.moveToNewPhone => true,
        _ => false,
      };
}
