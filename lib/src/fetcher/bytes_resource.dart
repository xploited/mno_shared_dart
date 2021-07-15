// Copyright (c) 2021 Mantano. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:typed_data';

import 'package:dartx/dartx.dart';
import 'package:r2_commons_dart/extensions/strings.dart';

import '../../fetcher.dart';
import '../../publication.dart';

typedef ByteDataRetriever = Future<ByteData> Function();
typedef StringRetriever = Future<String> Function();

abstract class BaseBytesResource extends Resource {
  final Link _link;
  final ByteDataRetriever _bytesFunction;
  ByteData _bytes;

  BaseBytesResource(this._link, this._bytesFunction);

  @override
  Future<Link> link() async => _link;

  @override
  Future<ResourceTry<ByteData>> read({IntRange range}) async {
    _bytes ??= await _bytesFunction();
    if (range == null) {
      return ResourceTry.success(_bytes);
    }
    IntRange range2 =
        IntRange(max(0, range.first), min(range.last, _bytes.lengthInBytes));
    return ResourceTry.success(
        _bytes.buffer.asByteData(range2.first, range2.length));
  }

  @override
  Future<ResourceTry<int>> length() async =>
      (await read()).map((it) => it.lengthInBytes);

  @override
  Future<void> close() async {}
}

/// Creates a Resource serving [ByteArray].
class BytesResource extends BaseBytesResource {
  BytesResource(Link link, ByteDataRetriever bytesFunction)
      : super(link, bytesFunction);

  @override
  String toString() {
    String length = (_bytes == null) ? "xxx" : _bytes.lengthInBytes.toString();
    return "BytesResource($length bytes)";
  }
}

/// Creates a Resource serving a [String].
class StringResource extends BaseBytesResource {
  StringResource(Link link, StringRetriever stringFunction)
      : super(link, wrap(stringFunction));

  static ByteDataRetriever wrap(StringRetriever stringFunction) =>
      () => stringFunction().then((value) => value.toByteData());

  @override
  String toString() {
    String length = (_bytes == null) ? "..." : _bytes.lengthInBytes.toString();
    return "StringResource($length bytes)";
  }
}