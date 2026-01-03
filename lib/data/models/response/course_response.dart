class ResourceResponse {
  final String id;
  final String title;
  final String type; // FREE or PAID
  final String url;

  ResourceResponse({
    required this.id,
    required this.title,
    required this.type,
    required this.url,
  });

  factory ResourceResponse.fromJson(Map<String, dynamic> json) =>
      ResourceResponse(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        type: json['type'] as String? ?? 'FREE',
        url: json['url'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type,
    'url': url,
  };
}

class LectureResponse {
  final String id;
  final String title;
  final String videoUrl;
  final String videoProvider;

  LectureResponse({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.videoProvider,
  });

  factory LectureResponse.fromJson(Map<String, dynamic> json) =>
      LectureResponse(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        videoUrl: json['videoUrl'] as String? ?? '',
        videoProvider: json['videoProvider'] as String? ?? 's3',
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'videoUrl': videoUrl,
    'videoProvider': videoProvider,
  };
}

class SectionResponse {
  final String id;
  final String title;
  final List<LectureResponse> lectures;

  SectionResponse({
    required this.id,
    required this.title,
    required this.lectures,
  });

  factory SectionResponse.fromJson(Map<String, dynamic> json) =>
      SectionResponse(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        lectures:
            (json['lectures'] as List<dynamic>?)
                ?.map(
                  (e) => LectureResponse.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'lectures': lectures.map((e) => e.toJson()).toList(),
  };
}

class CourseResponse {
  final String id;
  final String title;
  final String description;
  final String thumbnail;
  final double price;
  final bool published;
  final String instructorId;
  final String? s3Key;
  final String? s3Bucket;
  final String? mediaType;
  final bool? enrolled; // Only present in course details response
  final List<SectionResponse> sections;
  final List<ResourceResponse> resources;

  CourseResponse({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.price,
    required this.published,
    required this.instructorId,
    this.s3Key,
    this.s3Bucket,
    this.mediaType,
    this.enrolled,
    required this.sections,
    required this.resources,
  });

  factory CourseResponse.fromJson(Map<String, dynamic> json) => CourseResponse(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    thumbnail: json['thumbnail'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    published: json['published'] as bool? ?? false,
    instructorId: json['instructorId'] as String? ?? '',
    s3Key: json['s3Key'] as String?,
    s3Bucket: json['s3Bucket'] as String?,
    mediaType: json['mediaType'] as String?,
    enrolled: (json['enrolled'] ?? json['isEnrolled']) as bool?,
    sections:
        (json['sections'] as List<dynamic>?)
            ?.map((e) => SectionResponse.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    resources:
        ((json['resources'] ?? json['courseResources']) as List<dynamic>?)
            ?.map((e) => ResourceResponse.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'thumbnail': thumbnail,
    'price': price,
    'published': published,
    'instructorId': instructorId,
    if (s3Key != null) 's3Key': s3Key,
    if (s3Bucket != null) 's3Bucket': s3Bucket,
    if (mediaType != null) 'mediaType': mediaType,
    if (enrolled != null) 'enrolled': enrolled,
    'sections': sections.map((e) => e.toJson()).toList(),
    'resources': resources.map((e) => e.toJson()).toList(),
  };
}
