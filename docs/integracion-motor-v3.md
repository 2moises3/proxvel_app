# Integración Flutter con el motor V3

Backend compatible: `prox_back` a partir de `5c51b0f`, snapshot `tesis-v3-20261022`.

## Contratos revisados

- Onboarding y Preferencias permiten seleccionar uno de los siete tipos de viajero. El modelo conserva y envía `perfil_turistico` al guardar el perfil. Un perfil anterior debe completar este dato; no se le asigna un estilo automáticamente.
- `TravelerVocabulary` contiene los 13 intereses del snapshot. Compras y Negocios no pertenecen a esta taxonomía. Climas: Frío, Templado, Cálido, Seco e Indiferente.
- El backend acepta `limit` entre 1 y 100. La app solicita hasta 100 para disponer del ranking completo; el universo científico contiene 14 destinos y se aplican las restricciones de visibilidad del backend.
- La caché del ranking del detalle distingue versión, usuario, perfil y mes. Los cambios de preferencias invalidan las recomendaciones y las respuestas antiguas no deben sustituir una carga posterior. Al cambiar de sesión se limpia la caché personalizada.
- `ExplanationModel` conserva `shap_base` y `shap_values`. El detalle muestra los aportes de afinidad, clima y afluencia en «Para ti» → «Cómo se ordena este destino». Son aportes al puntaje, no probabilidades ni causas demostradas.
- Presupuesto y días son información de referencia; no modifican el ranking del núcleo V3. La valoración ABSA de costos sí participa según los pesos científicos.

## Reproducir la revisión

Desde la raíz de esta app:

```sh
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

La URL de ejemplo sirve para web/desktop local. En Android emulado el host local normalmente se alcanza mediante `10.0.2.2`. Para el backend desplegado se debe proporcionar su URL HTTPS con sufijo `/api/v1` mediante `API_BASE_URL`; consultar `.env.example`. No versionar el archivo `.env` real.

Las pruebas de `test/integration/motor_v3_contract_test.dart` usan una API simulada para verificar serialización y caché. No prueban la base de datos desplegada. El push de Flutter comparte el código; no actualiza una instalación móvil existente.

## Pendientes para lanzamiento

Confirmar el despliegue y la migración del backend en Railway, probar el flujo completo en Android físico y aprobar los borradores legales con el responsable del producto. Esta entrega de código no certifica esos pasos.
