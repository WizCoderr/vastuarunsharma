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

// Create order provider
final createOrderProvider = FutureProvider.family<Order, CheckoutFormData>((
  ref,
  formData,
) async {
  final repository = ref.watch(remidiesRepositoryProvider);
  return repository.createOrder(
    fullName: formData.fullName,
    phoneNumber: formData.phoneNumber,
    address: formData.address,
    city: formData.city,
    state: formData.state,
    postalCode: formData.postalCode,
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

  CheckoutFormData({
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    required this.city,
    required this.state,
    required this.postalCode,
  });

  CheckoutFormData copyWith({
    String? fullName,
    String? phoneNumber,
    String? address,
    String? city,
    String? state,
    String? postalCode,
  }) {
    return CheckoutFormData(
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
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
