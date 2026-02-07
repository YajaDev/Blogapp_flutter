enum MessageType { success, error }

class NotifMessage {
  final String text;
  final MessageType type;

  NotifMessage(this.text, this.type);
}
