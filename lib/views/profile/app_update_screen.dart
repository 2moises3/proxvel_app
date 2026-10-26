import 'package:flutter/foundation.dart';
import 'widgets/profile_page_bar.dart';
import '../../core/theme/app_colors.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../integration/services/app_update_service.dart';

class AppUpdateScreen extends StatefulWidget {
  const AppUpdateScreen({super.key});

  @override
  State<AppUpdateScreen> createState() => _AppUpdateScreenState();
}

class _AppUpdateScreenState extends State<AppUpdateScreen> {
  final _service = AppUpdateService();
  AppRelease? _release;
  String _message = 'Buscando actualizaciones…';
  bool _checking = true;
  bool _downloading = false;
  double? _progress;
  String _installedVersion = '';

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _message = 'Buscando actualizaciones…';
    });
    try {
      if (kIsWeb || !Platform.isAndroid) {
        setState(
          () => _message =
              'Las actualizaciones se instalan desde PROXVEL para Android.',
        );
        return;
      }
      final installed = await PackageInfo.fromPlatform();
      final release = await _service.latestAvailable();
      if (!mounted) return;
      setState(() {
        _installedVersion = '${installed.version}+${installed.buildNumber}';
        _release = release;
        _message = release == null
            ? 'Ya tienes la última versión publicada.'
            : 'Nueva versión disponible';
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _message =
            'No pudimos comprobar las actualizaciones. Revisa tu conexión.',
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _install() async {
    final release = _release;
    if (release == null || _downloading) return;
    setState(() {
      _downloading = true;
      _progress = null;
    });
    try {
      await _service.downloadAndInstall(release, (progress) {
        if (mounted) setState(() => _progress = progress);
      });
      if (mounted) {
        setState(() => _message = 'Confirma la instalación en Android.');
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = 'No se pudo instalar la actualización: $error',
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: profilePageBar(context, 'Actualizaciones'),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_message, style: Theme.of(context).textTheme.titleLarge),
          if (_installedVersion.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Versión instalada: $_installedVersion'),
          ],
          if (_release case final release?) ...[
            const SizedBox(height: 12),
            Text('Disponible: ${release.versionName}+${release.versionCode}'),
            if (release.changelog != null && release.changelog!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(release.changelog!),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _downloading ? null : _install,
              child: Text(
                _downloading ? 'Descargando…' : 'Descargar e instalar',
              ),
            ),
            if (_downloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress),
            ],
            const SizedBox(height: 16),
            const Text(
              'Android puede pedirte permiso para instalar desde PROXVEL y confirmar la actualización.',
            ),
          ],
          if (_checking)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: CircularProgressIndicator(),
            ),
          if (!_checking && !_downloading && !kIsWeb && Platform.isAndroid)
            TextButton(
              onPressed: _check,
              child: const Text('Volver a comprobar'),
            ),
        ],
      ),
    ),
  );
}
