import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../theme/app_colors.dart';

// One picker/upload at a time, including taps from separate profile entry points.
bool _avatarBusy = false;

String? avatarValidationMessage(List<int> bytes) {
  if (bytes.isEmpty) return 'La imagen está vacía. Elige otra foto.';
  if (bytes.length > 5 * 1024 * 1024) return 'Elige una imagen de hasta 5 MB.';
  bool starts(List<int> signature) =>
      bytes.length >= signature.length &&
      List.generate(
        signature.length,
        (i) => bytes[i] == signature[i],
      ).every((v) => v);
  final png = starts([137, 80, 78, 71, 13, 10, 26, 10]);
  final jpg = starts([255, 216, 255]);
  final webp =
      starts([82, 73, 70, 70]) &&
      bytes.length >= 12 &&
      bytes.sublist(8, 12).join(',') == '87,69,66,80';
  return png || jpg || webp ? null : 'Elige una foto JPG, PNG o WEBP.';
}

Future<void> pickAndUploadAvatar(BuildContext context) async {
  if (_avatarBusy) return;
  final auth = context.read<AuthController>();
  final userId = auth.currentUser?.id;
  final messenger = ScaffoldMessenger.of(context);
  _avatarBusy = true;
  var showingProgress = false;
  try {
    if (userId == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Vuelve a iniciar sesión para cambiar tu foto.'),
        ),
      );
      return;
    }
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (picked == null || !context.mounted || auth.currentUser?.id != userId) {
      return;
    }
    final bytes = await picked.readAsBytes();
    if (!context.mounted || auth.currentUser?.id != userId) return;
    final validation = avatarValidationMessage(bytes);
    if (validation != null) {
      messenger.showSnackBar(SnackBar(content: Text(validation)));
      return;
    }
    messenger.showSnackBar(
      const SnackBar(
        duration: Duration(minutes: 2),
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Expanded(child: Text('Guardando tu foto…')),
          ],
        ),
      ),
    );
    showingProgress = true;
    await auth.uploadAvatar(fileBytes: bytes, filename: picked.name);
    if (!context.mounted || auth.currentUser?.id != userId) return;
    messenger.hideCurrentSnackBar();
    showingProgress = false;
    messenger.showSnackBar(
      const SnackBar(content: Text('Tu foto de perfil está actualizada.')),
    );
  } catch (_) {
    if (context.mounted) {
      messenger.hideCurrentSnackBar();
      showingProgress = false;
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'No pudimos cambiar tu foto. Revisa el permiso de fotos y tu conexión e inténtalo otra vez.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  } finally {
    if (showingProgress && messenger.mounted) messenger.hideCurrentSnackBar();
    _avatarBusy = false;
  }
}
