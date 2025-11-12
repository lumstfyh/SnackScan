import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/currency_service.dart';

class CurrencyConversionScreen extends StatefulWidget {
  final double? initialAmountUsd;
  const CurrencyConversionScreen({Key? key, this.initialAmountUsd})
    : super(key: key);

  @override
  State<CurrencyConversionScreen> createState() =>
      _CurrencyConversionScreenState();
}

class _CurrencyConversionScreenState extends State<CurrencyConversionScreen> {
  final TextEditingController _controller = TextEditingController();
  String from = 'USD';
  String to = 'IDR';
  double? result;
  bool loading = false;
  String? error;

  final Map<String, Map<String, dynamic>> currencyInfo = {
    'USD': {'name': 'US Dollar', 'symbol': '\$', 'flag': '🇺🇸'},
    'IDR': {'name': 'Indonesian Rupiah', 'symbol': 'Rp', 'flag': '🇮🇩'},
    'EUR': {'name': 'Euro', 'symbol': '€', 'flag': '🇪🇺'},
    'GBP': {'name': 'British Pound', 'symbol': '£', 'flag': '🇬🇧'},
    'JPY': {'name': 'Japanese Yen', 'symbol': '¥', 'flag': '🇯🇵'},
    'SGD': {'name': 'Singapore Dollar', 'symbol': 'S\$', 'flag': '🇸🇬'},
    'MYR': {'name': 'Malaysian Ringgit', 'symbol': 'RM', 'flag': '🇲🇾'},
    'CNY': {'name': 'Chinese Yuan', 'symbol': '¥', 'flag': '🇨🇳'},
  };

  @override
  void initState() {
    super.initState();
    _controller.text = (widget.initialAmountUsd ?? 1.0).toStringAsFixed(2);
    // Auto convert on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _convert();
    });
  }

  Future<void> _convert() async {
    final val = double.tryParse(_controller.text.replaceAll(',', '.'));
    if (val == null || val <= 0) {
      setState(() => error = 'Masukkan jumlah yang valid');
      return;
    }

    setState(() {
      loading = true;
      error = null;
      result = null;
    });

    try {
      final res = await CurrencyService.convert(
        from: from,
        to: to,
        amount: val,
      );

      setState(() {
        loading = false;
        if (res == null) {
          error = 'Gagal mengonversi. Coba lagi.';
        } else {
          result = res;
        }
      });
    } catch (e) {
      print('Conversion error: $e');
      setState(() {
        loading = false;
        error = 'Terjadi kesalahan: ${e.toString()}';
      });
    }
  }

  void _swapCurrencies() {
    setState(() {
      final temp = from;
      from = to;
      to = temp;
      result = null;
      error = null;
    });
    _convert();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Konversi Mata Uang'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF2D2D2D)),
        titleTextStyle: TextStyle(
          color: Color(0xFF2D2D2D),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount Input Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFF0F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.payments,
                          color: Color(0xFFFF6B9D),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Jumlah',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFFFFF0F5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFFFFF0F5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Color(0xFFFF6B9D),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Color(0xFFFFF0F5),
                      contentPadding: EdgeInsets.all(20),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Currency Selection Card
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // From Currency
                  _buildCurrencySelector(
                    label: 'Dari',
                    value: from,
                    onChanged: (v) {
                      setState(() {
                        from = v!;
                        result = null;
                        error = null;
                      });
                    },
                  ),

                  SizedBox(height: 16),

                  // Swap Button
                  InkWell(
                    onTap: _swapCurrencies,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF6B9D), Color(0xFFFF8FAB)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFF6B9D).withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.swap_vert,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // To Currency
                  _buildCurrencySelector(
                    label: 'Ke',
                    value: to,
                    onChanged: (v) {
                      setState(() {
                        to = v!;
                        result = null;
                        error = null;
                      });
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Convert Button
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF6B9D), Color(0xFFFF8FAB)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF6B9D).withOpacity(0.3),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: loading ? null : _convert,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: loading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.currency_exchange, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Konversi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            SizedBox(height: 24),

            // Error Message
            if (error != null)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        error!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                  ],
                ),
              ),

            // Result Card
            if (result != null && !loading)
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B9D), Color(0xFFFF8FAB)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFFF6B9D).withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Hasil Konversi',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currencyInfo[to]?['flag'] ?? '',
                          style: TextStyle(fontSize: 32),
                        ),
                        SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            '${currencyInfo[to]?['symbol']} ${result!.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      currencyInfo[to]?['name'] ?? to,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencySelector({
    required String label,
    required String value,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Color(0xFFFFF0F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFFFF6B9D).withOpacity(0.2)),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: SizedBox(),
            icon: Icon(Icons.arrow_drop_down, color: Color(0xFFFF6B9D)),
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF2D2D2D),
              fontWeight: FontWeight.w600,
            ),
            items: currencyInfo.keys.map((currency) {
              return DropdownMenuItem(
                value: currency,
                child: Row(
                  children: [
                    Text(
                      currencyInfo[currency]?['flag'] ?? '',
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currency,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          currencyInfo[currency]?['name'] ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
