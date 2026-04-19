// lib/presentation/pages/details_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/streaming_provider.dart';
import '../widgets/glass_container.dart';
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

    return Scaffold(
      body: Stack(
        children: [
          // Background Backdrop (Simulated)
          Opacity(
            opacity: 0.3,
            child: Container(color: Colors.black),
          ),

          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                expandedHeight: 200,
                pinned: true,
                title: Text(streamProv.currentTVDetails?.name ?? (widget.isTv ? 'TV Show' : 'Movie')),
              ),

              if (streamProv.isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildShimmerBlock(height: 100, width: double.infinity),
                        const SizedBox(height: 20),
                        _buildShimmerBlock(height: 50, width: double.infinity),
                        const SizedBox(height: 20),
                        _buildShimmerBlock(height: 200, width: double.infinity),
                      ],
                    ),
                  ),
                )
              else ...[
                // Season Selection Section (Only for TV)
                if (widget.isTv && streamProv.currentTVDetails != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Select Season', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: streamProv.currentTVDetails!.seasons.length,
                              itemBuilder: (context, index) {
                                final season = streamProv.currentTVDetails!.seasons[index];
                                final isSelected = streamProv.selectedSeason == season;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: ChoiceChip(
                                    label: Text(season.name),
                                    selected: isSelected,
                                    onSelected: (_) => streamProv.selectSeason(season),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Episode Selection (Only for TV)
                if (widget.isTv && streamProv.currentEpisodes.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final ep = streamProv.currentEpisodes[index];
                          final isSelected = streamProv.selectedEpisode == ep;
                          return GestureDetector(
                            onTap: () => streamProv.selectEpisode(ep),
                            child: GlassContainer(
                              borderRadius: BorderRadius.circular(10),
                              opacity: isSelected ? 0.3 : 0.1,
                              child: Center(
                                child: Text('EP ${ep.episodeNumber}', 
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          );
                        },
                        childCount: streamProv.currentEpisodes.length,
                      ),
                    ),
                  ),

                // Server Selection (Always show if streams available)
                if (streamProv.availableStreams.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(color: Colors.white24),
                          const Text('Select Server', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          ...streamProv.availableStreams.map((s) => Card(
                            color: streamProv.selectedStream == s ? const Color(0xFFE50914).withOpacity(0.2) : Colors.white12,
                            child: ListTile(
                              leading: const Icon(Icons.play_circle_fill),
                              title: Text('${s.language} Server'),
                              subtitle: const Text('High Quality'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                streamProv.selectStream(s);
                                Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerPage(stream: s)));
                              },
                            ),
                          )),
                        ],
                      ),
                    ),
                  )
                else if (!streamProv.isLoading)
                  const SliverToBoxAdapter(
                    child: Center(child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text('No servers found for this media.'),
                    )),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBlock({required double height, required double width}) {
    return Shimmer.fromColors(
      baseColor: Colors.white10,
      highlightColor: Colors.white24,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
