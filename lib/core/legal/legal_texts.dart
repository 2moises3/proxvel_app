// GENERADO: textos legales de PROXVEL. No editar a mano: se regeneran junto con las páginas
// de la landing para que ambos digan exactamente lo mismo.

/// Versión vigente de los Términos y la Política de Privacidad.
/// Debe coincidir con TERMS_VERSION del backend (app/core/legal.py).
const String kLegalVersion = '1.0';
const String kLegalUpdated = '19 de octubre de 2026';
const String kSupportEmail = 'soporte@m3biznovatech.com';

class LegalBlock {
  /// 'h' = título de sección, 'p' = párrafo, 'ul' = lista.
  final String type;
  final String text;
  final List<String> items;
  const LegalBlock.h(this.text)
      : type = 'h',
        items = const [];
  const LegalBlock.p(this.text)
      : type = 'p',
        items = const [];
  const LegalBlock.ul(this.items)
      : type = 'ul',
        text = '';
}

class LegalDoc {
  final String id;
  final String title;
  final List<LegalBlock> blocks;
  const LegalDoc(this.id, this.title, this.blocks);
}


const LegalDoc privacyPolicy = LegalDoc('privacidad', 'Política de Privacidad', [
  LegalBlock.h('1. Quién es el responsable'),
  LegalBlock.p('Biznovatech S.A.C. (nombre comercial M3Biznovatech), con domicilio en Ñaña, Lurigancho-Chosica, Lima, Perú. Escríbenos a soporte@m3biznovatech.com para cualquier consulta sobre tus datos.'),
  LegalBlock.h('2. Qué es PROXVEL y a quién va dirigida'),
  LegalBlock.p('PROXVEL es una aplicación que recomienda destinos turísticos del Perú según tus preferencias de viaje. Está dirigida a personas mayores de 18 años. Si eres menor de edad, no debes crear una cuenta.'),
  LegalBlock.h('3. Qué datos tratamos y para qué'),
  LegalBlock.ul([
    'Nombre y apellidos, correo y contraseña: para crear y proteger tu cuenta, iniciar sesión y enviarte avisos de seguridad. La contraseña se guarda cifrada; nadie, ni nosotros, puede leerla.',
    'Lugar de residencia (departamento, provincia y distrito): información de tu perfil. El motor V3 no la utiliza para ordenar destinos.',
    'Estilo de viajero, intereses, clima preferido y tolerancia a multitudes: para generar recomendaciones. Presupuesto y días de viaje: referencia de planificación, sin efecto en el ranking V3.',
    'Favoritos, destinos archivados y notificaciones: para mostrarte tu información dentro de la app.',
    'Reseñas (calificación, comentario y, si lo eliges, el aspecto evaluado): para mostrarlas a otros viajeros y mejorar nuestro modelo (ver punto 5).',
    'Foto de perfil (opcional): para mostrarla en tu perfil.',
    'Registros de seguridad (tu dirección IP y los intentos de acceso, cambios de contraseña y eliminaciones de cuenta): para proteger tu cuenta y prevenir abusos.',
  ]),
  LegalBlock.h('4. Ubicación'),
  LegalBlock.p('Si lo autorizas, tu teléfono usa el GPS únicamente para calcular qué tan lejos estás de un destino. Esa ubicación no sale de tu teléfono ni se guarda en nuestros servidores.'),
  LegalBlock.h('5. Tus reseñas y la mejora del modelo'),
  LegalBlock.p('Tu reseña se muestra a otros viajeros con tu nombre y la inicial de tu apellido (por ejemplo, «Lucía G.»). Además, podemos usar el texto y la calificación de tus reseñas, sin tu nombre, para analizar y mejorar el modelo de recomendación. Esto lo hacemos solo de forma interna.'),
  LegalBlock.h('6. Lo que no hacemos'),
  LegalBlock.ul([
    'No vendemos tus datos ni los cedemos a otras empresas.',
    'No mostramos publicidad ni usamos herramientas de analítica o seguimiento.',
    'Las recomendaciones las genera un modelo estadístico con fines informativos; no producen efectos legales sobre ti.',
  ]),
  LegalBlock.h('7. Con quién se comparten'),
  LegalBlock.p('Solo con los proveedores que necesitamos para que PROXVEL funcione:'),
  LegalBlock.ul([
    'Cloudinary: almacenamiento de imágenes, incluida tu foto de perfil. Sus servidores están fuera del Perú.',
    'OpenStreetMap: proveedor de los mapas. Al cargar un mapa recibe tu dirección IP.',
    'Proveedor de alojamiento del servidor y la base de datos (por ahora, tu servidor local de pruebas; al publicar la app usaremos un proveedor en la nube y lo indicaremos aquí).',
  ]),
  LegalBlock.h('8. Cuánto tiempo conservamos tus datos'),
  LegalBlock.ul([
    'Cuenta y preferencias: mientras tu cuenta esté activa.',
    'Si pides eliminar tu cuenta: tu acceso se bloquea de inmediato y tienes 14 días para arrepentirte escribiendo a soporte@m3biznovatech.com. Pasado ese plazo borramos tu perfil, favoritos, archivados, notificaciones, foto y datos de residencia, y anonimizamos tu nombre y correo.',
    'Reseñas: se conservan sin identificarte, para mejorar el modelo.',
    'Registros de seguridad (IP): hasta 90 días; luego se borran automáticamente.',
  ]),
  LegalBlock.h('9. Tus derechos'),
  LegalBlock.p('Puedes pedir acceso, rectificación, cancelación, oposición y portabilidad de tus datos escribiendo a soporte@m3biznovatech.com desde el correo de tu cuenta. Responderemos dentro de 20 días hábiles. Puedes eliminar tu cuenta tú mismo desde la app (Perfil > Privacidad y legal > Mis datos). Si consideras que no atendimos tu solicitud, puedes acudir a la Autoridad Nacional de Protección de Datos Personales (Ministerio de Justicia y Derechos Humanos).'),
  LegalBlock.h('10. Seguridad'),
  LegalBlock.p('Protegemos tus datos con contraseñas cifradas, conexión cifrada, límite de intentos de acceso y cierre de sesiones cuando cambias tu contraseña (también puedes cerrar la sesión en todos tus dispositivos desde tu perfil). Ningún sistema es infalible: si ocurre un incidente que te afecte, te lo informaremos y avisaremos a la autoridad dentro de los plazos legales.'),
  LegalBlock.h('11. Cambios en esta política'),
  LegalBlock.p('Si la cambiamos de forma importante, te avisaremos en la app y te pediremos aceptarla otra vez. Siempre indicaremos la versión y la fecha de la última actualización.'),
]);

const LegalDoc termsOfUse = LegalDoc('terminos', 'Términos y Condiciones', [
  LegalBlock.h('1. Aceptación y edad'),
  LegalBlock.p('Al crear una cuenta declaras que eres mayor de 18 años y aceptas estos Términos y la Política de Privacidad. Si no estás de acuerdo, no uses PROXVEL.'),
  LegalBlock.h('2. Tu cuenta'),
  LegalBlock.p('Debes dar datos verdaderos y cuidar tu contraseña. Eres responsable de lo que ocurra con tu cuenta. Si sospechas que alguien más la usa, cambia tu contraseña y escríbenos.'),
  LegalBlock.h('3. Uso permitido'),
  LegalBlock.p('No está permitido intentar vulnerar la seguridad de PROXVEL, extraer datos de forma masiva, hacerse pasar por otra persona ni usar la app para fines ilegales.'),
  LegalBlock.h('4. Reseñas de usuarios'),
  LegalBlock.ul([
    'Deben ser tu opinión sincera sobre una experiencia real. Tú respondes por lo que escribes.',
    'No pueden ser insultantes ni discriminatorias, ni contener datos personales de terceros ni publicidad.',
    'Nos autorizas a mostrarlas dentro de la app, a usarlas sin tu nombre para mejorar el modelo de recomendación (ver la Política de Privacidad) y a ocultar las que incumplan estas normas o sean reportadas por otros viajeros.',
  ]),
  LegalBlock.h('5. Información turística referencial'),
  LegalBlock.p('Las descripciones, tiempos, costos, clima y afluencia que muestra PROXVEL son orientativos. Horarios, tarifas, accesos y condiciones de seguridad cambian: verifícalos en las fuentes oficiales antes de viajar. No garantizamos su exactitud ni nos responsabilizamos por decisiones de viaje basadas únicamente en la app.'),
  LegalBlock.h('6. Recomendaciones'),
  LegalBlock.p('Las recomendaciones las genera un modelo estadístico a partir de tus preferencias y de datos de clima, afluencia y opiniones. No sustituyen tu criterio.'),
  LegalBlock.h('7. Versión beta'),
  LegalBlock.p('PROXVEL está en fase beta: puede tener errores y cambiar sin previo aviso, y no garantizamos que esté siempre disponible.'),
  LegalBlock.h('8. Propiedad intelectual'),
  LegalBlock.p('La app, su marca, su diseño y su código pertenecen a Biznovatech S.A.C. Los datos y mapas de terceros mantienen sus propias licencias (ver «Fuentes y licencias»).'),
  LegalBlock.h('9. Suspensión de cuentas'),
  LegalBlock.p('Podemos suspender o cerrar cuentas que incumplan estos Términos. Tú puedes eliminar tu cuenta cuando quieras desde la app.'),
  LegalBlock.h('10. Cambios'),
  LegalBlock.p('Podemos actualizar estos Términos. Si el cambio es importante, te lo avisaremos y te pediremos aceptarlos de nuevo.'),
  LegalBlock.h('11. Ley aplicable y contacto'),
  LegalBlock.p('Se aplica la legislación peruana. Para cualquier consulta escríbenos a soporte@m3biznovatech.com. Responsable: Biznovatech S.A.C. (nombre comercial M3Biznovatech), con domicilio en Ñaña, Lurigancho-Chosica, Lima, Perú.'),
]);

const LegalDoc myData = LegalDoc('mis-datos', 'Mis datos y eliminación de cuenta', [
  LegalBlock.h('Qué datos guardamos de ti'),
  LegalBlock.ul([
    'Cuenta: nombre y apellidos, correo, contraseña cifrada y residencia.',
    'Preferencias de viaje: intereses, clima, tolerancia a multitudes, presupuesto y días.',
    'Tu actividad: favoritos, destinos archivados, notificaciones y reseñas.',
    'Foto de perfil, si la subiste.',
    'Registros de seguridad (IP e intentos de acceso), por 90 días.',
    'Tu ubicación NO se guarda: el GPS se usa solo en tu teléfono.',
  ]),
  LegalBlock.h('Eliminar mi cuenta desde la app'),
  LegalBlock.p('Ve a Perfil > Privacidad y legal > Mis datos > Eliminar mi cuenta. Te pediremos tu contraseña para confirmar.'),
  LegalBlock.h('Eliminar mi cuenta si no puedo entrar a la app'),
  LegalBlock.p('Escribe a soporte@m3biznovatech.com desde el correo de tu cuenta con el asunto «Eliminar mi cuenta». Verificaremos que seas el titular y procesaremos tu solicitud.'),
  LegalBlock.h('Qué pasa cuando pides eliminarla'),
  LegalBlock.ul([
    'Tu acceso se bloquea de inmediato.',
    'Tienes 14 días para arrepentirte: escríbenos a soporte@m3biznovatech.com.',
    'Pasado ese plazo se borran tu perfil, favoritos, archivados, notificaciones, foto y datos de residencia, y se anonimizan tu nombre y correo.',
    'Tus reseñas se conservan sin identificarte, para mejorar el modelo.',
  ]),
  LegalBlock.h('Otros derechos: acceso, rectificación, oposición y portabilidad'),
  LegalBlock.p('Escríbenos a soporte@m3biznovatech.com desde el correo de tu cuenta indicando qué derecho quieres ejercer. Responderemos dentro de 20 días hábiles. Si no quedas conforme, puedes acudir a la Autoridad Nacional de Protección de Datos Personales.'),
  LegalBlock.h('Cerrar sesión en todos mis dispositivos'),
  LegalBlock.p('En la app: Perfil > Privacidad y legal > Mis datos > Cerrar sesión en todos mis dispositivos.'),
]);

const LegalDoc appPermissions = LegalDoc('permisos', 'Permisos de la app', [
  LegalBlock.h('Qué permisos usa PROXVEL y para qué'),
  LegalBlock.ul([
    'Internet: para comunicarse con nuestros servidores (tu cuenta, tus recomendaciones y los destinos) y cargar los mapas.',
    'Ubicación aproximada (opcional): solo para calcular qué tan lejos estás de un destino. Se usa en tu teléfono y no se envía ni se guarda en nuestros servidores. Puedes negarla: la app sigue funcionando.',
    'Fotos (opcional): al elegir tu foto de perfil se usa el selector de fotos de tu teléfono; la app solo recibe la imagen que tú elijas, no tu galería.',
  ]),
  LegalBlock.h('Cómo cambiarlos'),
  LegalBlock.p('Puedes revisar o retirar los permisos en los Ajustes de tu teléfono > Aplicaciones > PROXVEL > Permisos.'),
  LegalBlock.h('Notificaciones'),
  LegalBlock.p('Las notificaciones de PROXVEL se muestran dentro de la app (campana del inicio). No enviamos notificaciones push al teléfono.'),
]);

const LegalDoc sourcesAndLicenses = LegalDoc('fuentes', 'Fuentes y licencias', [
  LegalBlock.h('Datos y mapas'),
  LegalBlock.ul([
    'Mapas: © OpenStreetMap contributors (openstreetmap.org/copyright), bajo licencia ODbL.',
    'Clima: SENAMHI, series climáticas 1991-2020.',
    'Llegadas de visitantes: MINCETUR.',
    'Descripciones y fichas de los destinos: elaboración propia de M3Biznovatech a partir de información pública. Verifica horarios y tarifas en las fuentes oficiales.',
  ]),
  LegalBlock.h('Software de código abierto'),
  LegalBlock.p('PROXVEL usa componentes de código abierto. Puedes ver sus licencias en «Licencias de código abierto».'),
]);

/// Documentos por identificador (usados por la ruta /legal/doc/:id).
const Map<String, LegalDoc> kLegalDocs = {
  'privacidad': privacyPolicy,
  'terminos': termsOfUse,
  'mis-datos': myData,
  'permisos': appPermissions,
  'fuentes': sourcesAndLicenses,
};
