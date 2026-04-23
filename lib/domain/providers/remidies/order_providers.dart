import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:vastuarunsharma/data/models/remidies/order.dart';
import 'package:vastuarunsharma/domain/providers/remidies/remidies_providers.dart';

// Checkout form state provider
final checkoutFormProvider = StateProvider<CheckoutFormData>((ref) {
  return CheckoutFormData(
    fullName: '',
    phoneNumber: '',
    address: '',
    city: '',
    state: '',
    postalCode: '',
  );
});

// Create order via new checkout endpoint — returns raw map with price breakdown
final createOrderProvider =
    FutureProvider.family<Map<String, dynamic>, CheckoutFormData>((
  ref,
  formData,
) async {
  final repository = ref.watch(remidiesRepositoryProvider);
  return repository.checkout(
    fullName: formData.fullName,
    phoneNumber: formData.phoneNumber,
    address: formData.address,
    city: formData.city,
    state: formData.state,
    postalCode: formData.postalCode,
    couponCode: formData.couponCode,
  );
});

// Orders history provider
final ordersProvider = FutureProvider<List<Order>>((ref) async {
  final repository = ref.watch(remidiesRepositoryProvider);
  return repository.getOrders();
});

// Form data model
class CheckoutFormData {
  final String fullName;
  final String phoneNumber;
  final String address;
  final String city;
  final String state;
  final String postalCode;
  final String? couponCode;

  CheckoutFormData({
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    required this.city,
    required this.state,
    required this.postalCode,
    this.couponCode,
  });

  CheckoutFormData copyWith({
    String? fullName,
    String? phoneNumber,
    String? address,
    String? city,
    String? state,
    String? postalCode,
    String? couponCode,
  }) {
    return CheckoutFormData(
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      couponCode: couponCode ?? this.couponCode,
    );
  }

  bool get isValid =>
      fullName.isNotEmpty &&
      phoneNumber.isNotEmpty &&
      address.isNotEmpty &&
      city.isNotEmpty &&
      state.isNotEmpty &&
      postalCode.isNotEmpty;
}
