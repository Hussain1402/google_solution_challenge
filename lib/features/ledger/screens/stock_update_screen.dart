import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/theme/colors.dart';
import '../../../core/models/sku_model.dart';
import '../../../core/models/inventory_log_model.dart';
import '../../../core/services/firestore_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/runway_badge.dart';

class StockUpdateScreen extends ConsumerStatefulWidget {
  final String skuId;
  final String eventType; // "STOCK_IN" or "STOCK_OUT"

  const StockUpdateScreen({
    super.key,
    required this.skuId,
    required this.eventType,
  });

  @override
  ConsumerState<StockUpdateScreen> createState() => _StockUpdateScreenState();
}

class _StockUpdateScreenState extends ConsumerState<StockUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isSubmitting = false;
  SkuModel? _sku;
  String? _error;

  bool get isStockIn => widget.eventType == 'STOCK_IN';

  @override
  void initState() {
    super.initState();
    _loadSku();
  }

  Future<void> _loadSku() async {
    final sku = await FirestoreService().getSku(widget.skuId);
    if (mounted) setState(() => _sku = sku);
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _sku == null) return;

    final qty = int.parse(_qtyCtrl.text);
    final newStock = isStockIn
        ? _sku!.currentStock + qty
        : _sku!.currentStock - qty;

    if (newStock < 0) {
      setState(() => _error = 'Cannot reduce stock below 0');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final authState = ref.read(authStateProvider);
      final uid = authState.when(
        data: (user) => user?.uid ?? 'unknown',
        loading: () => 'unknown',
        error: (e, st) => 'unknown',
      );

      final db = FirestoreService();

      // Update inventory stock (also recalculates runway)
      await db.updateStock(
        skuId: widget.skuId,
        newStock: newStock,
        updatedBy: uid,
        avgDailyConsumption: _sku!.avgDailyConsumption,
        reservedStock: _sku!.reservedStock,
      );

      // Create inventory log entry
      final log = InventoryLogModel(
        eventId: const Uuid().v4(),
        skuId: widget.skuId,
        eventType: widget.eventType,
        quantityDelta: qty,
        stockAfter: newStock,
        performedBy: uid,
        timestamp: DateTime.now(),
        notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text.trim(),
      );
      await db.addInventoryLog(log);

      // Trigger the Two-Mode Response Logic via Cloud Function
      // This checks if a proactive drive needs to be created or a critical alert sent
      try {
        final callable = FirebaseFunctions.instance.httpsCallable(
          'checkRunwayAndCreateDrive',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 300)),
        );
        final response = await callable.call({'skuId': widget.skuId});
        final action = response.data['action'] ?? 'UNKNOWN';
        print('[REPLENISHER] Cloud Function response: $action');
      } catch (e) {
        print('[REPLENISHER] checkRunwayAndCreateDrive failed (non-blocking): $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isStockIn
                  ? '+$qty ${_sku!.unit} added to ${_sku!.skuName}'
                  : '-$qty ${_sku!.unit} removed from ${_sku!.skuName}',
            ),
            backgroundColor: isStockIn ? kGreen : kAmber,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed: $e';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isStockIn ? 'Stock In' : 'Stock Out'),
      ),
      body: _sku == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SKU info header
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kLightGray,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        CategoryIcon(categoryId: _sku!.categoryId),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_sku!.skuName, style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600, color: kGray)),
                              const SizedBox(height: 2),
                              Text('Current: ${_sku!.currentStock} ${_sku!.unit}',
                                  style: TextStyle(fontSize: 13, color: kMidGray)),
                            ],
                          ),
                        ),
                        RunwayBadge(daysOfRunway: _sku!.daysOfRunway),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // Event type indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isStockIn ? kLightGreen : kLightAmb,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        Icon(isStockIn ? Icons.add_circle : Icons.remove_circle,
                            color: isStockIn ? kGreen : kAmber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isStockIn ? 'Adding stock to inventory' : 'Removing stock from inventory',
                          style: TextStyle(
                            color: isStockIn ? kGreen : kAmber,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // Quantity field
                    Text('Quantity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kGray)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter quantity in ${_sku!.unit}',
                        prefixIcon: const Icon(Icons.numbers),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final n = int.tryParse(v);
                        if (n == null || n <= 0) return 'Enter a positive number';
                        if (!isStockIn && n > _sku!.currentStock) {
                          return 'Cannot exceed current stock (${_sku!.currentStock})';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Notes field
                    Text('Notes (optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kGray)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Add any notes about this transaction',
                        prefixIcon: Icon(Icons.note),
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: kRed, fontSize: 13)),
                    ],

                    const SizedBox(height: 28),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        icon: _isSubmitting
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Icon(isStockIn ? Icons.add : Icons.remove),
                        label: Text(_isSubmitting
                            ? 'Processing...'
                            : isStockIn ? 'Record Stock In' : 'Record Stock Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isStockIn ? kGreen : kAmber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
