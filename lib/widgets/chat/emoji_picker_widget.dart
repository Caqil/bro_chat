import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmojiPickerWidget extends ConsumerStatefulWidget {
  final ValueChanged<String> onEmojiSelected;
  final double height;
  final bool showSearchBar;
  final bool showCategoryTabs;
  final bool showRecentEmojis;
  final int columns;
  final Color? backgroundColor;
  final String? selectedSkinTone;

  const EmojiPickerWidget({
    super.key,
    required this.onEmojiSelected,
    this.height = 250,
    this.showSearchBar = true,
    this.showCategoryTabs = true,
    this.showRecentEmojis = true,
    this.columns = 8,
    this.backgroundColor,
    this.selectedSkinTone,
  });

  @override
  ConsumerState<EmojiPickerWidget> createState() => _EmojiPickerWidgetState();
}

class _EmojiPickerWidgetState extends ConsumerState<EmojiPickerWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  final TextEditingController _searchController = TextEditingController();

  List<EmojiCategory> _emojiCategories = [];
  List<String> _recentEmojis = [];
  List<String> _filteredEmojis = [];
  String _searchQuery = '';
  bool _isLoading = true;

  static const String _recentEmojisKey = 'recent_emojis';
  static const int _maxRecentEmojis = 24;

  @override
  void initState() {
    super.initState();
    _loadEmojis();
    _loadRecentEmojis();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmojis() async {
    try {
      final String emojiData = await rootBundle.loadString(
        'assets/data/emojis.json',
      );
      final Map<String, dynamic> data = json.decode(emojiData);

      final categories = <EmojiCategory>[];

      for (final categoryData in data['categories']) {
        final category = EmojiCategory.fromJson(categoryData);
        categories.add(category);
      }

      setState(() {
        _emojiCategories = categories;
        _isLoading = false;
      });

      _initializeControllers();
    } catch (e) {
      // Fallback to hardcoded emojis if asset loading fails
      _loadFallbackEmojis();
    }
  }

  void _loadFallbackEmojis() {
    setState(() {
      _emojiCategories = _getFallbackEmojis();
      _isLoading = false;
    });
    _initializeControllers();
  }

  void _initializeControllers() {
    if (_emojiCategories.isNotEmpty) {
      final tabCount = widget.showRecentEmojis
          ? _emojiCategories.length + 1
          : _emojiCategories.length;
      _tabController = TabController(length: tabCount, vsync: this);
      _pageController = PageController();

      _tabController.addListener(() {
        if (_tabController.indexIsChanging) {
          _pageController.animateToPage(
            _tabController.index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  Future<void> _loadRecentEmojis() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentEmojisJson = prefs.getString(_recentEmojisKey);

      if (recentEmojisJson != null) {
        final List<dynamic> recentList = json.decode(recentEmojisJson);
        setState(() {
          _recentEmojis = recentList.cast<String>();
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _saveRecentEmojis() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_recentEmojisKey, json.encode(_recentEmojis));
    } catch (e) {
      // Handle error silently
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filteredEmojis = _getFilteredEmojis();
    });
  }

  List<String> _getFilteredEmojis() {
    if (_searchQuery.isEmpty) return [];

    final filtered = <String>[];
    for (final category in _emojiCategories) {
      for (final emoji in category.emojis) {
        if (emoji.keywords.any(
              (keyword) => keyword.toLowerCase().contains(_searchQuery),
            ) ||
            emoji.name.toLowerCase().contains(_searchQuery)) {
          filtered.add(emoji.emoji);
        }
      }
    }
    return filtered;
  }

  void _onEmojiSelected(String emoji) {
    // Add to recent emojis
    _recentEmojis.remove(emoji);
    _recentEmojis.insert(0, emoji);

    if (_recentEmojis.length > _maxRecentEmojis) {
      _recentEmojis = _recentEmojis.take(_maxRecentEmojis).toList();
    }

    _saveRecentEmojis();

    widget.onEmojiSelected(emoji);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: widget.height,
        color: widget.backgroundColor ?? Colors.white,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      height: widget.height,
      color: widget.backgroundColor ?? Colors.white,
      child: Column(
        children: [
          if (widget.showSearchBar) _buildSearchBar(),
          if (widget.showCategoryTabs) _buildCategoryTabs(),
          Expanded(child: _buildEmojiGrid()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: ShadInput(
        controller: _searchController,
        placeholder: const Text('Search emojis...'),
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Icon(Icons.search, size: 20, color: Colors.grey),
        ),
        trailing: _searchQuery.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ShadButton.ghost(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _filteredEmojis = [];
                    });
                  },
                  size: ShadButtonSize.sm,
                  child: const Icon(Icons.clear, size: 16),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildCategoryTabs() {
    if (_emojiCategories.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Theme.of(context).primaryColor,
        tabs: [
          if (widget.showRecentEmojis)
            Tab(icon: Icon(Icons.access_time, size: 20)),
          ..._emojiCategories.map((category) {
            return Tab(
              icon: Text(category.icon, style: const TextStyle(fontSize: 20)),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEmojiGrid() {
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResults();
    }

    if (_emojiCategories.isEmpty) {
      return const Center(child: Text('No emojis available'));
    }

    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        _tabController.animateTo(index);
      },
      children: [
        if (widget.showRecentEmojis) _buildRecentEmojisGrid(),
        ..._emojiCategories.map((category) {
          return _buildCategoryGrid(category);
        }).toList(),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_filteredEmojis.isEmpty) {
      return const Center(child: Text('No emojis found'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.columns,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _filteredEmojis.length,
      itemBuilder: (context, index) {
        return _buildEmojiButton(_filteredEmojis[index]);
      },
    );
  }

  Widget _buildRecentEmojisGrid() {
    if (_recentEmojis.isEmpty) {
      return const Center(
        child: Text(
          'No recently used emojis',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.columns,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _recentEmojis.length,
      itemBuilder: (context, index) {
        return _buildEmojiButton(_recentEmojis[index]);
      },
    );
  }

  Widget _buildCategoryGrid(EmojiCategory category) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.columns,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: category.emojis.length,
      itemBuilder: (context, index) {
        return _buildEmojiButton(category.emojis[index].emoji);
      },
    );
  }

  Widget _buildEmojiButton(String emoji) {
    return ShadButton.ghost(
      onPressed: () => _onEmojiSelected(emoji),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  List<EmojiCategory> _getFallbackEmojis() {
    return [
      EmojiCategory(
        name: 'Smileys & People',
        icon: '😀',
        emojis: [
          EmojiData(
            emoji: '😀',
            name: 'grinning face',
            keywords: ['happy', 'smile'],
          ),
          EmojiData(
            emoji: '😃',
            name: 'grinning face with big eyes',
            keywords: ['happy', 'joy'],
          ),
          EmojiData(
            emoji: '😄',
            name: 'grinning face with smiling eyes',
            keywords: ['happy', 'joy'],
          ),
          EmojiData(
            emoji: '😁',
            name: 'beaming face with smiling eyes',
            keywords: ['happy', 'grin'],
          ),
          EmojiData(
            emoji: '😆',
            name: 'grinning squinting face',
            keywords: ['laugh', 'happy'],
          ),
          EmojiData(
            emoji: '😅',
            name: 'grinning face with sweat',
            keywords: ['relief', 'laugh'],
          ),
          EmojiData(
            emoji: '🤣',
            name: 'rolling on the floor laughing',
            keywords: ['laugh', 'rofl'],
          ),
          EmojiData(
            emoji: '😂',
            name: 'face with tears of joy',
            keywords: ['laugh', 'cry'],
          ),
          EmojiData(
            emoji: '🙂',
            name: 'slightly smiling face',
            keywords: ['smile', 'happy'],
          ),
          EmojiData(
            emoji: '🙃',
            name: 'upside-down face',
            keywords: ['silly', 'sarcasm'],
          ),
          EmojiData(
            emoji: '😉',
            name: 'winking face',
            keywords: ['wink', 'flirt'],
          ),
          EmojiData(
            emoji: '😊',
            name: 'smiling face with smiling eyes',
            keywords: ['blush', 'happy'],
          ),
          EmojiData(
            emoji: '😇',
            name: 'smiling face with halo',
            keywords: ['angel', 'innocent'],
          ),
          EmojiData(
            emoji: '🥰',
            name: 'smiling face with hearts',
            keywords: ['love', 'adore'],
          ),
          EmojiData(
            emoji: '😍',
            name: 'smiling face with heart-eyes',
            keywords: ['love', 'crush'],
          ),
          EmojiData(
            emoji: '🤩',
            name: 'star-struck',
            keywords: ['stars', 'excited'],
          ),
          EmojiData(
            emoji: '😘',
            name: 'face blowing a kiss',
            keywords: ['kiss', 'love'],
          ),
          EmojiData(
            emoji: '😗',
            name: 'kissing face',
            keywords: ['kiss', 'pucker'],
          ),
          EmojiData(
            emoji: '☺️',
            name: 'smiling face',
            keywords: ['blush', 'happy'],
          ),
          EmojiData(
            emoji: '😚',
            name: 'kissing face with closed eyes',
            keywords: ['kiss', 'love'],
          ),
          EmojiData(
            emoji: '😙',
            name: 'kissing face with smiling eyes',
            keywords: ['kiss', 'affection'],
          ),
          EmojiData(
            emoji: '🥲',
            name: 'smiling face with tear',
            keywords: ['happy', 'cry'],
          ),
          EmojiData(
            emoji: '😋',
            name: 'face savoring food',
            keywords: ['delicious', 'yum'],
          ),
          EmojiData(
            emoji: '😛',
            name: 'face with tongue',
            keywords: ['tongue', 'silly'],
          ),
          EmojiData(
            emoji: '😜',
            name: 'winking face with tongue',
            keywords: ['tongue', 'wink'],
          ),
          EmojiData(
            emoji: '🤪',
            name: 'zany face',
            keywords: ['crazy', 'silly'],
          ),
          EmojiData(
            emoji: '😝',
            name: 'squinting face with tongue',
            keywords: ['tongue', 'prank'],
          ),
          EmojiData(
            emoji: '🤑',
            name: 'money-mouth face',
            keywords: ['money', 'rich'],
          ),
          EmojiData(
            emoji: '🤗',
            name: 'hugging face',
            keywords: ['hug', 'embrace'],
          ),
          EmojiData(
            emoji: '🤭',
            name: 'face with hand over mouth',
            keywords: ['secret', 'quiet'],
          ),
          EmojiData(
            emoji: '🤫',
            name: 'shushing face',
            keywords: ['quiet', 'secret'],
          ),
          EmojiData(
            emoji: '🤔',
            name: 'thinking face',
            keywords: ['think', 'hmm'],
          ),
          EmojiData(
            emoji: '🤐',
            name: 'zipper-mouth face',
            keywords: ['quiet', 'zip'],
          ),
        ],
      ),
      EmojiCategory(
        name: 'Animals & Nature',
        icon: '🐶',
        emojis: [
          EmojiData(emoji: '🐶', name: 'dog face', keywords: ['dog', 'puppy']),
          EmojiData(emoji: '🐱', name: 'cat face', keywords: ['cat', 'kitten']),
          EmojiData(
            emoji: '🐭',
            name: 'mouse face',
            keywords: ['mouse', 'rodent'],
          ),
          EmojiData(emoji: '🐹', name: 'hamster', keywords: ['hamster', 'pet']),
          EmojiData(
            emoji: '🐰',
            name: 'rabbit face',
            keywords: ['rabbit', 'bunny'],
          ),
          EmojiData(emoji: '🦊', name: 'fox', keywords: ['fox', 'clever']),
          EmojiData(emoji: '🐻', name: 'bear', keywords: ['bear', 'animal']),
          EmojiData(emoji: '🐼', name: 'panda', keywords: ['panda', 'bear']),
          EmojiData(
            emoji: '🐨',
            name: 'koala',
            keywords: ['koala', 'australia'],
          ),
          EmojiData(
            emoji: '🐯',
            name: 'tiger face',
            keywords: ['tiger', 'cat'],
          ),
          EmojiData(emoji: '🦁', name: 'lion', keywords: ['lion', 'king']),
          EmojiData(emoji: '🐮', name: 'cow face', keywords: ['cow', 'moo']),
          EmojiData(emoji: '🐷', name: 'pig face', keywords: ['pig', 'oink']),
          EmojiData(emoji: '🐽', name: 'pig nose', keywords: ['pig', 'nose']),
          EmojiData(emoji: '🐸', name: 'frog', keywords: ['frog', 'ribbit']),
        ],
      ),
      EmojiCategory(
        name: 'Food & Drink',
        icon: '🍕',
        emojis: [
          EmojiData(emoji: '🍕', name: 'pizza', keywords: ['pizza', 'food']),
          EmojiData(
            emoji: '🍔',
            name: 'hamburger',
            keywords: ['burger', 'food'],
          ),
          EmojiData(
            emoji: '🍟',
            name: 'french fries',
            keywords: ['fries', 'chips'],
          ),
          EmojiData(
            emoji: '🌭',
            name: 'hot dog',
            keywords: ['hotdog', 'sausage'],
          ),
          EmojiData(
            emoji: '🥪',
            name: 'sandwich',
            keywords: ['sandwich', 'lunch'],
          ),
          EmojiData(emoji: '🌮', name: 'taco', keywords: ['taco', 'mexican']),
          EmojiData(
            emoji: '🌯',
            name: 'burrito',
            keywords: ['burrito', 'wrap'],
          ),
          EmojiData(
            emoji: '🥗',
            name: 'green salad',
            keywords: ['salad', 'healthy'],
          ),
          EmojiData(
            emoji: '🥘',
            name: 'shallow pan of food',
            keywords: ['cooking', 'paella'],
          ),
          EmojiData(
            emoji: '🍝',
            name: 'spaghetti',
            keywords: ['pasta', 'noodles'],
          ),
          EmojiData(
            emoji: '🍜',
            name: 'steaming bowl',
            keywords: ['ramen', 'noodles'],
          ),
          EmojiData(
            emoji: '🍲',
            name: 'pot of food',
            keywords: ['stew', 'soup'],
          ),
          EmojiData(
            emoji: '🍛',
            name: 'curry rice',
            keywords: ['curry', 'rice'],
          ),
          EmojiData(
            emoji: '🍣',
            name: 'sushi',
            keywords: ['sushi', 'japanese'],
          ),
          EmojiData(
            emoji: '🍱',
            name: 'bento box',
            keywords: ['bento', 'japanese'],
          ),
        ],
      ),
      EmojiCategory(
        name: 'Activity',
        icon: '⚽',
        emojis: [
          EmojiData(
            emoji: '⚽',
            name: 'soccer ball',
            keywords: ['soccer', 'football'],
          ),
          EmojiData(
            emoji: '🏀',
            name: 'basketball',
            keywords: ['basketball', 'sport'],
          ),
          EmojiData(
            emoji: '🏈',
            name: 'american football',
            keywords: ['football', 'american'],
          ),
          EmojiData(
            emoji: '⚾',
            name: 'baseball',
            keywords: ['baseball', 'sport'],
          ),
          EmojiData(
            emoji: '🥎',
            name: 'softball',
            keywords: ['softball', 'sport'],
          ),
          EmojiData(emoji: '🎾', name: 'tennis', keywords: ['tennis', 'sport']),
          EmojiData(
            emoji: '🏐',
            name: 'volleyball',
            keywords: ['volleyball', 'sport'],
          ),
          EmojiData(
            emoji: '🏉',
            name: 'rugby football',
            keywords: ['rugby', 'sport'],
          ),
          EmojiData(
            emoji: '🥏',
            name: 'flying disc',
            keywords: ['frisbee', 'disc'],
          ),
          EmojiData(
            emoji: '🎱',
            name: 'pool 8 ball',
            keywords: ['pool', 'billiards'],
          ),
          EmojiData(emoji: '🪀', name: 'yo-yo', keywords: ['yoyo', 'toy']),
          EmojiData(
            emoji: '🏓',
            name: 'ping pong',
            keywords: ['ping pong', 'table tennis'],
          ),
          EmojiData(
            emoji: '🏸',
            name: 'badminton',
            keywords: ['badminton', 'sport'],
          ),
          EmojiData(emoji: '🥅', name: 'goal net', keywords: ['goal', 'sport']),
          EmojiData(
            emoji: '⛳',
            name: 'flag in hole',
            keywords: ['golf', 'sport'],
          ),
        ],
      ),
      EmojiCategory(
        name: 'Travel & Places',
        icon: '🚗',
        emojis: [
          EmojiData(
            emoji: '🚗',
            name: 'automobile',
            keywords: ['car', 'vehicle'],
          ),
          EmojiData(emoji: '🚕', name: 'taxi', keywords: ['taxi', 'cab']),
          EmojiData(
            emoji: '🚙',
            name: 'sport utility vehicle',
            keywords: ['suv', 'car'],
          ),
          EmojiData(emoji: '🚌', name: 'bus', keywords: ['bus', 'vehicle']),
          EmojiData(
            emoji: '🚎',
            name: 'trolleybus',
            keywords: ['trolley', 'bus'],
          ),
          EmojiData(
            emoji: '🏎️',
            name: 'racing car',
            keywords: ['race', 'car'],
          ),
          EmojiData(
            emoji: '🚓',
            name: 'police car',
            keywords: ['police', 'car'],
          ),
          EmojiData(
            emoji: '🚑',
            name: 'ambulance',
            keywords: ['ambulance', 'medical'],
          ),
          EmojiData(
            emoji: '🚒',
            name: 'fire engine',
            keywords: ['fire', 'truck'],
          ),
          EmojiData(emoji: '🚐', name: 'minibus', keywords: ['van', 'minibus']),
          EmojiData(
            emoji: '🛻',
            name: 'pickup truck',
            keywords: ['truck', 'pickup'],
          ),
          EmojiData(
            emoji: '🚚',
            name: 'delivery truck',
            keywords: ['truck', 'delivery'],
          ),
          EmojiData(
            emoji: '🚛',
            name: 'articulated lorry',
            keywords: ['truck', 'semi'],
          ),
          EmojiData(
            emoji: '🚜',
            name: 'tractor',
            keywords: ['tractor', 'farm'],
          ),
          EmojiData(
            emoji: '🏍️',
            name: 'motorcycle',
            keywords: ['motorcycle', 'bike'],
          ),
        ],
      ),
      EmojiCategory(
        name: 'Objects',
        icon: '💡',
        emojis: [
          EmojiData(
            emoji: '💡',
            name: 'light bulb',
            keywords: ['idea', 'light'],
          ),
          EmojiData(
            emoji: '🔦',
            name: 'flashlight',
            keywords: ['flashlight', 'torch'],
          ),
          EmojiData(
            emoji: '🕯️',
            name: 'candle',
            keywords: ['candle', 'light'],
          ),
          EmojiData(emoji: '🪔', name: 'diya lamp', keywords: ['lamp', 'oil']),
          EmojiData(
            emoji: '🏮',
            name: 'red paper lantern',
            keywords: ['lantern', 'chinese'],
          ),
          EmojiData(emoji: '🪅', name: 'piñata', keywords: ['pinata', 'party']),
          EmojiData(
            emoji: '🎊',
            name: 'confetti ball',
            keywords: ['confetti', 'party'],
          ),
          EmojiData(
            emoji: '🎉',
            name: 'party popper',
            keywords: ['party', 'celebration'],
          ),
          EmojiData(
            emoji: '🎈',
            name: 'balloon',
            keywords: ['balloon', 'party'],
          ),
          EmojiData(
            emoji: '🎁',
            name: 'wrapped gift',
            keywords: ['gift', 'present'],
          ),
          EmojiData(emoji: '🎀', name: 'ribbon', keywords: ['ribbon', 'bow']),
          EmojiData(
            emoji: '🎗️',
            name: 'reminder ribbon',
            keywords: ['ribbon', 'awareness'],
          ),
          EmojiData(
            emoji: '🎟️',
            name: 'admission tickets',
            keywords: ['ticket', 'event'],
          ),
          EmojiData(
            emoji: '🎫',
            name: 'ticket',
            keywords: ['ticket', 'admission'],
          ),
          EmojiData(
            emoji: '🎖️',
            name: 'military medal',
            keywords: ['medal', 'award'],
          ),
        ],
      ),
      EmojiCategory(
        name: 'Symbols',
        icon: '❤️',
        emojis: [
          EmojiData(
            emoji: '❤️',
            name: 'red heart',
            keywords: ['love', 'heart'],
          ),
          EmojiData(
            emoji: '🧡',
            name: 'orange heart',
            keywords: ['love', 'heart'],
          ),
          EmojiData(
            emoji: '💛',
            name: 'yellow heart',
            keywords: ['love', 'heart'],
          ),
          EmojiData(
            emoji: '💚',
            name: 'green heart',
            keywords: ['love', 'heart'],
          ),
          EmojiData(
            emoji: '💙',
            name: 'blue heart',
            keywords: ['love', 'heart'],
          ),
          EmojiData(
            emoji: '💜',
            name: 'purple heart',
            keywords: ['love', 'heart'],
          ),
          EmojiData(
            emoji: '🖤',
            name: 'black heart',
            keywords: ['love', 'heart'],
          ),
          EmojiData(
            emoji: '🤍',
            name: 'white heart',
            keywords: ['love', 'heart'],
          ),
          EmojiData(
            emoji: '🤎',
            name: 'brown heart',
            keywords: ['love', 'heart'],
          ),
          EmojiData(
            emoji: '💔',
            name: 'broken heart',
            keywords: ['heartbreak', 'sad'],
          ),
          EmojiData(
            emoji: '❣️',
            name: 'heart exclamation',
            keywords: ['love', 'exclamation'],
          ),
          EmojiData(
            emoji: '💕',
            name: 'two hearts',
            keywords: ['love', 'hearts'],
          ),
          EmojiData(
            emoji: '💞',
            name: 'revolving hearts',
            keywords: ['love', 'hearts'],
          ),
          EmojiData(
            emoji: '💓',
            name: 'beating heart',
            keywords: ['love', 'heartbeat'],
          ),
          EmojiData(
            emoji: '💗',
            name: 'growing heart',
            keywords: ['love', 'growing'],
          ),
        ],
      ),
    ];
  }
}

class EmojiCategory {
  final String name;
  final String icon;
  final List<EmojiData> emojis;

  EmojiCategory({required this.name, required this.icon, required this.emojis});

  factory EmojiCategory.fromJson(Map<String, dynamic> json) {
    return EmojiCategory(
      name: json['name'],
      icon: json['icon'],
      emojis: (json['emojis'] as List)
          .map((e) => EmojiData.fromJson(e))
          .toList(),
    );
  }
}

class EmojiData {
  final String emoji;
  final String name;
  final List<String> keywords;

  EmojiData({required this.emoji, required this.name, required this.keywords});

  factory EmojiData.fromJson(Map<String, dynamic> json) {
    return EmojiData(
      emoji: json['emoji'],
      name: json['name'],
      keywords: List<String>.from(json['keywords'] ?? []),
    );
  }
}

// Compact emoji picker for quick access
class CompactEmojiPicker extends ConsumerWidget {
  final ValueChanged<String> onEmojiSelected;
  final int maxRecentEmojis;

  const CompactEmojiPicker({
    super.key,
    required this.onEmojiSelected,
    this.maxRecentEmojis = 8,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          // Recent emojis
          Expanded(
            child: FutureBuilder<List<String>>(
              future: _getRecentEmojis(),
              builder: (context, snapshot) {
                final recentEmojis = snapshot.data ?? [];

                if (recentEmojis.isEmpty) {
                  return _buildDefaultEmojis();
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentEmojis.length,
                  itemBuilder: (context, index) {
                    return _buildEmojiButton(recentEmojis[index]);
                  },
                );
              },
            ),
          ),

          // Full picker button
          ShadButton.ghost(
            onPressed: () => _showFullPicker(context),
            size: ShadButtonSize.sm,
            child: const Icon(Icons.emoji_emotions, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultEmojis() {
    const defaultEmojis = ['😀', '😂', '😍', '🥰', '😘', '👍', '❤️', '🔥'];

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: defaultEmojis.length,
      itemBuilder: (context, index) {
        return _buildEmojiButton(defaultEmojis[index]);
      },
    );
  }

  Widget _buildEmojiButton(String emoji) {
    return ShadButton.ghost(
      onPressed: () => onEmojiSelected(emoji),
      size: ShadButtonSize.sm,
      child: Text(emoji, style: const TextStyle(fontSize: 20)),
    );
  }

  Future<List<String>> _getRecentEmojis() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentEmojisJson = prefs.getString('recent_emojis');

      if (recentEmojisJson != null) {
        final List<dynamic> recentList = json.decode(recentEmojisJson);
        return recentList.cast<String>().take(maxRecentEmojis).toList();
      }
    } catch (e) {
      // Handle error silently
    }
    return [];
  }

  void _showFullPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: EmojiPickerWidget(
                onEmojiSelected: (emoji) {
                  onEmojiSelected(emoji);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
