# Publicar PROXVEL para Android

## Primera vez: firma

1. Desde la carpeta de la app, ejecuta `powershell -File scripts/setup_android_signing.ps1`. Si estás en otra carpeta, pasa la ruta absoluta del script a `-File`. El script invoca `keytool` de forma interactiva y guarda la llave fuera del repositorio, en `%USERPROFILE%/.proxvel-signing/proxvel-release.jks`. Usa una contraseña aleatoria alfanumérica de al menos 20 caracteres creada en tu gestor; no la pases como argumento ni la envíes por chat.
2. El script escribe `android/key.properties` localmente para Gradle. El archivo está ignorado por Git. Si necesitas configurarlo manualmente, usa `android/key.properties.example` como guía.
3. Guarda una copia de la llave y las contraseñas en lugares seguros separados. Todas las versiones futuras deberán firmarse con esta misma llave.

## Cada versión

1. Incrementa `version` en `pubspec.yaml` (`nombre+código`; el código siempre aumenta).
2. Compila: `flutter build apk --release --dart-define-from-file=.env`. El APK sale en `build/app/outputs/flutter-apk/app-release.apk`. La URL de Railway también está configurada como fallback de producción.
3. Comprueba el paquete, versión y firma con `aapt dump badging` y `apksigner verify --print-certs` del Android SDK.
4. Crea un GitHub Release público en `2moises3/proxvel_app` con etiqueta como `v1.0.0` y adjunta el APK con el nombre `PROXVEL.apk`. No hagas commit del APK al repositorio.
5. En el dashboard, registra una versión Android con exactamente el mismo nombre y código del APK. Pega la URL **de esa versión**, por ejemplo `https://github.com/2moises3/proxvel_app/releases/download/v1.0.0/PROXVEL.apk`, y publica. No uses `/releases/latest/download/` en el dashboard, porque puede apuntar a un Release distinto de la versión publicada allí.
6. Verifica `GET /api/v1/releases/latest?platform=android` y la descarga `/api/v1/releases/latest/download`. El botón y el QR de la landing pasan a esa URL cuando existe una versión publicada. La app ofrece la actualización cuando `version_code` es mayor que el instalado.

El APK beta que estaba en la landing tenía otro identificador de paquete y una firma de depuración. Quienes lo instalaron tendrán que desinstalarlo e instalar esta primera versión definitiva; después podrán actualizar sobre la instalación existente.
