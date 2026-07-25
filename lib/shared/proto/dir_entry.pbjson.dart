// This is a generated file - do not edit.
//
// Generated from dir_entry.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use dirEntryDescriptor instead')
const DirEntry$json = {
  '1': 'DirEntry',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'path', '3': 2, '4': 1, '5': 9, '10': 'path'},
    {'1': 'is_dir', '3': 3, '4': 1, '5': 8, '10': 'isDir'},
    {'1': 'size', '3': 4, '4': 1, '5': 4, '10': 'size'},
    {'1': 'modified_at', '3': 5, '4': 1, '5': 3, '10': 'modifiedAt'},
    {'1': 'type', '3': 6, '4': 1, '5': 9, '10': 'type'},
    {'1': 'mime_type', '3': 7, '4': 1, '5': 9, '10': 'mimeType'},
    {'1': 'thumbnail_url', '3': 8, '4': 1, '5': 9, '10': 'thumbnailUrl'},
    {'1': 'id', '3': 9, '4': 1, '5': 3, '10': 'id'},
  ],
};

/// Descriptor for `DirEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dirEntryDescriptor = $convert.base64Decode(
    'CghEaXJFbnRyeRISCgRuYW1lGAEgASgJUgRuYW1lEhIKBHBhdGgYAiABKAlSBHBhdGgSFQoGaX'
    'NfZGlyGAMgASgIUgVpc0RpchISCgRzaXplGAQgASgEUgRzaXplEh8KC21vZGlmaWVkX2F0GAUg'
    'ASgDUgptb2RpZmllZEF0EhIKBHR5cGUYBiABKAlSBHR5cGUSGwoJbWltZV90eXBlGAcgASgJUg'
    'htaW1lVHlwZRIjCg10aHVtYm5haWxfdXJsGAggASgJUgx0aHVtYm5haWxVcmwSDgoCaWQYCSAB'
    'KANSAmlk');

@$core.Deprecated('Use dirResponseDescriptor instead')
const DirResponse$json = {
  '1': 'DirResponse',
  '2': [
    {
      '1': 'entries',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.server.proto.DirEntry',
      '10': 'entries'
    },
  ],
};

/// Descriptor for `DirResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dirResponseDescriptor = $convert.base64Decode(
    'CgtEaXJSZXNwb25zZRIwCgdlbnRyaWVzGAEgAygLMhYuc2VydmVyLnByb3RvLkRpckVudHJ5Ug'
    'dlbnRyaWVz');
