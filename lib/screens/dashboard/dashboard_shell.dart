import 'package:flutter/material.dart';

class Dashboard extends StatelessWidget {
  final Widget child;

  const Dashboard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(children: [Expanded(child: child)]);
  }
}
