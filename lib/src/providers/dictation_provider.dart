import 'package:dication/src/core/models/text_model.dart';
import 'package:dication/src/core/services/pocketbase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DictationListState {
  final List<TextModel> items;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;
  final bool isInitialLoading;
  final String? error;

  const DictationListState({
    this.items = const [],
    this.currentPage = 0,
    this.totalPages = 1,
    this.isLoadingMore = false,
    this.isInitialLoading = true,
    this.error,
  });

  bool get hasMore => currentPage < totalPages;

  DictationListState copyWith({
    List<TextModel>? items,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
    bool? isInitialLoading,
    String? error,
  }) {
    return DictationListState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      error: error,
    );
  }
}

class DictationListNotifier extends StateNotifier<DictationListState> {
  DictationListNotifier() : super(const DictationListState()) {
    fetchNextPage();
  }

  Future<void> fetchNextPage() async {
    if (state.isLoadingMore || (!state.isInitialLoading && !state.hasMore)) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final result = await PocketBaseService.fetchDictations(page: nextPage);

      state = state.copyWith(
        items: [...state.items, ...result.items],
        currentPage: nextPage,
        totalPages: result.totalPages,
        isLoadingMore: false,
        isInitialLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        isInitialLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    state = const DictationListState();
    await fetchNextPage();
  }
}

final dictationProvider =
    StateNotifierProvider<DictationListNotifier, DictationListState>(
  (ref) => DictationListNotifier(),
);
