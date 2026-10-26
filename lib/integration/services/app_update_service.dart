import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../api/api_config.dart';

class AppRelease {
  final String versionName;
  final int versionCode;
  final String apkUrl;
  final String? changelog;

  const AppRelease({
    required this.versionName,
    required this.versionCode,
    required this.apkUrl,
    this.changelog,
  });

  factory AppRelease.fromJson(Map<String, dynamic> json) => AppRelease(
    versionName: json['version_name'] as String,
    versionCode: json['version_code'] as int,
    apkUrl: json['apk_url'] as String,
    changelog: json['changelog'] as String?,
  );
}

class AppUpdateService {
  Future<AppRelease?> latestAvailable() async {
    if (kIsWeb || !Platform.isAndroid) return null;
    final response = await http
        .get(Uri.parse('${ApiConfig.baseUrl}/releases/latest?platform=android'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('No se pudo consultar la versión');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final releaseData = data['data'];
    if (releaseData is! Map<String, dynamic> || releaseData['apk_url'] == null) {
      return null;
    }
    final release = AppRelease.fromJson(releaseData);
    final installed = await PackageInfo.fromPlatform();
    final installedCode = int.tryParse(installed.buildNumber) ?? 0;
    return release.versionCode > installedCode ? release : null;
  }

  Future<void> downloadAndInstall(
    AppRelease release,
    void Function(double) onProgress,
  ) async {
    final uri = Uri.tryParse(release.apkUrl);
    if (uri == null || uri.scheme != 'https') {
      throw Exception('La URL del APK debe usar HTTPS');
    }

    final directory = await getTemporaryDirectory();
    final apk = File('${directory.path}/proxvel-${release.versionCode}.apk');
    final client = http.Client();
    try {
      final response = await client
          .send(http.Request('GET', uri))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw Exception('No se pudo descargar el APK');
      }
      if (response.request?.url.scheme != 'https') {
        throw Exception('La descarga dejó de usar HTTPS');
      }
      final file = await apk.open(mode: FileMode.write);
      var received = 0;
      try {
        await for (final chunk in response.stream) {
          received += chunk.length;
          if (received > 250 * 1024 * 1024) {
            throw Exception('El APK excede el tamaño permitido');
          }
          await file.writeFrom(chunk);
          if (response.contentLength != null && response.contentLength! > 0) {
            onProgress(received / response.contentLength!);
          }
        }
      } finally {
        await file.close();
      }
      if (received == 0 ||
          (response.contentLength != null &&
              received != response.contentLength)) {
        throw Exception('La descarga del APK quedó incompleta');
      }
      final reader = await apk.open();
      try {
        final signature = await reader.read(4);
        if (signature.length != 4 ||
            signature[0] != 0x50 ||
            signature[1] != 0x4b ||
            signature[2] != 0x03 ||
            signature[3] != 0x04) {
          throw Exception('El archivo descargado no es un APK válido');
        }
      } finally {
        await reader.close();
      }
      final result = await OpenFilex.open(
        apk.path,
        type: 'application/vnd.android.package-archive',
      );
      if (result.type != ResultType.done) throw Exception(result.message);
    } catch (_) {
      if (await apk.exists()) await apk.delete();
      rethrow;
    } finally {
      client.close();
    }
  }
}
