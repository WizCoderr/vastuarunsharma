import '../../domain/entities/live_class.dart';
import '../../domain/entities/course.dart';

class LiveClassModel extends LiveClass {
  const LiveClassModel({
    required super.id,
    required super.courseId,
    required super.courseName,
    required super.title,
    required super.description,
    required super.scheduledAt,
    required super.durationMinutes,
    required super.status,
    super.meetingUrl,
    required super.canJoin,
    required super.startsIn,
  });

  factory LiveClassModel.fromJson(Map<String, dynamic> json) {
    return LiveClassModel(
      id: json['id'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      courseName: json['courseName'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      scheduledAt:
          DateTime.tryParse(json['scheduledAt'] as String? ?? '') ??
          DateTime.now(),
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      status: json['status'] as String? ?? 'SCHEDULED',
      meetingUrl: json['meetingUrl'] as String?,
      canJoin: json['canJoin'] as bool? ?? false,
      startsIn: json['startsIn'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'courseName': courseName,
      'title': title,
      'description': description,
      'scheduledAt': scheduledAt.toIso8601String(),
      'durationMinutes': durationMinutes,
      'status': status,
      'meetingUrl': meetingUrl,
      'canJoin': canJoin,
      'startsIn': startsIn,
    };
  }
}

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
      // Prefer watchId (full YouTube URL) over videoUrl when present
      videoUrl: (json['watchId'] as String?) ?? (json['videoUrl'] as String?) ?? '',
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
    List<LiveClassModel>? liveClasses,
  }) : super(liveClasses: liveClasses ?? const []);

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      lectures:
          (json['lectures'] as List<dynamic>?)
              ?.map((e) => LectureModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      liveClasses:
          (json['liveClasses'] as List<dynamic>?)
              ?.map((e) => LiveClassModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lectures': lectures.map((e) => (e as LectureModel).toJson()).toList(),
      'liveClasses': liveClasses
          .map((e) => (e as LiveClassModel).toJson())
          .toList(),
    };
  }
}

class PaymentPlanModel extends PaymentPlan {
  const PaymentPlanModel({
    super.id,
    required super.stageName,
    required super.amount,
    super.startDate,
    super.endDate,
    required super.dueAfterDays,
    required super.orderIndex,
    super.description,
  });

  factory PaymentPlanModel.fromJson(Map<String, dynamic> json) {
    return PaymentPlanModel(
      id: json['id'] as String?,
      stageName: (json['stageName'] ?? json['name'] ?? '') as String,
      amount: (json['amount'] ?? json['fee'] ?? 0.0).toDouble(),
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'])
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'])
          : null,
      dueAfterDays: (json['dueAfterDays'] ?? json['dueDays'] ?? 0) as int,
      orderIndex: (json['orderIndex'] ?? 0) as int,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stageName': stageName,
      'amount': amount,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'dueAfterDays': dueAfterDays,
      'orderIndex': orderIndex,
      'description': description,
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
    required super.isEnrolled,
    super.serialNumber,
    required List<SectionModel> super.sections,
    List<LiveClassModel>? liveClasses,
    super.endDate,
    super.paymentStatus,
    super.activePaymentPlan,
    super.paymentPlans,
  }) : super(
          liveClasses: liveClasses ?? const [],
        );

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
      isEnrolled: (json['isEnrolled'] ?? json['enrolled'] ?? false) as bool,
      serialNumber: json['serialNumber'] as String?,
      sections:
          (json['sections'] as List<dynamic>?)
              ?.map((e) => SectionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      liveClasses:
          (json['liveClasses'] as List<dynamic>?)
              ?.map((e) => LiveClassModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      endDate:
          json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
      paymentStatus: json['paymentStatus'] as String?,
      activePaymentPlan: json['activePaymentPlan'] != null
          ? PaymentPlanModel.fromJson(
              json['activePaymentPlan'] as Map<String, dynamic>)
          : null,
      paymentPlans: (json['paymentPlans'] as List<dynamic>?)
              ?.map((e) => PaymentPlanModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
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
      'isEnrolled': isEnrolled,
      'serialNumber': serialNumber,
      'sections': sections.map((e) => (e as SectionModel).toJson()).toList(),
      'liveClasses': liveClasses
          .map((e) => (e as LiveClassModel).toJson())
          .toList(),
      'endDate': endDate?.toIso8601String(),
      'paymentStatus': paymentStatus,
      'activePaymentPlan': (activePaymentPlan as PaymentPlanModel?)?.toJson(),
      'paymentPlans': paymentPlans.map((e) => (e as PaymentPlanModel).toJson()).toList(),
    };
  }
}
