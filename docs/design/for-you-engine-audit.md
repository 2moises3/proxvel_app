# Para ti — revisión 2026-10-26

## Contrato observado en el código local
- `/recommendations/me` requiere sesión y perfil. La app usa getMyRecommendations, sin fallback de datos simulados.
- Motor tesis V3: afinidad de intereses y calidad ABSA; reordenamiento mensual con clima y afluencia históricos. Presupuesto y días no cambian sus puntajes.
- `month` acepta 1–12. Omitirlo usa el mes actual del servidor. No existe un ranking anual o Todos. La opción automática se llama Actual; no se agregó una fórmula anual ni se modificó la del motor.
- La app solicita hasta 100 resultados (máximo actual de API), suficiente para el catálogo de 14. Se retiró el recorte visual a tres. Se muestran etiquetas Recomendado y Parcialmente recomendado, conservando orden; No recomendado queda fuera de Para ti.
- La etiqueta depende de cobertura de intereses y calidad, no del mes. El porcentaje es afinidad normalizada, no probabilidad. No se inventan estrellas, popularidad o probabilidades.
- Archivados se persiste vía `/archives`; la app oculta esos IDs después del cálculo. No se alimenta al motor como aprendizaje de visitas. Se usa Ocultar destino y se permite recuperar desde Archivados.

## Interacción
- Hero compartido, sin buscador en Para ti.
- Una fila para editar preferencias y mes. Mantener, arrastrar y soltar selecciona; tocar también abre. Solo se consulta al confirmar. Escape cancela; flechas y Enter permiten teclado. Panel alternativo para espacio limitado o texto ampliado.
- La petición nueva invalida respuestas antiguas mediante generation en RecommendationController.
- Tarjetas sin ranking numerado; muestran fotografía, ubicación, etiqueta y explicación real, con favorito y menú para ocultar.
- Error de archivado revierte estado; error de recarga conserva exclusiones conocidas.

## Validación y límites
- Pruebas locales del motor, meses, puntuación, explicación, perfiles inválidos y campos inactivos.
- Pruebas Flutter de selección por arrastre, cancelación, texto ampliado, lista de más de tres, archivados y respuestas fuera de orden.
- Inspección de capturas renderizadas. No se inició sesión en Railway ni se comprobó que producción ejecute el mismo commit; no se publicaron cambios.
