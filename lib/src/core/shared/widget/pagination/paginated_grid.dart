// import 'package:pagination_pkg/pagination_pkg.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart';

// import '../../../localization/app_localizations.dart';

// class PaginatedGridView<K, T> extends StatefulWidget {
//   final PaginationEngine<K, T> pagination;

//   /// Widget shown as skeleton cell (provided by the caller)
//   final Widget skeleton;

//   /// How many skeletons to show when loading / refreshing
//   final int skeletonCount;

//   final String emptyMessage;

//   /// Caller decides how each grid item looks
//   final Widget Function(int index, T data) itemBuilder;

//   /// Caller decides the grid layout
//   final SliverGridDelegate gridDelegate;

//   /// Optional: control scroll physics
//   final ScrollPhysics? physics;

//   /// Optional: padding for the grid
//   final EdgeInsetsGeometry? padding;

//   /// Optional: if you use this inside another scroll view (like your List version),
//   /// keep it non-scrollable. Default matches your List behavior.
//   final bool shrinkWrap;
//   final bool disableScroll;
//   final Key? scrollViewKey;
//   final SliverOverlapAbsorberHandle? overlapHandle;

//   const PaginatedGridView({
//     super.key,
//     required this.pagination,
//     required this.skeleton,
//     required this.skeletonCount,
//     required this.itemBuilder,
//     required this.gridDelegate,
//     this.emptyMessage = "No data found",
//     this.physics,
//     this.padding,
//     this.shrinkWrap = true,
//     this.disableScroll = true,
//     this.scrollViewKey,
//     this.overlapHandle,
//   });

//   @override
//   State<PaginatedGridView<K, T>> createState() =>
//       _PaginatedGridViewState<K, T>();
// }

// class _PaginatedGridViewState<K, T> extends State<PaginatedGridView<K, T>> {
//   @override
//   Widget build(BuildContext context) {
//     return ListenableBuilder(
//       listenable: widget.pagination,
//       builder: (context, _) {
//         final state = widget.pagination.state.value;

//         if (state == PaginationLoadState.nopages) {
//           return Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Center(child: Text(widget.emptyMessage.tr(context))),
//               IconButton(
//                 onPressed: widget.pagination.refresh,
//                 icon: const Icon(Icons.refresh),
//               ),
//             ],
//           ).animate().fadeIn(duration: 300.ms);
//         }
//         if (state == PaginationLoadState.error &&
//             widget.pagination.totalItemsCount == 0) {
//           return Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Center(child: Text(widget.emptyMessage.tr(context))),
//               IconButton(
//                 onPressed: widget.pagination.refresh,
//                 icon: const Icon(Icons.refresh),
//               ),
//             ],
//           ).animate().fadeIn(duration: 300.ms);
//         }

//         final itemCount = widget.pagination.totalItemsCount;

//         return LayoutBuilder(
//           builder: (context, constraints) {
//             if (constraints.maxWidth <= 0) {
//               return const SizedBox.shrink();
//             }

//             return NotificationListener<ScrollUpdateNotification>(
//               onNotification: (notification) {
//                 if (notification.depth != 0 ||
//                     notification.metrics.axis != Axis.vertical) {
//                   return false;
//                 }

//                 final s = widget.pagination.state.value;
//                 final canLoad =
//                     s != PaginationLoadState.loading &&
//                     s != PaginationLoadState.refreshing &&
//                     s != PaginationLoadState.allLoaded &&
//                     s != PaginationLoadState.nopages;

//                 if (canLoad && notification.metrics.extentAfter < 250) {
//                   widget.pagination.loadNextPage();
//                 }
//                 return false;
//               },
//               child: CustomScrollView(
//                 key: widget.scrollViewKey,
//                 physics: widget.physics,
//                 slivers: [
//                   if (widget.overlapHandle != null)
//                     SliverOverlapInjector(handle: widget.overlapHandle!),
//                   SliverGrid.builder(
//                     gridDelegate: widget.gridDelegate,
//                     itemCount: itemCount,
//                     itemBuilder: (context, index) {
//                       final isFooter =
//                           index == widget.pagination.totalItemsCount;

//                       if (!isFooter) {
//                         final element = widget.pagination.itemAt(index);
//                         if (element == null) {
//                           return const SizedBox.shrink();
//                         }
//                         return widget
//                             .itemBuilder(index, element)
//                             .animate()
//                             .slideY(
//                               begin: 0.1,
//                               end: 0,
//                               duration: 300.ms,
//                               curve: Curves.easeOutCubic,
//                             )
//                             .fadeIn(
//                               duration: 300.ms,
//                               curve: Curves.easeOutCubic,
//                             );
//                       }

//                       return const SizedBox.shrink();
//                     },
//                   ),
//                   SliverToBoxAdapter(
//                     child: SizedBox(
//                       height: 150,
//                       child: Align(
//                         alignment: Alignment.topCenter,
//                         child: ValueListenableBuilder(
//                           valueListenable: widget.pagination.state,
//                           builder: (context, value, child) {
//                             if (value == PaginationLoadState.allLoaded) {
//                               return Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Text(
//                                   "End of the page".tr(context),
//                                   style: const TextStyle(
//                                     fontStyle: FontStyle.normal,
//                                     fontSize: 14,
//                                     color: Colors.grey,
//                                   ).bold,
//                                 ),
//                               ).animate().fadeIn(duration: 300.ms);
//                             }
//                             if (value == PaginationLoadState.loading ||
//                                 value == PaginationLoadState.refreshing) {
//                               return Center(
//                                 child: SizedBox(
//                                   height: 30,
//                                   width: 30,
//                                   child: CircularProgressIndicator(
//                                     strokeWidth: 4,
//                                     valueColor: AlwaysStoppedAnimation<Color>(
//                                       Theme.of(context).primaryColor,
//                                     ),
//                                   ),
//                                 ),
//                               );
//                             }
//                             return Container();
//                           },
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }
