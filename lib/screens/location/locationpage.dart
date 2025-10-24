import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Locationpage extends StatelessWidget {
  const Locationpage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
   
          SizedBox.expand(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/images/onboarding_discovery_map.png',
                fit: BoxFit.fill,
              ),
            ),
          ),

          
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: SvgPicture.asset(
                  'assets/images/authentick_logo.svg',
                  width: 150,
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0), 
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                 
                   Text(
                    '...Coming soon...',
                    style: TextStyle(
                      fontSize: 28, // adjust for screen size
                      fontWeight: FontWeight.bold,
                    
                      height: 1.3, // line spacing
                     
                    ),
                  
                                     ),
                  SizedBox(height: 25,),
                  Text(
                    'See unfiltered moments on a real-time map, from your city to cities you’ve never seen.',
                    style: TextStyle(
                      fontSize: 20, // adjust for screen size
                      fontWeight: FontWeight.bold,
                    
                      height: 1.3, // line spacing
                     
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
