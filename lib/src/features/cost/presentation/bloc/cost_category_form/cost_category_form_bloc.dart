import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/core/utils/debug/debug_service.dart';
import 'package:aanda/src/core/utils/helpers/handle_future_request.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_category.dart';
import 'package:aanda/src/features/cost/domain/repo/cost_repo.dart';
import 'package:aanda/src/features/cost/domain/usecases/cost_usecases.dart';

part 'cost_category_form_event.dart';
part 'cost_category_form_state.dart';

final class CostCategoryFormBloc
    extends Bloc<CostCategoryFormEvent, CostCategoryFormState> {
  CostCategoryFormBloc({
    required CreateCostCategory createCostCategory,
    String? initialHouseId,
  })  : _createCostCategory = createCostCategory,
        super(CostCategoryFormState(houseId: initialHouseId)) {
    on<CostCategoryNameChanged>(_onNameChanged);
    on<CostCategoryEmojiSelected>(_onEmojiSelected);
    on<CostCategoryPresetImageSelected>(_onPresetImageSelected);
    on<CostCategoryImageFilePicked>(_onImageFilePicked);
    on<CostCategoryFoodToggled>(_onFoodToggled);
    on<CostCategoryNatureChanged>(_onNatureChanged);
    on<CostCategoryDefaultAmountChanged>(_onDefaultAmountChanged);
    on<CostCategoryHouseChanged>(_onHouseChanged);
    on<CostCategorySubmitted>(_onSubmitted);
  }

  final CreateCostCategory _createCostCategory;

  void _onNameChanged(
    CostCategoryNameChanged event,
    Emitter<CostCategoryFormState> emit,
  ) {
    emit(state.copyWith(name: event.name, clearError: true));
  }

  void _onEmojiSelected(
    CostCategoryEmojiSelected event,
    Emitter<CostCategoryFormState> emit,
  ) {
    emit(state.copyWith(
      selectedEmoji: event.emoji,
      clearImageUrl: true,
      clearPickedImage: true,
    ));
  }

  void _onPresetImageSelected(
    CostCategoryPresetImageSelected event,
    Emitter<CostCategoryFormState> emit,
  ) {
    emit(state.copyWith(
      selectedImageUrl: event.imageUrl,
      clearEmoji: true,
      clearPickedImage: true,
    ));
  }

  void _onImageFilePicked(
    CostCategoryImageFilePicked event,
    Emitter<CostCategoryFormState> emit,
  ) {
    emit(state.copyWith(
      pickedImagePath: event.filePath,
      clearEmoji: true,
      clearImageUrl: true,
    ));
  }

  void _onFoodToggled(
    CostCategoryFoodToggled event,
    Emitter<CostCategoryFormState> emit,
  ) {
    emit(state.copyWith(isMealCosting: event.isFood));
  }

  void _onNatureChanged(
    CostCategoryNatureChanged event,
    Emitter<CostCategoryFormState> emit,
  ) {
    emit(state.copyWith(
      costNature: event.nature,
      clearDefaultAmount: event.nature == 'variable',
    ));
  }

  void _onDefaultAmountChanged(
    CostCategoryDefaultAmountChanged event,
    Emitter<CostCategoryFormState> emit,
  ) {
    emit(state.copyWith(defaultAmount: event.amount));
  }

  void _onHouseChanged(
    CostCategoryHouseChanged event,
    Emitter<CostCategoryFormState> emit,
  ) {
    emit(state.copyWith(houseId: event.houseId));
  }

  Future<void> _onSubmitted(
    CostCategorySubmitted event,
    Emitter<CostCategoryFormState> emit,
  ) async {
    final name = state.name.trim();
    if (name.isEmpty) {
      emit(state.copyWith(
        status: CostCategoryFormStatus.failure,
        errorMessage: 'Please enter a category name',
      ));
      return;
    }

    if (state.houseId == null || state.houseId!.trim().isEmpty) {
      emit(state.copyWith(
        status: CostCategoryFormStatus.failure,
        errorMessage: 'An active account is required to create a category',
      ));
      return;
    }

    emit(state.copyWith(
      status: CostCategoryFormStatus.submitting,
      clearError: true,
    ));

    String? iconUrl = state.selectedEmoji ?? state.selectedImageUrl;

    // Upload picked image file to Supabase storage if selected
    if (state.pickedImagePath != null) {
      try {
        final supabase = Supabase.instance.client;
        final file = File(state.pickedImagePath!);
        final bytes = await file.readAsBytes();
        final ext = state.pickedImagePath!.split('.').lastOrNull?.toLowerCase() ?? 'jpg';
        final fileName = 'cat_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}.$ext';
        final storagePath = 'custom/$fileName';

        await supabase.storage.from('category-icons').uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$ext',
            upsert: true,
          ),
        );
        iconUrl = supabase.storage.from('category-icons').getPublicUrl(storagePath);
      } catch (e) {
        debugPrint('Error uploading category image: $e');
      }
    }

    final defaultAmt = state.costNature == 'variable' ? null : state.defaultAmount;
    final createData = CreateCostCategoryData(
      name: name,
      icon: iconUrl,
      isFood: state.isMealCosting,
      houseId: state.houseId!.trim(),
      defaultAmount: defaultAmt,
      costNature: state.costNature,
    );

    await handleFutureRequest<CostCategory>(
      request: () => _createCostCategory(createData),
      debugger: ControllerDebugger(),
      onError: (failure) {
        emit(state.copyWith(
          status: CostCategoryFormStatus.failure,
          errorMessage: failure.message,
        ));
      },
      onSuccess: (cat) {
        emit(state.copyWith(
          status: CostCategoryFormStatus.success,
          createdCategory: cat,
        ));
      },
    );
  }
}
