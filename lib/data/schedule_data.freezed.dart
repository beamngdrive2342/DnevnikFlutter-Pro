// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Lesson {

 String get id; int get num; String get subject; String get room; String get time; String get topic; String get hw;
/// Create a copy of Lesson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonCopyWith<Lesson> get copyWith => _$LessonCopyWithImpl<Lesson>(this as Lesson, _$identity);

  /// Serializes this Lesson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Lesson&&(identical(other.id, id) || other.id == id)&&(identical(other.num, num) || other.num == num)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.room, room) || other.room == room)&&(identical(other.time, time) || other.time == time)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.hw, hw) || other.hw == hw));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,num,subject,room,time,topic,hw);

@override
String toString() {
  return 'Lesson(id: $id, num: $num, subject: $subject, room: $room, time: $time, topic: $topic, hw: $hw)';
}


}

/// @nodoc
abstract mixin class $LessonCopyWith<$Res>  {
  factory $LessonCopyWith(Lesson value, $Res Function(Lesson) _then) = _$LessonCopyWithImpl;
@useResult
$Res call({
 String id, int num, String subject, String room, String time, String topic, String hw
});




}
/// @nodoc
class _$LessonCopyWithImpl<$Res>
    implements $LessonCopyWith<$Res> {
  _$LessonCopyWithImpl(this._self, this._then);

  final Lesson _self;
  final $Res Function(Lesson) _then;

/// Create a copy of Lesson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? num = null,Object? subject = null,Object? room = null,Object? time = null,Object? topic = null,Object? hw = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,num: null == num ? _self.num : num // ignore: cast_nullable_to_non_nullable
as int,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,room: null == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as String,topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String,hw: null == hw ? _self.hw : hw // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Lesson].
extension LessonPatterns on Lesson {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Lesson value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Lesson() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Lesson value)  $default,){
final _that = this;
switch (_that) {
case _Lesson():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Lesson value)?  $default,){
final _that = this;
switch (_that) {
case _Lesson() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int num,  String subject,  String room,  String time,  String topic,  String hw)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Lesson() when $default != null:
return $default(_that.id,_that.num,_that.subject,_that.room,_that.time,_that.topic,_that.hw);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int num,  String subject,  String room,  String time,  String topic,  String hw)  $default,) {final _that = this;
switch (_that) {
case _Lesson():
return $default(_that.id,_that.num,_that.subject,_that.room,_that.time,_that.topic,_that.hw);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int num,  String subject,  String room,  String time,  String topic,  String hw)?  $default,) {final _that = this;
switch (_that) {
case _Lesson() when $default != null:
return $default(_that.id,_that.num,_that.subject,_that.room,_that.time,_that.topic,_that.hw);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Lesson implements Lesson {
  const _Lesson({required this.id, required this.num, required this.subject, required this.room, required this.time, this.topic = 'Обычный урок', this.hw = ''});
  factory _Lesson.fromJson(Map<String, dynamic> json) => _$LessonFromJson(json);

@override final  String id;
@override final  int num;
@override final  String subject;
@override final  String room;
@override final  String time;
@override@JsonKey() final  String topic;
@override@JsonKey() final  String hw;

/// Create a copy of Lesson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LessonCopyWith<_Lesson> get copyWith => __$LessonCopyWithImpl<_Lesson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LessonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Lesson&&(identical(other.id, id) || other.id == id)&&(identical(other.num, num) || other.num == num)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.room, room) || other.room == room)&&(identical(other.time, time) || other.time == time)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.hw, hw) || other.hw == hw));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,num,subject,room,time,topic,hw);

@override
String toString() {
  return 'Lesson(id: $id, num: $num, subject: $subject, room: $room, time: $time, topic: $topic, hw: $hw)';
}


}

/// @nodoc
abstract mixin class _$LessonCopyWith<$Res> implements $LessonCopyWith<$Res> {
  factory _$LessonCopyWith(_Lesson value, $Res Function(_Lesson) _then) = __$LessonCopyWithImpl;
@override @useResult
$Res call({
 String id, int num, String subject, String room, String time, String topic, String hw
});




}
/// @nodoc
class __$LessonCopyWithImpl<$Res>
    implements _$LessonCopyWith<$Res> {
  __$LessonCopyWithImpl(this._self, this._then);

  final _Lesson _self;
  final $Res Function(_Lesson) _then;

/// Create a copy of Lesson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? num = null,Object? subject = null,Object? room = null,Object? time = null,Object? topic = null,Object? hw = null,}) {
  return _then(_Lesson(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,num: null == num ? _self.num : num // ignore: cast_nullable_to_non_nullable
as int,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,room: null == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as String,time: null == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as String,topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String,hw: null == hw ? _self.hw : hw // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$HomeworkItem {

 String get id; set id(String value); String get subject; set subject(String value); String get task; set task(String value); String get deadline; set deadline(String value); String? get imageUrl; set imageUrl(String? value); List<String>? get imageUrls; set imageUrls(List<String>? value); List<String>? get fullResolutionUrls; set fullResolutionUrls(List<String>? value); bool get done; set done(bool value); bool get fromSchedule; set fromSchedule(bool value);
/// Create a copy of HomeworkItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeworkItemCopyWith<HomeworkItem> get copyWith => _$HomeworkItemCopyWithImpl<HomeworkItem>(this as HomeworkItem, _$identity);





@override
String toString() {
  return 'HomeworkItem(id: $id, subject: $subject, task: $task, deadline: $deadline, imageUrl: $imageUrl, imageUrls: $imageUrls, fullResolutionUrls: $fullResolutionUrls, done: $done, fromSchedule: $fromSchedule)';
}


}

/// @nodoc
abstract mixin class $HomeworkItemCopyWith<$Res>  {
  factory $HomeworkItemCopyWith(HomeworkItem value, $Res Function(HomeworkItem) _then) = _$HomeworkItemCopyWithImpl;
@useResult
$Res call({
 String id, String subject, String task, String deadline, String? imageUrl, List<String>? imageUrls, List<String>? fullResolutionUrls, bool done, bool fromSchedule
});




}
/// @nodoc
class _$HomeworkItemCopyWithImpl<$Res>
    implements $HomeworkItemCopyWith<$Res> {
  _$HomeworkItemCopyWithImpl(this._self, this._then);

  final HomeworkItem _self;
  final $Res Function(HomeworkItem) _then;

/// Create a copy of HomeworkItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? subject = null,Object? task = null,Object? deadline = null,Object? imageUrl = freezed,Object? imageUrls = freezed,Object? fullResolutionUrls = freezed,Object? done = null,Object? fromSchedule = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,task: null == task ? _self.task : task // ignore: cast_nullable_to_non_nullable
as String,deadline: null == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,imageUrls: freezed == imageUrls ? _self.imageUrls : imageUrls // ignore: cast_nullable_to_non_nullable
as List<String>?,fullResolutionUrls: freezed == fullResolutionUrls ? _self.fullResolutionUrls : fullResolutionUrls // ignore: cast_nullable_to_non_nullable
as List<String>?,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as bool,fromSchedule: null == fromSchedule ? _self.fromSchedule : fromSchedule // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [HomeworkItem].
extension HomeworkItemPatterns on HomeworkItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeworkItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeworkItem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeworkItem value)  $default,){
final _that = this;
switch (_that) {
case _HomeworkItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeworkItem value)?  $default,){
final _that = this;
switch (_that) {
case _HomeworkItem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String subject,  String task,  String deadline,  String? imageUrl,  List<String>? imageUrls,  List<String>? fullResolutionUrls,  bool done,  bool fromSchedule)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeworkItem() when $default != null:
return $default(_that.id,_that.subject,_that.task,_that.deadline,_that.imageUrl,_that.imageUrls,_that.fullResolutionUrls,_that.done,_that.fromSchedule);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String subject,  String task,  String deadline,  String? imageUrl,  List<String>? imageUrls,  List<String>? fullResolutionUrls,  bool done,  bool fromSchedule)  $default,) {final _that = this;
switch (_that) {
case _HomeworkItem():
return $default(_that.id,_that.subject,_that.task,_that.deadline,_that.imageUrl,_that.imageUrls,_that.fullResolutionUrls,_that.done,_that.fromSchedule);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String subject,  String task,  String deadline,  String? imageUrl,  List<String>? imageUrls,  List<String>? fullResolutionUrls,  bool done,  bool fromSchedule)?  $default,) {final _that = this;
switch (_that) {
case _HomeworkItem() when $default != null:
return $default(_that.id,_that.subject,_that.task,_that.deadline,_that.imageUrl,_that.imageUrls,_that.fullResolutionUrls,_that.done,_that.fromSchedule);case _:
  return null;

}
}

}

/// @nodoc


class _HomeworkItem extends HomeworkItem {
   _HomeworkItem({required this.id, required this.subject, required this.task, required this.deadline, this.imageUrl, this.imageUrls, this.fullResolutionUrls, this.done = false, this.fromSchedule = false}): super._();
  

@override  String id;
@override  String subject;
@override  String task;
@override  String deadline;
@override  String? imageUrl;
@override  List<String>? imageUrls;
@override  List<String>? fullResolutionUrls;
@override@JsonKey()  bool done;
@override@JsonKey()  bool fromSchedule;

/// Create a copy of HomeworkItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeworkItemCopyWith<_HomeworkItem> get copyWith => __$HomeworkItemCopyWithImpl<_HomeworkItem>(this, _$identity);





@override
String toString() {
  return 'HomeworkItem(id: $id, subject: $subject, task: $task, deadline: $deadline, imageUrl: $imageUrl, imageUrls: $imageUrls, fullResolutionUrls: $fullResolutionUrls, done: $done, fromSchedule: $fromSchedule)';
}


}

/// @nodoc
abstract mixin class _$HomeworkItemCopyWith<$Res> implements $HomeworkItemCopyWith<$Res> {
  factory _$HomeworkItemCopyWith(_HomeworkItem value, $Res Function(_HomeworkItem) _then) = __$HomeworkItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String subject, String task, String deadline, String? imageUrl, List<String>? imageUrls, List<String>? fullResolutionUrls, bool done, bool fromSchedule
});




}
/// @nodoc
class __$HomeworkItemCopyWithImpl<$Res>
    implements _$HomeworkItemCopyWith<$Res> {
  __$HomeworkItemCopyWithImpl(this._self, this._then);

  final _HomeworkItem _self;
  final $Res Function(_HomeworkItem) _then;

/// Create a copy of HomeworkItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? subject = null,Object? task = null,Object? deadline = null,Object? imageUrl = freezed,Object? imageUrls = freezed,Object? fullResolutionUrls = freezed,Object? done = null,Object? fromSchedule = null,}) {
  return _then(_HomeworkItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,task: null == task ? _self.task : task // ignore: cast_nullable_to_non_nullable
as String,deadline: null == deadline ? _self.deadline : deadline // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,imageUrls: freezed == imageUrls ? _self.imageUrls : imageUrls // ignore: cast_nullable_to_non_nullable
as List<String>?,fullResolutionUrls: freezed == fullResolutionUrls ? _self.fullResolutionUrls : fullResolutionUrls // ignore: cast_nullable_to_non_nullable
as List<String>?,done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as bool,fromSchedule: null == fromSchedule ? _self.fromSchedule : fromSchedule // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
