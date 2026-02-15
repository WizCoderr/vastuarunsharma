import 'package:flutter/material.dart';
import '../../../../domain/entities/testimonial.dart';
import '../DashboardColors.dart';
import 'TestimonialCard.dart';

class TestimonialsSection extends StatefulWidget {
  const TestimonialsSection({super.key});

  @override
  State<TestimonialsSection> createState() => _TestimonialsSectionState();
}

class _TestimonialsSectionState extends State<TestimonialsSection> {
  late PageController _pageController;
  int _currentPage = 0;

  // Mock Data - Replace with API call later
  final List<Testimonial> _testimonials = [
    Testimonial(
      authorName: 'Neha Nougai',
      profilePhotoUrl:
          'https://ui-avatars.com/api/?name=Neha+Nougai&background=white&color=000000',
      rating: 5,
      text:
          "Vastu Arun Sharma has helped us in transforming our home into a place of peace and prosperity. His ideas and advice have made a big difference in our lives.",
      relativeTime: "2 weeks ago",
    ),
    Testimonial(
      authorName: 'Mayank Kapila',
      profilePhotoUrl:
          'https://ui-avatars.com/api/?name=Mayank+Kapila&background=white&color=000000',
      rating: 5,
      text:
          "The Vastu consultation from Arun sir leads to increased productivity and a more positive work environment around us.",
      relativeTime: "1 month ago",
    ),
    Testimonial(
      authorName: 'Hanish Bansal',
      profilePhotoUrl:
          'https://ui-avatars.com/api/?name=Hanish+Bansa&background=white&color=000000',
      rating: 4,
      text:
          "I was unsure of Vastu at first, but after working with Arun Sharma Ji, I am convinced of its effectiveness as My firm has seen a significant improvement after implementing his recommendations.",
      relativeTime: "3 weeks ago",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Placeholder for Google Reviews API integration
  // Future<void> _fetchGoogleReviews() async {
  // 1. Get Place Details from Google Places API
  // 2. Parse 'reviews' array
  // 3. Update _testimonials list
  // 4. setState()
  // }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Testimonials',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: DashboardColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 380, // Adjust height based on card content
          child: PageView.builder(
            controller: _pageController,
            itemCount: _testimonials.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TestimonialCard(testimonial: _testimonials[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_testimonials.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentPage == index ? 24 : 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? DashboardColors.accentGold
                    : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
