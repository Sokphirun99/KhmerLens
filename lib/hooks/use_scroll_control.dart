import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// A hook that manages a ScrollController and provides:
/// 1. FAB visibility state based on scroll direction
/// 2. Pagination callback triggering when near bottom
///
/// Returns a record: `(ScrollController, bool isFabExtended)`
(ScrollController, bool) useScrollControl({
  required VoidCallback onLoadMore,
  required bool canLoadMore,
  double loadMoreThreshold = 200.0,
}) {
  final scrollController = useScrollController();
  final isFabExtended = useState(true);
  final lastScrollOffset = useRef(0.0);
  final isMounted = useIsMounted();

  useEffect(() {
    void onScroll() {
      if (!scrollController.hasClients) return;

      final currentOffset = scrollController.offset;
      final scrollDelta = currentOffset - lastScrollOffset.value;

      // 1. Handle FAB visibility
      // Only trigger state change if scroll delta is significant (avoid jitter)
      if (scrollDelta.abs() > 5) {
        final shouldExtend = scrollDelta < 0 || currentOffset <= 0;
        if (isFabExtended.value != shouldExtend && isMounted()) {
          isFabExtended.value = shouldExtend;
        }
        lastScrollOffset.value = currentOffset;
      }

      // 2. Handle Pagination
      // Load more when near bottom
      final maxScroll = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.position.pixels;

      if (maxScroll - currentScroll <= loadMoreThreshold) {
        if (canLoadMore) {
          onLoadMore();
        }
      }
    }

    scrollController.addListener(onScroll);
    return () => scrollController.removeListener(onScroll);
  }, [scrollController, canLoadMore, onLoadMore, loadMoreThreshold]);

  return (scrollController, isFabExtended.value);
}
