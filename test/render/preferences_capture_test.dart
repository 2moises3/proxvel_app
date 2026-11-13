import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proxvell_app/core/theme/app_theme.dart';
import 'package:proxvell_app/controllers/profile_controller.dart';
import 'package:proxvell_app/integration/local/local_storage_service.dart';
import 'package:proxvell_app/integration/services/profile_service.dart';
import 'package:proxvell_app/views/profile/preferences_screen.dart';
class PreviewProfile extends ProfileController {
 PreviewProfile(LocalStorageService storage):super(ProfileService(storage),storage);
 @override Future<void> loadProfileData() async {}
}
void main(){testWidgets('render real preferences without account or API writes',(tester)async{
 final outfit=FontLoader('Outfit'); for(final name in ['Regular','Medium','SemiBold','Bold']) { outfit.addFont(rootBundle.load('assets/fonts/outfit/Outfit-$name.ttf')); } await outfit.load();
 final icons=FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));await icons.load();
 SharedPreferences.setMockInitialValues({});final storage=LocalStorageService();await storage.init();
 tester.view.physicalSize=const Size(430,900);tester.view.devicePixelRatio=1;
 final key=GlobalKey();
 await tester.pumpWidget(ChangeNotifierProvider<ProfileController>(create:(_)=>PreviewProfile(storage),child:MaterialApp(theme:AppTheme.lightTheme,debugShowCheckedModeBanner:false,home:RepaintBoundary(key:key,child:const PreferencesScreen()))));
 await tester.pump();await tester.pump(const Duration(seconds:1));
 final option=find.text('Cultural');if(option.evaluate().isNotEmpty){await tester.tap(option.first);await tester.pump();}
 final boundary=key.currentContext!.findRenderObject() as RenderRepaintBoundary;
 await tester.runAsync(()async{final image=await boundary.toImage(pixelRatio:2);final bytes=await image.toByteData(format:ui.ImageByteFormat.png);File('../proxvel_landing/.artifacts/preferences-outfit.png').writeAsBytesSync(bytes!.buffer.asUint8List());image.dispose();});
 await tester.pumpWidget(const SizedBox.shrink());
});}
