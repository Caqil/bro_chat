import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../services/storage/local_storage.dart';
import '../../services/api/api_service.dart';

enum LanguageCode {
  en,
  es,
  fr,
  de,
  it,
  pt,
  ru,
  ja,
  ko,
  zh,
  ar,
  hi,
  tr,
  nl,
  sv,
  pl,
  cs,
  da,
  fi,
  no,
  he,
  th,
  vi,
  id,
  ms,
  tl,
  uk,
  bg,
  hr,
  sk,
  sl,
  et,
  lv,
  lt,
  mt,
  hu,
  ro,
  el,
  ca,
  eu,
  gl,
  cy,
  ga,
  mk,
  sq,
  sr,
  bs,
  me,
  fa,
  ur,
  bn,
  ta,
  te,
  mr,
  gu,
  kn,
  ml,
  or,
  pa,
  as,
  ne,
  si,
  my,
  km,
  lo,
  ka,
  am,
  sw,
  zu,
  af,
  xh,
  st,
  tn,
  ts,
  ss,
  ve,
  nr,
}

class LanguageInfo {
  final LanguageCode code;
  final String name;
  final String nativeName;
  final String flag;
  final bool isRTL;
  final List<String> supportedRegions;
  final double completionPercentage;
  final DateTime? lastUpdated;

  const LanguageInfo({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    this.isRTL = false,
    this.supportedRegions = const [],
    this.completionPercentage = 100.0,
    this.lastUpdated,
  });

  Locale get locale => Locale(code.name);
  
  bool get isFullyTranslated => completionPercentage >= 95.0;
  bool get needsTranslation => completionPercentage < 100.0;

  Map<String, dynamic> toJson() {
    return {
      'code': code.name,
      'name': name,
      'native_name': nativeName,
      'flag': flag,
      'is_rtl': isRTL,
      'supported_regions': supportedRegions,
      'completion_percentage': completionPercentage,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  factory LanguageInfo.fromJson(Map<String, dynamic> json) {
    return LanguageInfo(
      code: LanguageCode.values.firstWhere(
        (code) => code.name == json['code'],
        orElse: () => LanguageCode.en,
      ),
      name: json['name'] ?? '',
      nativeName: json['native_name'] ?? '',
      flag: json['flag'] ?? '',
      isRTL: json['is_rtl'] ?? false,
      supportedRegions: List<String>.from(json['supported_regions'] ?? []),
      completionPercentage: (json['completion_percentage'] ?? 100.0).toDouble(),
      lastUpdated: json['last_updated'] != null
          ? DateTime.tryParse(json['last_updated'])
          : null,
    );
  }
}

class LanguageState {
  final LanguageInfo currentLanguage;
  final List<LanguageInfo> availableLanguages;
  final bool isLoading;
  final bool isChanging;
  final String? error;
  final bool isInitialized;
  final bool isAutoDetectEnabled;
  final LanguageInfo? detectedLanguage;
  final DateTime? lastUpdate;
  final Map<String, String> customTranslations;

  LanguageState({
    LanguageInfo? currentLanguage,
    this.availableLanguages = const [],
    this.isLoading = false,
    this.isChanging = false,
    this.error,
    this.isInitialized = false,
    this.isAutoDetectEnabled = true,
    this.detectedLanguage,
    this.lastUpdate,
    this.customTranslations = const {},
  }) : currentLanguage = currentLanguage ?? _defaultLanguage;

  static const LanguageInfo _defaultLanguage = LanguageInfo(
    code: LanguageCode.en,
    name: 'English',
    nativeName: 'English',
    flag: '🇺🇸',
  );

  LanguageState copyWith({
    LanguageInfo? currentLanguage,
    List<LanguageInfo>? availableLanguages,
    bool? isLoading,
    bool? isChanging,
    String? error,
    bool? isInitialized,
    bool? isAutoDetectEnabled,
    LanguageInfo? detectedLanguage,
    DateTime? lastUpdate,
    Map<String, String>? customTranslations,
  }) {
    return LanguageState(
      currentLanguage: currentLanguage ?? this.currentLanguage,
      availableLanguages: availableLanguages ?? this.availableLanguages,
      isLoading: isLoading ?? this.isLoading,
      isChanging: isChanging ?? this.isChanging,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
      isAutoDetectEnabled: isAutoDetectEnabled ?? this.isAutoDetectEnabled,
      detectedLanguage: detectedLanguage ?? this.detectedLanguage,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      customTranslations: customTranslations ?? this.customTranslations,
    );
  }

  LanguageInfo? getLanguage(LanguageCode code) {
    try {
      return availableLanguages.firstWhere((lang) => lang.code == code);
    } catch (e) {
      return null;
    }
  }

  List<LanguageInfo> get popularLanguages {
    final popular = [
      LanguageCode.en,
      LanguageCode.es,
      LanguageCode.fr,
      LanguageCode.de,
      LanguageCode.it,
      LanguageCode.pt,
      LanguageCode.ru,
      LanguageCode.ja,
      LanguageCode.ko,
      LanguageCode.zh,
      LanguageCode.ar,
      LanguageCode.hi,
    ];

    return availableLanguages
        .where((lang) => popular.contains(lang.code))
        .toList();
  }

  List<LanguageInfo> get fullyTranslatedLanguages {
    return availableLanguages.where((lang) => lang.isFullyTranslated).toList();
  }

  List<LanguageInfo> get rtlLanguages {
    return availableLanguages.where((lang) => lang.isRTL).toList();
  }

  bool get isCurrentLanguageRTL => currentLanguage.isRTL;
  Locale get currentLocale => currentLanguage.locale;
  TextDirection get textDirection => isCurrentLanguageRTL ? TextDirection.rtl : TextDirection.ltr;
}

class LanguageNotifier extends StateNotifier<AsyncValue<LanguageState>> {
  final LocalStorage _localStorage;
  final ApiService _apiService;

  Timer? _detectionTimer;
  static const Duration _detectionDelay = Duration(milliseconds: 500);

  LanguageNotifier({
    required LocalStorage localStorage,
    required ApiService apiService,
  }) : _localStorage = localStorage,
       _apiService = apiService,
       super(AsyncValue.data(LanguageState())) {
    _initialize();
  }

  void _initialize() async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));

    try {
      await _loadAvailableLanguages();
      await _loadCurrentLanguage();
      await _loadCustomTranslations();
      
      if (state.value!.isAutoDetectEnabled) {
        await _detectSystemLanguage();
      }

      state = AsyncValue.data(
        state.value!.copyWith(
          isLoading: false,
          isInitialized: true,
          lastUpdate: DateTime.now(),
        ),
      );

      if (kDebugMode) print('✅ Language provider initialized');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      if (kDebugMode) print('❌ Error initializing language provider: $e');
    }
  }

  Future<void> _loadAvailableLanguages() async {
    try {
      // Load from cache first
      final cachedLanguages = await _loadLanguagesFromCache();
      
      if (cachedLanguages.isNotEmpty) {
        state = AsyncValue.data(
          state.value!.copyWith(availableLanguages: cachedLanguages),
        );
      }

      // Load from API or use default list
      await _loadLanguagesFromAPI();
    } catch (e) {
      if (kDebugMode) print('❌ Error loading available languages: $e');
      // Use default languages if loading fails
      _setDefaultLanguages();
    }
  }

  Future<List<LanguageInfo>> _loadLanguagesFromCache() async {
    try {
      final cachedData = _localStorage.getStringList('cached_languages') ?? [];
      return cachedData
          .map((data) => LanguageInfo.fromJson(Map<String, dynamic>.from({})))
          .toList();
    } catch (e) {
      if (kDebugMode) print('❌ Error loading languages from cache: $e');
      return [];
    }
  }

  Future<void> _loadLanguagesFromAPI() async {
    try {
      final response = await _apiService.getAvailableLanguages();
      
      if (response.success && response.data != null) {
        final languages = (response.data as List)
            .map((data) => LanguageInfo.fromJson(data))
            .toList();

        state = AsyncValue.data(
          state.value!.copyWith(availableLanguages: languages),
        );

        await _cacheLanguages(languages);
        if (kDebugMode) print('✅ Loaded ${languages.length} languages from API');
      } else {
        _setDefaultLanguages();
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error loading languages from API: $e');
      _setDefaultLanguages();
    }
  }

  void _setDefaultLanguages() {
    final defaultLanguages = [
      const LanguageInfo(
        code: LanguageCode.en,
        name: 'English',
        nativeName: 'English',
        flag: '🇺🇸',
      ),
      const LanguageInfo(
        code: LanguageCode.es,
        name: 'Spanish',
        nativeName: 'Español',
        flag: '🇪🇸',
      ),
      const LanguageInfo(
        code: LanguageCode.fr,
        name: 'French',
        nativeName: 'Français',
        flag: '🇫🇷',
      ),
      const LanguageInfo(
        code: LanguageCode.de,
        name: 'German',
        nativeName: 'Deutsch',
        flag: '🇩🇪',
      ),
      const LanguageInfo(
        code: LanguageCode.it,
        name: 'Italian',
        nativeName: 'Italiano',
        flag: '🇮🇹',
      ),
      const LanguageInfo(
        code: LanguageCode.pt,
        name: 'Portuguese',
        nativeName: 'Português',
        flag: '🇵🇹',
      ),
      const LanguageInfo(
        code: LanguageCode.ru,
        name: 'Russian',
        nativeName: 'Русский',
        flag: '🇷🇺',
      ),
      const LanguageInfo(
        code: LanguageCode.ja,
        name: 'Japanese',
        nativeName: '日本語',
        flag: '🇯🇵',
      ),
      const LanguageInfo(
        code: LanguageCode.ko,
        name: 'Korean',
        nativeName: '한국어',
        flag: '🇰🇷',
      ),
      const LanguageInfo(
        code: LanguageCode.zh,
        name: 'Chinese',
        nativeName: '中文',
        flag: '🇨🇳',
      ),
      const LanguageInfo(
        code: LanguageCode.ar,
        name: 'Arabic',
        nativeName: 'العربية',
        flag: '🇸🇦',
        isRTL: true,
      ),
      const LanguageInfo(
        code: LanguageCode.hi,
        name: 'Hindi',
        nativeName: 'हिन्दी',
        flag: '🇮🇳',
      ),
      const LanguageInfo(
        code: LanguageCode.tr,
        name: 'Turkish',
        nativeName: 'Türkçe',
        flag: '🇹🇷',
      ),
      const LanguageInfo(
        code: LanguageCode.nl,
        name: 'Dutch',
        nativeName: 'Nederlands',
        flag: '🇳🇱',
      ),
      const LanguageInfo(
        code: LanguageCode.sv,
        name: 'Swedish',
        nativeName: 'Svenska',
        flag: '🇸🇪',
      ),
      const LanguageInfo(
        code: LanguageCode.id,
        name: 'Indonesian',
        nativeName: 'Bahasa Indonesia',
        flag: '🇮🇩',
      ),
    ];

    state = AsyncValue.data(
      state.value!.copyWith(availableLanguages: defaultLanguages),
    );
  }

  Future<void> _loadCurrentLanguage() async {
    try {
      final savedLanguageCode = _localStorage.getString('current_language');
      
      if (savedLanguageCode != null) {
        final languageCode = LanguageCode.values.firstWhere(
          (code) => code.name == savedLanguageCode,
          orElse: () => LanguageCode.en,
        );

        final language = state.value!.getLanguage(languageCode);
        if (language != null) {
          state = AsyncValue.data(
            state.value!.copyWith(currentLanguage: language),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error loading current language: $e');
    }
  }

  Future<void> _loadCustomTranslations() async {
    try {
      final customTranslations = _localStorage.getMap('custom_translations') ?? {};
      
      state = AsyncValue.data(
        state.value!.copyWith(
          customTranslations: Map<String, String>.from(customTranslations),
        ),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Error loading custom translations: $e');
    }
  }

  Future<void> _detectSystemLanguage() async {
    try {
      final systemLocale = ui.window.locale;
      final detectedCode = LanguageCode.values.firstWhere(
        (code) => code.name == systemLocale.languageCode,
        orElse: () => LanguageCode.en,
      );

      final detectedLanguage = state.value!.getLanguage(detectedCode);
      if (detectedLanguage != null) {
        state = AsyncValue.data(
          state.value!.copyWith(detectedLanguage: detectedLanguage),
        );

        // Auto-switch if user hasn't manually selected a language
        final hasManualSelection = _localStorage.getBool('manual_language_selection') ?? false;
        if (!hasManualSelection && detectedLanguage.code != state.value!.currentLanguage.code) {
          await changeLanguage(detectedLanguage.code, autoDetected: true);
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error detecting system language: $e');
    }
  }

  // Public methods
  Future<void> changeLanguage(LanguageCode code, {bool autoDetected = false}) async {
    try {
      final language = state.value!.getLanguage(code);
      if (language == null) {
        throw Exception('Language not available: ${code.name}');
      }

      state = AsyncValue.data(state.value!.copyWith(isChanging: true));

      // Update state
      state = AsyncValue.data(
        state.value!.copyWith(
          currentLanguage: language,
          isChanging: false,
          lastUpdate: DateTime.now(),
        ),
      );

      // Save to storage
      await _localStorage.setString('current_language', code.name);
      
      if (!autoDetected) {
        await _localStorage.setBool('manual_language_selection', true);
      }

      // Sync with server
      await _syncLanguageWithServer(code);

      if (kDebugMode) {
        print('✅ Language changed to: ${language.name} (${code.name})');
      }
    } catch (e) {
      state = AsyncValue.data(
        state.value!.copyWith(isChanging: false, error: e.toString()),
      );
      if (kDebugMode) print('❌ Error changing language: $e');
      rethrow;
    }
  }

  Future<void> _syncLanguageWithServer(LanguageCode code) async {
    try {
      await _apiService.updateUserLanguage(code.name);
    } catch (e) {
      if (kDebugMode) print('❌ Error syncing language with server: $e');
      // Don't throw error as this is not critical
    }
  }

  Future<void> toggleAutoDetect(bool enabled) async {
    try {
      await _localStorage.setBool('auto_detect_language', enabled);
      
      state = AsyncValue.data(
        state.value!.copyWith(isAutoDetectEnabled: enabled),
      );

      if (enabled) {
        await _detectSystemLanguage();
      }

      if (kDebugMode) print('✅ Auto-detect ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      if (kDebugMode) print('❌ Error toggling auto-detect: $e');
      rethrow;
    }
  }

  Future<void> addCustomTranslation(String key, String translation) async {
    try {
      final currentTranslations = Map<String, String>.from(
        state.value!.customTranslations,
      );
      currentTranslations[key] = translation;

      await _localStorage.setMap('custom_translations', currentTranslations);
      
      state = AsyncValue.data(
        state.value!.copyWith(customTranslations: currentTranslations),
      );

      if (kDebugMode) print('✅ Custom translation added: $key -> $translation');
    } catch (e) {
      if (kDebugMode) print('❌ Error adding custom translation: $e');
      rethrow;
    }
  }

  Future<void> removeCustomTranslation(String key) async {
    try {
      final currentTranslations = Map<String, String>.from(
        state.value!.customTranslations,
      );
      currentTranslations.remove(key);

      await _localStorage.setMap('custom_translations', currentTranslations);
      
      state = AsyncValue.data(
        state.value!.copyWith(customTranslations: currentTranslations),
      );

      if (kDebugMode) print('✅ Custom translation removed: $key');
    } catch (e) {
      if (kDebugMode) print('❌ Error removing custom translation: $e');
      rethrow;
    }
  }

  Future<void> clearCustomTranslations() async {
    try {
      await _localStorage.remove('custom_translations');
      
      state = AsyncValue.data(
        state.value!.copyWith(customTranslations: {}),
      );

      if (kDebugMode) print('✅ Custom translations cleared');
    } catch (e) {
      if (kDebugMode) print('❌ Error clearing custom translations: $e');
      rethrow;
    }
  }

  String translate(String key, {Map<String, String>? params}) {
    final customTranslation = state.value?.customTranslations[key];
    if (customTranslation != null) {
      return _replaceParams(customTranslation, params);
    }

    // TODO: Implement actual translation logic here
    // This would typically load translations from assets or API
    return _replaceParams(key, params);
  }

  String _replaceParams(String text, Map<String, String>? params) {
    if (params == null) return text;
    
    String result = text;
    for (final entry in params.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }

  Future<void> refreshLanguages() async {
    await _loadLanguagesFromAPI();
  }

  Future<void> _cacheLanguages(List<LanguageInfo> languages) async {
    try {
      final languageData = languages.map((lang) => lang.toJson()).toList();
      await _localStorage.setStringList(
        'cached_languages',
        languageData.map((data) => data.toString()).toList(),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Error caching languages: $e');
    }
  }

  // Utility methods
  bool isLanguageSupported(LanguageCode code) {
    return state.value?.getLanguage(code) != null;
  }

  LanguageInfo? getLanguageInfo(LanguageCode code) {
    return state.value?.getLanguage(code);
  }

  List<LanguageInfo> searchLanguages(String query) {
    if (query.isEmpty) return availableLanguages;
    
    final lowercaseQuery = query.toLowerCase();
    return availableLanguages.where((lang) {
      return lang.name.toLowerCase().contains(lowercaseQuery) ||
             lang.nativeName.toLowerCase().contains(lowercaseQuery) ||
             lang.code.name.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  Future<void> reportTranslationIssue(String key, String issue) async {
    try {
      await _apiService.reportTranslationIssue(
        languageCode: currentLanguage.code.name,
        translationKey: key,
        issue: issue,
      );

      if (kDebugMode) print('✅ Translation issue reported');
    } catch (e) {
      if (kDebugMode) print('❌ Error reporting translation issue: $e');
      rethrow;
    }
  }

  Future<void> contributeTranslation(String key, String translation) async {
    try {
      await _apiService.contributeTranslation(
        languageCode: currentLanguage.code.name,
        translationKey: key,
        translation: translation,
      );

      if (kDebugMode) print('✅ Translation contributed');
    } catch (e) {
      if (kDebugMode) print('❌ Error contributing translation: $e');
      rethrow;
    }
  }

  // Getters
  LanguageInfo get currentLanguage => state.value?.currentLanguage ?? LanguageState().currentLanguage;
  List<LanguageInfo> get availableLanguages => state.value?.availableLanguages ?? [];
  List<LanguageInfo> get popularLanguages => state.value?.popularLanguages ?? [];
  bool get isLoading => state.value?.isLoading ?? false;
  bool get isChanging => state.value?.isChanging ?? false;
  bool get isAutoDetectEnabled => state.value?.isAutoDetectEnabled ?? true;
  bool get isCurrentLanguageRTL => state.value?.isCurrentLanguageRTL ?? false;
  Locale get currentLocale => state.value?.currentLocale ?? const Locale('en');
  TextDirection get textDirection => state.value?.textDirection ?? TextDirection.ltr;
  Map<String, String> get customTranslations => state.value?.customTranslations ?? {};

  @override
  void dispose() {
    _detectionTimer?.cancel();
    super.dispose();
  }
}

// Providers
final languageProvider = StateNotifierProvider<LanguageNotifier, AsyncValue<LanguageState>>((ref) {
  return LanguageNotifier(
    localStorage: LocalStorage(),
    apiService: ref.watch(apiServiceProvider),
  );
});

// Convenience providers
final currentLanguageProvider = Provider<LanguageInfo>((ref) {
  final languageState = ref.watch(languageProvider);
  return languageState.whenOrNull(data: (state) => state.currentLanguage) ??
      const LanguageInfo(
        code: LanguageCode.en,
        name: 'English',
        nativeName: 'English',
        flag: '🇺🇸',
      );
});

final availableLanguagesProvider = Provider<List<LanguageInfo>>((ref) {
  final languageState = ref.watch(languageProvider);
  return languageState.whenOrNull(data: (state) => state.availableLanguages) ?? [];
});

final popularLanguagesProvider = Provider<List<LanguageInfo>>((ref) {
  final languageState = ref.watch(languageProvider);
  return languageState.whenOrNull(data: (state) => state.popularLanguages) ?? [];
});

final currentLocaleProvider = Provider<Locale>((ref) {
  final currentLanguage = ref.watch(currentLanguageProvider);
  return currentLanguage.locale;
});

final textDirectionProvider = Provider<TextDirection>((ref) {
  final languageState = ref.watch(languageProvider);
  return languageState.whenOrNull(data: (state) => state.textDirection) ?? TextDirection.ltr;
});

final isRTLProvider = Provider<bool>((ref) {
  final languageState = ref.watch(languageProvider);
  return languageState.whenOrNull(data: (state) => state.isCurrentLanguageRTL) ?? false;
});

final languageLoadingProvider = Provider<bool>((ref) {
  final languageState = ref.watch(languageProvider);
  return languageState.whenOrNull(data: (state) => state.isLoading) ?? false;
});

final languageChangingProvider = Provider<bool>((ref) {
  final languageState = ref.watch(languageProvider);
  return languageState.whenOrNull(data: (state) => state.isChanging) ?? false;
});

final autoDetectEnabledProvider = Provider<bool>((ref) {
  final languageState = ref.watch(languageProvider);
  return languageState.whenOrNull(data: (state) => state.isAutoDetectEnabled) ?? true;
});

final detectedLanguageProvider = Provider<LanguageInfo?>((ref) {
  final languageState = ref.watch(languageProvider);
  return languageState.whenOrNull(data: (state) => state.detectedLanguage);
});

final customTranslationsProvider = Provider<Map<String, String>>((ref) {
  final languageState = ref.watch(languageProvider);
  return languageState.whenOrNull(data: (state) => state.customTranslations) ?? {};
});

final languageByCodeProvider = Provider.family<LanguageInfo?, LanguageCode>((ref, code) {
  final languageState = ref.watch(languageProvider);
  return languageState.whenOrNull(data: (state) => state.getLanguage(code));
});

// Translation provider
final translationProvider = Provider.family<String, String>((ref, key) {
  final notifier = ref.watch(languageProvider.notifier);
  return notifier.translate(key);
});

final translationWithParamsProvider = Provider.family<String, (String, Map<String, String>)>((ref, params) {
  final notifier = ref.watch(languageProvider.notifier);
  return notifier.translate(params.$1, params: params.$2);
});