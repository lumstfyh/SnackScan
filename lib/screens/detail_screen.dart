import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/snack_model.dart';
import '../utils/notification_helper.dart';
import 'time_conversion_screen.dart';
import 'currency_conversion_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const DetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isFavorite = false;
  double? _distanceKm;
  String? _originCountry;
  bool _isLoadingDistance = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
    _checkAndNotifyAllergens();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateSnackOriginDistance();
    });
  }

  Future<void> _calculateSnackOriginDistance() async {
    try {
      setState(() => _isLoadingDistance = true);

      final origins =
          widget.product['origins'] ??
          widget.product['manufacturing_places'] ??
          widget.product['countries_tags'] ??
          'Tidak tersedia';

      if (origins == null ||
          origins.toString().isEmpty ||
          origins == 'Tidak tersedia') {
        print('⚠️ Tidak ada data asal negara produk.');
        setState(() => _isLoadingDistance = false);
        return;
      }

      String countryName = origins is List && origins.isNotEmpty
          ? origins.first.toString()
          : origins.toString();

      countryName = countryName
          .replaceAll('en:', '')
          .replaceAll('_', ' ')
          .split(',')
          .first
          .trim();

      // Minta izin lokasi
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('🚫 Izin lokasi ditolak');
        setState(() => _isLoadingDistance = false);
        return;
      }

      // Ambil posisi pengguna
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Ambil koordinat negara asal produk
      final locations = await locationFromAddress(countryName);
      if (locations.isEmpty) {
        print('⚠️ Tidak bisa menemukan koordinat untuk $countryName');
        setState(() => _isLoadingDistance = false);
        return;
      }

      final countryLat = locations.first.latitude;
      final countryLon = locations.first.longitude;

      // Hitung jarak
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        countryLat,
        countryLon,
      );

      setState(() {
        _originCountry = countryName;
        _distanceKm = distance / 1000; // meter -> km
        _isLoadingDistance = false;
      });

      print(
        '✅ Jarak ke $_originCountry: ${_distanceKm!.toStringAsFixed(2)} km',
      );
    } catch (e) {
      print('❌ Error menghitung jarak: $e');
      setState(() => _isLoadingDistance = false);
    }
  }

  Future<void> _checkAndNotifyAllergens() async {
    final allergens =
        widget.product['allergens'] ??
        widget.product['allergens_tags']?.toString() ??
        '';

    if (allergens.isNotEmpty && allergens != 'Tidak tersedia') {
      final productName =
          widget.product['product_name'] ??
          widget.product['product_name_en'] ??
          'Produk ini';

      List<String> allergensList = [];
      if (allergens is String) {
        allergensList = allergens
            .replaceAll('en:', '')
            .replaceAll('_', ' ')
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (allergens is List) {
        allergensList = allergens
            .map((e) => e.toString().replaceAll('en:', '').replaceAll('_', ' '))
            .toList();
      }

      if (allergensList.isNotEmpty) {
        await NotificationHelper().showMultipleAllergensWarning(
          productName: productName,
          allergensList: allergensList,
        );

        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            _showAllergenDialog(productName, allergensList);
          }
        });
      }
    }
  }

  void _showAllergenDialog(String productName, List<String> allergens) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade600,
                  size: 28,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Peringatan Alergen!',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Produk "$productName" mengandung alergen berikut:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: allergens.map((allergen) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: Colors.red.shade600,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              allergen,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mohon periksa dengan teliti sebelum dikonsumsi, terutama jika Anda memiliki alergi.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Saya Mengerti',
                style: TextStyle(
                  color: Color(0xFFFF6B9D),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkFavorite() async {
    final barcode = widget.product['code'] ?? '';
    final favorites = await DBHelper.instance.queryAll('favorites');
    final isFav = favorites.any((fav) => fav['barcode'] == barcode);
    setState(() => _isFavorite = isFav);
  }

  Future<void> _toggleFavorite() async {
    final barcode = widget.product['code'] ?? '';
    final name = widget.product['product_name'] ?? 'Unknown';

    if (_isFavorite) {
      final favorites = await DBHelper.instance.queryAll('favorites');
      final favList = favorites.where((f) => f['barcode'] == barcode).toList();
      if (favList.isNotEmpty) {
        final fav = favList.first;
        await DBHelper.instance.deleteWhere('favorites', 'id = ?', [fav['id']]);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Dihapus dari favorit'),
            backgroundColor: Color(0xFFFF6B9D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } else {
      String? imageUrl;
      String? imageSmallUrl;

      if (widget.product['image_url'] != null) {
        imageUrl = widget.product['image_url'].toString();
      } else if (widget.product['image_front_url'] != null) {
        imageUrl = widget.product['image_front_url'].toString();
      }

      if (widget.product['image_small_url'] != null) {
        imageSmallUrl = widget.product['image_small_url'].toString();
      } else if (widget.product['image_front_small_url'] != null) {
        imageSmallUrl = widget.product['image_front_small_url'].toString();
      }

      await DBHelper.instance.create('favorites', {
        'barcode': barcode,
        'product_name': name,
        'data': json.encode(widget.product),
        'image_url': imageUrl,
        'image_front_small_url': imageSmallUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ditambahkan ke favorit'),
          backgroundColor: Color(0xFFFF6B9D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
    setState(() => _isFavorite = !_isFavorite);
  }

  String _formatTimestampToLocal(int? tsSeconds) {
    if (tsSeconds == null) return 'Tidak tersedia';
    final dt = DateTime.fromMillisecondsSinceEpoch(
      tsSeconds * 1000,
      isUtc: true,
    ).toLocal();
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final name =
        widget.product['product_name'] ??
        widget.product['product_name_en'] ??
        'Nama tidak tersedia';
    final img =
        widget.product['image_url'] ?? widget.product['image_small_url'];
    final barcode = widget.product['code'] ?? 'N/A';
    final snack = SnackModel.fromJson(widget.product);

    final nutriments = widget.product['nutriments'] ?? {};
    final ingredients =
        widget.product['ingredients_text'] ??
        widget.product['ingredients_text_id'] ??
        'Tidak tersedia';
    final brands = widget.product['brands'] ?? 'Tidak tersedia';
    final categories = widget.product['categories'] ?? 'Tidak tersedia';
    final quantity = widget.product['quantity'] ?? 'Tidak tersedia';

    final allergens =
        widget.product['allergens'] ??
        widget.product['allergens_tags']?.toString() ??
        'Tidak tersedia';
    final traces =
        widget.product['traces'] ??
        widget.product['traces_tags']?.toString() ??
        'Tidak tersedia';
    final additives = widget.product['additives_tags'] ?? [];
    final nutritionGrade =
        widget.product['nutrition_grade_fr'] ??
        widget.product['nutrition_grades'] ??
        'Tidak tersedia';
    final novaGroup = widget.product['nova_group'];
    final labels =
        widget.product['labels'] ??
        widget.product['labels_tags']?.toString() ??
        'Tidak tersedia';
    final hasAllergens = allergens.isNotEmpty && allergens != 'Tidak tersedia';
    // 🔍 Informasi Asal Negara (LBS Integration)
    final origins =
        widget.product['origins_tags'] ??
        widget.product['origins'] ??
        widget.product['manufacturing_places'] ??
        widget.product['countries_tags'] ??
        'Tidak tersedia';

    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(Icons.arrow_back, color: Color(0xFF2D2D2D)),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (hasAllergens)
                Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red.shade600,
                      ),
                    ),
                    onPressed: () {
                      List<String> allergensList = [];
                      if (allergens is String) {
                        allergensList = allergens
                            .replaceAll('en:', '')
                            .replaceAll('_', ' ')
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList();
                      }
                      _showAllergenDialog(name, allergensList);
                    },
                  ),
                ),
              IconButton(
                icon: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Color(0xFFFF6B9D) : Color(0xFF2D2D2D),
                  ),
                ),
                onPressed: _toggleFavorite,
              ),
              SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.white,
                child: Center(
                  child: img != null
                      ? Image.network(
                          img,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.fastfood,
                            size: 100,
                            color: Color(0xFFFF6B9D).withOpacity(0.5),
                          ),
                        )
                      : Icon(
                          Icons.fastfood,
                          size: 100,
                          color: Color(0xFFFF6B9D).withOpacity(0.5),
                        ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.all(16),
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
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildInfoChip(Icons.qr_code, 'Barcode: $barcode'),
                      if (brands != 'Tidak tersedia') ...[
                        SizedBox(height: 8),
                        _buildInfoChip(Icons.business, 'Brand: $brands'),
                      ],
                      if (quantity != 'Tidak tersedia') ...[
                        SizedBox(height: 8),
                        _buildInfoChip(
                          Icons.shopping_bag,
                          'Quantity: $quantity',
                        ),
                      ],
                    ],
                  ),
                ),

                _buildSectionCard(
                  title: 'Informasi Harga & Tanggal',
                  icon: Icons.info_outline,
                  children: [
                    _buildDetailRowWithButton(
                      'Harga Rata-rata',
                      '\$ ${snack.avgPriceUSD.toStringAsFixed(2)} USD',
                      Icons.attach_money,
                      icon2: Icons.currency_exchange,
                      buttonLabel: 'Konversi',
                      gradient: [Color(0xFFFF6B9D), Color(0xFFFF8FAB)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CurrencyConversionScreen(
                              initialAmountUsd: snack.avgPriceUSD,
                            ),
                          ),
                        );
                      },
                    ),
                    Divider(height: 24),
                    _buildDetailRowWithButton(
                      'Ditambahkan',
                      _formatTimestampToLocal(snack.createdTime),
                      Icons.calendar_today,
                      icon2: Icons.access_time,
                      buttonLabel: 'Konversi',
                      gradient: [Color(0xFFFF6B9D), Color(0xFFFF8FAB)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TimeConversionScreen(
                              createdTimestampUtc: snack.createdTime,
                            ),
                          ),
                        );
                      },
                    ),
                    Divider(height: 24),
                    _buildDetailRowWithButton(
                      'Terakhir Diperbarui',
                      _formatTimestampToLocal(snack.lastModifiedTime),
                      Icons.update,
                      icon2: Icons.access_time,
                      buttonLabel: 'Konversi',
                      gradient: [Color(0xFFFF6B9D), Color(0xFFFF8FAB)],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TimeConversionScreen(
                              createdTimestampUtc: snack.lastModifiedTime,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                if (nutriments.isNotEmpty)
                  _buildSectionCard(
                    title: 'Informasi Nutrisi',
                    icon: Icons.local_dining,
                    subtitle: 'Per 100g/100ml',
                    children: <Widget>[
                      if (nutriments['energy-kcal_100g'] != null)
                        _buildNutritionRow(
                          'Kalori',
                          '${nutriments['energy-kcal_100g']} kcal',
                          Colors.orange,
                        ),
                      if (nutriments['fat_100g'] != null)
                        _buildNutritionRow(
                          'Lemak',
                          '${nutriments['fat_100g']} g',
                          Colors.red,
                        ),
                      if (nutriments['saturated-fat_100g'] != null)
                        _buildNutritionRow(
                          'Lemak Jenuh',
                          '${nutriments['saturated-fat_100g']} g',
                          Colors.red.shade300,
                        ),
                      if (nutriments['carbohydrates_100g'] != null)
                        _buildNutritionRow(
                          'Karbohidrat',
                          '${nutriments['carbohydrates_100g']} g',
                          Colors.blue,
                        ),
                      if (nutriments['sugars_100g'] != null)
                        _buildNutritionRow(
                          'Gula',
                          '${nutriments['sugars_100g']} g',
                          Colors.blue.shade300,
                        ),
                      if (nutriments['proteins_100g'] != null)
                        _buildNutritionRow(
                          'Protein',
                          '${nutriments['proteins_100g']} g',
                          Colors.green,
                        ),
                      if (nutriments['salt_100g'] != null)
                        _buildNutritionRow(
                          'Garam',
                          '${nutriments['salt_100g']} g',
                          Colors.purple,
                        ),
                      if (nutriments['sodium_100g'] != null)
                        _buildNutritionRow(
                          'Sodium',
                          '${nutriments['sodium_100g']} g',
                          Colors.purple.shade300,
                        ),
                      if (nutriments['fiber_100g'] != null)
                        _buildNutritionRow(
                          'Serat',
                          '${nutriments['fiber_100g']} g',
                          Colors.brown,
                        ),
                    ],
                  ),

                if (nutritionGrade != 'Tidak tersedia' ||
                    novaGroup != null ||
                    allergens != 'Tidak tersedia' ||
                    traces != 'Tidak tersedia' ||
                    additives.isNotEmpty ||
                    labels != 'Tidak tersedia')
                  _buildSectionCard(
                    title: 'Informasi Tambahan',
                    icon: Icons.info,
                    children: [
                      if (nutritionGrade != 'Tidak tersedia')
                        _buildAdditionalInfoRow(
                          'Nutrition Grade',
                          nutritionGrade.toString().toUpperCase(),
                          Icons.grade,
                          _getNutritionGradeColor(nutritionGrade.toString()),
                        ),
                      if (novaGroup != null) ...[
                        if (nutritionGrade != 'Tidak tersedia')
                          Divider(height: 20),
                        _buildAdditionalInfoRow(
                          'NOVA Group',
                          'Group $novaGroup - ${_getNovaDescription(novaGroup)}',
                          Icons.science,
                          _getNovaGroupColor(novaGroup),
                        ),
                      ],
                      if (allergens != 'Tidak tersedia') ...[
                        if (nutritionGrade != 'Tidak tersedia' ||
                            novaGroup != null)
                          Divider(height: 20),
                        _buildAdditionalInfoRow(
                          'Alergen',
                          _formatTagsList(allergens),
                          Icons.warning_amber,
                          Colors.red,
                        ),
                      ],
                      if (traces != 'Tidak tersedia') ...[
                        Divider(height: 20),
                        _buildAdditionalInfoRow(
                          'Jejak Alergen',
                          _formatTagsList(traces),
                          Icons.error_outline,
                          Colors.orange,
                        ),
                      ],
                      if (additives.isNotEmpty) ...[
                        Divider(height: 20),
                        _buildAdditionalInfoRow(
                          'Bahan Tambahan',
                          '${additives.length} bahan tambahan terdeteksi',
                          Icons.add_circle_outline,
                          Colors.blue,
                        ),
                      ],
                      if (labels != 'Tidak tersedia') ...[
                        Divider(height: 20),
                        _buildAdditionalInfoRow(
                          'Label',
                          _formatTagsList(labels),
                          Icons.label,
                          Colors.green,
                        ),
                      ],
                    ],
                  ),

                if (categories != 'Tidak tersedia')
                  _buildSectionCard(
                    title: 'Kategori',
                    icon: Icons.category,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.split(',').map<Widget>((cat) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFFFF0F5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Color(0xFFFF6B9D).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              cat.trim(),
                              style: TextStyle(
                                color: Color(0xFFFF6B9D),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                if (ingredients != 'Tidak tersedia')
                  _buildSectionCard(
                    title: 'Komposisi',
                    icon: Icons.list_alt,
                    children: [
                      Text(
                        ingredients,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2D2D2D),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),

                if (origins != 'Tidak tersedia' &&
                    origins.toString().isNotEmpty)
                  _buildSectionCard(
                    title: 'Asal Negara Produk',
                    icon: Icons.public,
                    children: [
                      if (origins is List && origins.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: origins.map<Widget>((country) {
                            final cleanCountry = country
                                .toString()
                                .replaceAll('en:', '')
                                .replaceAll('_', ' ')
                                .trim();
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Color(0xFF4CAF50).withOpacity(0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.flag,
                                    size: 14,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    cleanCountry,
                                    style: TextStyle(
                                      color: Color(0xFF2E7D32),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        )
                      else
                        Text(
                          origins
                              .toString()
                              .replaceAll('en:', '')
                              .replaceAll('_', ' ')
                              .trim(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2D2D2D),
                            height: 1.6,
                          ),
                        ),
                    ],
                  ),

                if (_isLoadingDistance)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Menghitung jarak produk...',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_originCountry != null && _distanceKm != null)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Produk ini berasal dari $_originCountry '
                      '(${_distanceKm!.toStringAsFixed(1)} km dari lokasi anda)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                child: Icon(icon, color: Color(0xFFFF6B9D), size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRowWithButton(
    String label,
    String value,
    IconData icon, {
    required IconData icon2,
    required String buttonLabel,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Color(0xFFFF6B9D)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withOpacity(0.3),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon2, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    buttonLabel,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Color(0xFF2D2D2D)),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTagsList(dynamic tags) {
    if (tags is String) {
      return tags
          .replaceAll('en:', '')
          .replaceAll('_', ' ')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .join(', ');
    } else if (tags is List) {
      return tags
          .map((e) => e.toString().replaceAll('en:', '').replaceAll('_', ' '))
          .join(', ');
    }
    return 'Tidak tersedia';
  }

  Color _getNutritionGradeColor(String grade) {
    switch (grade.toLowerCase()) {
      case 'a':
        return Colors.green;
      case 'b':
        return Colors.lightGreen;
      case 'c':
        return Colors.yellow.shade700;
      case 'd':
        return Colors.orange;
      case 'e':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getNovaGroupColor(int group) {
    switch (group) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getNovaDescription(int group) {
    switch (group) {
      case 1:
        return 'Unprocessed/minimally processed';
      case 2:
        return 'Processed culinary ingredients';
      case 3:
        return 'Processed foods';
      case 4:
        return 'Ultra-processed foods';
      default:
        return 'Unknown';
    }
  }
}
