import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const CustomAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 22.0,
          fontWeight: FontWeight.w600,
          fontFamily: 'Courier New',
          color: Color.fromARGB(255, 117, 151, 167),
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 71, 0, 119),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: ClipOval(
            child: Image.asset(
              'lib/assets/icon/app_icon.png',
              width: 40.0,
              height: 40.0,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}