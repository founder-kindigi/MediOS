import 'package:flutter/material.dart';

/// A paginated ListView that automatically loads more items when scrolling.
///
/// This widget handles:
/// - Loading indicator when fetching more data
/// - Error display and retry functionality
/// - Scroll detection for infinite scrolling
/// - Empty state display
class PaginatedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final VoidCallback? onRefresh;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final ScrollController? scrollController;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Axis scrollDirection;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final double? cacheExtent;

  const PaginatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.onLoadMore,
    this.onRefresh,
    this.emptyWidget,
    this.errorWidget,
    this.errorMessage,
    this.onRetry,
    this.scrollController,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.scrollDirection = Axis.vertical,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.cacheExtent = 500.0,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  late ScrollController _scrollController;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (_isScrolling) return;
    
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _isScrolling = true;
      
      // Load more items if available
      if (widget.hasMore && !widget.isLoadingMore && !widget.isLoading) {
        widget.onLoadMore();
      }
      
      // Reset scrolling flag after a delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _isScrolling = false;
      });
    }
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) return widget.errorWidget!;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            widget.errorMessage ?? 'Failed to load items',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          if (widget.onRetry != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: widget.onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    if (widget.emptyWidget != null) return widget.emptyWidget!;
    
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No items found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator for initial load
    if (widget.isLoading && widget.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show error for initial load
    if (widget.errorMessage != null && widget.items.isEmpty) {
      return _buildErrorWidget();
    }

    // Show empty state
    if (widget.items.isEmpty) {
      return _buildEmptyWidget();
    }

    // Build the list with pagination support
    final itemCount = widget.items.length + (widget.hasMore ? 1 : 0);
    
    Widget listView = ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      scrollDirection: widget.scrollDirection,
      itemCount: itemCount,
      addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
      addRepaintBoundaries: widget.addRepaintBoundaries,
      cacheExtent: widget.cacheExtent,
      itemBuilder: (context, index) {
        // Loading more indicator at the end
        if (widget.hasMore && index == widget.items.length) {
          return _buildLoadingIndicator();
        }
        
        // Regular item
        return widget.itemBuilder(context, widget.items[index], index);
      },
    );

    // Add pull-to-refresh if provided
    if (widget.onRefresh != null) {
      listView = RefreshIndicator(
        onRefresh: () async => widget.onRefresh!(),
        child: listView,
      );
    }

    return listView;
  }
}

/// A builder widget for paginated lists that handles loading states.
class PaginatedListBuilder<T> extends StatelessWidget {
  final List<T> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final Widget Function(BuildContext, List<T>) builder;
  final Widget? loadingWidget;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  final String? errorMessage;

  const PaginatedListBuilder({
    super.key,
    required this.items,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.onLoadMore,
    required this.builder,
    this.loadingWidget,
    this.emptyWidget,
    this.errorWidget,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    // Initial loading
    if (isLoading && items.isEmpty) {
      return loadingWidget ??
          const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (errorMessage != null && items.isEmpty) {
      return errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          );
    }

    // Empty state
    if (items.isEmpty) {
      return emptyWidget ??
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No items found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
    }

    // Build the list with loading more detection
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification.metrics.pixels >=
                scrollNotification.metrics.maxScrollExtent - 200 &&
            hasMore &&
            !isLoadingMore) {
          onLoadMore();
        }
        return false;
      },
      child: builder(context, items),
    );
  }
}