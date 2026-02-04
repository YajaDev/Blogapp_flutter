import 'package:flutter/material.dart';

class Logo extends StatelessWidget {
  const Logo({super.key});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28.0),
        children: const [
          TextSpan(
            text: 'Q',
            style: TextStyle(color: Color.fromARGB(255, 27, 84, 228)),
          ),
          TextSpan(text: 'uickBlog'),
        ],
      ),
    );
  }
}
