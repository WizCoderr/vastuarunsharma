import '../../domain/entities/course.dart';

class CourseRepository {
  // Mock implementations
  Future<List<Course>> getCourses() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      const Course(
        id: '6953275230fae621f9efbe28',
        title: 'test',
        description: 'test',
        thumbnail:
            'https://vastu-media-prod.s3.ap-south-1.amazonaws.com/vastu-courses/images/1767057222890-del1.jpeg',
        price: 1200,
        published: true,
        instructorId: '6951a43ae20339f19833f2b1',
        mediaType: 'image',
        sections: [
          Section(
            id: '6953276330fae621f9efbe29',
            title: 'getting Started',
            lectures: [
              Lecture(
                id: '695327c630fae621f9efbe2e',
                title: 'Untitled Lecture',
                videoUrl: '',
                videoProvider: 'cloudinary',
              ),
            ],
          ),
        ],
      ),
    ];
  }
}
