import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:aanda/src/features/auth/domain/entities/account.dart';

part 'account_model.freezed.dart';
part 'account_model.g.dart';

@freezed
abstract class AccountModel extends Account with _$AccountModel {
  const AccountModel._() : super();

  const factory AccountModel({
    required String id,
    required String email,
    required String uniqueName,
    String? fullName,
    String? avatarUrl,
    String? token,
  }) = _AccountModel;

  factory AccountModel.fromJson(Map<String, dynamic> json) =>
      _$AccountModelFromJson(json);

  /// Creates an [AccountModel] from a Supabase profiles row joined with
  /// auth.users data.
  factory AccountModel.fromSupabase({
    required Map<String, dynamic> profile,
    required String email,
    String? token,
  }) {
    return AccountModel(
      id: profile['id'] as String,
      email: email,
      uniqueName: ((profile['username'] as String?)?.isNotEmpty == true
          ? profile['username'] as String
          : email.split('@').first),
      fullName: profile['full_name'] as String?,
      avatarUrl: profile['avatar_url'] as String?,
      token: token,
    );
  }
}
