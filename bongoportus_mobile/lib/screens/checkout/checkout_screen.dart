import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/address.dart';
import '../../services/order_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final OrderService _orderService = OrderService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _couponController = TextEditingController();

  String _paymentMethod = 'cod';
  bool _isSubmitting = false;
  List<Address> _savedAddresses = [];
  Address? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;
    try {
      _savedAddresses = await _orderService.getUserAddresses(userId);
      if (_savedAddresses.isNotEmpty) {
        _selectedAddress = _savedAddresses.firstWhere((a) => a.isDefault,
            orElse: () => _savedAddresses.first);
        _populateAddress(_selectedAddress!);
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _populateAddress(Address addr) {
    _nameController.text = addr.fullName;
    _phoneController.text = addr.phone;
    _addressController.text = addr.addressLine1;
    _cityController.text = addr.city;
    _stateController.text = addr.state;
    _postalCodeController.text = addr.postalCode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();

    try {
      final address = Address(
        id: '',
        userId: auth.userId!,
        label: 'Checkout',
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        addressLine1: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
      );

      final cartItems = cart.items
          .map((item) => <String, dynamic>{
                'productId': item.productId,
                'variantId': item.variantId,
                'quantity': item.quantity,
                'price': item.product?.effectivePrice ?? 0.0,
                'productName': item.product?.name ?? 'Product',
                'productImageUrl': item.product?.primaryImageUrl,
                'sellerId': item.product?.sellerId ?? '',
                'shopId': item.product?.shopId ?? '',
                'commissionRate': 10.0,
              })
          .toList();

      final order = await _orderService.createOrder(
        userId: auth.userId!,
        cartItems: cartItems,
        address: address,
        paymentMethod: _paymentMethod,
        couponCode: _couponController.text.trim().isNotEmpty
            ? _couponController.text.trim()
            : null,
      );

      // Clear cart
      await cart.clearCart(auth.userId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #${order.orderNumber} placed successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.go('/order/${order.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order failed: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Saved addresses
            if (_savedAddresses.isNotEmpty) ...[
              const Text(
                'Saved Addresses',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _savedAddresses.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final addr = _savedAddresses[i];
                    final isSelected = _selectedAddress?.id == addr.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedAddress = addr);
                        _populateAddress(addr);
                      },
                      child: Container(
                        width: 200,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor.withAlpha(13)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(addr.label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(
                              addr.formattedAddress,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Delivery Information
            _buildSectionTitle(
                'Delivery Information', Icons.local_shipping_rounded),
            const SizedBox(height: 12),
            _buildTextField(_nameController, 'Full Name', Icons.person_outline),
            const SizedBox(height: 12),
            _buildTextField(
                _phoneController, 'Phone Number', Icons.phone_outlined,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _buildTextField(
                _addressController, 'Address', Icons.location_on_outlined,
                maxLines: 2),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTextField(_cityController, 'City', null)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildTextField(_stateController, 'State', null)),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(_postalCodeController, 'Postal Code', null,
                keyboardType: TextInputType.number),

            const SizedBox(height: 24),

            // Payment method
            _buildSectionTitle('Payment Method', Icons.payment_rounded),
            const SizedBox(height: 12),
            _buildPaymentOption('cod', 'Cash on Delivery', Icons.money_rounded),
            _buildPaymentOption('bkash', 'bKash', Icons.phone_android_rounded),
            _buildPaymentOption(
                'card', 'Credit/Debit Card', Icons.credit_card_rounded),

            const SizedBox(height: 24),

            // Coupon
            _buildSectionTitle('Coupon Code', Icons.local_offer_rounded),
            const SizedBox(height: 12),
            TextFormField(
              controller: _couponController,
              decoration: InputDecoration(
                hintText: 'Enter coupon code',
                suffixIcon: TextButton(
                  onPressed: () {},
                  child: const Text('Apply'),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Order Summary
            _buildSectionTitle('Order Summary', Icons.receipt_long_rounded),
            const SizedBox(height: 12),
            _buildSummaryRow('Items (${cart.itemCount})',
                '৳${cart.subtotal.toStringAsFixed(0)}'),
            _buildSummaryRow(
                'Shipping', '৳${cart.shippingCharge.toStringAsFixed(0)}'),
            const Divider(height: 24),
            _buildSummaryRow('Total', '৳${cart.total.toStringAsFixed(0)}',
                isBold: true),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _placeOrder,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Place Order - ৳${cart.total.toStringAsFixed(0)}'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 22),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData? icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
    );
  }

  Widget _buildPaymentOption(String value, String label, IconData icon) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withAlpha(12)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Icon(icon,
                color: isSelected
                    ? AppTheme.primaryColor
                    : Colors.grey.shade500,
                size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppTheme.secondaryColor
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: isBold ? 16 : 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isBold ? AppTheme.secondaryColor : Colors.grey.shade600,
              )),
          Text(value,
              style: TextStyle(
                fontSize: isBold ? 18 : 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: isBold ? AppTheme.primaryColor : AppTheme.secondaryColor,
              )),
        ],
      ),
    );
  }
}
