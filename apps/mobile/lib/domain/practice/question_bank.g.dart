// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_bank.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExamBlueprint _$ExamBlueprintFromJson(Map<String, dynamic> json) =>
    _ExamBlueprint(
      totalQuestions: (json['totalQuestions'] as num).toInt(),
      passCorrect: (json['passCorrect'] as num).toInt(),
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      distribution: Map<String, int>.from(json['distribution'] as Map),
    );

Map<String, dynamic> _$ExamBlueprintToJson(_ExamBlueprint instance) =>
    <String, dynamic>{
      'totalQuestions': instance.totalQuestions,
      'passCorrect': instance.passCorrect,
      'durationMinutes': instance.durationMinutes,
      'distribution': instance.distribution,
    };

_QuestionBank _$QuestionBankFromJson(Map<String, dynamic> json) =>
    _QuestionBank(
      version: json['version'] as String,
      generatedAt: json['generatedAt'] as String,
      count: (json['count'] as num).toInt(),
      blueprint: ExamBlueprint.fromJson(
        json['blueprint'] as Map<String, dynamic>,
      ),
      questions: (json['questions'] as List<dynamic>)
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$QuestionBankToJson(_QuestionBank instance) =>
    <String, dynamic>{
      'version': instance.version,
      'generatedAt': instance.generatedAt,
      'count': instance.count,
      'blueprint': instance.blueprint,
      'questions': instance.questions,
    };
