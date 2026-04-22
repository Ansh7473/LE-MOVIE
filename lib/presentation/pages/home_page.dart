// lib/presentation/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../providers/home_provider.dart';
import '../providers/language_provider.dart';
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
  int _activeNavIndex = 0; // 0=Home, 1=Movies, 2=Series, 3=Genres
  bool _isSearchExpanded = false;
  
  // Custom states for view 3 (Genres)
  bool _isTvGenre = false;
  int? _selectedGenreId;

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    setState(() {
      _activeNavIndex = index;
      if (index == 3) {
        _selectedGenreId = null; // reset filter
      }
    });

    final homeProv = context.read<HomeProvider>();
    if (index == 1) {
      homeProv.loadMovies();
    } else if (index == 2) {
      homeProv.loadSeries();
    } else if (index == 3) {
      homeProv.loadGenres();
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeProv = context.watch<HomeProvider>();
    final langProv = context.watch<LanguageProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Edge-to-Edge Responsive Scaling!
    // Simply use 5% padding or static 60px on massive screens so content always expands.
    final horizontalPadding = screenWidth > 1200 
        ? 60.0 
        : screenWidth > 800 
            ? 40.0 
            : 20.0;
                
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

          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                _buildTopNavigationBar(isDesktop, horizontalPadding, langProv),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          if (!isDesktop) ...[
                            _buildMobileSearchBar(),
                            const SizedBox(height: 20),
                          ],

                          _buildActiveView(homeProv, isDesktop),

                          const SizedBox(height: 80),
                          _buildMegaFooter(isDesktop),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SearchOverlay(),
        ],
      ),
    );
  }

  // ─── Routing System ────────────────────────────────────────────────────────
  Widget _buildActiveView(HomeProvider homeProv, bool isDesktop) {
    if (_activeNavIndex == 0) {
      return _buildHomeView(homeProv, isDesktop);
    } else if (_activeNavIndex == 1) {
      return _buildMoviesView(homeProv, isDesktop);
    } else if (_activeNavIndex == 2) {
      return _buildSeriesView(homeProv, isDesktop);
    } else if (_activeNavIndex == 3) {
      return _buildGenresView(homeProv, isDesktop);
    }
    return const SizedBox.shrink();
  }

  // ─── View 0: Home ──────────────────────────────────────────────────────────
  Widget _buildHomeView(HomeProvider homeProv, bool isDesktop) {
    if (homeProv.isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            _buildShimmerHero(isDesktop),
            const SizedBox(height: 40),
            _buildShimmerList(isDesktop),
            const SizedBox(height: 40),
            _buildShimmerList(isDesktop),
            const SizedBox(height: 40),
            _buildShimmerList(isDesktop),
            const SizedBox(height: 40),
            _buildShimmerList(isDesktop),
            const SizedBox(height: 40),
            _buildShimmerList(isDesktop),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (homeProv.trendingTV.isNotEmpty)
          HeroCarousel(items: homeProv.trendingTV.take(5).toList(), isDesktop: isDesktop, isTv: true),
        const SizedBox(height: 40),
        _buildSectionTitle('Trending TV Shows'),
        const SizedBox(height: 15),
        _buildHorizontalList(context, homeProv.trendingTV,
            isTv: true, isDesktop: isDesktop),
        const SizedBox(height: 40),
        _buildSectionTitle('Trending Movies'),
        const SizedBox(height: 15),
        _buildHorizontalList(context, homeProv.trendingMovies,
            isTv: false, isDesktop: isDesktop),
        const SizedBox(height: 40),
        _buildSectionTitle('Upcoming Movies'),
        const SizedBox(height: 15),
        _buildHorizontalList(context, homeProv.upcomingMovies,
            isTv: false, isDesktop: isDesktop),
        const SizedBox(height: 40),
        _buildSectionTitle('Now Playing'),
        const SizedBox(height: 15),
        _buildHorizontalList(context, homeProv.nowPlayingMovies,
            isTv: false, isDesktop: isDesktop),
        const SizedBox(height: 40),
        _buildSectionTitle('Top Rated Movies'),
        const SizedBox(height: 15),
        _buildHorizontalList(context, homeProv.topRatedMovies,
            isTv: false, isDesktop: isDesktop),
        const SizedBox(height: 40),
        _buildSectionTitle('Popular TV Shows'),
        const SizedBox(height: 15),
        _buildHorizontalList(context, homeProv.popularTV,
            isTv: true, isDesktop: isDesktop),
      ],
    );
  }

  // ─── View 1: Movies (Grid) ──────────────────────────────────────────────────
  Widget _buildMoviesView(HomeProvider homeProv, bool isDesktop) {
    if (homeProv.isLoadingCategory) return _buildShimmerGrid();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Popular Movies', subtitle: 'The most watched films this week.'),
        const SizedBox(height: 20),
        _buildResponsiveGrid(homeProv.popularMovies, isTv: false),
      ],
    );
  }

  // ─── View 2: Series (Grid) ──────────────────────────────────────────────────
  Widget _buildSeriesView(HomeProvider homeProv, bool isDesktop) {
    if (homeProv.isLoadingCategory) return _buildShimmerGrid();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Popular TV Series', subtitle: 'Binge-worthy shows trending right now.'),
        const SizedBox(height: 20),
        _buildResponsiveGrid(homeProv.popularTV, isTv: true),
      ],
    );
  }

  // ─── View 3: Genres ─────────────────────────────────────────────────────────
  Widget _buildGenresView(HomeProvider homeProv, bool isDesktop) {
    if (homeProv.isLoadingCategory && homeProv.movieGenres.isEmpty) {
      return const SizedBox(height: 400, child: Center(child: CircularProgressIndicator()));
    }

    final activeGenres = _isTvGenre ? homeProv.tvGenres : homeProv.movieGenres;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Browse by Genre', subtitle: 'Filter thousands of titles by category.'),
        const SizedBox(height: 20),
        
        // Type Switcher
        Row(
          children: [
            _genreFilterTab('Movies', !_isTvGenre, () {
              setState(() { _isTvGenre = false; _selectedGenreId = null; });
            }),
            const SizedBox(width: 12),
            _genreFilterTab('TV Series', _isTvGenre, () {
              setState(() { _isTvGenre = true; _selectedGenreId = null; });
            }),
          ],
        ),
        const SizedBox(height: 20),

        // Genre Chips
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: activeGenres.map((g) {
            final isSelected = _selectedGenreId == g['id'];
            return InkWell(
              onTap: () {
                setState(() => _selectedGenreId = g['id']);
                homeProv.selectGenre(g['id'], _isTvGenre);
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE50914) : Colors.white12,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? const Color(0xFFE50914) : Colors.white24),
                ),
                child: Text(
                  g['name'],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 40),
        
        // Results
        if (_selectedGenreId != null) ...[
          if (homeProv.isLoadingCategory)
            _buildShimmerGrid()
          else if (homeProv.genreResults.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text('No results found.', style: TextStyle(color: Colors.white54)),
            ))
          else
            _buildResponsiveGrid(homeProv.genreResults, isTv: _isTvGenre),
        ],
      ],
    );
  }

  Widget _genreFilterTab(String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isActive ? Colors.white : Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ─── Responsive Grid ────────────────────────────────────────────────────────
  Widget _buildResponsiveGrid(List items, {required bool isTv}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 24,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(showId: item.id, isTv: isTv))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white10,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: item.fullPosterPath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(color: Colors.white10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    item.voteAverage.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  // ─── Top Navigation Bar ──────────────────────────────────────────────────
  Widget _buildTopNavigationBar(bool isDesktop, double hPadding, LanguageProvider langProv) {
    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: hPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F).withOpacity(0.95),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Text(
            'LE MOVIE',
            style: TextStyle(
              fontSize: isDesktop ? 24 : 20,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFE50914),
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(width: isDesktop ? 40 : 15),

          if (isDesktop) ...[
            _navLink('Home', 0),
            _navLink('Movies', 1),
            _navLink('Series', 2),
            _navLink('Genres', 3),
          ],

          const Spacer(),

          if (isDesktop) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isSearchExpanded ? 250 : 40,
              height: 36,
              decoration: BoxDecoration(
                color: _isSearchExpanded ? Colors.white12 : Colors.transparent,
                border: Border.all(color: _isSearchExpanded ? Colors.white24 : Colors.transparent),
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
                        onChanged: (val) => context.read<SearchProvider>().onSearchChanged(val),
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
            const SizedBox(width: 20),
          ],

          // Language Selector
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: const Color(0xFF1E1E1E),
                value: langProv.currentLanguageCode,
                icon: const Icon(Icons.language, color: Colors.white, size: 16),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    langProv.setLanguage(newValue);
                    context.read<HomeProvider>().init(newValue);
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'en-US', child: Text('EN ')),
                  DropdownMenuItem(value: 'hi-IN', child: Text('HI ')),
                  DropdownMenuItem(value: 'es-ES', child: Text('ES ')),
                  DropdownMenuItem(value: 'fr-FR', child: Text('FR ')),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),

          const CircleAvatar(
            radius: 14,
            backgroundColor: Colors.white12,
            child: Icon(Icons.person, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _navLink(String title, int index) {
    final bool isActive = _activeNavIndex == index;
    return GestureDetector(
      onTap: () => _onNavTap(index),
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
  
  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.white54)),
        ],
      ],
    );
  }

  Widget _buildHorizontalList(BuildContext context, List items, {required bool isTv, required bool isDesktop}) {
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
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(showId: item.id, isTv: isTv))),
            child: Container(
              width: cardWidth,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: cardWidth, height: cardHeight, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white10), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: item.fullPosterPath, fit: BoxFit.cover, placeholder: (_, __) => Container(color: Colors.white10)))),
                  const SizedBox(height: 8),
                  Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMegaFooter(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white10))),
      child: Column(
        children: [
          Text('LE MOVIE', style: TextStyle(fontSize: isDesktop ? 32 : 24, fontWeight: FontWeight.w900, color: const Color(0xFFE50914), letterSpacing: 2)),
          const SizedBox(height: 20),
          const Text('The ultimate destination for premium streaming.', style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 30),
          Wrap(alignment: WrapAlignment.center, spacing: 20, runSpacing: 10, children: const [Text('FAQ', style: TextStyle(color: Colors.white70, fontSize: 13)), Text('Terms of Service', style: TextStyle(color: Colors.white70, fontSize: 13)), Text('Privacy Policy', style: TextStyle(color: Colors.white70, fontSize: 13))]),
          const SizedBox(height: 40),
          const Text('© 2026 LE MOVIE Platform. All Rights Reserved.', style: TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildShimmerHero(bool isDesktop) => Shimmer.fromColors(baseColor: Colors.white10, highlightColor: Colors.white24, child: Container(height: isDesktop ? 450 : 300, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))));
  Widget _buildShimmerList(bool isDesktop) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Shimmer.fromColors(baseColor: Colors.white10, highlightColor: Colors.white24, child: Container(width: 150, height: 20, color: Colors.white)), const SizedBox(height: 15), SizedBox(height: 220, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: 8, itemBuilder: (_, __) => Padding(padding: const EdgeInsets.only(right: 15), child: Shimmer.fromColors(baseColor: Colors.white10, highlightColor: Colors.white24, child: Container(width: 130, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)))))))]);
  Widget _buildShimmerGrid() => GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: 20, gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 200, childAspectRatio: 0.65, crossAxisSpacing: 16, mainAxisSpacing: 24), itemBuilder: (_, __) => Shimmer.fromColors(baseColor: Colors.white10, highlightColor: Colors.white24, child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)))));
}

// ─── Animated Auto-Sliding Hero Carousel ──────────────────────────────────────
class HeroCarousel extends StatefulWidget {
  final List items;
  final bool isDesktop;
  final bool isTv;

  const HeroCarousel({super.key, required this.items, required this.isDesktop, required this.isTv});

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    Future.delayed(const Duration(seconds: 6), () {
      if (!mounted) return;
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % widget.items.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
      _startAutoSlide(); // Loop the timer
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    
    return Container(
      height: widget.isDesktop ? 450 : 300,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(showId: item.id, isTv: widget.isTv))),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: item.fullBackdropPath,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        placeholder: (context, url) => Container(color: Colors.white10),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black87, Colors.black45, Colors.transparent], 
                            begin: Alignment.bottomCenter, 
                            end: Alignment.topCenter
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(widget.isDesktop ? 40 : 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFE50914), borderRadius: BorderRadius.circular(3)), child: Text('Trending #${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))) ]),
                            const SizedBox(height: 12),
                            SizedBox(width: widget.isDesktop ? 600 : double.infinity, child: Text(item.title, style: TextStyle(fontSize: widget.isDesktop ? 40 : 28, fontWeight: FontWeight.w900, letterSpacing: -0.5))),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.play_arrow, color: Colors.blue),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, padding: EdgeInsets.symmetric(horizontal: widget.isDesktop ? 24 : 16, vertical: widget.isDesktop ? 18 : 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(showId: item.id, isTv: widget.isTv))),
                                  label: Text('Play Now', style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: widget.isDesktop ? 16 : 14)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Page Indicators
          Positioned(
            bottom: 20,
            right: 30,
            child: Row(
              children: List.generate(widget.items.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: _currentPage == index ? 24 : 6,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? const Color(0xFFE50914) : Colors.white38,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
