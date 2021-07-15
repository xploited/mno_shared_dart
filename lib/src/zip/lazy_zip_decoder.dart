// Copyright (c) 2021 Mantano. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:archive/archive_io.dart' as archive;
import 'package:fimber/fimber.dart';
import 'package:universal_io/io.dart';

import 'file_buffer.dart';
import 'lazy_archive.dart';
import 'lazy_archive_file.dart';
import 'lazy_zip_directory.dart';
import 'lazy_zip_file.dart';
import 'lazy_zip_file_header.dart';

/// Decode a zip formatted buffer into an [Archive] object.
class LazyZipDecoder {
  LazyZipDirectory directory;

  Future<LazyArchive> decodeBuffer(File file, {String password}) async {
    final fileBuffer = await FileBuffer.from(file);
    LazyArchive _archive = LazyArchive();
    directory = LazyZipDirectory();
    return directory.load(fileBuffer, password: password).then((_) {
      for (LazyZipFileHeader zfh in directory.fileHeaders) {
        LazyZipFile zf = zfh.file;

        // The attributes are stored in base 8
        final mode = zfh.externalFileAttributes;
        final compress = zf.compressionMethod != archive.ZipFile.STORE;

        var file = LazyArchiveFile(
            zfh, zf.filename, zf.uncompressedSize, zf.compressionMethod);

        file.mode = mode >> 16;

        // see https://github.com/brendan-duncan/archive/issues/21
        // UNIX systems has a creator version of 3 decimal at 1 byte offset
        if (zfh.versionMadeBy >> 8 == 3) {
          //final bool isDirectory = file.mode & 0x7000 == 0x4000;
          final bool isFile = file.mode & 0x3F000 == 0x8000;
          file.isFile = isFile;
        } else {
          file.isFile = !file.name.endsWith('/');
        }

        file.crc32 = zf.crc32;
        file.compress = compress;
        file.lastModTime = zf.lastModFileDate << 16 | zf.lastModFileTime;

        _archive.addFile(file);
      }

      return _archive;
    }).catchError((ex, st) {
      Fimber.d("ERROR", ex: ex, stacktrace: st);
    }).whenComplete(fileBuffer.close);
  }
}