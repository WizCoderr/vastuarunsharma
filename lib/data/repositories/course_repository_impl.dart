import 'package:vastu_mobile/shared/utils/either.dart';
import '../../domain/entities/course.dart' as entity;
import '../../domain/entities/course_curriculum.dart' as entity_curriculum;
import '../../domain/entities/live_class.dart' as entity_live;
import '../../domain/repositories/course_repository.dart';
import '../datasources/remote/course_remote_datasource.dart';
import '../models/response/course_response.dart';
import '../models/response/curriculum_response.dart' as response_curriculum;
import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import 'package:dio/dio.dart';

class CourseRepositoryImpl implements CourseRepository {
  final CourseRemoteDataSource remote;
  CourseRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, List<entity.Course>>> getAllCourses() async {
    try {
      final resp = await remote.fetchAllCourses();
      final list = resp.map((r) => _map(r)).toList();
      return Right(list);
    } on Exception catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<entity.Course>>> getEnrolledCourses() async {
    try {
      final resp = await remote.fetchEnrolledCourses();
      final list = resp.map((r) => _map(r)).toList();
      return Right(list);
    } on DioException catch (e) {
      if (e.error is AuthException) {
        return Left(AuthFailure('Unauthorized'));
      }
      return Left(NetworkFailure(e.message ?? e.toString()));
    } on Exception catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, entity.Course>> getCourseDetails(
    String courseId,
  ) async {
    try {
      final r = await remote.fetchCourseDetails(courseId);
      return Right(_map(r));
    } on Exception catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, entity_curriculum.CourseCurriculum>>
  getCourseCurriculum(String courseId) async {
    try {
      final curr = await remote.fetchCourseCurriculum(courseId);
      return Right(_mapCurriculum(curr));
    } on Exception catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  entity.Course _map(CourseResponse r) => entity.Course(
    id: r.id,
    title: r.title,
    description: r.description,
    thumbnail: r.thumbnail,
    price: r.price,
    published: r.published,
    instructorId: r.instructorId,
    mediaType: r.mediaType ?? 'image',
    enrolled: r.enrolled,
    sections: r.sections.map((s) => _mapSection(s)).toList(),
    resources: r.resources.map((res) => _mapResource(res)).toList(),
    liveClasses: r.liveClasses.map((l) => _mapLiveClass(l)).toList(),
  );

  entity.Section _mapSection(SectionResponse s) => entity.Section(
    id: s.id,
    title: s.title,
    lectures: s.lectures.map((l) => _mapLecture(l)).toList(),
    liveClasses: s.liveClasses.map((l) => _mapLiveClass(l)).toList(),
  );

  entity.Lecture _mapLecture(LectureResponse l) => entity.Lecture(
    id: l.id,
    title: l.title,
    videoUrl: l.videoUrl,
    videoProvider: l.videoProvider,
  );

  entity.Resource _mapResource(ResourceResponse r) =>
      entity.Resource(id: r.id, title: r.title, type: r.type, url: r.url);

  entity_live.LiveClass _mapLiveClass(LiveClassResponse l) =>
      entity_live.LiveClass(
        id: l.id,
        courseId: l.courseId,
        courseName: l.courseName,
        title: l.title,
        description: l.description,
        scheduledAt: l.scheduledAt,
        durationMinutes: l.durationMinutes,
        status: l.status,
        meetingUrl: l.meetingUrl,
        canJoin: l.canJoin,
        startsIn: l.startsIn,
      );

  entity_curriculum.CourseCurriculum _mapCurriculum(
    response_curriculum.CurriculumResponse r,
  ) => entity_curriculum.CourseCurriculum(
    courseId: r.courseId,
    progress: r.progress,
    sections: r.sections.map((s) => _mapSectionFromCurriculum(s)).toList(),
    liveClasses: [], // Initially empty
  );

  entity.Section _mapSectionFromCurriculum(
    response_curriculum.SectionResponse s,
  ) => entity.Section(
    id: s.id,
    title: s.title,
    lectures: s.lectures.map((l) => _mapLectureFromCurriculum(l)).toList(),
    liveClasses: [],
  );

  entity.Lecture _mapLectureFromCurriculum(
    response_curriculum.LectureResponse l,
  ) => entity.Lecture(
    id: l.id,
    title: l.title,
    videoUrl: '', // Curriculum response might not provide video URL
    videoProvider: '',
  );
}
