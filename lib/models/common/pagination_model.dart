class PaginationModel {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;
  final int? nextPage;
  final int? prevPage;

  PaginationModel({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
    this.nextPage,
    this.prevPage,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    final page = json['page'] ?? 1;
    final totalPages = json['total_pages'] ?? json['pages'] ?? 1;

    return PaginationModel(
      page: page,
      limit: json['limit'] ?? json['per_page'] ?? 20,
      total: json['total'] ?? json['total_count'] ?? 0,
      totalPages: totalPages,
      hasNext: json['has_next'] ?? json['has_more'] ?? (page < totalPages),
      hasPrev: json['has_prev'] ?? json['has_previous'] ?? (page > 1),
      nextPage: json['next_page'] ?? (page < totalPages ? page + 1 : null),
      prevPage: json['prev_page'] ?? (page > 1 ? page - 1 : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      'total_pages': totalPages,
      'has_next': hasNext,
      'has_prev': hasPrev,
      if (nextPage != null) 'next_page': nextPage,
      if (prevPage != null) 'prev_page': prevPage,
    };
  }

  // Utility methods
  int get startIndex => (page - 1) * limit;
  int get endIndex => startIndex + limit - 1;
  bool get isFirstPage => page == 1;
  bool get isLastPage => page == totalPages;

  // Calculate progress
  double get progress {
    if (total == 0) return 1.0;
    return (page * limit).clamp(0, total) / total;
  }

  // Get page info string
  String get pageInfo {
    final start = startIndex + 1;
    final end = (startIndex + limit).clamp(0, total);
    return '$start-$end of $total';
  }

  // Create pagination for next/previous page
  PaginationModel? get nextPagination {
    if (!hasNext) return null;
    return PaginationModel(
      page: page + 1,
      limit: limit,
      total: total,
      totalPages: totalPages,
      hasNext: page + 1 < totalPages,
      hasPrev: true,
      nextPage: page + 1 < totalPages ? page + 2 : null,
      prevPage: page,
    );
  }

  PaginationModel? get prevPagination {
    if (!hasPrev) return null;
    return PaginationModel(
      page: page - 1,
      limit: limit,
      total: total,
      totalPages: totalPages,
      hasNext: true,
      hasPrev: page - 1 > 1,
      nextPage: page,
      prevPage: page - 1 > 1 ? page - 2 : null,
    );
  }

  // Factory for first page
  factory PaginationModel.first({int limit = 20}) {
    return PaginationModel(
      page: 1,
      limit: limit,
      total: 0,
      totalPages: 1,
      hasNext: false,
      hasPrev: false,
    );
  }

  // Copy with new values
  PaginationModel copyWith({
    int? page,
    int? limit,
    int? total,
    int? totalPages,
    bool? hasNext,
    bool? hasPrev,
    int? nextPage,
    int? prevPage,
  }) {
    return PaginationModel(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      hasNext: hasNext ?? this.hasNext,
      hasPrev: hasPrev ?? this.hasPrev,
      nextPage: nextPage ?? this.nextPage,
      prevPage: prevPage ?? this.prevPage,
    );
  }
}
