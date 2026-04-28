import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/home_provider.dart';
import '../providers/language_provider.dart';
import '../providers/search_provider.dart';
import '../widgets/search_overlay.dart';
import 'details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _activeNavIndex = 0;
  bool _isSearchExpanded = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // Genre filtering state
  bool _isTvGenre = false;
  int? _selectedGenreId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final langProv = context.read<LanguageProvider>();
      context.read<HomeProvider>().init(langProv.currentLanguageCode);
    });
  }

  void _onNavChange(int index) {
    setState(() => _activeNavIndex = index);
    final homeProv = context.read<HomeProvider>();
    if (index == 1) homeProv.loadMovies();
    if (index == 2) homeProv.loadSeries();
    if (index == 3) homeProv.loadGenres();
  }

  @override
  Widget build(BuildContext context) {
    final homeProv = context.watch<HomeProvider>();
    final langProv = context.watch<LanguageProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 1200 ? 60.0 : screenWidth > 800 ? 40.0 : 16.0;
    final isDesktop = screenWidth > 800;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              // Navigation
              _buildTopNavigationBar(isDesktop, horizontalPadding, langProv),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildActiveView(homeProv, isDesktop, horizontalPadding),
                      const SizedBox(height: 60),
                      _buildMegaFooter(isDesktop, horizontalPadding),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Search Results Overlay
          const SearchOverlay(),
        ],
      ),
    );
  }

  // ─── Routing System ────────────────────────────────────────────────────────
  Widget _buildActiveView(HomeProvider homeProv, bool isDesktop, double hPadding) {
    if (_activeNavIndex == 0) {
      return _buildHomeView(homeProv, isDesktop, hPadding);
    } else if (_activeNavIndex == 1) {
      return Padding(padding: EdgeInsets.symmetric(horizontal: hPadding), child: _buildMoviesView(homeProv, isDesktop));
    } else if (_activeNavIndex == 2) {
      return Padding(padding: EdgeInsets.symmetric(horizontal: hPadding), child: _buildSeriesView(homeProv, isDesktop));
    } else if (_activeNavIndex == 3) {
      return Padding(padding: EdgeInsets.symmetric(horizontal: hPadding), child: _buildGenresView(homeProv, isDesktop));
    }
    return const SizedBox.shrink();
  }

  // ─── View 0: Home ──────────────────────────────────────────────────────────
  Widget _buildHomeView(HomeProvider homeProv, bool isDesktop, double hPadding) {
    if (homeProv.isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: hPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              _buildShimmerHero(isDesktop),
              const SizedBox(height: 40),
              _buildShimmerList(isDesktop),
              const SizedBox(height: 40),
              _buildShimmerList(isDesktop),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (homeProv.trendingMovies.isNotEmpty)
          HeroCarousel(items: homeProv.trendingMovies.take(5).toList(), isDesktop: isDesktop),
        
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              // TV Series Section
              _buildSectionTitle('Trending Series'),
              const SizedBox(height: 20),
              _buildHorizontalList(context, homeProv.trendingTV, isTv: true, isDesktop: isDesktop, delay: 0),

              const SizedBox(height: 50),
              _buildSectionTitle('Trending Movies'),
              const SizedBox(height: 20),
              _buildHorizontalList(context, homeProv.trendingMovies, isTv: false, isDesktop: isDesktop, delay: 200),
              
              const SizedBox(height: 50),
              _buildSectionTitle('Latest Releases'),
              const SizedBox(height: 20),
              _buildHorizontalList(context, homeProv.upcomingMovies, isTv: false, isDesktop: isDesktop, delay: 400),
              
              const SizedBox(height: 50),
              _buildSectionTitle('Global Favorites'),
              const SizedBox(height: 20),
              _buildHorizontalList(context, homeProv.topRatedMovies, isTv: false, isDesktop: isDesktop, delay: 600),

              const SizedBox(height: 50),
              // NEW: Animation Section
              _buildSectionTitle('Animated Adventures'),
              const SizedBox(height: 20),
              _buildHorizontalList(context, homeProv.animationMovies, isTv: false, isDesktop: isDesktop, delay: 800),

              const SizedBox(height: 50),
              // NEW: Horror Section
              _buildSectionTitle('Midnight Horrors'),
              const SizedBox(height: 20),
              _buildHorizontalList(context, homeProv.horrorMovies, isTv: false, isDesktop: isDesktop, delay: 1000),
            ],
          ),
        ),
      ],
    );
  }

  // ─── View 1: Movies (Grid) ─────────────────────────────────────────────────
  Widget _buildMoviesView(HomeProvider homeProv, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        _buildSectionTitle('Cinematic Masterpieces'),
        const SizedBox(height: 30),
        if (homeProv.isLoadingCategory) _buildShimmerGrid() else _buildResponsiveGrid(homeProv.popularMovies, isTv: false),
      ],
    );
  }

  // ─── View 2: Series (Grid) ──────────────────────────────────────────────────
  Widget _buildSeriesView(HomeProvider homeProv, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        _buildSectionTitle('Binge-worthy Dramas'),
        const SizedBox(height: 30),
        if (homeProv.isLoadingCategory) _buildShimmerGrid() else _buildResponsiveGrid(homeProv.popularTV, isTv: true),
      ],
    );
  }

  // ─── View 3: Genres ─────────────────────────────────────────────────────────
  Widget _buildGenresView(HomeProvider homeProv, bool isDesktop) {
    final activeGenres = _isTvGenre ? homeProv.tvGenres : homeProv.movieGenres;

    if (homeProv.isLoadingCategory && activeGenres.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 100),
        child: _buildShimmerGrid(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        _buildSectionTitle('Find your vibe'),
        const SizedBox(height: 30),
        
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
        const SizedBox(height: 30),

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
              borderRadius: BorderRadius.circular(4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: isSelected ? Colors.white : Colors.white10),
                ),
                child: Text(
                  g['name'].toString().toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 50),
        
        // Results
        if (_selectedGenreId != null) ...[
          if (homeProv.isLoadingCategory)
            _buildShimmerGrid()
          else if (homeProv.genreResults.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(80.0),
              child: Text('NO RESULTS FOUND IN THIS CATEGORY.', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 10)),
            ))
          else
            _buildResponsiveGrid(homeProv.genreResults, isTv: _isTvGenre),
        ],
      ],
    );
  }

  // ─── UI Components ──────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        color: Colors.white,
      ),
    );
  }

  Widget _buildHorizontalList(BuildContext context, List items, {required bool isTv, required bool isDesktop, int delay = 0}) {
    final double cardWidth = isDesktop ? 160 : 130;
    final double cardHeight = isDesktop ? 240 : 195;
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(40 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: SizedBox(
        height: cardHeight + 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Padding(
              padding: const EdgeInsets.only(right: 20),
              child: _MovieCard(
                item: item,
                width: cardWidth,
                height: cardHeight,
                isTv: isTv,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResponsiveGrid(List items, {required bool isTv}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        childAspectRatio: 0.62,
        crossAxisSpacing: 20,
        mainAxisSpacing: 30,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _MovieCard(
          item: item,
          width: 160,
          height: 240,
          isTv: isTv,
        );
      },
    );
  }

  Widget _genreFilterTab(String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isActive ? Colors.white : Colors.white10),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white60,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _navLink(String label, int index) {
    final bool isActive = _activeNavIndex == index;
    return InkWell(
      onTap: () => _onNavChange(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white38,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTopNavigationBar(bool isDesktop, double hPadding, LanguageProvider langProv) {
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: hPadding),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        children: [
          // Brand
          Text(
            'LE MOVIE',
            style: TextStyle(
              fontSize: isDesktop ? 22 : 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          SizedBox(width: isDesktop ? 60 : 20),

          if (isDesktop) ...[
            _navLink('HOME', 0),
            _navLink('MOVIES', 1),
            _navLink('SERIES', 2),
            _navLink('GENRES', 3),
          ],

          const Spacer(),

          // Search & Profile
          if (isDesktop) ...[
            _buildDesktopSearchWidget(),
            const SizedBox(width: 24),
          ],

          _buildLanguageSelector(langProv),
          const SizedBox(width: 24),

          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white10,
            child: Icon(Icons.person_outline, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSearchWidget() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isSearchExpanded ? 240 : 40,
      height: 40,
      decoration: BoxDecoration(
        color: _isSearchExpanded ? Colors.white.withOpacity(0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _isSearchExpanded ? Colors.white10 : Colors.transparent),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white.withOpacity(0.7), size: 20),
            onPressed: () {
              setState(() {
                _isSearchExpanded = !_isSearchExpanded;
                if (_isSearchExpanded) _searchFocus.requestFocus();
              });
            },
          ),
          if (_isSearchExpanded)
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                onChanged: (val) => context.read<SearchProvider>().onSearchChanged(val),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Search titles...',
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(LanguageProvider langProv) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: const Color(0xFF0D0D0D),
          value: langProv.currentLanguageCode,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white60, size: 14),
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          onChanged: (String? newValue) {
            if (newValue != null) {
              langProv.setLanguage(newValue);
              context.read<HomeProvider>().init(newValue);
            }
          },
          items: const [
            DropdownMenuItem(value: 'en-US', child: Text('EN')),
            DropdownMenuItem(value: 'hi-IN', child: Text('HI')),
            DropdownMenuItem(value: 'es-ES', child: Text('ES')),
            DropdownMenuItem(value: 'fr-FR', child: Text('FR')),
          ],
        ),
      ),
    );
  }

  Widget _buildMegaFooter(bool isDesktop, double hPadding) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 60, horizontal: hPadding),
      decoration: const BoxDecoration(
        color: Color(0xFF050505),
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            'LE MOVIE',
            style: TextStyle(
              fontSize: isDesktop ? 28 : 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'THE ULTIMATE STREAMING EXPERIENCE',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 30,
            runSpacing: 15,
            children: [
              _footerLink('BROWSE'),
              _footerLink('WATCHLIST'),
              _footerLink('SETTINGS'),
              _footerLink('HELP'),
            ],
          ),
          const SizedBox(height: 60),
          const Text(
            '© 2026 LE MOVIE PLATFORM. ALL RIGHTS RESERVED.',
            style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildShimmerHero(bool isDesktop) => Shimmer.fromColors(baseColor: Colors.white10, highlightColor: Colors.white24, child: Container(height: isDesktop ? 550 : 380, width: double.infinity, color: Colors.white));
  Widget _buildShimmerList(bool isDesktop) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Shimmer.fromColors(baseColor: Colors.white10, highlightColor: Colors.white24, child: Container(width: 150, height: 16, color: Colors.white)), const SizedBox(height: 20), SizedBox(height: 220, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: 8, itemBuilder: (_, __) => Padding(padding: const EdgeInsets.only(right: 20), child: Shimmer.fromColors(baseColor: Colors.white10, highlightColor: Colors.white24, child: Container(width: 150, color: Colors.white)))))]);
  Widget _buildShimmerGrid() => GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: 20, gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 200, childAspectRatio: 0.65, crossAxisSpacing: 16, mainAxisSpacing: 24), itemBuilder: (_, __) => Shimmer.fromColors(baseColor: Colors.white10, highlightColor: Colors.white24, child: Container(color: Colors.white)));
}

class _MovieCard extends StatefulWidget {
  final dynamic item;
  final double width;
  final double height;
  final bool isTv;

  const _MovieCard({required this.item, required this.width, required this.height, required this.isTv});

  @override
  State<_MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<_MovieCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(showId: widget.item.id, isTv: widget.item.isTv ?? widget.isTv))),
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white10,
                  boxShadow: _isHovered ? [
                    BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.3), blurRadius: 15, spreadRadius: -5)
                  ] : [],
                  border: Border.all(color: _isHovered ? Colors.white38 : Colors.transparent),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: widget.item.fullPosterPath,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: widget.width,
                child: Text(
                  widget.item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.bold, 
                    color: _isHovered ? Colors.white : Colors.white70, 
                    letterSpacing: 0.5
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

class HeroCarousel extends StatefulWidget {
  final List items;
  final bool isDesktop;

  const HeroCarousel({super.key, required this.items, required this.isDesktop});

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
    Future.delayed(const Duration(seconds: 8), () {
      if (!mounted) return;
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % widget.items.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 1200),
          curve: Curves.easeInOutQuart,
        );
      }
      _startAutoSlide();
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
    
    return SizedBox(
      height: widget.isDesktop ? 550 : 380,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(showId: item.id, isTv: false))),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Backdrop Image with Parallax
                    AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        double offset = 0;
                        if (_pageController.hasClients) {
                          offset = (_pageController.page ?? 0) - index;
                        }
                        return Transform.translate(
                          offset: Offset(offset * 100, 0),
                          child: CachedNetworkImage(
                            imageUrl: item.fullBackdropPath,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            placeholder: (context, url) => Container(color: Colors.black),
                          ),
                        );
                      },
                    ),
                    
                    // Matte Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black,
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                            Colors.black,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                        ),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.isDesktop ? 60 : 20,
                        vertical: 40,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.5), blurRadius: 10)
                              ],
                            ),
                            child: const Text(
                              'HOT NOW',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: widget.isDesktop ? 700 : double.infinity,
                            child: Hero(
                              tag: 'title-${item.id}',
                              child: Material(
                                color: Colors.transparent,
                                child: Text(
                                  item.title.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: widget.isDesktop ? 56 : 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              _heroButton(
                                label: 'WATCH NOW',
                                icon: Icons.play_arrow_rounded,
                                isPrimary: true,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(showId: item.id, isTv: false))),
                              ),
                              const SizedBox(width: 16),
                              _heroButton(
                                label: 'DETAILS',
                                icon: Icons.info_outline_rounded,
                                isPrimary: false,
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(showId: item.id, isTv: false))),
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
          
          // Custom Indicators
          Positioned(
            bottom: 40,
            right: widget.isDesktop ? 60 : 20,
            child: Row(
              children: List.generate(widget.items.length, (index) {
                final bool isActive = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 2,
                  width: isActive ? 30 : 15,
                  decoration: BoxDecoration(
                    color: isActive ? Theme.of(context).primaryColor : Colors.white24,
                    borderRadius: BorderRadius.circular(1),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroButton({required String label, required IconData icon, required bool isPrimary, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: widget.isDesktop ? 28 : 20,
          vertical: widget.isDesktop ? 14 : 10,
        ),
        decoration: BoxDecoration(
          color: isPrimary ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: isPrimary ? null : Border.all(color: Colors.white24),
          boxShadow: isPrimary ? [
            BoxShadow(color: Colors.white.withOpacity(0.2), blurRadius: 10)
          ] : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: isPrimary ? Colors.black : Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.black : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
