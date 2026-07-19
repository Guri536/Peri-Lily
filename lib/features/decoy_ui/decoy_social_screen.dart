import 'dart:ffi';
import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:peri_lily_android/core/enums.dart';
import 'package:peri_lily_android/features/decoy_ui/gesture_wrapper.dart';

class FakePostGenerator {
  static final _usernames = [
    'wanderlust.jay', 'morning.coffee', 'urban.explorer', 'sunday.vibes',
    'thecreativeedit', 'naturefirst22', 'studio.notes', 'quiet.hours',
    'plantmomdiaries', 'citylights99',
  ];

  static final _captions = [
    'best part of my week 🌿',
    'finally caught up on sleep',
    'this view though...',
    'small wins today',
    'coffee first, everything else after',
    'can\'t stop thinking about this trip',
    'new favorite spot 📍',
    'just a regular tuesday',
    'grateful for days like this',
    'still can\'t believe this is real',
  ];

  static final _random = Random();

  static String randomUsername() => _usernames[_random.nextInt(_usernames.length)];
  static String randomCaption() => _captions[_random.nextInt(_captions.length)];
  static String randomLikeCount() => '${_random.nextInt(900) + 50} likes';
}

class FeedPost {
  final String username;
  final String caption;
  final String likeCount;
  final String networkUrl;
  final String localAssetPath;

  FeedPost({
    required this.username,
    required this.caption,
    required this.likeCount,
    required this.networkUrl,
    required this.localAssetPath,
  });
}

class FeedLoader {
  static const _localAssetPool = [
    'lib/core/assets/decoy_posts/post_1.jpg',
    'lib/core/assets/decoy_posts/post_2.jpg',
    'lib/core/assets/decoy_posts/post_3.jpg',
    'lib/core/assets/decoy_posts/post_4.jpg',
    'lib/core/assets/decoy_posts/post_5.jpg',
  ];

  static List<FeedPost> generateFeed({int count = 12}) {
    return List.generate(count, (i) {
      final seed = DateTime.now().millisecondsSinceEpoch + i;
      return FeedPost(
        username: FakePostGenerator.randomUsername(),
        caption: FakePostGenerator.randomCaption(),
        likeCount: FakePostGenerator.randomLikeCount(),
        networkUrl: 'https://picsum.photos/seed/$seed/500/500',
        localAssetPath: _localAssetPool[i % _localAssetPool.length],
      );
    });
  }
}

class SocialFeedScreen extends StatelessWidget {
  const SocialFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final posts = FeedLoader.generateFeed();

    return Scaffold(
      body: DecoyGestureWrapper(
        decoyType: DecoyType.socialFeed,
        child: ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) => _FeedPostCard(post: posts[index]),
        ),
      ),
    );
  }
}

class _FeedImage extends StatefulWidget {
  final String networkUrl;
  final String localAssetPath;

  const _FeedImage({required this.networkUrl, required this.localAssetPath});

  @override
  State<_FeedImage> createState() => _FeedImageState();
}

class _FeedImageState extends State<_FeedImage> {
  Uint8List? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchWithTimeout();
  }

  Future<void> _fetchWithTimeout() async {
    try {
      final response = await http
          .get(Uri.parse(widget.networkUrl))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _bytes = response.bodyBytes;
          _loading = false;
        });
        return;
      }
      throw Exception('Bad status: ${response.statusCode}');
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoadingCard();

    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _localOrLoadingCard(),
      );
    }

    // network failed outright
    return _localOrLoadingCard();
  }

  Widget _localOrLoadingCard() {
    return Image.asset(
      widget.localAssetPath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildLoadingCard(),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}

class _FeedPostCard extends StatelessWidget {
  final FeedPost post;

  const _FeedPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(radius: 16, backgroundColor: Colors.grey.shade300),
              const SizedBox(width: 8),
              Text(post.username, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        AspectRatio(
          aspectRatio: 1,
          child: _FeedImage(
            networkUrl: post.networkUrl,
            localAssetPath: post.localAssetPath,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post.likeCount, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(text: '${post.username} ', style: const TextStyle(fontWeight: FontWeight.w600)),
                    TextSpan(text: post.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}