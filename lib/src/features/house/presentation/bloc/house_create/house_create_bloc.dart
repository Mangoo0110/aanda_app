import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/core/utils/debug/debug_service.dart';
import 'package:aanda/src/core/utils/helpers/handle_future_request.dart';
import 'package:aanda/src/features/house/domain/entities/house.dart';
import 'package:aanda/src/features/house/domain/usecases/house_usecases.dart';

part 'house_create_event.dart';
part 'house_create_state.dart';

final class HouseCreateBloc extends Bloc<HouseCreateEvent, HouseCreateState> {
  HouseCreateBloc({
    required CreateHouse createHouse,
    required UploadHouseAvatar uploadHouseAvatar,
  })  : _createHouse = createHouse,
        _uploadHouseAvatar = uploadHouseAvatar,
        super(const HouseCreateState()) {
    on<HouseCreateNameChanged>(_onNameChanged);
    on<HouseCreateSubmitted>(_onSubmitted);
  }

  final CreateHouse _createHouse;
  final UploadHouseAvatar _uploadHouseAvatar;

  void _onNameChanged(
    HouseCreateNameChanged event,
    Emitter<HouseCreateState> emit,
  ) {
    emit(state.copyWith(name: event.name, clearError: true));
  }

  Future<void> _onSubmitted(
    HouseCreateSubmitted event,
    Emitter<HouseCreateState> emit,
  ) async {
    final name = state.name.trim();

    if (event.avatarBytes == null || event.avatarBytes!.isEmpty) {
      emit(
        state.copyWith(
          errorMessage: 'Please select a profile photo for the shared house.',
        ),
      );
      return;
    }

    if (name.length < 2) {
      emit(
        state.copyWith(
          errorMessage: 'House name must be at least 2 characters.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(status: HouseCreateStatus.submitting, clearError: true),
    );

    // 1. Upload house avatar first
    String? avatarUrl;
    final uploadRes = await _uploadHouseAvatar(
      UploadHouseAvatarParams(
        houseId: 'house_${DateTime.now().millisecondsSinceEpoch}',
        fileBytes: event.avatarBytes!,
        fileExtension: event.avatarExtension ?? 'jpg',
      ),
    );

    if (uploadRes.success && uploadRes.data != null) {
      avatarUrl = uploadRes.data;
    } else {
      emit(
        state.copyWith(
          status: HouseCreateStatus.failure,
          errorMessage: uploadRes.message.isNotEmpty
              ? uploadRes.message
              : 'Failed to upload house photo. Please try again.',
        ),
      );
      return;
    }

    // 2. Create house with uploaded avatarUrl
    final result = await handleFutureRequest<House>(
      request: () => _createHouse(
        CreateHouseParams(name: name, avatarUrl: avatarUrl),
      ),
      debugger: ControllerDebugger(),
      onError: (failure) {
        emit(
          state.copyWith(
            status: HouseCreateStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
      onSuccess: (house) {
        emit(
          state.copyWith(
            status: HouseCreateStatus.success,
            createdHouseId: house.id,
            clearError: true,
          ),
        );
      },
    );

    if (result == null && state.status == HouseCreateStatus.submitting) {
      emit(state.copyWith(status: HouseCreateStatus.failure));
    }
  }
}
