// lib/presentation/widgets/search_overlay.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import 'glass_container.dart';
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
      top: 80,
      left: 20,
      right: 20,
      child: GlassContainer(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 400),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: searchProv.suggestions.length,
            itemBuilder: (context, index) {
              final item = searchProv.suggestions[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: CachedNetworkImage(
                    imageUrl: item.fullPosterPath,
                    width: 40,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[900]),
                    errorWidget: (context, url, error) => const Icon(Icons.movie),
                  ),
                ),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(item.releaseDate),
                onTap: () {
                  // Handle selection - will implement navigation to details later
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
