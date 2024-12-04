// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Profile _$ProfileFromJson(Map<String, dynamic> json) {
  return _Profile.fromJson(json);
}

/// @nodoc
mixin _$Profile {
  String? get id => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  String? get job => throw _privateConstructorUsedError;
  String? get avatar => throw _privateConstructorUsedError;
  int? get diamond => throw _privateConstructorUsedError;
  @JsonKey(name: 'expiry_date_premium')
  DateTime? get expiryDatePremium => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_lifetime_premium')
  bool? get isLifetimePremium => throw _privateConstructorUsedError;

  /// Serializes this Profile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProfileCopyWith<Profile> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfileCopyWith<$Res> {
  factory $ProfileCopyWith(Profile value, $Res Function(Profile) then) =
      _$ProfileCopyWithImpl<$Res, Profile>;
  @useResult
  $Res call(
      {String? id,
      String? email,
      String? name,
      String? job,
      String? avatar,
      int? diamond,
      @JsonKey(name: 'expiry_date_premium') DateTime? expiryDatePremium,
      @JsonKey(name: 'is_lifetime_premium') bool? isLifetimePremium});
}

/// @nodoc
class _$ProfileCopyWithImpl<$Res, $Val extends Profile>
    implements $ProfileCopyWith<$Res> {
  _$ProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? email = freezed,
    Object? name = freezed,
    Object? job = freezed,
    Object? avatar = freezed,
    Object? diamond = freezed,
    Object? expiryDatePremium = freezed,
    Object? isLifetimePremium = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      job: freezed == job
          ? _value.job
          : job // ignore: cast_nullable_to_non_nullable
              as String?,
      avatar: freezed == avatar
          ? _value.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as String?,
      diamond: freezed == diamond
          ? _value.diamond
          : diamond // ignore: cast_nullable_to_non_nullable
              as int?,
      expiryDatePremium: freezed == expiryDatePremium
          ? _value.expiryDatePremium
          : expiryDatePremium // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isLifetimePremium: freezed == isLifetimePremium
          ? _value.isLifetimePremium
          : isLifetimePremium // ignore: cast_nullable_to_non_nullable
              as bool?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProfileImplCopyWith<$Res> implements $ProfileCopyWith<$Res> {
  factory _$$ProfileImplCopyWith(
          _$ProfileImpl value, $Res Function(_$ProfileImpl) then) =
      __$$ProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? id,
      String? email,
      String? name,
      String? job,
      String? avatar,
      int? diamond,
      @JsonKey(name: 'expiry_date_premium') DateTime? expiryDatePremium,
      @JsonKey(name: 'is_lifetime_premium') bool? isLifetimePremium});
}

/// @nodoc
class __$$ProfileImplCopyWithImpl<$Res>
    extends _$ProfileCopyWithImpl<$Res, _$ProfileImpl>
    implements _$$ProfileImplCopyWith<$Res> {
  __$$ProfileImplCopyWithImpl(
      _$ProfileImpl _value, $Res Function(_$ProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? email = freezed,
    Object? name = freezed,
    Object? job = freezed,
    Object? avatar = freezed,
    Object? diamond = freezed,
    Object? expiryDatePremium = freezed,
    Object? isLifetimePremium = freezed,
  }) {
    return _then(_$ProfileImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      job: freezed == job
          ? _value.job
          : job // ignore: cast_nullable_to_non_nullable
              as String?,
      avatar: freezed == avatar
          ? _value.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as String?,
      diamond: freezed == diamond
          ? _value.diamond
          : diamond // ignore: cast_nullable_to_non_nullable
              as int?,
      expiryDatePremium: freezed == expiryDatePremium
          ? _value.expiryDatePremium
          : expiryDatePremium // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isLifetimePremium: freezed == isLifetimePremium
          ? _value.isLifetimePremium
          : isLifetimePremium // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProfileImpl implements _Profile {
  const _$ProfileImpl(
      {this.id = null,
      this.email = null,
      this.name = null,
      this.job = null,
      this.avatar = null,
      this.diamond = null,
      @JsonKey(name: 'expiry_date_premium') this.expiryDatePremium = null,
      @JsonKey(name: 'is_lifetime_premium') this.isLifetimePremium = null});

  factory _$ProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProfileImplFromJson(json);

  @override
  @JsonKey()
  final String? id;
  @override
  @JsonKey()
  final String? email;
  @override
  @JsonKey()
  final String? name;
  @override
  @JsonKey()
  final String? job;
  @override
  @JsonKey()
  final String? avatar;
  @override
  @JsonKey()
  final int? diamond;
  @override
  @JsonKey(name: 'expiry_date_premium')
  final DateTime? expiryDatePremium;
  @override
  @JsonKey(name: 'is_lifetime_premium')
  final bool? isLifetimePremium;

  @override
  String toString() {
    return 'Profile(id: $id, email: $email, name: $name, job: $job, avatar: $avatar, diamond: $diamond, expiryDatePremium: $expiryDatePremium, isLifetimePremium: $isLifetimePremium)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.job, job) || other.job == job) &&
            (identical(other.avatar, avatar) || other.avatar == avatar) &&
            (identical(other.diamond, diamond) || other.diamond == diamond) &&
            (identical(other.expiryDatePremium, expiryDatePremium) ||
                other.expiryDatePremium == expiryDatePremium) &&
            (identical(other.isLifetimePremium, isLifetimePremium) ||
                other.isLifetimePremium == isLifetimePremium));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, email, name, job, avatar,
      diamond, expiryDatePremium, isLifetimePremium);

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfileImplCopyWith<_$ProfileImpl> get copyWith =>
      __$$ProfileImplCopyWithImpl<_$ProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProfileImplToJson(
      this,
    );
  }
}

abstract class _Profile implements Profile {
  const factory _Profile(
      {final String? id,
      final String? email,
      final String? name,
      final String? job,
      final String? avatar,
      final int? diamond,
      @JsonKey(name: 'expiry_date_premium') final DateTime? expiryDatePremium,
      @JsonKey(name: 'is_lifetime_premium')
      final bool? isLifetimePremium}) = _$ProfileImpl;

  factory _Profile.fromJson(Map<String, dynamic> json) = _$ProfileImpl.fromJson;

  @override
  String? get id;
  @override
  String? get email;
  @override
  String? get name;
  @override
  String? get job;
  @override
  String? get avatar;
  @override
  int? get diamond;
  @override
  @JsonKey(name: 'expiry_date_premium')
  DateTime? get expiryDatePremium;
  @override
  @JsonKey(name: 'is_lifetime_premium')
  bool? get isLifetimePremium;

  /// Create a copy of Profile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProfileImplCopyWith<_$ProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
