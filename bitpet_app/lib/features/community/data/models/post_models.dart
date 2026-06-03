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
  final bool isHot;
  final bool isPinned;
  final bool isBookmarked;
  final List<String> tags;
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
    this.isHot = false,
    this.isPinned = false,
    this.isBookmarked = false,
    this.tags = const [],
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
        isHot: json['isHot'] as bool? ?? false,
        isPinned: json['isPinned'] as bool? ?? false,
        isBookmarked: json['isBookmarked'] as bool? ?? false,
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Post copyWith({
    bool? isLiked,
    int? likeCount,
    bool? isBookmarked,
  }) =>
      Post(
        id: id,
        userId: userId,
        authorName: authorName,
        authorImageUrl: authorImageUrl,
        categoryCode: categoryCode,
        title: title,
        content: content,
        viewCount: viewCount,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount,
        isLiked: isLiked ?? this.isLiked,
        isHot: isHot,
        isPinned: isPinned,
        isBookmarked: isBookmarked ?? this.isBookmarked,
        tags: tags,
        createdAt: createdAt,
      );
}

class PostComment {
  final int id;
  final int postId;
  final int userId;
  final String authorName;
  final String? authorImageUrl;
  final int? parentCommentId;
  final String content;
  final int likeCount;
  final bool isLiked;
  final bool isAuthor;
  final List<PostComment> replies;
  final DateTime createdAt;

  const PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.authorName,
    this.authorImageUrl,
    this.parentCommentId,
    required this.content,
    this.likeCount = 0,
    this.isLiked = false,
    this.isAuthor = false,
    this.replies = const [],
    required this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) => PostComment(
        id: json['id'] as int,
        postId: json['postId'] as int,
        userId: json['userId'] as int,
        authorName: json['authorName'] as String? ?? '익명',
        authorImageUrl: json['authorImageUrl'] as String?,
        parentCommentId: json['parentCommentId'] as int?,
        content: json['content'] as String,
        likeCount: json['likeCount'] as int? ?? 0,
        isLiked: json['isLiked'] as bool? ?? false,
        isAuthor: json['isAuthor'] as bool? ?? false,
        replies: (json['replies'] as List<dynamic>?)
                ?.map((e) => PostComment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class CreatePostRequest {
  final String categoryCode;
  final String title;
  final String content;
  final List<String> tags;
  final bool anonymous;
  final bool allowComments;

  const CreatePostRequest({
    required this.categoryCode,
    required this.title,
    required this.content,
    this.tags = const [],
    this.anonymous = false,
    this.allowComments = true,
  });

  Map<String, dynamic> toJson() => {
        'categoryCode': categoryCode,
        'title': title,
        'content': content,
        'tags': tags,
        'anonymous': anonymous,
        'allowComments': allowComments,
      };
}

class UpdatePostRequest {
  final String categoryCode;
  final String title;
  final String content;
  final List<String> tags;

  const UpdatePostRequest({
    required this.categoryCode,
    required this.title,
    required this.content,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
        'categoryCode': categoryCode,
        'title': title,
        'content': content,
        'tags': tags,
      };
}
