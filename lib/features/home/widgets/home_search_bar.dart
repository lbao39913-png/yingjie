import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Material(
        color: YingjieTheme.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: YingjieTheme.textMuted),
                SizedBox(width: 8),
                Text(
                  '搜索影片、演员、导演',
                  style: TextStyle(color: YingjieTheme.textMuted, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
