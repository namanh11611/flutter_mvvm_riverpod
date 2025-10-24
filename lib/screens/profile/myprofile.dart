import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class MyProfile extends StatelessWidget {
  const MyProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> imageUrls = [
      'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
      'https://images.unsplash.com/photo-1495567720989-cebdbdd97913',
      'https://images.unsplash.com/photo-1503342217505-b0a15ec3261c',
      'https://images.unsplash.com/photo-1504196606672-aef5c9cefc92',
      'https://images.unsplash.com/photo-1481349518771-20055b2a7b24',
      'https://images.unsplash.com/photo-1501594907352-04cda38ebc29',
      'https://images.unsplash.com/photo-1503342217505-b0a15ec3261c',
      'https://images.unsplash.com/photo-1504196606672-aef5c9cefc92',
      'https://images.unsplash.com/photo-1481349518771-20055b2a7b24',
      'https://images.unsplash.com/photo-1501594907352-04cda38ebc29',
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SvgPicture.asset(
                    'assets/images/authentick_logo.svg',
                    width: 40,
                    height: 30,
                    fit: BoxFit.cover,
                  ),
                  const Icon(Icons.settings_outlined, size: 28),
                ],
              ),
            ),

            const SizedBox(height: 20),

        
            Center(
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF3620B3),
                            width: 3,
                          ),
                          image: const DecorationImage(
                           
                           image: AssetImage('assets/images/user1.jpg'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                               color: Color(0xFF3620B3),
                              shape: BoxShape.rectangle,
                              
                            
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Alok Mishra',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Text(
                    '@alokmishra',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: MasonryGridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                  ),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                 
                    final double height = (index % 3 == 0)
                        ? 250
                        : (index % 3 == 1)
                            ? 180
                            : 220;

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: height,
                        color: Colors.grey[200],
                        child: Image.network(
                          imageUrls[index],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Icon(Icons.error)),
                        ),
                      ),
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
}
