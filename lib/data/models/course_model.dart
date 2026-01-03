import '../../domain/entities/course.dart';

class LectureModel extends Lecture {
  const LectureModel({
    required super.id,
    required super.title,
    required super.videoUrl,
    required super.videoProvider,
  });

  factory LectureModel.fromJson(Map<String, dynamic> json) {
    return LectureModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      videoUrl: json['videoUrl'] as String? ?? '',
      videoProvider: json['videoProvider'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'videoUrl': videoUrl,
      'videoProvider': videoProvider,
    };
  }
}

class SectionModel extends Section {
  const SectionModel({
    required super.id,
    required super.title,
    required List<LectureModel> super.lectures,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      lectures:
          (json['lectures'] as List<dynamic>?)
              ?.map((e) => LectureModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lectures': lectures.map((e) => (e as LectureModel).toJson()).toList(),
    };
  }
}

class CourseModel extends Course {
  const CourseModel({
    required super.id,
    required super.title,
    required super.description,
    required super.thumbnail,
    required super.price,
    required super.published,
    required super.instructorId,
    required super.mediaType,
    required List<SectionModel> super.sections,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      published: json['published'] as bool? ?? false,
      instructorId: json['instructorId'] as String? ?? '',
      mediaType: json['mediaType'] as String? ?? '',
      sections:
          (json['sections'] as List<dynamic>?)
              ?.map((e) => SectionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnail': thumbnail,
      'price': price,
      'published': published,
      'instructorId': instructorId,
      'mediaType': mediaType,
      'sections': sections.map((e) => (e as SectionModel).toJson()).toList(),
    };
  }
}
