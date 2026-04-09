import 'package:flutter/material.dart';
import '../services/payment_service.dart';
import 'payu_webview_screen.dart';
import '../main.dart';
import '../services/analytics_service.dart';

class PlanSelectionScreen extends StatefulWidget {
  final String role;
  
  const PlanSelectionScreen({super.key, required this.role});

  @override
  State<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen> {
  List<dynamic> _plans = [];
  bool _isLoading = true;
  String _error = '';

  Map<String, dynamic>? _selectedPlan;
  
  final _couponController = TextEditingController();
  List<dynamic> _availableCoupons = [];
  bool _isLoadingCoupons = true;
  bool _isCheckingCoupon = false;
  bool _couponApplied = false;
  double? _finalAmount;
  String _couponMessage = '';

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
    _fetchCoupons();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _fetchPlans() async {
    try {
      final plans = await PaymentService.getPlans();
      if (mounted) {
        setState(() {
          _plans = plans;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load plans securely. Please restart the app.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchCoupons() async {
    try {
      final coupons = await PaymentService.getAvailableCoupons('access');
      if (mounted) {
        setState(() {
          _availableCoupons = coupons;
          _isLoadingCoupons = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCoupons = false);
    }
  }

  Future<void> _applyCoupon([String? forcedCode]) async {
    final code = forcedCode ?? _couponController.text.trim();
    if (code.isEmpty || _selectedPlan == null) return;
    
    if (forcedCode != null) {
      _couponController.text = forcedCode;
    }
    setState(() {
      _isCheckingCoupon = true;
      _couponMessage = '';
    });

    final amount = double.parse(_selectedPlan!['price'].toString());
    final res = await PaymentService.validateCoupon(code, amount, 'access');

    if (mounted) {
      setState(() {
        _isCheckingCoupon = false;
        if (res['valid'] == true) {
          _couponApplied = true;
          _finalAmount = double.parse(res['data']['final_amount'].toString());
          _couponMessage = 'Coupon applied successfully!';
        } else {
          _couponApplied = false;
          _finalAmount = null;
          _couponMessage = res['message'] ?? 'Invalid coupon';
        }
      });
    }
  }

  Future<void> _processPayment() async {
    if (_selectedPlan == null) return;
    
    setState(() => _isProcessing = true);
    
    final basePrice = double.parse(_selectedPlan!['price'].toString());
    final amount = _couponApplied && _finalAmount != null ? _finalAmount! : basePrice;

    final res = await PaymentService.createPayUOrder(
      type: 'access',
      planId: _selectedPlan!['id'].toString(),
      amount: amount,
      couponCode: _couponApplied ? _couponController.text.trim() : null,
    );

    if (mounted) {
      setState(() => _isProcessing = false);

      if (res['success'] == true) {
        final Map<String, dynamic> payuData = res['data'];
        
        // Handle 100% coupon/free access without launching WebView
        if (payuData['free'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(payuData['message'] ?? 'Access granted successfully!'), backgroundColor: Colors.green),
          );
          AnalyticsService.logPurchase(
            amount: amount,
            currency: 'INR',
            parameters: {
              'plan_id': _selectedPlan!['id'].toString(),
              'plan_name': _selectedPlan!['name'],
              'coupon_code': _couponApplied ? _couponController.text.trim() : 'none',
              'method': 'free_coupon',
            },
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainLayout()),
            (route) => false,
          );
          return;
        }

        // Launch the internal invisible browser checkout
        final bool? paymentSuccess = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PayUWebViewScreen(payuData: payuData),
          ),
        );

        if (!mounted) return;

        if (paymentSuccess == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment Successful! Welcome to your dashboard.'), backgroundColor: Colors.green),
          );
          AnalyticsService.logPurchase(
            amount: amount,
            currency: 'INR',
            parameters: {
              'plan_id': _selectedPlan!['id'].toString(),
              'plan_name': _selectedPlan!['name'],
              'coupon_code': _couponApplied ? _couponController.text.trim() : 'none',
              'method': 'payu',
            },
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainLayout()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment cancelled or failed. Please try again.')),
          );
        }
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Unable to create payment session')),
         );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAFAF9),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFE63946))),
      );
    }

    if (_plans.isEmpty && _error.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAFAF9),
        body: Center(child: Text('No pricing plans found for your role.', style: TextStyle(color: Colors.black54))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF9),
      appBar: AppBar(
        title: const Text('Choose Your Plan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFFAFAF9),
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Pay once to access your dashboard. Secure payment via PayU.',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 16, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error, style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w500))),
                  ],
                ),
              )
            ],
            const SizedBox(height: 32),
            ..._plans.map((plan) => _buildPlanCard(plan)),
            
            if (_selectedPlan != null) ...[
               const SizedBox(height: 24),
               const Text('Have a coupon code?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
               const SizedBox(height: 12),
               Row(
                 children: [
                   Expanded(
                     child: TextField(
                       controller: _couponController,
                       textCapitalization: TextCapitalization.characters,
                       decoration: InputDecoration(
                         filled: true,
                         fillColor: Colors.white,
                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                         enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                         focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE63946))),
                         hintText: 'e.g. SAVE20',
                         hintStyle: TextStyle(color: Colors.grey.shade400),
                         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                       ),
                       onChanged: (_) {
                          if (_couponApplied) {
                            setState(() { _couponApplied = false; _couponMessage = ''; });
                          }
                       },
                     ),
                   ),
                   const SizedBox(width: 12),
                   SizedBox(
                     height: 50,
                     child: ElevatedButton(
                       onPressed: _isCheckingCoupon ? null : _applyCoupon,
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.black,
                         foregroundColor: Colors.white,
                         padding: const EdgeInsets.symmetric(horizontal: 24),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                         elevation: 0,
                       ),
                       child: _isCheckingCoupon 
                           ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                           : const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                     ),
                   )
                 ],
               ),
                if (_couponMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Icon(_couponApplied ? Icons.check_circle : Icons.error, color: _couponApplied ? const Color(0xFF10B981) : Colors.red, size: 16),
                        const SizedBox(width: 6),
                        Text(_couponMessage, style: TextStyle(color: _couponApplied ? const Color(0xFF10B981) : Colors.red, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),

               if (_availableCoupons.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  const Text('Available Offers', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _availableCoupons.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final c = _availableCoupons[index];
                        return _buildCouponItem(c);
                      },
                    ),
                  ),
               ],
                  
               const SizedBox(height: 48),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _selectedPlan != null ? Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE63946),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isProcessing
                 ? const CircularProgressIndicator(color: Colors.white)
                 : Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       const Text('Pay via PayU Securely', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                       const SizedBox(width: 8),
                       const Icon(Icons.lock_outline, size: 18),
                     ],
                   ),
            ),
          ),
        ),
      ) : null,
    );
  }

  Widget _buildPlanCard(dynamic plan) {
    bool isSelected = _selectedPlan != null && _selectedPlan!['id'] == plan['id'];
    
    return GestureDetector(
      onTap: () => setState(() {
        _selectedPlan = plan;
        _couponApplied = false;
        _couponMessage = '';
        _couponController.text = '';
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE63946).withValues(alpha: 0.05) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFFE63946) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!isSelected)
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
            if (isSelected)
               BoxShadow(color: const Color(0xFFE63946).withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan['name'] ?? '', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: isSelected ? const Color(0xFFE63946) : Colors.black87)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${(_couponApplied && isSelected && _finalAmount != null) ? _finalAmount : plan['price']}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.black),
                      ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text('/ ${plan['duration'] ?? 'Lifetime'}', style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  if (_couponApplied && isSelected)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: const Text('Discount applied', style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFFE63946) : Colors.transparent,
                border: Border.all(color: isSelected ? const Color(0xFFE63946) : Colors.grey.shade300, width: 2),
              ),
              child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCouponItem(dynamic c) {
    return GestureDetector(
      onTap: () => _applyCoupon(c['code']),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3), width: 1.5, style: BorderStyle.solid),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(c['code'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF10B981), fontFamily: 'monospace')),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    '${c['discount_type'] == 'percent' ? c['discount_value'] + '%' : '₹' + c['discount_value']} OFF',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              c['description'] ?? 'Limited time offer!',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11, height: 1.2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
