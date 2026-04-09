import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../screens/creator_profile_screen.dart';

class CreatorCard extends StatelessWidget {
  final Map<String, dynamic> creator;

  const CreatorCard({super.key, required this.creator});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
        builder: (context) => CreatorProfileScreen(creatorSlug: creator['slug']?.toString() ?? ''),
          ),
        );
      },
            child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05),
              offset: const Offset(0, 2),
              blurRadius: 10,
            ),
          ],
        ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Builder(
                  builder: (context) {
                    final String imageUrl = creator['image']?.toString() ?? '';
                    if (imageUrl.startsWith('http')) {
                      return CachedNetworkImage(
                                                imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF3F4F6)),
                        errorWidget: (context, url, error) => Container(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF3F4F6),
                          child: Center(child: Icon(Icons.person, size: 50, color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : const Color(0xFF9CA3AF))),
                        ),
                      );
                    } else if (imageUrl.isNotEmpty) {
                      return Image.asset(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFFF3F4F6),
                          child: const Center(child: Icon(Icons.person, size: 50, color: Color(0xFF9CA3AF))),
                        ),
                      );
                    } else {
                                            return Container(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFF3F4F6),
                        child: Center(
                          child: Icon(Icons.person, size: 50, color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : const Color(0xFF9CA3AF)),
                        ),
                      );
                    }
                  },
                ),
                if (creator['topCreator'] == true)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.star, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Top Creator',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (creator['category'] != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        creator['category'],
                        style: const TextStyle(color: Colors.black87, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                if (creator['ugc'] == true)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.video_camera_back, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'UGC',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        creator['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          '${creator['rating']}',
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color),
                        ),
                      ],
                    ),
                  ],
                ),
                if (creator['followers'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${creator['followers']} followers',
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? const Color(0xFF6B7280), fontSize: 11),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  creator['tagline'],
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? const Color(0xFF6B7280), fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  creator['location'],
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? const Color(0xFF6B7280), fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  creator['price'].toString().toLowerCase() == 'contact'
                      ? 'Contact'
                      : '₹${creator['price']}',
                  style: const TextStyle(color: Color(0xFFE63946), fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
