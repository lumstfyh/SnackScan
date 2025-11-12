class SnackModel {
  final String? barcode;
  final String? productName;
  final String? imageUrl;
  final Map<String, dynamic> raw;
  final int? createdTime; // waktu dibuat (UTC, detik)
  final int? lastModifiedTime; // waktu terakhir diubah (UTC, detik)
  final double avgPriceUSD;
  final String? categoryTag;

  // Fitur LBS (asal dan jarak produk)
  final String? originCountry;
  final double? distanceKm;

  SnackModel({
    this.barcode,
    this.productName,
    this.imageUrl,
    required this.raw,
    this.createdTime,
    this.lastModifiedTime,
    required this.avgPriceUSD,
    this.categoryTag,
    this.originCountry,
    this.distanceKm,
  });

  factory SnackModel.fromJson(Map<String, dynamic> json) {
    // Barcode
    final code = json['code'] ?? json['barcode'];

    // Nama produk
    final name =
        json['product_name'] ??
        json['product_name_en'] ??
        json['generic_name'] ??
        json['brands'];

    // URL gambar
    final img =
        json['image_url'] ?? json['image_small_url'] ?? json['image_front_url'];

    // Kategori
    final categoriesTags = json['categories_tags'];
    String category = 'unknown';
    if (categoriesTags is List && categoriesTags.isNotEmpty) {
      category = (categoriesTags[0] as String).toString();
    } else if (json['categories'] != null &&
        json['categories'].toString().isNotEmpty) {
      category = json['categories'].toString();
    }

    // Estimasi harga berdasarkan kategori
    double dummyPriceUSD = 2.0;
    final catLower = category.toLowerCase();
    final nameLower = (name ?? '').toLowerCase();

    if (catLower.contains('chocolate') || nameLower.contains('chocolate')) {
      dummyPriceUSD = 2.5;
    } else if (catLower.contains('biscuit') ||
        catLower.contains('cookie') ||
        nameLower.contains('biscuit') ||
        nameLower.contains('cookie')) {
      dummyPriceUSD = 1.5;
    } else if (catLower.contains('drink') ||
        catLower.contains('beverage') ||
        nameLower.contains('juice') ||
        nameLower.contains('soda')) {
      dummyPriceUSD = 1.0;
    } else if (catLower.contains('cereal') || nameLower.contains('cereal')) {
      dummyPriceUSD = 3.0;
    } else if (catLower.contains('candy') ||
        catLower.contains('sweet') ||
        nameLower.contains('candy')) {
      dummyPriceUSD = 1.8;
    } else if (catLower.contains('chips') ||
        catLower.contains('crisp') ||
        nameLower.contains('chips')) {
      dummyPriceUSD = 2.2;
    } else if (catLower.contains('snack') || nameLower.contains('snack')) {
      dummyPriceUSD = 2.0;
    }

    // Variasi harga acak (±20%)
    final random = (code?.hashCode ?? 0) % 100;
    final variance = 0.8 + (random / 100.0 * 0.4);
    dummyPriceUSD = dummyPriceUSD * variance;

    // Pembulatan 2 desimal
    dummyPriceUSD = (dummyPriceUSD * 100).round() / 100;

    // Batas harga
    if (dummyPriceUSD < 0.5) dummyPriceUSD = 0.5;
    if (dummyPriceUSD > 15.0) dummyPriceUSD = 15.0;

    // Parsing waktu
    int? created;
    int? lastModified;

    try {
      final createdRaw = json['created_t'];
      if (createdRaw != null) {
        if (createdRaw is int) {
          created = createdRaw;
        } else if (createdRaw is String) {
          created = int.tryParse(createdRaw);
        } else if (createdRaw is double) {
          created = createdRaw.toInt();
        }
      }

      final lastModifiedRaw = json['last_modified_t'];
      if (lastModifiedRaw != null) {
        if (lastModifiedRaw is int) {
          lastModified = lastModifiedRaw;
        } else if (lastModifiedRaw is String) {
          lastModified = int.tryParse(lastModifiedRaw);
        } else if (lastModifiedRaw is double) {
          lastModified = lastModifiedRaw.toInt();
        }
      }
    } catch (e) {
      print('⚠️ [SnackModel] Error parsing timestamps: $e');
    }

    // Validasi waktu
    if (created != null && (created < 946684800 || created > 2147483647)) {
      print('⚠️ [SnackModel] Invalid created_t: $created');
      created = null;
    }

    if (lastModified != null &&
        (lastModified < 946684800 || lastModified > 2147483647)) {
      print('⚠️ [SnackModel] Invalid last_modified_t: $lastModified');
      lastModified = null;
    }

    // Data negara asal
    String? origin;
    if (json['manufacturing_places'] != null &&
        json['manufacturing_places'].toString().isNotEmpty) {
      origin = json['manufacturing_places'];
    } else if (json['countries_tags'] != null &&
        json['countries_tags'] is List &&
        (json['countries_tags'] as List).isNotEmpty) {
      origin = (json['countries_tags'][0] as String)
          .replaceAll('en:', '')
          .toUpperCase();
    } else if (json['origins'] != null &&
        json['origins'].toString().isNotEmpty) {
      origin = json['origins'];
    } else {
      origin = 'Unknown';
    }

    return SnackModel(
      barcode: code?.toString(),
      productName: name?.toString(),
      imageUrl: img?.toString(),
      raw: json,
      createdTime: created,
      lastModifiedTime: lastModified,
      avgPriceUSD: dummyPriceUSD,
      categoryTag: category,
      originCountry: origin,
      distanceKm: null,
    );
  }

  // Konversi ke JSON
  Map<String, dynamic> toJson() {
    return {
      'code': barcode,
      'barcode': barcode,
      'product_name': productName,
      'image_url': imageUrl,
      'created_t': createdTime,
      'last_modified_t': lastModifiedTime,
      'avg_price_usd': avgPriceUSD,
      'categories_tags': categoryTag != null ? [categoryTag] : [],
      'origin_country': originCountry,
      'distance_km': distanceKm,
      ...raw,
    };
  }

  // Format waktu dibuat
  String get createdTimeFormatted {
    if (createdTime == null) return 'Tidak tersedia';
    final dt = DateTime.fromMillisecondsSinceEpoch(
      createdTime! * 1000,
      isUtc: true,
    ).toLocal();
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // Format waktu terakhir diubah
  String get lastModifiedTimeFormatted {
    if (lastModifiedTime == null) return 'Tidak tersedia';
    final dt = DateTime.fromMillisecondsSinceEpoch(
      lastModifiedTime! * 1000,
      isUtc: true,
    ).toLocal();
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // Format harga
  String get formattedPrice => '\$ ${avgPriceUSD.toStringAsFixed(2)} USD';

  // Format kategori singkat
  String get categoryShort {
    if (categoryTag == null) return 'Unknown';
    final cat = categoryTag!;
    if (cat.contains(':')) {
      return cat.split(':').last.replaceAll('-', ' ').trim();
    }
    return cat.replaceAll('-', ' ').trim();
  }

  // Cek validitas waktu
  bool get hasValidTimestamps =>
      createdTime != null && lastModifiedTime != null;

  // Copy data dengan perubahan sebagian
  SnackModel copyWith({
    String? barcode,
    String? productName,
    String? imageUrl,
    Map<String, dynamic>? raw,
    int? createdTime,
    int? lastModifiedTime,
    double? avgPriceUSD,
    String? categoryTag,
    String? originCountry,
    double? distanceKm,
  }) {
    return SnackModel(
      barcode: barcode ?? this.barcode,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      raw: raw ?? this.raw,
      createdTime: createdTime ?? this.createdTime,
      lastModifiedTime: lastModifiedTime ?? this.lastModifiedTime,
      avgPriceUSD: avgPriceUSD ?? this.avgPriceUSD,
      categoryTag: categoryTag ?? this.categoryTag,
      originCountry: originCountry ?? this.originCountry,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }

  @override
  String toString() {
    return 'SnackModel(barcode: $barcode, name: $productName, price: $formattedPrice, category: $categoryShort, origin: $originCountry, distance: ${distanceKm?.toStringAsFixed(2)} km)';
  }
}
