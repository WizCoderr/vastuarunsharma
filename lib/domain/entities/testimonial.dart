class Testimonial {
  final String authorName;
  final String profilePhotoUrl;
  final int rating;
  final String text;
  final String? relativeTime;

  Testimonial({
    required this.authorName,
    required this.profilePhotoUrl,
    required this.rating,
    required this.text,
    this.relativeTime,
  });

  factory Testimonial.fromJson(Map<String, dynamic> json) {
    return Testimonial(
      authorName: json['author_name'] ?? '',
      profilePhotoUrl: json['profile_photo_url'] ?? '',
      rating: json['rating'] ?? 5,
      text: json['text'] ?? '',
      relativeTime: json['relative_time_description'],
    );
  }
}
