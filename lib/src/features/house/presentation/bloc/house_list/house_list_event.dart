part of 'house_list_bloc.dart';

sealed class HouseListEvent {}

final class HouseListStarted extends HouseListEvent {}

final class HouseListRefreshRequested extends HouseListEvent {}
