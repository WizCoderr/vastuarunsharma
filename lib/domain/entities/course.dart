import 'live_class.dart';

class Resource {
  final String id;
  final String title;
  final String type; // FREE or PAID
  final String url;

  const Resource({
    required this.id,
    required this.title,
    required this.type,
    required this.url,
  });
}

class Lecture {
  final String id;
  final String title;
  final String videoUrl;
  final String videoProvider;

  const Lecture({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.videoProvider,
  });
}

class Section {
  final String id;
  final String title;
  final List<Lecture> lectures;
  final List<LiveClass> liveClasses;

  const Section({
    required this.id,
    required this.title,
    required this.lectures,
    this.liveClasses = const [],
  });
}

class Course {
  final String id;
  final String title;
  final String description;
  final String thumbnail;
  final double price;
  final bool published;
  final String instructorId;
  final String mediaType;
  final bool? enrolled;
  final List<Section> sections;
  final List<Resource> resources;
  final List<LiveClass> liveClasses;

  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.price,
    required this.published,
    required this.instructorId,
    required this.mediaType,
    this.enrolled,
    this.sections = const [],
    this.resources = const [],
    this.liveClasses = const [],
  });
}
