// lib/presentation/pages/details_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      context.read<StreamingProvider>().loadMedia(widget.showId, isTv: widget.isTv)
    );
  }

  @override
  Widget build(BuildContext context) {
    final streamProv = context.watch<StreamingProvider>();
    final title = streamProv.currentTVDetails?.name ?? (widget.isTv ? 'TV Show' : 'Movie');

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: const Color(0xFF0F0F0F).withOpacity(0.9),
            expandedHeight: 60,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isTv
                      ? Colors.blue.withOpacity(0.2)
                      : const Color(0xFFE50914).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: widget.isTv
                        ? Colors.blue.withOpacity(0.5)
                        : const Color(0xFFE50914).withOpacity(0.5),
                  ),
                ),
                child: Text(
                  widget.isTv ? 'TV SERIES' : 'MOVIE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: widget.isTv ? Colors.lightBlueAccent : const Color(0xFFE50914),
                  ),
                ),
              ),
            ],
          ),

          // ── Content ──────────────────────────────────────────────────────
          if (streamProv.isLoading && streamProv.availableStreams.isEmpty)
            SliverToBoxAdapter(child: _buildShimmer())
          else
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                    // ── Season Selector (TV only) ─────────────────────────
                    if (widget.isTv && streamProv.currentTVDetails != null) ...[
                      _sectionLabel('SEASON'),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: streamProv.currentTVDetails!.seasons.length,
                          itemBuilder: (context, i) {
                            final season = streamProv.currentTVDetails!.seasons[i];
                            final isSelected = streamProv.selectedSeason == season;
                            return GestureDetector(
                              onTap: () => streamProv.selectSeason(season),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFE50914)
                                      : const Color(0xFF1E1E2E),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFE50914)
                                        : Colors.white12,
                                  ),
                                ),
                                child: Text(
                                  season.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : Colors.white54,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ── Episode Grid (TV only) ────────────────────────────
                    if (widget.isTv && streamProv.currentEpisodes.isNotEmpty) ...[
                      _sectionLabel('EPISODES'),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 80,
                          childAspectRatio: 1.5,
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
                                color: isSelected
                                    ? const Color(0xFFE50914)
                                    : const Color(0xFF1E1E2E),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFE50914)
                                      : Colors.white10,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFE50914).withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: Text(
                                  'E${ep.episodeNumber}',
                                  style: TextStyle(
                                    fontSize: 13,
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

                    // ── Server Selection ──────────────────────────────────
                    if (streamProv.isLoading && streamProv.selectedEpisode != null)
                      _buildServerShimmer()
                    else if (streamProv.availableStreams.isNotEmpty) ...[
                      _sectionLabel('SELECT SERVER'),
                      const SizedBox(height: 12),
                      ...streamProv.availableStreams.asMap().entries.map((entry) {
                        final i = entry.key;
                        final s = entry.value;
                        final isSelected = streamProv.selectedStream == s;
                        return GestureDetector(
                          onTap: () {
                            streamProv.selectStream(s);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlayerPage(stream: s),
                              ),
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFE50914).withOpacity(0.15)
                                  : const Color(0xFF1E1E2E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFE50914).withOpacity(0.6)
                                    : Colors.white12,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFE50914).withOpacity(0.2),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE50914).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.play_circle_fill,
                                    color: Color(0xFFE50914),
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.language,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'HD • Fast Stream • Tap to Play',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE50914),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.play_arrow,
                                          size: 14, color: Colors.white),
                                      SizedBox(width: 4),
                                      Text('PLAY',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          )),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ] else if (!streamProv.isLoading)
                      _buildNoStreams(),
                  ],
                ),
              ),
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
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white38,
          letterSpacing: 1.5,
        ),
      );

  Widget _buildNoStreams() => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.white24),
              const SizedBox(height: 12),
              const Text(
                'No servers found',
                style: TextStyle(fontSize: 16, color: Colors.white54),
              ),
              const SizedBox(height: 6),
              Text(
                'Try selecting a different episode',
                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.3)),
              ),
            ],
          ),
        ),
      );

  Widget _buildServerShimmer() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('SELECT SERVER'),
          const SizedBox(height: 12),
          ...List.generate(
            2,
            (_) => Shimmer.fromColors(
              baseColor: Colors.white10,
              highlightColor: Colors.white24,
              child: Container(
                height: 78,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );

  Widget _buildShimmer() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Shimmer.fromColors(
              baseColor: Colors.white10,
              highlightColor: Colors.white24,
              child: Container(
                  height: 20, width: 80, color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 10)),
            ),
            Shimmer.fromColors(
              baseColor: Colors.white10,
              highlightColor: Colors.white24,
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  itemBuilder: (_, __) => Container(
                    width: 90,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Shimmer.fromColors(
              baseColor: Colors.white10,
              highlightColor: Colors.white24,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5, childAspectRatio: 1.6,
                  crossAxisSpacing: 8, mainAxisSpacing: 8,
                ),
                itemCount: 15,
                itemBuilder: (_, __) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
