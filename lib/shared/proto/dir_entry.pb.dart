// This is a generated file - do not edit.
//
// Generated from dir_entry.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class DirEntry extends $pb.GeneratedMessage {
  factory DirEntry({
    $core.String? name,
    $core.String? path,
    $core.bool? isDir,
    $fixnum.Int64? size,
    $fixnum.Int64? modifiedAt,
    $core.String? type,
    $core.String? mimeType,
    $core.String? thumbnailUrl,
    $fixnum.Int64? id,
    $core.String? blurhash,
  }) {
    final result = create();
    if (name != null) result.name = name;
    if (path != null) result.path = path;
    if (isDir != null) result.isDir = isDir;
    if (size != null) result.size = size;
    if (modifiedAt != null) result.modifiedAt = modifiedAt;
    if (type != null) result.type = type;
    if (mimeType != null) result.mimeType = mimeType;
    if (thumbnailUrl != null) result.thumbnailUrl = thumbnailUrl;
    if (id != null) result.id = id;
    if (blurhash != null) result.blurhash = blurhash;
    return result;
  }

  DirEntry._();

  factory DirEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DirEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DirEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'server.proto'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aOS(2, _omitFieldNames ? '' : 'path')
    ..aOB(3, _omitFieldNames ? '' : 'isDir')
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'size', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aInt64(5, _omitFieldNames ? '' : 'modifiedAt')
    ..aOS(6, _omitFieldNames ? '' : 'type')
    ..aOS(7, _omitFieldNames ? '' : 'mimeType')
    ..aOS(8, _omitFieldNames ? '' : 'thumbnailUrl')
    ..aInt64(9, _omitFieldNames ? '' : 'id')
    ..aOS(10, _omitFieldNames ? '' : 'blurhash')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DirEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DirEntry copyWith(void Function(DirEntry) updates) =>
      super.copyWith((message) => updates(message as DirEntry)) as DirEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DirEntry create() => DirEntry._();
  @$core.override
  DirEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DirEntry getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DirEntry>(create);
  static DirEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get path => $_getSZ(1);
  @$pb.TagNumber(2)
  set path($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPath() => $_has(1);
  @$pb.TagNumber(2)
  void clearPath() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get isDir => $_getBF(2);
  @$pb.TagNumber(3)
  set isDir($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIsDir() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsDir() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get size => $_getI64(3);
  @$pb.TagNumber(4)
  set size($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSize() => $_has(3);
  @$pb.TagNumber(4)
  void clearSize() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get modifiedAt => $_getI64(4);
  @$pb.TagNumber(5)
  set modifiedAt($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasModifiedAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearModifiedAt() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get type => $_getSZ(5);
  @$pb.TagNumber(6)
  set type($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasType() => $_has(5);
  @$pb.TagNumber(6)
  void clearType() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get mimeType => $_getSZ(6);
  @$pb.TagNumber(7)
  set mimeType($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMimeType() => $_has(6);
  @$pb.TagNumber(7)
  void clearMimeType() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get thumbnailUrl => $_getSZ(7);
  @$pb.TagNumber(8)
  set thumbnailUrl($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasThumbnailUrl() => $_has(7);
  @$pb.TagNumber(8)
  void clearThumbnailUrl() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get id => $_getI64(8);
  @$pb.TagNumber(9)
  set id($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasId() => $_has(8);
  @$pb.TagNumber(9)
  void clearId() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get blurhash => $_getSZ(9);
  @$pb.TagNumber(10)
  set blurhash($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasBlurhash() => $_has(9);
  @$pb.TagNumber(10)
  void clearBlurhash() => $_clearField(10);
}

class DirResponse extends $pb.GeneratedMessage {
  factory DirResponse({
    $core.Iterable<DirEntry>? entries,
  }) {
    final result = create();
    if (entries != null) result.entries.addAll(entries);
    return result;
  }

  DirResponse._();

  factory DirResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DirResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DirResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'server.proto'),
      createEmptyInstance: create)
    ..pPM<DirEntry>(1, _omitFieldNames ? '' : 'entries',
        subBuilder: DirEntry.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DirResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DirResponse copyWith(void Function(DirResponse) updates) =>
      super.copyWith((message) => updates(message as DirResponse))
          as DirResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DirResponse create() => DirResponse._();
  @$core.override
  DirResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DirResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DirResponse>(create);
  static DirResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<DirEntry> get entries => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
