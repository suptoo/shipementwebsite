import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OrderProvider>().loadOrder(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Order Details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final order = provider.selectedOrder;
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Order Details')),
            body: const Center(child: Text('Order not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('#${order.orderNumber}'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status
              _buildStatusCard(order),
              const SizedBox(height: 16),
              // Items
              _buildItemsCard(order),
              const SizedBox(height: 16),
              // Delivery
              _buildDeliveryCard(order),
              const SizedBox(height: 16),
              // Payment summary
              _buildPaymentCard(order),
              const SizedBox(height: 16),
              // Tracking
              if (order.trackingNumber != null) _buildTrackingCard(order),
              // Cancel button
              if (order.orderStatus == 'pending' ||
                  order.orderStatus == 'confirmed') ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelOrder(order.id),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel Order'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: const BorderSide(color: AppTheme.errorColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(Order order) {
    // Cancelled orders get a special card
    if (order.orderStatus == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.errorColor.withAlpha(13),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.errorColor.withAlpha(51)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.cancel_rounded,
                  color: AppTheme.errorColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order CANCELLED',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cancelled on ${_formatDate(order.createdAt)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Timeline steps
    const stages = ['pending', 'confirmed', 'processing', 'shipped', 'delivered'];
    const stageLabels = ['Placed', 'Confirmed', 'Processing', 'Shipped', 'Delivered'];
    const stageIcons = [
      Icons.receipt_long_rounded,
      Icons.check_circle_rounded,
      Icons.settings_rounded,
      Icons.local_shipping_rounded,
      Icons.done_all_rounded,
    ];
    const stageColors = [
      Color(0xFFF59E0B), // orange
      Color(0xFF3B82F6), // blue
      Color(0xFF8B5CF6), // purple
      Color(0xFF6366F1), // indigo
      Color(0xFF22C55E), // green
    ];

    final currentIndex = stages.indexOf(order.orderStatus);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline_rounded, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Order Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                _formatDate(order.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Timeline
          Row(
            children: List.generate(stages.length, (i) {
              final isCompleted = i <= currentIndex;
              final isCurrent = i == currentIndex;
              final color = isCompleted ? stageColors[i] : Colors.grey.shade300;

              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Left connector
                        if (i > 0)
                          Expanded(
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: i <= currentIndex
                                    ? stageColors[i].withAlpha(180)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        // Circle
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: isCurrent ? 36 : 28,
                          height: isCurrent ? 36 : 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted ? color : Colors.grey.shade100,
                            border: Border.all(
                              color: isCompleted ? color : Colors.grey.shade300,
                              width: isCurrent ? 3 : 2,
                            ),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: color.withAlpha(80),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Icon(
                            stageIcons[i],
                            size: isCurrent ? 16 : 13,
                            color: isCompleted ? Colors.white : Colors.grey.shade400,
                          ),
                        ),
                        // Right connector
                        if (i < stages.length - 1)
                          Expanded(
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: i < currentIndex
                                    ? stageColors[i + 1].withAlpha(180)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stageLabels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isCompleted ? color : Colors.grey.shade400,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Items',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: item.productImageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: item.productImageUrl!,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image, size: 24),
                                ),
                              )
                            : Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image, size: 24),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.quantity}x ৳${item.unitPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '৳${item.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Delivery Address',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Text(order.deliveryFullName),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.phone_outlined, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Text(order.deliveryPhone),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined,
                  size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Expanded(child: Text(order.formattedAddress)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _row('Subtotal', '৳${order.subtotal.toStringAsFixed(0)}'),
          if (order.discountAmount > 0)
            _row('Discount', '-৳${order.discountAmount.toStringAsFixed(0)}',
                color: AppTheme.successColor),
          _row('Shipping', '৳${order.shippingCharge.toStringAsFixed(0)}'),
          if (order.taxAmount > 0)
            _row('Tax', '৳${order.taxAmount.toStringAsFixed(0)}'),
          const Divider(height: 16),
          _row('Total', '৳${order.totalAmount.toStringAsFixed(0)}',
              isBold: true),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Method: ',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              Text(order.paymentMethod.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: order.paymentStatus == 'paid'
                      ? AppTheme.successColor.withAlpha(25)
                      : Colors.orange.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.paymentStatus.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: order.paymentStatus == 'paid'
                        ? AppTheme.successColor
                        : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingCard(Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tracking',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (order.courierName != null)
            Text('Courier: ${order.courierName}',
                style: TextStyle(color: Colors.grey.shade600)),
          Text('Tracking #: ${order.trackingNumber}',
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: isBold ? 15 : 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: Colors.grey.shade600,
              )),
          Text(value,
              style: TextStyle(
                fontSize: isBold ? 16 : 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: color ?? (isBold ? AppTheme.primaryColor : null),
              )),
        ],
      ),
    );
  }

  void _cancelOrder(String orderId) async {
    final orderProvider = context.read<OrderProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await orderProvider.cancelOrder(orderId);
        await orderProvider.loadOrder(orderId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order cancelled'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${date.day} ${months[date.month]} ${date.year}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}
