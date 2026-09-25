import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/async_handlers/response.dart';
import 'package:aanda/src/core/error_handler/error_handler.dart';
import 'package:aanda/src/features/house/data/datasources/house_remote_datasource.dart';
import 'package:aanda/src/features/house/domain/entities/house.dart';
import 'package:aanda/src/features/house/domain/entities/house_invite.dart';
import 'package:aanda/src/features/house/domain/entities/house_member.dart';
import 'package:aanda/src/features/house/domain/entities/sprint.dart';
import 'package:aanda/src/features/house/domain/repo/house_repo.dart';

class HouseRepoImpl with ErrorHandler implements HouseRepo {
  HouseRepoImpl({required HouseRemoteDatasource datasource})
    : _datasource = datasource;

  final HouseRemoteDatasource _datasource;

  @override
  AsyncRequest<House> createHouse({required String name, String? avatarUrl}) {
    return asyncTryCatch(
      tryFunc: () async {
        final house = await _datasource.createHouse(
          name: name,
          avatarUrl: avatarUrl,
        );
        return SuccessRepoCall(data: house);
      },
    );
  }

  @override
  AsyncRequest<House> joinHouse({required String inviteCode}) {
    return asyncTryCatch(
      tryFunc: () async {
        final house = await _datasource.joinHouse(inviteCode: inviteCode);
        return SuccessRepoCall(data: house);
      },
    );
  }

  @override
  AsyncRequest<List<House>> getMyHouses() {
    return asyncTryCatch(
      tryFunc: () async {
        final houses = await _datasource.getMyHouses();
        return SuccessRepoCall(data: houses);
      },
    );
  }

  @override
  AsyncRequest<List<HouseMember>> getHouseMembers({required String houseId}) {
    return asyncTryCatch(
      tryFunc: () async {
        final members = await _datasource.getHouseMembers(houseId: houseId);
        return SuccessRepoCall(data: members);
      },
    );
  }

  @override
  AsyncRequest<House> getHouseDetail({required String houseId}) {
    return asyncTryCatch(
      tryFunc: () async {
        final house = await _datasource.getHouseDetail(houseId: houseId);
        return SuccessRepoCall(data: house);
      },
    );
  }

  @override
  AsyncRequest<String> uploadHouseAvatar({
    required String houseId,
    required List<int> fileBytes,
    required String fileExtension,
  }) {
    return asyncTryCatch(
      tryFunc: () async {
        final url = await _datasource.uploadHouseAvatar(
          houseId: houseId,
          fileBytes: fileBytes,
          fileExtension: fileExtension,
        );
        return SuccessRepoCall(data: url);
      },
    );
  }

  @override
  AsyncRequest<void> updateHouseAvatar({
    required String houseId,
    required String avatarUrl,
  }) {
    return asyncTryCatch(
      tryFunc: () async {
        await _datasource.updateHouseAvatarUrl(
          houseId: houseId,
          avatarUrl: avatarUrl,
        );
        return const SuccessRepoCall();
      },
    );
  }

  @override
  AsyncRequest<void> leaveHouse({required String houseId}) {
    return asyncTryCatch(
      tryFunc: () async {
        await _datasource.leaveHouse(houseId: houseId);
        return const SuccessRepoCall();
      },
    );
  }

  @override
  AsyncRequest<void> removeMember({
    required String houseId,
    required String userId,
  }) {
    return asyncTryCatch(
      tryFunc: () async {
        await _datasource.removeMember(houseId: houseId, userId: userId);
        return const SuccessRepoCall();
      },
    );
  }

  @override
  AsyncRequest<HouseInvite> getHouseInvite({required String houseId}) {
    return asyncTryCatch(
      tryFunc: () async {
        final invite = await _datasource.getHouseInvite(houseId: houseId);
        return SuccessRepoCall(data: invite);
      },
    );
  }

  @override
  AsyncRequest<HouseInvite> regenerateInviteCode({required String houseId}) {
    return asyncTryCatch(
      tryFunc: () async {
        final invite = await _datasource.regenerateInviteCode(houseId: houseId);
        return SuccessRepoCall(data: invite);
      },
    );
  }

  @override
  AsyncRequest<List<Sprint>> getSprints({required String houseId}) {
    return asyncTryCatch(
      tryFunc: () async {
        final sprints = await _datasource.getSprints(houseId: houseId);
        return SuccessRepoCall(data: sprints);
      },
    );
  }

  @override
  AsyncRequest<Sprint> createSprint({
    required String houseId,
    required String label,
    required DateTime startDate,
    DateTime? endDate,
  }) {
    return asyncTryCatch(
      tryFunc: () async {
        final sprint = await _datasource.createSprint(
          houseId: houseId,
          label: label,
          startDate: startDate,
          endDate: endDate,
        );
        return SuccessRepoCall(data: sprint);
      },
    );
  }

  @override
  AsyncRequest<Sprint> closeSprint({
    required String cycleId,
    DateTime? closedAt,
  }) {
    return asyncTryCatch(
      tryFunc: () async {
        final sprint = await _datasource.closeSprint(
          cycleId: cycleId,
          closedAt: closedAt,
        );
        return SuccessRepoCall(data: sprint);
      },
    );
  }

  @override
  AsyncRequest<Map<String, dynamic>> getSprintStats({
    required String houseId,
    String? cycleId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return asyncTryCatch(
      tryFunc: () async {
        final stats = await _datasource.getSprintStats(
          houseId: houseId,
          cycleId: cycleId,
          startDate: startDate,
          endDate: endDate,
        );
        return SuccessRepoCall(data: stats);
      },
    );
  }
}
