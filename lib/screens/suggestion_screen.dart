import 'package:flutter/material.dart';

class SuggestionScreen extends StatelessWidget {
  const SuggestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7),
      body: CustomScrollView(
        slivers: [
          // Custom App Bar dengan efek melengkung
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFFFF6B9D),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Kesan & Saran \n Mata Kuliah PAM',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF6B9D), Color(0xFFFF6B9D)],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Profile Card dengan desain floating
                _buildProfileCard(),

                const SizedBox(height: 24),

                // Kesan Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildModernCard(
                    icon: Icons.auto_awesome,
                    title: 'Kesan',
                    content:
                        'Selama mengikuti mata kuliah ini, saya mendapatkan banyak pengetahuan baru '
                        'terkait pengembangan aplikasi berbasis mobile menggunakan Flutter. '
                        'Pengetahuan tersebut mulai koneksi database, LBS, hingga penggunaan API. Hal paling menarik yang '
                        'baru saya ketahui dari pembuatan aplikasi menggunakan Flutter ini adalah kita bisa menginstal aplikasi '
                        'yang kita buat tanpa harus hosting atau semacamnya.',
                    gradientColors: const [
                      Color(0xFFFF6B9D),
                      Color(0xFFFF8FAB),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Saran Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildModernCard(
                    icon: Icons.emoji_objects,
                    title: 'Saran',
                    content:
                        'Mungkin lebih baik mahasiswa diberitahu di awal perkuliahan mengenai deadline Tugas Akhir yang cukup '
                        'cepat dibanding Tugas Akhir mata kuliah lain supaya mahasiswa bisa menyicil tugasnya dari awal.',
                    gradientColors: const [
                      Color(0xFFFF6B9D),
                      Color(0xFFFF8FAB),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Footer dengan desain wave
                // _buildFooter(),

                // const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B9D).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar dengan efek glow
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6B9D), Color(0xFFFF8DB3)],
                  ),
                ),
              ),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B9D).withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  radius: 55,
                  backgroundImage: AssetImage('assets/images/profile.jpg'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Nama
          const Text(
            'Lulu Mustafiyah',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 16),

          // Info chips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoChip(Icons.badge, '124230040'),
              const SizedBox(width: 12),
              _buildInfoChip(Icons.school, 'SI-A'),
            ],
          ),

          const SizedBox(height: 12),

          // Divider dengan dot
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6B9D),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 40,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF6B9D).withOpacity(0.3),
                      const Color(0xFFFF6B9D),
                      const Color(0xFFFF6B9D).withOpacity(0.3),
                    ],
                  ),
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6B9D),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE5EB), Color(0xFFFFF5F7)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF6B9D).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFFF6B9D), size: 18),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF2D3436),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard({
    required IconData icon,
    required String title,
    required String content,
    required List<Color> gradientColors,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan gradient dan icon melayang
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 15,
                height: 1.7,
                color: Color(0xFF636E72),
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildFooter() {
  //   return Container(
  //     margin: const EdgeInsets.symmetric(horizontal: 20),
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       gradient: const LinearGradient(
  //         colors: [Color(0xFFFFE5EB), Color(0xFFFFF5F7)],
  //       ),
  //       borderRadius: BorderRadius.circular(20),
  //       border: Border.all(
  //         color: const Color(0xFFFF6B9D).withOpacity(0.3),
  //         width: 2,
  //       ),
  //     ),
  //     child: Column(
  //       children: [
  //         Container(
  //           padding: const EdgeInsets.all(12),
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             shape: BoxShape.circle,
  //             boxShadow: [
  //               BoxShadow(
  //                 color: const Color(0xFFFF6B9D).withOpacity(0.3),
  //                 blurRadius: 10,
  //                 offset: const Offset(0, 4),
  //               ),
  //             ],
  //           ),
  //           child: const Icon(
  //             Icons.favorite,
  //             color: Color(0xFFFF6B9D),
  //             size: 28,
  //           ),
  //         ),
  //         const SizedBox(height: 12),
  //         const Text(
  //           'Pemrograman Aplikasi Mobile',
  //           style: TextStyle(
  //             fontSize: 17,
  //             fontWeight: FontWeight.bold,
  //             color: Color(0xFF2D3436),
  //             letterSpacing: 0.5,
  //           ),
  //         ),
  //         const SizedBox(height: 4),
  //       ],
  //     ),
  //   );
  // }
}
