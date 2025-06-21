class Reply {
  final int id;
  final String description;
  final String createdAt;
  final String? firstName;
  final String? lastName;
  final String? imageUrl;
  final int likesCount;
  final int repliesCount;
  final List<Reply> replies;

  Reply({
    required this.id,
    required this.description,
    required this.createdAt,
    this.firstName,
    this.lastName,
    this.imageUrl,
    required this.likesCount,
    required this.repliesCount,
    this.replies = const [],
  });

  factory Reply.fromMap(Map<String, dynamic> map) {
    final creator = map['creator']?['profile'] ?? {};
    final String? firstName = creator['first_name'];
    final String? lastName = creator['last_name'];
    final String? imageUrl = creator['image'];

    return Reply(
      id: map['id'] ?? 0,
      description: map['description'] ?? '',
      createdAt: map['created_at'] ?? '',
      firstName: firstName,
      lastName: lastName,
      imageUrl: imageUrl,
      likesCount: map['likes_count'] ?? 0,
      repliesCount: map['replies_count'] ?? 0,
      replies: (map['replies'] as List<dynamic>?)?.map((subReply) {
        final updatedSubReply =
        Map<String, dynamic>.from(subReply as Map<String, dynamic>);
        if (updatedSubReply['creator'] == null) {
          updatedSubReply['creator'] = {'profile': creator};
        }
        return Reply.fromMap(updatedSubReply);
      }).toList() ??
          [],
    );
  }
}
