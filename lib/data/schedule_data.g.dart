// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Lesson _$LessonFromJson(Map<String, dynamic> json) => _Lesson(
  id: json['id'] as String,
  num: (json['num'] as num).toInt(),
  subject: json['subject'] as String,
  room: json['room'] as String,
  time: json['time'] as String,
  topic: json['topic'] as String? ?? 'Обычный урок',
  hw: json['hw'] as String? ?? '',
);

Map<String, dynamic> _$LessonToJson(_Lesson instance) => <String, dynamic>{
  'id': instance.id,
  'num': instance.num,
  'subject': instance.subject,
  'room': instance.room,
  'time': instance.time,
  'topic': instance.topic,
  'hw': instance.hw,
};
