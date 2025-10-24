import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvvm_riverpod/screens/friends/friendpage.dart';
// import 'package:flutter_mvvm_riverpod/screens/home/homepage.dart';
import 'package:flutter_mvvm_riverpod/screens/home/postpage.dart';
import 'package:flutter_mvvm_riverpod/screens/location/locationpage.dart';
import 'package:flutter_mvvm_riverpod/screens/post/postpage.dart';
// import 'package:flutter_mvvm_riverpod/screens/post/postpage.dart';
import 'package:flutter_mvvm_riverpod/screens/profile/myprofile.dart';


class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int currentIndex = 0;

  final List<Widget> pages = [
    const MyHome(),
    const Locationpage(),
    const Postpage(),
    const Friendpage(),
    const MyProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),

      bottomNavigationBar: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
         
          Container(
            height: 70,
            decoration: const BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              selectedItemColor: const Color(0xFF3620B3),
              unselectedItemColor: Colors.grey,
              onTap: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
                BottomNavigationBarItem(icon: Icon(Icons.location_on), label: ''),
                BottomNavigationBarItem(icon: SizedBox.shrink(), label: ''), 
                BottomNavigationBarItem(icon: Icon(Icons.people), label: ''),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
              ],
            ),
          ),

          
          Positioned(
            top: -25, 
            child: GestureDetector(
              onTap: () {
                setState(() {
                  currentIndex = 2;
                });
              },
              child: Container(
                height: 65,
                width: 65,
                decoration: BoxDecoration(
                  color: const Color(0xFF3620B3),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.plus,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
