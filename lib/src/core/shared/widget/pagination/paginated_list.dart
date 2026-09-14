// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:pagination_pkg/pagination_pkg.dart';

// import '../../../localization/app_localizations.dart';

// class PaginatedListWidget<K, T> extends StatefulWidget {
//   final PaginationEngine<K, T> pagination;
//   final Axis scrollDirection;
//   final Widget skeleton;
//   final bool isPaginated;

//   /// How many skeletons to show, when there is no data
//   final int skeletonCount;
//   final String emptyMessage;
//   final String errorMessage;
//   final Widget Function(int index, T data) builder;
//   const PaginatedListWidget({
//     super.key,
//     required this.pagination,
//     required this.skeleton,
//     required this.skeletonCount,
//     required this.builder,
//     this.emptyMessage = "No data found",
//     this.errorMessage = "Something went wrong",
//     required this.scrollDirection,
//     required this.isPaginated,
//   });

//   @override
//   State<PaginatedListWidget<K, T>> createState() => _PaginatedListWidgetState<K, T>();
// }

// class _PaginatedListWidgetState<K, T> extends State<PaginatedListWidget<K, T>> {
//   final ScrollController scrollController = ScrollController();

//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();

//     if (widget.isPaginated) {
//       scrollController.addListener(() {
//         // When scrolled to the bottom, load next page
//         if (scrollController.position.pixels ==
//             scrollController.position.maxScrollExtent) {
//           widget.pagination.loadNextPage();
//         }

//         // When scrolled to the top, load previous page
//         if (scrollController.position.pixels ==
//             scrollController.position.minScrollExtent) {
//           widget.pagination.loadPreviousPage();
//         }
//       });
//     }
//   }

//   @override
//   void dispose() {
//     // TODO: implement dispose
//     super.dispose();
//     scrollController.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return RefreshIndicator(
//       onRefresh: () async {
//         widget.pagination.refresh();
//       },
//       child: ListenableBuilder(
//         listenable: widget.pagination,
//         builder: (context, _) {
//           final state = widget.pagination.state.value;

//           if (state == PaginationLoadState.nopages) {
//             return CustomScrollView(
//               controller: scrollController,
//               scrollDirection: widget.scrollDirection,
//               slivers: [
//                 SliverFillRemaining(
//                   hasScrollBody: false,
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Center(child: Text(widget.emptyMessage.tr(context))),
//                       IconButton(
//                         onPressed: widget.pagination.refresh,
//                         icon: const Icon(Icons.refresh),
//                       ),
//                     ],
//                   ).animate().fadeIn(duration: 300.ms),
//                 ),
//               ],
//             );
//           }

//           if (state == PaginationLoadState.error &&
//               widget.pagination.totalItemsCount == 0) {
//             return CustomScrollView(
//               controller: scrollController,
//               scrollDirection: widget.scrollDirection,
//               slivers: [
//                 SliverFillRemaining(
//                   hasScrollBody: false,
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Center(child: Text(widget.errorMessage.tr(context))),
//                       IconButton(
//                         onPressed: widget.pagination.refresh,
//                         icon: const Icon(Icons.refresh),
//                       ),
//                     ],
//                   ).animate().fadeIn(duration: 300.ms),
//                 ),
//               ],
//             );
//           }

//           if (state == PaginationLoadState.idle) {
//             return CustomScrollView(
//               controller: scrollController,
//               slivers: [
//                 SliverFillRemaining(
//                   hasScrollBody: false,
//                   child: Center(
//                     child: Text("Pull to refresh!".tr(context)),
//                   ).animate().fadeIn(duration: 300.ms),
//                 ),
//               ],
//             );
//           }

//           return CustomScrollView(
//             controller: scrollController,
//             scrollDirection: widget.scrollDirection,
//             slivers: [
//               SliverList(
//                 delegate: SliverChildBuilderDelegate((context, index) {
//                   final item = widget.pagination.itemAt(index);
//                   if (item == null) {
//                     return const SizedBox.shrink();
//                   }
//                   return widget.builder(index, item);
//                 }, childCount: widget.pagination.totalItemsCount),
//               ),
//               SliverToBoxAdapter(child: _listFooter(context, state)),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

// Widget _listFooter(BuildContext context, PaginationLoadState state) {
//   if (state == PaginationLoadState.loading ||
//       state == PaginationLoadState.refreshing) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       child: Center(
//         child: SizedBox(
//           height: 22,
//           width: 22,
//           child: CircularProgressIndicator(strokeWidth: 3),
//         ),
//       ),
//     );
//   }
//   if (state == PaginationLoadState.allLoaded) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 12),
//         child: Text("End".tr(context), style: TextStyle(fontStyle: FontStyle.italic).w500),
//       ),
//     ).animate().fadeIn(duration: 300.ms);
//   }
//   return const SizedBox.shrink();
// }
