import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:vastuarunsharma/presentation/screens/dashboard/DashboardColors.dart';

class InquiryCard extends StatefulWidget {
  const InquiryCard({super.key});

  @override
  State<InquiryCard> createState() => _InquiryCardState();
}

class _InquiryCardState extends State<InquiryCard> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _remarksController = TextEditingController();

  // WhatsApp number to send inquiry to
  final String _contactNumber = "+919810520104"; 

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _submitInquiry() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final city = _cityController.text.trim();
      final phone = _phoneController.text.trim();
      final remarks = _remarksController.text.trim();

      final message = "New Inquiry from App:\n\n"
          "Name: $name\n"
          "Email: $email\n"
          "City: $city\n"
          "Phone: $phone\n"
          "Remarks: $remarks";

      final encodedMessage = Uri.encodeComponent(message);
      final url = "https://wa.me/$_contactNumber?text=$encodedMessage";

      try {
        if (await canLaunchUrlString(url)) {
          await launchUrlString(url, mode: LaunchMode.externalApplication);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Opening WhatsApp...'),
                backgroundColor: Colors.green,
              ),
            );
            _formKey.currentState!.reset();
          }
        } else {
          throw 'Could not launch WhatsApp';
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error launching WhatsApp: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DashboardColors.background, 
            DashboardColors.accentGold,
            DashboardColors.background,
          ],
          stops: [0.0, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inquiry',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: DashboardColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _nameController,
              hintText: 'Your Name',
              validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              hintText: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _cityController,
              hintText: 'City',
              validator: (value) =>
                  value == null || value.isEmpty ? 'Please enter your city' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              hintText: 'Phone Number',
              keyboardType: TextInputType.phone,
              validator: (value) => value == null || value.isEmpty
                  ? 'Please enter your phone number'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _remarksController,
              hintText: 'Remarks',
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitInquiry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A65), // Coral/Orange button
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white, width: 1),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Submit Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          errorStyle: const TextStyle(
            color: Colors.white, 
            fontSize: 12, 
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
          ),
        ),
      ),
    );
  }
}
