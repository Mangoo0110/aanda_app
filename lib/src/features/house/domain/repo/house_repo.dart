import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/features/house/domain/entities/house.dart';
import 'package:aanda/src/features/house/domain/entities/house_invite.dart';
import 'package:aanda/src/features/house/domain/entities/house_member.dart';
import 'package:aanda/src/features/house/domain/entities/sprint.dart';

abstract interface class HouseRepo {
  /// Creates a new house; the caller becomes the admin.
  AsyncRequest<House> createHouse({required String name});

  /// Joins a house by its invite code.
  AsyncRequest<House> joinHouse({required String inviteCode});

  /// Returns all houses the current user belongs to.
  AsyncRequest<List<House>> getMyHouses();

  /// Returns all members of [houseId].
  AsyncRequest<List<HouseMember>> getHouseMembers({required String houseId});

  /// Leaves a house (cannot leave if you are the last admin).
  AsyncRequest<void> leaveHouse({required String houseId});

  /// Admin-only: removes [userId] from [houseId].
  AsyncRequest<void> removeMember({
    required String houseId,
    required String userId,
  });

  /// Fetches the active invite for [houseId].
  AsyncRequest<HouseInvite> getHouseInvite({required String houseId});

  /// Admin-only: generates a new invite code for [houseId].
  AsyncRequest<HouseInvite> regenerateInviteCode({required String houseId});

  /// Returns a single house with full member list.
  AsyncRequest<House> getHouseDetail({required String houseId});

  /// Returns all sprints for [houseId].
  AsyncRequest<List<Sprint>> getSprints({required String houseId});

  /// Creates a new sprint for [houseId].
  AsyncRequest<Sprint> createSprint({
    required String houseId,
    required String label,
    required DateTime startDate,
    DateTime? endDate, // null = open cycle
  });

  /// Closes an open sprint with effective closed/end date.
  AsyncRequest<Sprint> closeSprint({
    required String cycleId,
    DateTime? closedAt,
  });

  /// Quick stats for an account's date range (no cycle required).
  AsyncRequest<Map<String, dynamic>> getSprintStats({
    required String houseId,
    String? cycleId,
    required DateTime startDate,
    required DateTime endDate,
  });
}
