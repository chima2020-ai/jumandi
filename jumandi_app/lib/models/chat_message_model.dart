class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
  });

  final int id;
  final int bookingId;
  final int senderId;
  final String senderName;
  final String content;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      bookingId: json['booking_id'] as int,
      senderId: json['sender_id'] as int,
      senderName: json['sender_name'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
