import '../../core/localization/l10n.dart';
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
  String? _message;
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
      _message = null;
    });
    try {
      if (kIsWeb || !Platform.isAndroid) {
        setState(
          () => _message =
              context.l10n.uiLasActualizacionesSeInstalanDesdeProxvel,
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
            ? context.l10n.uiYaTienesLaUltimaVersionPublicada
            : context.l10n.uiNuevaVersionDisponible;
      });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _message =
            context.l10n.uiNoPudimosComprobarLasActualizacionesRevisa,
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
        setState(() => _message = context.l10n.uiConfirmaLaInstalacionEnAndroid);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = context.l10n.updateInstallError,
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: profilePageBar(context, context.l10n.updates),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_message ?? context.l10n.uiBuscandoActualizaciones, style: Theme.of(context).textTheme.titleLarge),
          if (_installedVersion.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(context.l10n.installedVersion(_installedVersion)),
          ],
          if (_release case final release?) ...[
            const SizedBox(height: 12),
            Text(context.l10n.availableVersion('${release.versionName}+${release.versionCode}')),
            if (release.changelog != null && release.changelog!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(release.changelog!),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _downloading ? null : _install,
              child: Text(
                _downloading ? 'Descargando…' : context.l10n.uiDescargarEInstalar,
              ),
            ),
            if (_downloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress),
            ],
            const SizedBox(height: 16),
            Text(
              context.l10n.uiAndroidPuedePedirtePermisoParaInstalar,
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
              child: Text(context.l10n.uiVolverAComprobar),
            ),
        ],
      ),
    ),
  );
}
