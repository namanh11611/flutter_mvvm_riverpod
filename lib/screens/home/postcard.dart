import 'package:flutter/material.dart';

class PostCard extends StatelessWidget {
  final String username;
  final String profileImage;
  final String postImage;

  const PostCard({
    super.key,
    required this.username,
    required this.profileImage,
    required this.postImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
            
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(profileImage),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        'Location • 2h ago',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),

             
              const Icon(Icons.more_vert),
            ],
          ),
        ),

     
        ClipRRect(
          borderRadius: BorderRadius.circular(0),
          child: Image.network(
            postImage,
            width: double.infinity,
            height: 300,
            fit: BoxFit.cover,
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Icon(Icons.favorite_border),
              
              Icon(Icons.send),
              
            ],
          ),
        ),

       
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 4),
          child: Text(
            'Just enjoying moments ',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
