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
    final primaryColor = Theme.of(context).primaryColor;

    if (searchProv.suggestions.isEmpty && !searchProv.isLoading) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 80, // Right below the nav bar
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        color: Colors.black.withOpacity(0.95),
        child: BackdropFilter(
          filter: ColorFilter.mode(Colors.black.withOpacity(0.1), BlendMode.darken),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white10)),
                ),
                child: Text(
                  'SEARCH RESULTS (${searchProv.suggestions.length})',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: searchProv.isLoading
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                        itemCount: searchProv.suggestions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = searchProv.suggestions[index];
                          final isTv = item.isTv;
                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 800),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(4),
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
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.03),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: CachedNetworkImage(
                                          imageUrl: item.fullPosterPath,
                                          width: 50,
                                          height: 75,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(color: Colors.white10),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title.toUpperCase(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 14,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: primaryColor,
                                                    borderRadius: BorderRadius.circular(2),
                                                  ),
                                                  child: Text(
                                                    isTv ? 'SERIES' : 'MOVIE',
                                                    style: const TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w900,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                if (item.releaseDate.isNotEmpty)
                                                  Text(
                                                    item.releaseDate.split('-')[0],
                                                    style: const TextStyle(fontSize: 12, color: Colors.white24, fontWeight: FontWeight.bold),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 14),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // Close Search Button
              Padding(
                padding: const EdgeInsets.all(30.0),
                child: TextButton(
                  onPressed: () => searchProv.clearSearch(),
                  child: const Text(
                    'CLOSE SEARCH',
                    style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
