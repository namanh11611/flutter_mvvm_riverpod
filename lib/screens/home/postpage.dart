import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/screens/home/postcard.dart';
import 'package:flutter_mvvm_riverpod/screens/home/postmodel.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MyHome extends StatefulWidget {
  const MyHome({super.key});

  @override
  State<MyHome> createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  String selectedTab = 'Friends';

  // Dummy data for posts 
  final List<PostModel> posts = [
    PostModel(
      username: 'john_doe',
      profileImage: 'https://randomuser.me/api/portraits/men/32.jpg',
      postImage: 'https://picsum.photos/id/237/400/300',
    ),
    PostModel(
      username: 'emma_watson',
      profileImage: 'https://randomuser.me/api/portraits/women/44.jpg',
      postImage: 'https://picsum.photos/id/238/400/300',
    ),
    PostModel(
      username: 'alex_smith',
      profileImage: 'https://randomuser.me/api/portraits/men/65.jpg',
      postImage: 'https://picsum.photos/id/239/400/300',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 16),
              child: SvgPicture.asset(
                'assets/images/authentick_logo.svg',
                width: 40,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 10),

          
            Row(
              children: [
                const SizedBox(width: 10),
                _buildTab(icon: Icons.people, label: 'Friends'),
                _buildTab(label: 'Following'),
                _buildTab(label: 'All'),
              ],
            ),

            

            Expanded(
              child: ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return PostCard(
                    username: post.username,
                    profileImage: post.profileImage,
                    postImage: post.postImage,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab({IconData? icon, required String label}) {
    final bool isSelected = selectedTab == label;

    return InkWell(
      onTap: () {
        setState(() {
          selectedTab = label;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            if (icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Icon(
                  icon,
                  color: isSelected ? const Color(0xFF3620B3) : Colors.black54,
                ),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF3620B3) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
