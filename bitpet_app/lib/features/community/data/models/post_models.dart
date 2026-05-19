class Post {
  final int id;
  final int userId;
  final String authorName;
  final String? authorImageUrl;
  final String categoryCode;
  final String title;
  final String content;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final DateTime createdAt;

  const Post({
    required this.id,
    required this.userId,
    required this.authorName,
    this.authorImageUrl,
    required this.categoryCode,
    required this.title,
    required this.content,
    required this.viewCount,
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as int,
        userId: json['userId'] as int,
        authorName: json['authorName'] as String? ?? '익명',
        authorImageUrl: json['authorImageUrl'] as String?,
        categoryCode: json['categoryCode'] as String? ?? 'FREE',
        title: json['title'] as String,
        content: json['content'] as String,
        viewCount: json['viewCount'] as int? ?? 0,
        likeCount: json['likeCount'] as int? ?? 0,
        commentCount: json['commentCount'] as int? ?? 0,
        isLiked: json['isLiked'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class PostComment {
  final int id;
  final int postId;
  final int userId;
  final String authorName;
  final int? parentCommentId;
  final String content;
  final DateTime createdAt;

  const PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.authorName,
    this.parentCommentId,
    required this.content,
    required this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) => PostComment(
        id: json['id'] as int,
        postId: json['postId'] as int,
        userId: json['userId'] as int,
        authorName: json['authorName'] as String? ?? '익명',
        parentCommentId: json['parentCommentId'] as int?,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class CreatePostRequest {
  final String categoryCode;
  final String title;
  final String content;

  const CreatePostRequest({
    required this.categoryCode,
    required this.title,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'categoryCode': categoryCode,
        'title': title,
        'content': content,
      };
}
