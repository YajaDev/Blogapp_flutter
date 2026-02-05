enum MessageType { success, error }

class UiMessage {
  final String text;
  final MessageType type;

  UiMessage(this.text, this.type);
}
