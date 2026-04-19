// lib/presentation/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/search_overlay.dart';
import '../widgets/glass_container.dart';
import 'details_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:shimmer/shimmer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final homeProv = context.watch<HomeProvider>();

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(context),
                    const SizedBox(height: 30),
                    _buildSearchBar(context),
                    const SizedBox(height: 40),

                    if (homeProv.isLoading)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShimmerHero(),
                          const SizedBox(height: 40),
                          _buildShimmerList(),
                          const SizedBox(height: 40),
                          _buildShimmerList(),
                        ],
                      )
                    else ...[
                      // Hero Featured Section
                      if (homeProv.featuredItem != null)
                        _buildHeroSection(context, homeProv.featuredItem!),

                      const SizedBox(height: 40),
                      _buildSectionTitle('Trending Movies'),
                      const SizedBox(height: 15),
                      _buildHorizontalList(context, homeProv.trendingMovies, isTv: false),

                      const SizedBox(height: 40),
                      _buildSectionTitle('Top Rated TV Shows'),
                      const SizedBox(height: 15),
                      _buildHorizontalList(context, homeProv.trendingTV, isTv: true),
                      const SizedBox(height: 50),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Smart Search Suggestions Overlay
          const SearchOverlay(),
        ],
      ),
    );
  }

  Widget _buildShimmerHero() {
    return Shimmer.fromColors(
      baseColor: Colors.white10,
      highlightColor: Colors.white24,
      child: Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: Colors.white10,
          highlightColor: Colors.white24,
          child: Container(width: 150, height: 20, color: Colors.white),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.only(right: 15),
              child: Shimmer.fromColors(
                baseColor: Colors.white10,
                highlightColor: Colors.white24,
                child: Container(
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5),
    );
  }

  Widget _buildHorizontalList(BuildContext context, List items, {required bool isTv}) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => DetailsPage(showId: item.id, isTv: isTv))
            ),
            child: Container(
              width: 130,
              margin: const EdgeInsets.only(right: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: item.fullPosterPath,
                        fit: BoxFit.cover,
                        width: 130,
                        placeholder: (context, url) => Container(color: Colors.white10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'LE MOVIE',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
            letterSpacing: 2,
          ),
        ),
        const CircleAvatar(
          backgroundColor: Colors.white12,
          child: Icon(Icons.person, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(30),
      child: TextField(
        onChanged: (val) => context.read<SearchProvider>().onSearchChanged(val),
        decoration: const InputDecoration(
          hintText: 'Search for movies or shows...',
          prefixIcon: Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, dynamic item) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(showId: item.id, isTv: false))),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(item.fullBackdropPath),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TRENDING RECOMMENDATION', style: TextStyle(color: Colors.white70, letterSpacing: 1.5, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(item.title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914)),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(showId: item.id, isTv: false)));
                      },
                      label: const Text('WATCH NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 15),
                    const Icon(Icons.info_outline, color: Colors.white),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
