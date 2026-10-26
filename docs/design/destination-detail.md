# Ficha de destino

- Portada de un viewport; fotografía sin reencuadrado al cambiar de pestaña. Con texto grande, el alto puede crecer para evitar recortes.
- Orden: El lugar, Para ti, Reseñas. La información práctica precede al análisis del motor.
- Contratos revisados: backend `tourism_schema.py`, `review_schema.py`, `review_routes.py`, `db_review_repository.py` y controlador de destino.
- Sin precios, horarios, teléfonos, fotos de autores ni servicios inventados. Los datos ausentes se omiten. El mapa actual se conserva.
- La afinidad, explicación, contexto y calendario vienen de los servicios existentes; el porcentaje no es una probabilidad.
- Promedio y distribución calculados de las reseñas visibles recibidas. Crear reseña exige puntuación 1–5 y comentario; no se ofrecen adjuntos porque la API no los admite.
- Ubicación opcional: permiso solo por acción explícita; lectura automática solo cuando ya existe permiso. Distancias en línea recta calculadas localmente. No modifica el motor. Se conserva la posición en memoria, y solo se persiste el día de ocultación del aviso.
- SVG locales Lucide (MIT), incluidos clock, mountain, wallet, route, accessibility, info y external-link. Fuente: https://github.com/lucide-icons/lucide/tree/main/icons. Licencia incluida en assets/icons/app/LUCIDE-LICENSE.txt.
