/*
* Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License").
* You may not use this file except in compliance with the License.
* A copy of the License is located at
*
*  http://aws.amazon.com/apache2.0
*
* or in the "license" file accompanying this file. This file is distributed
* on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
* express or implied. See the License for the specific language governing
* permissions and limitations under the License.
*/

// NOTE: This file is generated and may not follow lint rules defined in your app
// Generated files can be excluded from analysis in analysis_options.yaml
// For more info, see: https://dart.dev/guides/language/analysis-options#excluding-code-from-analysis

// ignore_for_file: public_member_api_docs, annotate_overrides, dead_code, dead_codepublic_member_api_docs, depend_on_referenced_packages, file_names, library_private_types_in_public_api, no_leading_underscores_for_library_prefixes, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, null_check_on_nullable_type_parameter, prefer_adjacent_string_concatenation, prefer_const_constructors, prefer_if_null_operators, prefer_interpolation_to_compose_strings, slash_for_doc_comments, sort_child_properties_last, unnecessary_const, unnecessary_constructor_name, unnecessary_late, unnecessary_new, unnecessary_null_aware_assignments, unnecessary_nullable_for_final_variable_declarations, unnecessary_string_interpolations, use_build_context_synchronously

import 'package:amplify_core/amplify_core.dart';
import 'package:flutter/foundation.dart';

/** This is an auto generated class representing the Tweet type in your schema. */
@immutable
class Tweet extends Model {
  static const classType = const _TweetModelType();
  final String id;
  final String? _author;
  final String? _content;
  final String? _imageKey;
  final TemporalDateTime? _createdAt;
  final TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;

  @override
  String getId() {
    return id;
  }

  String? get author {
    return _author;
  }

  String get content {
    try {
      return _content!;
    } catch (e) {
      throw new AmplifyCodeGenModelException(
          AmplifyExceptionMessages
              .codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion: AmplifyExceptionMessages
              .codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString());
    }
  }

  String? get imageKey {
    return _imageKey;
  }

  TemporalDateTime? get createdAt {
    return _createdAt;
  }

  TemporalDateTime? get updatedAt {
    return _updatedAt;
  }

  const Tweet._internal(
      {required this.id,
      author,
      required content,
      imageKey,
      createdAt,
      updatedAt})
      : _author = author,
        _content = content,
        _imageKey = imageKey,
        _createdAt = createdAt,
        _updatedAt = updatedAt;

  factory Tweet(
      {String? id, String? author, required String content, String? imageKey}) {
    return Tweet._internal(
        id: id == null ? UUID.getUUID() : id,
        author: author,
        content: content,
        imageKey: imageKey);
  }

  bool equals(Object other) {
    return this == other;
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Tweet &&
        id == other.id &&
        _author == other._author &&
        _content == other._content &&
        _imageKey == other._imageKey;
  }

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() {
    var buffer = new StringBuffer();

    buffer.write("Tweet {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("author=" + "$_author" + ", ");
    buffer.write("content=" + "$_content" + ", ");
    buffer.write("imageKey=" + "$_imageKey" + ", ");
    buffer.write("createdAt=" +
        (_createdAt != null ? _createdAt!.format() : "null") +
        ", ");
    buffer.write(
        "updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");

    return buffer.toString();
  }

  Tweet copyWith(
      {String? id, String? author, String? content, String? imageKey}) {
    return Tweet._internal(
        id: id ?? this.id,
        author: author ?? this.author,
        content: content ?? this.content,
        imageKey: imageKey ?? this.imageKey);
  }

  Tweet.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        _author = json['author'],
        _content = json['content'],
        _imageKey = json['imageKey'],
        _createdAt = json['createdAt'] != null
            ? TemporalDateTime.fromString(json['createdAt'])
            : null,
        _updatedAt = json['updatedAt'] != null
            ? TemporalDateTime.fromString(json['updatedAt'])
            : null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': _author,
        'content': _content,
        'imageKey': _imageKey,
        'createdAt': _createdAt?.format(),
        'updatedAt': _updatedAt?.format()
      };

  Map<String, Object?> toMap() => {
        'id': id,
        'author': _author,
        'content': _content,
        'imageKey': _imageKey,
        'createdAt': _createdAt,
        'updatedAt': _updatedAt
      };

  static final QueryField ID = QueryField(fieldName: "id");
  static final QueryField AUTHOR = QueryField(fieldName: "author");
  static final QueryField CONTENT = QueryField(fieldName: "content");
  static final QueryField IMAGEKEY = QueryField(fieldName: "imageKey");
  static var schema =
      Model.defineSchema(define: (ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Tweet";
    modelSchemaDefinition.pluralName = "Tweets";

    modelSchemaDefinition.authRules = [
      AuthRule(authStrategy: AuthStrategy.PUBLIC, operations: [
        ModelOperation.CREATE,
        ModelOperation.UPDATE,
        ModelOperation.DELETE,
        ModelOperation.READ
      ]),
      AuthRule(
          authStrategy: AuthStrategy.OWNER,
          ownerField: "author",
          identityClaim: "cognito:username",
          provider: AuthRuleProvider.USERPOOLS,
          operations: [
            ModelOperation.CREATE,
            ModelOperation.UPDATE,
            ModelOperation.DELETE,
            ModelOperation.READ
          ])
    ];

    modelSchemaDefinition.addField(ModelFieldDefinition.id());

    modelSchemaDefinition.addField(ModelFieldDefinition.field(
        key: Tweet.AUTHOR,
        isRequired: false,
        ofType: ModelFieldType(ModelFieldTypeEnum.string)));

    modelSchemaDefinition.addField(ModelFieldDefinition.field(
        key: Tweet.CONTENT,
        isRequired: true,
        ofType: ModelFieldType(ModelFieldTypeEnum.string)));

    modelSchemaDefinition.addField(ModelFieldDefinition.field(
        key: Tweet.IMAGEKEY,
        isRequired: false,
        ofType: ModelFieldType(ModelFieldTypeEnum.string)));

    modelSchemaDefinition.addField(ModelFieldDefinition.nonQueryField(
        fieldName: 'createdAt',
        isRequired: false,
        isReadOnly: true,
        ofType: ModelFieldType(ModelFieldTypeEnum.dateTime)));

    modelSchemaDefinition.addField(ModelFieldDefinition.nonQueryField(
        fieldName: 'updatedAt',
        isRequired: false,
        isReadOnly: true,
        ofType: ModelFieldType(ModelFieldTypeEnum.dateTime)));
  });
}

class _TweetModelType extends ModelType<Tweet> {
  const _TweetModelType();

  @override
  String modelName() {
    return 'Tweet';
  }

  @override
  Tweet fromJson(Map<String, dynamic> jsonData) {
    return Tweet.fromJson(jsonData);
  }
}
