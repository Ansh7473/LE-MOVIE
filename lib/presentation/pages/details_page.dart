// lib/presentation/pages/details_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui' show ImageFilter;
import '../providers/streaming_provider.dart';
import 'player_page.dart';
import 'package:shimmer/shimmer.dart';

class DetailsPage extends StatefulWidget {
  final int showId;
  final bool isTv;
  const DetailsPage({super.key, required this.showId, this.isTv = true});

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<StreamingProvider>().loadMedia(widget.showId, isTv: widget.isTv));
  }

  @override
  Widget build(BuildContext context) {
    final streamProv = context.watch<StreamingProvider>();
    final size = MediaQuery.of(context).size;
    
    // Determine dynamic values based on media type
    final movieDetails = streamProv.currentMovieDetails;
    final tvDetails = streamProv.currentTVDetails;
    
    final title = widget.isTv 
        ? (tvDetails?.name ?? 'Loading...') 
        : (movieDetails?.title ?? 'Loading...');
    
    final backdropPath = widget.isTv 
        ? (tvDetails?.backdropPath ?? '') 
        : (movieDetails?.backdropPath ?? '');
        
    final posterPath = widget.isTv 
        ? '' // TV typically shows season posters later, but we can use first season or empty for now
        : (movieDetails?.posterPath ?? '');
        
    final overview = widget.isTv 
        ? (tvDetails?.overview ?? '') 
        : (movieDetails?.overview ?? '');
        
    final rating = widget.isTv 
        ? (tvDetails?.voteAverage ?? 0.0) 
        : (movieDetails?.voteAverage ?? 0.0);
        
    final releaseDate = widget.isTv 
        ? (tvDetails?.firstAirDate ?? '') 
        : (movieDetails?.releaseDate ?? '');

    final primaryColor = widget.isTv ? Colors.blue : const Color(0xFFE50914);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0B),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero Backdrop & Info ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: size.height * 0.55,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF0A0A0B),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black38,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Backdrop Image
                  if (backdropPath.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: 'https://image.tmdb.org/t/p/original$backdropPath',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.black12),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    )
                  else
                    Container(color: const Color(0xFF1A1A1D)),

                  // Cinematic Gradient Overlays
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Color(0xFF0A0A0B),
                        ],
                        stops: [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color(0xFF0A0A0B),
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.3],
                      ),
                    ),
                  ),

                  // Metadata Overlay
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.isTv ? 'TV SERIES' : 'MOVIE',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (releaseDate.isNotEmpty)
                              Text(
                                releaseDate.split('-')[0],
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            const Spacer(),
                            Row(
                              children: [
                                Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          overview,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Controls Section ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Loading Indicator
                  if (streamProv.isLoading && streamProv.availableStreams.isEmpty)
                    _buildShimmer()
                  else ...[
                    // TV Specific: Seasons & Episodes
                    if (widget.isTv && tvDetails != null) ...[
                      _sectionLabel('CHOOSE SEASON'),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 45,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: tvDetails.seasons.length,
                          itemBuilder: (context, i) {
                            final season = tvDetails.seasons[i];
                            final isSelected = streamProv.selectedSeason == season;
                            return GestureDetector(
                              onTap: () => streamProv.selectSeason(season),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 22),
                                decoration: BoxDecoration(
                                  color: isSelected ? primaryColor : Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? primaryColor : Colors.white10,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  season.name,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.white60,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionLabel('EPISODES'),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 70,
                          childAspectRatio: 1,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: streamProv.currentEpisodes.length,
                        itemBuilder: (context, i) {
                          final ep = streamProv.currentEpisodes[i];
                          final isSelected = streamProv.selectedEpisode == ep;
                          return GestureDetector(
                            onTap: () => streamProv.selectEpisode(ep),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryColor : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isSelected ? primaryColor : Colors.white10),
                              ),
                              child: Center(
                                child: Text(
                                  'E${ep.episodeNumber}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.white38,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Server Selection
                    if (streamProv.isLoading && streamProv.selectedStream == null)
                      _buildServerShimmer()
                    else if (streamProv.availableStreams.isNotEmpty) ...[
                      _sectionLabel('SELECT SERVER'),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1.5,
                              ),
                            ),
                            child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: streamProv.availableStreams.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final s = streamProv.availableStreams[i];
                            final isSelected = streamProv.selectedStream == s;
                            return GestureDetector(
                              onTap: () {
                                streamProv.selectStream(s);
                                Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerPage(stream: s)));
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected ? primaryColor.withOpacity(0.15) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? primaryColor.withOpacity(0.5) : Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isSelected ? primaryColor : Colors.white.withOpacity(0.05),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isSelected ? Icons.play_arrow_rounded : Icons.dns_rounded,
                                        size: 20,
                                        color: isSelected ? Colors.white : Colors.white60,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s.language,
                                            style: TextStyle(
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            'Premium High Speed Server',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white38,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(Icons.check_circle_rounded, color: primaryColor, size: 22),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ] else if (!streamProv.isLoading)
                      _buildNoStreams(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Colors.white70,
              letterSpacing: 2.0,
            ),
          ),
        ],
      );

  Widget _buildNoStreams() => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              Icon(Icons.error_outline_rounded, size: 50, color: Colors.white24),
              const SizedBox(height: 16),
              const Text(
                'NO STREAMING SERVERS FOUND',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white38),
              ),
              const SizedBox(height: 8),
              Text(
                'Try selecting a different provider or episode',
                style: TextStyle(fontSize: 12, color: Colors.white30),
              ),
            ],
          ),
        ),
      );

  Widget _buildServerShimmer() => Column(
        children: List.generate(
          3,
          (index) => Container(
            height: 70,
            margin: const EdgeInsets.only(bottom: 12),
            child: Shimmer.fromColors(
              baseColor: Colors.white.withOpacity(0.05),
              highlightColor: Colors.white.withOpacity(0.1),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildShimmer() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.white.withOpacity(0.05),
            highlightColor: Colors.white.withOpacity(0.1),
            child: Container(height: 20, width: 100, color: Colors.white),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (_, __) => Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
}
