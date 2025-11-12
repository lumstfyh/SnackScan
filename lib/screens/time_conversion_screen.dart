import 'package:flutter/material.dart';
import '../services/time_service.dart';

class TimeConversionScreen extends StatefulWidget {
  final int? createdTimestampUtc;

  const TimeConversionScreen({Key? key, this.createdTimestampUtc})
    : super(key: key);

  @override
  State<TimeConversionScreen> createState() => _TimeConversionScreenState();
}

class _TimeConversionScreenState extends State<TimeConversionScreen> {
  final Map<String, String> zones = {
    'WIB (Asia/Jakarta)': 'Asia/Jakarta',
    'WITA (Asia/Makassar)': 'Asia/Makassar',
    'WIT (Asia/Jayapura)': 'Asia/Jayapura',
    'London (Europe/London)': 'Europe/London',
    'New York (America/New_York)': 'America/New_York',
    'Tokyo (Asia/Tokyo)': 'Asia/Tokyo',
  };

  String selectedLabel = 'WIB (Asia/Jakarta)';
  DateTime? converted;
  Duration? targetOffset;
  Duration? localOffset;
  bool loading = false;
  String? error;
  DateTime? baseUtc;

  @override
  void initState() {
    super.initState();
    if (widget.createdTimestampUtc != null) {
      baseUtc = DateTime.fromMillisecondsSinceEpoch(
        widget.createdTimestampUtc! * 1000,
        isUtc: true,
      );

      localOffset = DateTime.now().timeZoneOffset;
      _convert();
    }
  }

  Future<void> _convert() async {
    if (baseUtc == null) {
      setState(() {
        error = 'Data tanggal tidak tersedia.';
      });
      return;
    }

    setState(() {
      loading = true;
      error = null;
      converted = null;
    });

    final zone = zones[selectedLabel]!;

    try {
      final info = await TimeService.fetchTimezoneInfo(zone);
      Duration offset;

      if (info != null) {
        final offsetStr =
            info['currentLocalTimeOffset'] ?? info['utcOffset'] ?? '+00:00';
        final parsedOffset = TimeService.parseUtcOffset(offsetStr);

        // Validate API response
        if (parsedOffset != null && parsedOffset != Duration.zero) {
          offset = parsedOffset;
        } else if (TimeService.fallbackOffsets.containsKey(zone)) {
          offset = TimeService.fallbackOffsets[zone]!;
        } else {
          offset = Duration.zero;
        }
      } else {
        offset = TimeService.fallbackOffsets[zone] ?? Duration.zero;
      }

      final conv = baseUtc!.add(offset);

      setState(() {
        converted = conv;
        targetOffset = offset;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = 'Gagal mengambil zona waktu. Menggunakan offset default.';
        final offset =
            TimeService.fallbackOffsets[zones[selectedLabel]] ?? Duration.zero;
        converted = baseUtc!.add(offset);
        targetOffset = offset;
      });
    }
  }

  String _formatDateTime(DateTime dt) {
    final days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${days[dt.weekday % 7]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}\n'
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  String _formatDurationDifference(Duration d) {
    final sign = d.isNegative ? '-' : '+';
    final abs = d.abs();
    final hours = abs.inHours;
    final mins = abs.inMinutes.remainder(60);
    return '$sign${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final baseUtcStr = baseUtc != null ? _formatDateTime(baseUtc!) : 'N/A';

    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Konversi Waktu'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF2D2D2D)),
        titleTextStyle: TextStyle(
          color: Color(0xFF2D2D2D),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: baseUtc == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Color(0xFFFF6B9D).withOpacity(0.5),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Tidak ada data tanggal produk',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // UTC Time Card
                  Container(
                    padding: EdgeInsets.all(20),
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
                        Icon(Icons.public, color: Colors.white, size: 40),
                        SizedBox(height: 12),
                        Text(
                          'Waktu UTC (Universal)',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          baseUtcStr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Timezone Selector
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
                                Icons.location_on,
                                color: Color(0xFFFF6B9D),
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Pilih Zona Waktu',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D2D2D),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFFFF0F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButton<String>(
                            value: selectedLabel,
                            isExpanded: true,
                            underline: SizedBox(),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFFFF6B9D),
                            ),
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF2D2D2D),
                              fontWeight: FontWeight.w500,
                            ),
                            items: zones.keys
                                .map(
                                  (k) => DropdownMenuItem(
                                    value: k,
                                    child: Text(k),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              setState(() => selectedLabel = v!);
                              _convert();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Result Card
                  if (loading)
                    Container(
                      padding: EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF6B9D),
                          ),
                        ),
                      ),
                    ),

                  if (error != null && !loading)
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              error!,
                              style: TextStyle(color: Colors.orange.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (!loading && converted != null)
                    Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(24),
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
                              Icon(
                                Icons.schedule,
                                color: Color(0xFFFF6B9D),
                                size: 40,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Waktu di $selectedLabel',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                _formatDateTime(converted!),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D2D2D),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),

                        // Time Difference Info
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Color(0xFFFFF0F5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.compare_arrows,
                                    color: Color(0xFFFF6B9D),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Perbedaan Waktu Lokal Anda',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                localOffset != null && targetOffset != null
                                    ? _formatDurationDifference(
                                        targetOffset! - localOffset!,
                                      )
                                    : 'N/A',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF6B9D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}
