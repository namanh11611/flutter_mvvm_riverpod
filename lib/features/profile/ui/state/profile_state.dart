import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../features/profile/model/profile.dart';

part 'profile_state.freezed.dart';
part 'profile_state.g.dart';

@freezed
class ProfileState with _$ProfileState {
  const factory ProfileState({
    Profile? profile,
  }) = _ProfileState;

  factory ProfileState.fromJson(Map<String, Object?> json) =>
      _$ProfileStateFromJson(json);
}
