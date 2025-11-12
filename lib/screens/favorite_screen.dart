import 'package:flutter/material.dart';
import 'dart:convert';
import '../database/db_helper.dart';
import '../services/api_service.dart';
import 'detail_screen.dart';

class FavoriteScreen extends StatefulWidget {
  @override
  _FavoriteScreenState createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  List<Map<String, Object?>> _fav = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await DBHelper.instance.queryAll('favorites');
    setState(() {
      _fav = data;
      _isLoading = false;
    });
  }

  Future<void> _deleteFavorite(int index) async {
    final item = _fav[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Hapus Favorit'),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${item['product_name']}" dari favorit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await DBHelper.instance.deleteWhere('favorites', 'id = ?', [
                item['id'],
              ]);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Dihapus dari favorit'),
                  backgroundColor: Color(0xFFFF6B9D),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
              _load();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _openDetail(Map<String, Object?> item) async {
    final barcode = item['barcode']?.toString();

    if (barcode == null || barcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barcode tidak valid'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFFFF6B9D)),
              SizedBox(height: 16),
              Text('Memuat detail produk...'),
            ],
          ),
        ),
      ),
    );

    try {
      final productData = await ApiService.getProductByBarcode(barcode);
      Navigator.pop(context);

      if (productData != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailScreen(product: productData)),
        ).then((_) => _load());
      } else {
        _openDetailWithStoredData(item);
      }
    } catch (e) {
      Navigator.pop(context);
      print('Error fetching product: $e');
      _openDetailWithStoredData(item);
    }
  }

  void _openDetailWithStoredData(Map<String, Object?> item) {
    try {
      final dataString = item['data']?.toString();
      Map<String, dynamic> productData;

      if (dataString != null && dataString.isNotEmpty) {
        try {
          productData = json.decode(dataString);
        } catch (_) {
          productData = {
            'code': item['barcode'],
            'product_name': item['product_name'],
          };
        }
      } else {
        productData = {
          'code': item['barcode'],
          'product_name': item['product_name'],
        };
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(product: productData)),
      ).then((_) => _load());
    } catch (e) {
      print('Error opening detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka detail produk'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF0F5), Colors.white],
          stops: [0.0, 0.3],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Favorit Saya',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_fav.length} produk tersimpan',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (_fav.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF6B9D), Color(0xFFFF8FAB)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFF6B9D).withOpacity(0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF6B9D),
                      ),
                    )
                  : _fav.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: Color(0xFFFF6B9D),
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _fav.length,
                        itemBuilder: (ctx, i) {
                          final item = _fav[i];
                          final name =
                              item['product_name']?.toString() ?? 'Unknown';
                          final barcode = item['barcode']?.toString() ?? 'N/A';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildFavoriteCard(name, barcode, i, item),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Color(0xFFFFF0F5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.favorite_border,
              size: 70,
              color: Color(0xFFFF6B9D).withOpacity(0.5),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Belum ada favorit',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Produk yang Anda tandai sebagai favorit\nakan muncul di sini',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF6B9D), Color(0xFFFF8FAB)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFF6B9D).withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Jelajahi Produk',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(
    String name,
    String barcode,
    int index,
    Map<String, Object?> item,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openDetail(item),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Gambar produk
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Color(0xFFFF6B9D),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        item['image_url'] != null &&
                            item['image_url']!.toString().isNotEmpty
                        ? Image.network(
                            item['image_url']!.toString(),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.fastfood,
                                color: Colors.white,
                                size: 28,
                              );
                            },
                          )
                        : item['image_front_small_url'] != null &&
                              item['image_front_small_url']!
                                  .toString()
                                  .isNotEmpty
                        ? Image.network(
                            item['image_front_small_url']!.toString(),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.fastfood,
                                color: Colors.white,
                                size: 28,
                              );
                            },
                          )
                        : Icon(Icons.fastfood, color: Colors.white, size: 28),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D2D2D),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.qr_code,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          SizedBox(width: 4),
                          Text(
                            barcode,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFFFF0F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red[400],
                          size: 22,
                        ),
                        onPressed: () => _deleteFavorite(index),
                        padding: EdgeInsets.all(8),
                        constraints: BoxConstraints(),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
