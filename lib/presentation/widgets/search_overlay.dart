// lib/presentation/widgets/search_overlay.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../pages/details_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchOverlay extends StatelessWidget {
  const SearchOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final searchProv = context.watch<SearchProvider>();

    if (searchProv.suggestions.isEmpty && !searchProv.isLoading) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 140,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 420),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: searchProv.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: searchProv.suggestions.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, index) {
                    final item = searchProv.suggestions[index];
                    final isTv = item.isTv;
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        searchProv.clearSearch();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailsPage(
                              showId: item.id,
                              isTv: isTv,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            // Poster thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CachedNetworkImage(
                                imageUrl: item.fullPosterPath,
                                width: 38,
                                height: 56,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                    width: 38,
                                    height: 56,
                                    color: Colors.white10),
                                errorWidget: (_, __, ___) => Container(
                                  width: 38,
                                  height: 56,
                                  color: Colors.white10,
                                  child: const Icon(Icons.movie,
                                      size: 20, color: Colors.white38),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Title + meta
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isTv
                                              ? Colors.blue.withOpacity(0.2)
                                              : const Color(0xFFE50914)
                                                  .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                            color: isTv
                                                ? Colors.blue.withOpacity(0.4)
                                                : const Color(0xFFE50914)
                                                    .withOpacity(0.4),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Text(
                                          isTv ? 'TV' : 'Movie',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isTv
                                                ? Colors.lightBlueAccent
                                                : const Color(0xFFE50914),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      if (item.releaseDate.isNotEmpty)
                                        Text(
                                          item.releaseDate.length >= 4
                                              ? item.releaseDate
                                                  .substring(0, 4)
                                              : item.releaseDate,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white38),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: Colors.white24, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
