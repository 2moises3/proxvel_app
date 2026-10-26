# Sistema visual de PROXVEL

Reglas de mantenimiento de la app móvil. Esta consolidación utiliza la identidad existente; el benchmarking y el rediseño de producto se trabajarán aparte.

## Fuentes de verdad

- `lib/core/theme/app_colors.dart`: paleta y estados semánticos.
- `lib/core/theme/app_text_styles.dart`: roles tipográficos.
- `lib/core/theme/app_layout.dart`: espacios, radios, tamaños y movimiento local.
- `lib/core/theme/app_theme.dart`: adapta los roles a Material. No define una segunda escala.

## Color y fotografía

Se conservan oscuro, ámbar y superficies neutras. El ámbar señala la acción principal; el oscuro estructura cabeceras y texto. El estado ámbar presionado centraliza el tono que ya usaba el acceso. Los colores de error y éxito existentes conservan su significado funcional.

Acceso y registro conservan fotografías y campos translúcidos. Las pantallas interiores usan superficies claras para lectura. Comparten tipografía, márgenes y geometría de controles; no es necesario oscurecer los formularios interiores para relacionarlas. Las imágenes de destinos siguen viniendo del backend.

## Tipografía

Outfit es la familia común y se hereda del tema (`AppTypography`).

| Uso | Rol | Tamaño/peso |
| --- | --- | --- |
| Título sobre fotografía | headingOnDark | 32 / 700 |
| Título principal | h1 | 28 / 700 |
| Encabezado de bloque principal | h2 | 24 / 700 |
| Sección y barra de pantalla | sectionTitle | 18 / 700 |
| Tarjeta y desplegable | cardTitle | 16 / 600 |
| Lectura | body1 / bodySecondary | 14 / 400, interlínea 1,5 |
| Aclaración | body2 | 13 / 400, interlínea 1,4 |
| Acción | button | 15 / 600 |
| Etiqueta secundaria | labelSmall / caption | 12 |

Las variantes sobre oscuro o de texto secundario conservan el tamaño de su rol. Números destacados, marcadores de mapa y animación de marca pueden usar tratamientos propios. Evitar inventar un nuevo tamaño para otro título del mismo nivel.

## Espaciado

| Relación | Token | dp |
| --- | --- | --- |
| Icono pequeño o detalle inmediato | micro | 4 |
| Elementos muy relacionados | related | 8 |
| Título con contenido | content | 12 |
| Campos consecutivos | field | 16 |
| Interior de tarjeta | card | 20 |
| Secciones consecutivas | section | 24 |
| Grupos de mayor independencia | group | 32 |
| Separación protagonista | hero | 40 |
| Borde de pantalla | screen | 24 |

El contenedor padre define la separación entre campos. `ProxvelTextField` no añade un margen externo oculto. La ficha cuenta el remate curvo como parte de su espacio superior: no se debe sumar otro margen completo sobre él.

## Componentes

- Controles de formulario y acciones principales: radio 16.
- Tarjetas de contenido principales: radio 20. Las variantes compactas pueden mantener radio 16.
- Etiquetas: radio 12; cápsulas y círculos se reservan para chips, indicadores y controles flotantes existentes.
- Paneles y diálogos: radio 28.
- Acción principal: ámbar y texto oscuro; secundaria: contorno y texto oscuro. Una acción destructiva mantiene su color semántico.
- Altura mínima de botón: 56, con crecimiento para texto ampliado. Referencia de área táctil: 48.
- Los botones de formulario permanecen en su sitio durante la espera y se deshabilitan para evitar nuevos toques.
- Vacío, error y perfil incompleto usan `ProxvelEmptyState`, con desplazamiento si el alto disponible es pequeño.

No forzar todas las tarjetas fotográficas al mismo tamaño: su composición depende de si son protagonistas o filas compactas. Las variaciones deben preservar jerarquía, márgenes y lectura.

## Información del destino

Primero aparecen identificación, datos de visita y navegación de contenido. En la explicación personalizada se priorizan etiqueta, afinidad y posición mensual. La distinción entre afinidad y probabilidad permanece visible; el desarrollo se consulta en un desplegable. El valor de gasto se distingue visualmente de su aclaración. No se cambian parámetros ni resultados del motor para simplificar la interfaz.

## Movimiento

### Continuidad visual obligatoria

- Antes de dar por terminado un cambio visual, revisar la transición completa de ida y vuelta, no solo capturas de los estados finales.
- Al ocultar controles (por ejemplo, el buscador entre Explorar y Para ti), conservar el encuadre y la escala de la fotografía, y la posición de los elementos que permanecen. No recalcular el `BoxFit.cover` según la altura contraída.
- Desvanecer el control durante la contracción del espacio: no retirarlo de golpe y luego animar únicamente su contenedor. El espacio sobrante debe desaparecer sin saltos ni escalado del texto.
- Las inversiones rápidas de dirección deben continuar desde el estado visible actual. Los controles ocultos no reciben pulsaciones ni aparecen como acciones accesibles.
- Validar cuadros intermedios, cambios rápidos de pestaña, texto ampliado, desplazamiento y reducción de movimiento. Reducir animaciones elimina la transición, pero conserva exactamente el encuadre.
- En el hero de Inicio, la fotografía mantiene el tamaño natural del diseño expandido y solo se recorta el área del buscador; su contenido se desvanece mientras se libera el espacio.

`AppMotion` define 180 ms para respuesta breve y 260 ms para cambios locales, con `easeOutCubic`. Se usa en foco, selección, expansión de perfil, contenido de ficha y pasos del registro. La opción del sistema de reducir animaciones elimina esos movimientos; el cambio de paso del registro se renderiza directamente. El brillo de botones no se dibuja en ese modo ni durante una operación.

No se añadieron transformaciones a la barra inferior ni nuevas bibliotecas de animación. La animación de marca y los movimientos fotográficos existentes requieren su propia evaluación antes de rediseñarlos.

## Verificación

Al modificar componentes compartidos, comprobar 320, 360 y 390 dp, texto ampliado y teclado. Usar el tema real en las pruebas de acceso. Revisar que un contenedor con color no tape el feedback de un desplegable Material. La revisión móvil web complementa, pero no sustituye, la validación en Android físico.

## Segunda consolidación: acceso y lectura del destino

Los fondos `auth_andes_v1.png`, `auth_costa_v1.png` y `auth_selva_v1.png` son ambientaciones generadas, sin relación documental con una ficha del catálogo. No deben reutilizarse como fotos reales de un destino.

La bienvenida rota los fondos cada 8 segundos mediante una disolución de 1,2 segundos. Precarga el siguiente paisaje con decodificación a 720 px. Pausa al cubrirse por otra ruta, al entrar la app en segundo plano o al activar reducción de movimiento. Login, registro y residencia capturan una imagen fija de esa misma selección. El onboarding mantiene esa dirección fotográfica en su cabecera.

El lenguaje prioriza orientación y autonomía: “Destinos para ti”, “Tu forma de viajar”, “Qué te espera” y “Prepara tu visita”. Las etiquetas científicas, afinidad y posiciones del motor permanecen intactas. Una descripción breve no ofrece un desplegable innecesario. Los detalles de valoraciones se consultan a demanda y no se duplican como chips.

Los datos prácticos se agrupan en una tarjeta con separadores suaves. Las tarjetas editoriales adaptan su alto al texto ampliado. Los ordinales de descubrimiento se retiraron porque el catálogo no representa una tendencia o clasificación de popularidad. Los iconos de preferencias y onboarding usan la familia Material existente.

`DestinationOpening` y `DestinationHero` conectan la imagen de las tarjetas del carrusel, recomendaciones y búsqueda con la ficha. La vista previa procede de la tarjeta real y solo se muestra si coincide el ID solicitado. El detalle vuelve a consultar la API. Las transiciones se omiten con reducción de movimiento; la navegación inferior no incorpora efectos nuevos. Se conserva el desplazamiento de los listados.


## Ficha inmersiva y ubicación (octubre 2026)

La ficha abre con una portada de un viewport y miniaturas horizontales. Con texto ampliado, el contenido puede crecer; nunca se corta para conservar una altura estética. El cambio de foto usa una disolución sin modificar su encuadre. Debajo: El lugar, Para ti y Reseñas, siempre en ese orden.

La información breve usa iconos SVG locales de la familia Lucide (`AppIcon`); se reutilizan los existentes y se incluye licencia para nuevos recursos. Los hechos prácticos usan mini tarjetas; las indicaciones largas se despliegan a demanda. Los datos faltantes no se sustituyen por supuestos.

No mezclar distancia y afinidad: la primera se calcula en el dispositivo, en línea recta; la segunda procede del motor. El aviso de ubicación es opcional y respeta la elección de no mostrarlo durante el día. Los datos del GPS no se envían al recomendador.

Los desplegables dentro de un scroll con PageStorageKey deben tener su propia PageStorageKey única: nunca compartir el estado abierto/cerrado con el desplazamiento numérico del padre. Verificar el cambio de pestañas después de desplazar la ficha y volver a abrir cada desplegable.



### Destino y recomendación: continuidad de interacción
- El selector mensual conserva el abanico en cada apertura, aunque cambien el scroll o el alto del hero. Ajustar su origen al área visible; en pantallas bajas permitir desplazar el lienzo, sin sustituirlo por otra interacción.
- Cerrar el selector antes de notificar el cambio de mes: las entradas de los resultados no deben consumirse detrás de una capa opaca.
- El detalle abierto desde recomendaciones prioriza Para ti; desde Explorar prioriza El lugar. Las pestañas permanecen accesibles durante el scroll.
- Separar afinidad del perfil, contribuciones al ranking y contexto mensual. No presentar estos valores como probabilidades. Los meses sin datos dejan huecos en el gráfico.
