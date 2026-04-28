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
    final primaryColor = Theme.of(context).primaryColor;
    
    final movieDetails = streamProv.currentMovieDetails;
    final tvDetails = streamProv.currentTVDetails;
    
    final title = widget.isTv 
        ? (tvDetails?.name ?? 'Loading...') 
        : (movieDetails?.title ?? 'Loading...');
    
    final backdropPath = widget.isTv 
        ? (tvDetails?.backdropPath ?? '') 
        : (movieDetails?.backdropPath ?? '');
        
    final overview = widget.isTv 
        ? (tvDetails?.overview ?? '') 
        : (movieDetails?.overview ?? '');
        
    final rating = widget.isTv 
        ? (tvDetails?.voteAverage ?? 0.0) 
        : (movieDetails?.voteAverage ?? 0.0);
        
    final releaseDate = widget.isTv 
        ? (tvDetails?.firstAirDate ?? '') 
        : (movieDetails?.releaseDate ?? '');

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero Backdrop & Info ─────────────────────────────────────────
          SliverAppBar(
            expandedHeight: size.height * 0.6,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.black,
            leading: Padding(
              padding: const EdgeInsets.all(12.0),
              child: CircleAvatar(
                backgroundColor: Colors.black38,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
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
                      alignment: Alignment.topCenter,
                      placeholder: (context, url) => Container(color: Colors.black),
                    )
                  else
                    Container(color: const Color(0xFF0D0D0D)),

                  // Cinematic Matte Overlays
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black,
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                        stops: const [0.0, 0.4, 0.7, 1.0],
                      ),
                    ),
                  ),

                  // Metadata Overlay
                  Positioned(
                    bottom: 30,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                widget.isTv ? 'SERIES' : 'MOVIE',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black),
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (releaseDate.isNotEmpty)
                              Text(
                                releaseDate.split('-')[0],
                                style: const TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          title.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.5,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          overview,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (streamProv.isLoading && streamProv.availableStreams.isEmpty)
                    _buildShimmer()
                  else if (!streamProv.isLoading && streamProv.availableStreams.isEmpty)
                    _buildNoStreams()
                  else ...[
                    // TV Specific: Seasons & Episodes
                    if (widget.isTv && tvDetails != null) ...[
                      _sectionLabel('CHOOSE SEASON'),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 48,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: tvDetails.seasons.length,
                          itemBuilder: (context, i) {
                            final season = tvDetails.seasons[i];
                            final isSelected = streamProv.selectedSeason == season;
                            return GestureDetector(
                              onTap: () => streamProv.selectSeason(season),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isSelected ? Colors.white : Colors.white10,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  season.name.toUpperCase(),
                                  style: TextStyle(
                                    color: isSelected ? Colors.black : Colors.white60,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 40),
                      _sectionLabel('EPISODES'),
                      const SizedBox(height: 20),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 70,
                          childAspectRatio: 1,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
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
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: isSelected ? primaryColor : Colors.white10),
                              ),
                              child: Center(
                                child: Text(
                                  '${ep.episodeNumber}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: isSelected ? Colors.black : Colors.white38,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                    ],

                    // Server Selection
                    if (streamProv.availableStreams.isNotEmpty) ...[
                      _sectionLabel('SELECT SERVER'),
                      const SizedBox(height: 20),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: streamProv.availableStreams.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white.withOpacity(0.05) : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isSelected ? Colors.white24 : Colors.white10,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.play_arrow_rounded : Icons.dns_outlined,
                                    size: 20,
                                    color: isSelected ? primaryColor : Colors.white38,
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.language.toUpperCase(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                            letterSpacing: 1,
                                            color: isSelected ? Colors.white : Colors.white60,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'PREMIUM MATTE SERVER',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white24,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.check_circle_outline_rounded, color: primaryColor, size: 20),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 3.0,
        ),
      );

  Widget _buildNoStreams() => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Column(
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.white10),
              const SizedBox(height: 24),
              const Text(
                'SERVERS CURRENTLY OFFLINE',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white24, letterSpacing: 2),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please try again in a few moments or switch providers.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.white10, fontWeight: FontWeight.bold),
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
                  borderRadius: BorderRadius.circular(4),
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
            child: Container(height: 16, width: 120, color: Colors.white),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (_, __) => Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      );
}
