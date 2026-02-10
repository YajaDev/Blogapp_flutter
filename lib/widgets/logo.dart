import 'package:flutter/material.dart';

class Logo extends StatelessWidget {
  const Logo({super.key});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
        children: [
          TextSpan(
            text: 'Q',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          const TextSpan(text: 'uickBlog'),
        ],
      ),
    );
  }
}
