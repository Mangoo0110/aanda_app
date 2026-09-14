import 'package:flutter/material.dart';

SliverGridDelegate sliverGridDelegateConfig() {
  return const SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 220,
    crossAxisSpacing: 18,
    mainAxisSpacing: 12,
    childAspectRatio: 1.1,
  );
}
