// lib/presentation/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/search_overlay.dart';
import 'details_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedLanguage = 'EN';
  int _activeNavIndex = 0;
  bool _isSearchExpanded = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeProv = context.watch<HomeProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F0F0F), Color(0xFF141414)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Premium Top Nav Bar
                _buildTopNavigationBar(isDesktop),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 40.0 : 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),

                              // Mobile Search Bar (Only shown on small screens if not in navbar)
                              if (!isDesktop) ...[
                                _buildMobileSearchBar(),
                                const SizedBox(height: 20),
                              ],

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
                                  _buildHeroSection(
                                      context, homeProv.featuredItem!, isDesktop),

                                const SizedBox(height: 40),
                                _buildSectionTitle('Trending Movies'),
                                const SizedBox(height: 15),
                                _buildHorizontalList(
                                    context, homeProv.trendingMovies,
                                    isTv: false, isDesktop: isDesktop),

                                const SizedBox(height: 40),
                                _buildSectionTitle('Top Rated TV Shows'),
                                const SizedBox(height: 15),
                                _buildHorizontalList(
                                    context, homeProv.trendingTV,
                                    isTv: true, isDesktop: isDesktop),
                                const SizedBox(height: 50),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Smart Search Suggestions Overlay
          const SearchOverlay(),
        ],
      ),
    );
  }

  // ─── Top Navigation Bar ──────────────────────────────────────────────────
  Widget _buildTopNavigationBar(bool isDesktop) {
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40.0 : 20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F).withOpacity(0.95),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Row(
            children: [
              // Logo
              Text(
                'LE MOVIE',
                style: TextStyle(
                  fontSize: isDesktop ? 24 : 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFE50914),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 40),

              // Desktop Links
              if (isDesktop) ...[
                _navLink('Home', 0),
                _navLink('Movies', 1),
                _navLink('Series', 2),
                _navLink('Genres', 3),
              ],

              const Spacer(),

              // Desktop Search Bar
              if (isDesktop)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _isSearchExpanded ? 250 : 40,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _isSearchExpanded ? Colors.white12 : Colors.transparent,
                    border: Border.all(
                        color: _isSearchExpanded ? Colors.white24 : Colors.transparent),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          setState(() {
                            _isSearchExpanded = !_isSearchExpanded;
                            if (_isSearchExpanded) {
                              _searchFocus.requestFocus();
                            } else {
                              _searchCtrl.clear();
                              context.read<SearchProvider>().clearSearch();
                            }
                          });
                        },
                        child: const SizedBox(
                          width: 38,
                          height: 38,
                          child: Icon(Icons.search, color: Colors.white, size: 20),
                        ),
                      ),
                      if (_isSearchExpanded)
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            focusNode: _searchFocus,
                            onChanged: (val) =>
                                context.read<SearchProvider>().onSearchChanged(val),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Titles, genres...',
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.only(right: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              if (isDesktop) const SizedBox(width: 20),

              // Language Selector
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: const Color(0xFF1E1E1E),
                    value: _selectedLanguage,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => _selectedLanguage = newValue);
                      }
                    },
                    items: <String>['EN', 'HI', 'ES', 'FR']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Profile Avatar
              const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white12,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navLink(String title, int index) {
    final bool isActive = _activeNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeNavIndex = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        onChanged: (val) => context.read<SearchProvider>().onSearchChanged(val),
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Search movies, TV shows...',
          hintStyle: TextStyle(color: Colors.white54),
          prefixIcon: Icon(Icons.search, color: Colors.white54),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, dynamic item, bool isDesktop) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => DetailsPage(showId: item.id, isTv: false))),
      child: Container(
        height: isDesktop ? 450 : 300,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: NetworkImage(item.fullBackdropPath),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Colors.black87, Colors.black45, Colors.transparent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          padding: EdgeInsets.all(isDesktop ? 40 : 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text('Trending #1',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: isDesktop ? 600 : double.infinity,
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: isDesktop ? 40 : 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow, color: Colors.blue),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 24 : 16,
                          vertical: isDesktop ? 18 : 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  DetailsPage(showId: item.id, isTv: false)));
                    },
                    label: Text(
                      'Play Now',
                      style: TextStyle(
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: isDesktop ? 16 : 14),
                    ),
                  ),
                  const SizedBox(width: 15),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 24 : 16,
                          vertical: isDesktop ? 18 : 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  DetailsPage(showId: item.id, isTv: false)));
                    },
                    label: Text(
                      'More Info',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isDesktop ? 16 : 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildHorizontalList(BuildContext context, List items,
      {required bool isTv, required bool isDesktop}) {
    final double cardWidth = isDesktop ? 150 : 120;
    final double cardHeight = isDesktop ? 225 : 180;

    return SizedBox(
      height: cardHeight + 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => DetailsPage(showId: item.id, isTv: isTv))),
            child: Container(
              width: cardWidth,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: cardWidth,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white10,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: item.fullPosterPath,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.white10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        item.releaseDate.length >= 4
                            ? item.releaseDate.substring(0, 4)
                            : '',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white54),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.star, color: Colors.amber, size: 10),
                      const SizedBox(width: 2),
                      Text(
                        item.voteAverage.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.amber,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerHero() => Shimmer.fromColors(
        baseColor: Colors.white10,
        highlightColor: Colors.white24,
        child: Container(
          height: 350,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );

  Widget _buildShimmerList() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.white10,
            highlightColor: Colors.white24,
            child: Container(width: 150, height: 20, color: Colors.white),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 8,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Shimmer.fromColors(
                  baseColor: Colors.white10,
                  highlightColor: Colors.white24,
                  child: Container(
                    width: 130,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}
