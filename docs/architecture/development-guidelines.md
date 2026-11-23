# Development guidelines

Estas convenciones complementan el manifiesto y se aplican a cada cambio. El código vigente, el enunciado actual y el contrato comprobado tienen prioridad sobre ejemplos antiguos. Las mejoras deben preservar el comportamiento y la fidelidad ya validados; una duda o diferencia se registra antes de alterar una decisión compartida.

### 1. Preparar un recorrido concreto

1. Sincronizar la rama y leer el último registro de continuidad. Confirmar qué archivos y responsabilidades se van a modificar; evitar dos cambios concurrentes sobre el mismo alcance sin coordinación.
2. Identificar actor, precondiciones, acción, recibo esperado, errores y destino de navegación. Determinar qué variante Figma representa cada estado y qué parte es una extensión funcional.
3. Leer controlador/resources, pruebas y documentación vigentes del backend. Registrar método, path, query, cuerpo, status, envelope de error, permisos y efecto persistente. No deducir un contrato solo porque Android hace una llamada similar.
4. Revisar los widgets, temas, casos de uso y adapters existentes. Reutilizar lo que tenga la responsabilidad correcta; añadir un archivo del manifiesto cuando exista su consumidor, no para llenar carpetas.
5. Implementar el recorrido con sus estados y validar funcionalidad y apariencia juntos. Actualizar el registro al terminar, distinguiendo lo comprobado de lo que falta.

### 2. Consultar Figma mediante su integración

Archivo de diseño: https://www.figma.com/design/jCppvxtSpLpHOrC3ZWUIVC/VitaHealth?node-id=563-2&m=dev . El inventario de variantes conserva los node IDs específicos; no usar el frame completo como si fuera una pantalla única.

- Cargar la guía de design-to-code de la integración instalada antes de solicitar contexto. Descubrir las herramientas y sus parámetros actuales; no asumir que todas las versiones exponen el mismo esquema.
- Cuando exista create_session, abrir una sesión para este trabajo y reutilizar su identificador en las consultas elegibles. No guardar UUIDs efímeros en el código ni en este plan.
- Solicitar get_design_context para el nodo exacto, indicando Flutter/Dart y la guía figma-design-to-code cuando el parámetro skillNames esté disponible. Incluir screenshot en la consulta inicial. Si no llega, pedir get_screenshot antes de implementar.
- Usar metadata para localizar nodos o dividir un frame demasiado grande. Una respuesta escasa no basta para implementar: contrastar los hijos visibles con el screenshot y consultar el contexto detallado de esos hijos.
- Inspeccionar jerarquía, medidas, colores, tipografía, assets, variantes y componentes vinculados. Reutilizar los componentes mapeados por Code Connect cuando sean aplicables al stack y al nodo correspondiente.
- Traducir el código de referencia devuelto al stack del proyecto. React/Tailwind o posiciones absolutas del export no se pegan en Dart ni justifican agregar dependencias ajenas.
- Si pide autenticación, reconectar la integración; no inventar el contenido de la pantalla ni registrar como comparación una consulta fallida. Mientras tanto se pueden trabajar contratos y lógica o referencias guardadas cuyo nodo y vigencia estén identificados. El estado visual continúa sin aprobar hasta obtener evidencia suficiente.

### 3. Elegir qué es un recurso y qué es un widget

Texto, campos, botones, tarjetas, chips, listas, progreso, navegación y estados se implementan en Flutter. Las imágenes se reservan para fotos, ilustraciones y recursos gráficos originales. Un screenshot completo no es una implementación de pantalla; tampoco se recorta para simular campos, textos o controles.

Los datos del mockup son ejemplos. Nombre, edad, medicación, fecha, stock, precio y estado provienen del contrato o de una entrada real. Los fixtures viven en pruebas y capturas identificadas. Cuando falta una foto dinámica, usar iniciales o un placeholder apropiado, sin asignar la imagen de Rosa a todos los usuarios. No inventar contenido clínico o resultados para llenar un diseño.

Los elementos del teléfono de Figma son contexto de presentación. No pintar dentro de la app la hora, batería, bisel o barra de gestos del mockup: utilizar SafeArea y el sistema operativo. Un ajuste por permisos o actor debe conservar la intención y registrarse; no habilitar consentimiento adulto en una sesión cuidadora solo por copiar un frame combinado.

### 4. Descargar y exportar imágenes correctamente

1. Usar los assets originales indicados por el contexto MCP o una copia local cuya identidad y procedencia coincidan exactamente. Seguir la instrucción de descarga que devuelva la herramienta; sus URLs son temporales y no se usan en runtime.
2. Guardar SVG en assets/icons o assets/illustrations según su función; PNG/fotos en assets/illustrations u otra carpeta con consumidor concreto. Declarar los recursos en pubspec.yaml y conservar sus licencias cuando corresponda.
3. Preferir SVG para iconos y gráficos vectoriales. Conservar el archivo original y sus root dimensions/viewBox; no extraer paths para dibujarlos a mano ni cambiar colores/forma a escondidas. No sustituir un icono por otro parecido sin comparar su diseño y dejarlo pendiente si no coincide.
4. Para raster, calcular la resolución necesaria desde el tamaño lógico y la densidad objetivo. Un slot de 80x80 a DPR 3 necesita 240x240 píxeles reales. Solicitar/exportar desde la fuente a esa resolución, normalmente 2x o 3x según el destino; no ampliar un PNG pequeño para aparentar mayor calidad. Si se usan variantes de densidad, organizarlas como assets/2.0x y 3.0x de la misma imagen lógica, con los nombres y carpetas adecuados para Flutter.
5. Exportar el nodo gráfico correcto con transparencia cuando corresponda. Revisar márgenes internos, sombras, máscara, clipping y esquinas. No exportar un fondo opaco junto a un icono que debe ser transparente; tampoco recortar una ilustración o sombra accidentalmente.
6. Verificar que cada archivo sea no vacío, decodificable y tenga dimensiones/viewBox correctos. Comprobar alpha y contraste sobre el fondo real, tanto seleccionado como normal. Leer metadatos basta para inventariar; no volcar bytes/path data a comentarios o herramientas de texto.
7. Mantener la proporción y la posición de su slot. SVG conserva su geometría original; cualquier escala del conjunto debe ser explícita y proporcional, sin estilos globales de 100% que deformen el root. En raster, escoger BoxFit.contain/cover por intención del diseño y comprobar el recorte efectivo.
8. Si el renderizador no soporta un efecto, no eliminarlo silenciosamente. Ejemplo vigente: flutter_svg no interpreta feGaussianBlur de los glows; ImageFiltered aplica el desenfoque nativo con el sigma comprobado sobre el SVG original. Verificar el resultado en la captura.
9. Si la fuente no permite conseguir resolución o transparencia adecuadas, registrar la limitación y no aceptar ese recurso como corregido. No generar una nueva ilustración, redibujarla ni aplicar un upscale como sustituto automático del original.

Por recurso registrar: nodo/layer, fuente, archivo relativo, licencia cuando aplique, dimensiones originales, slot lógico, DPR de validación, consumidor, BoxFit/escala y resultado visual. La presencia del archivo por sí sola no demuestra uso correcto.

### 5. Fuentes, iconos y caracteres

Reutilizar las fuentes licenciadas de assets/fonts con sus pesos declarados. No simular semibold/bold cuando exista el peso original. Comprobar acentos, signos, números, plurales y el carácter de ocultación de contraseña. Ya se corrigió un subconjunto Inter sin U+2022 utilizando la versión completa 4.001 de la misma fuente; no reintroducir ese subconjunto por reducir tamaño sin comprobar cobertura.

Cargar fuentes reales en pruebas visuales; la tipografía de sustitución del runner no demuestra fidelidad. Cargar también MaterialIcons si el render contiene iconos nativos. Un glifo vacío, tofu, fondo cuadrado inesperado o contraste perdido en selección es una incidencia abierta, no un detalle menor aprobado.

### 6. Implementar layout idiomático de Flutter

- Preferir Scaffold, SafeArea, Padding, Column, Row, SizedBox, Spacer, Expanded/Flexible, Form, TextFormField, Card/Container, botones, listas y selectores nativos según su finalidad. No existe una lista cerrada de widgets por haber usado unos pocos en clase.
- Elegir ListView.builder, slivers o composición desplazable según cantidad de contenido y restricciones; no meter grandes listas eager en un Column ni usar shrinkWrap como arreglo automático de cualquier constraint.
- Respetar constraints mediante LayoutBuilder, ConstrainedBox, MediaQuery y tamaños adaptables. No fijar toda la pantalla a 393x852: esa medida es referencia de comparación, no el tamaño obligatorio del teléfono.
- Reservar Stack/Positioned para superposición real e ilustraciones. El canvas escalado de onboarding solo agrupa decoración; no contiene controles interactivos ni limita el tamaño del texto útil.
- Usar Spacer solo con restricciones de altura apropiadas. IntrinsicHeight puede servir en una composición pequeña comprobada; no extenderlo a listas largas para resolver layout.
- Considerar teclado, área segura, pantalla pequeña, texto al 150%, nombres largos, listas vacías y estados de error. Evitar títulos tapados y botones fuera de alcance. Aislar el scroll cuando cambiar de recorrido pueda heredar una posición indebida.
- Mantener alineaciones y espaciado coherentes entre pantallas, aun cuando el mockup varíe ligeramente. Se busca fidelidad proporcional, con composición y opciones reconocibles, no copiar errores del diseño o datos de muestra.
- Usar componentes compartidos y tokens existentes para roles visuales repetidos. No introducir un framework de diseño paralelo ni abstraer cada SizedBox en una clase sin un consumidor que lo justifique.

### 7. Comparar la pantalla con Figma

Para cada variante, conservar el nodo de referencia y producir un render del mismo estado y actor. La captura de Figma es la referencia; la captura Flutter es evidencia, nunca un asset productivo.

1. Representar estado normal, vacío, carga, error, éxito, selección o consentimiento que corresponda. Fijar datos/clock solo en fixtures para poder reproducirlo.
2. Comparar viewport lógico, DPR, locale, textScaler, safe area y estado del teclado. No atribuir a fidelidad un recorte o distinta densidad sin identificarlo.
3. En widget tests cargar fuentes y precargar imágenes; esperar el pintado real. Si se capturan PNG, usar RepaintBoundary y el helper test/support/visual_capture.dart con TATA_CAPTURE_DIR. Las operaciones de captura/archivo deben ejecutarse fuera del reloj falso cuando sea necesario.
4. Revisar el PNG obtenido: no basta que se haya escrito o que el test esté verde. Comprobar jerarquía, tipografía, proporciones, espacios, recortes, recursos, contraste, controles y estado. Revisar normal y seleccionado cuando haya navegación o chips.
5. Comparar cada asset visible por archivo, slot, callsite y geometría efectiva. Un recurso que no cargó puede dejar un hueco y aun así pasar una aserción de texto; eso no aprueba la pantalla.
6. Verificar interacción además de apariencia: inputs editables, foco/teclado, validación, callbacks distintos, bloqueo de doble envío, errores legibles, back/cancelar y actualización después del recibo.
7. Comprobar adaptación a texto al 150% y una altura/ancho menor cuando la composición lo requiera. El texto útil no se reduce a una imagen o un FittedBox para evitar overflow.
8. Las capturas instaladas agregan evidencia de plataforma. No sobrescribir la instalación Android nativa con el mismo applicationId para hacer una prueba Flutter: utilizar un dispositivo/AVD separado o acordar explícitamente ese reemplazo. La exigencia de demostración física se valida aparte del emulador y los widgets.

Estados de registro: sin comparar, comparada con ajustes o aceptada proporcionalmente. Solo aprobar tras revisar la imagen y resolver las diferencias del alcance. Señalar regresiones ajenas al cambio sin ampliar silenciosamente el trabajo. Una pantalla aprobada no aprueba sus variantes de error ni su versión EN por herencia.

### 8. Tomar Kotlin y materiales como referencia

Consultar Android para entender comportamiento, vocabulario, permisos, datos, navegación y casos ya descubiertos. Se pueden reutilizar SVG, ilustraciones originales, fuentes con licencia y traducciones revisadas. No copiar configuraciones privadas ni trasladar una captura Compose como UI Flutter.

No traducir línea a línea composables, ViewModels, paquetes Gradle, handlers o APIs Android. Text/Row/Column/Spacer de Compose no establecen por sí mismos el layout Flutter: elegir widgets por constraints y ciclo de vida de Flutter. Convertir strings XML a ARB con placeholders/plurales, sin pegar escapes o formatos Android. Una estructura Android equivocada no se conserva por simetría.

Los ejemplos del profesor sirven para patrones enseñados y legibilidad, no para copiar datos de alumnos, espaciadores enormes, proyectos monolíticos o dependencias antiguas. Mantener BLoC, repositorios y fronteras acordadas; no añadir a la vez ViewModel y Bloc para una misma autoridad de estado ni capas solo para parecerse a otro equipo.

### 9. Límites de responsabilidad e imports

| Ubicación | Puede depender de | No debe contener |
| --- | --- | --- |
| domain | Dart y conceptos puros del contexto | Flutter, HTTP, plugins, JSON de transporte, navegación o almacenamiento |
| application | Domain y contratos/read models de aplicación | Widgets, BuildContext, cliente HTTP concreto, SQL o SDK externo |
| infrastructure | Contratos de aplicación/domain y bibliotecas técnicas necesarias | Navegación, widgets o mensajes de interfaz como resultado de negocio |
| presentation | Widgets, BLoC, casos de uso y modelos públicos necesarios | Llamadas HTTP/SQL, FlutterSecureStorage directo, tokens en estado o reglas clínicas del servidor |
| app | Composición y conexiones explícitas entre contextos | Reglas de negocio duplicadas o un archivo que implemente todos los recorridos |
| shared | Capacidades técnicas/visuales con consumidores reales | Un contenedor de negocio sin dueño o carpetas/abstracciones vacías |

Orden de imports: dart:, paquetes externos/propio y relativos, con grupos separados y orden alfabético; directives_ordering lo verifica. Usar una convención consistente en cada grupo y respetar el análisis vigente. No escribir nombres de paquete completos dentro del cuerpo para evitar ordenar imports. Los prefijos como http, ui o math son válidos para desambiguar bibliotecas; no son equivalentes a pegar rutas org.xxx o com.xxx en cada llamada.

No importar una implementación infrastructure de otro BC ni el app host desde una feature. Componer mediante puertos/callbacks en app; una dependencia transversal de sesión/resultado vive en shared cuando su responsabilidad realmente es común. No abrir barrel exports globales que oculten dependencias cíclicas. Evitar dynamic, casts, non-null assertions y catch genéricos como atajo: validar en el boundary y tipar el resultado. Un uso técnico necesario debe estar acotado y explicado.

No fijar límites arbitrarios de líneas como sustituto de diseño. Revisar un archivo cuando mezcla varias pantallas, transporte y estado, múltiples actores o responsabilidades independientes. Extraer por responsabilidad real; no dividir un flujo pequeño en docenas de wrappers ni acumular todos los handlers en un archivo general. Mantener APIs públicas pequeñas, nombres de intención y dependencias hacia contratos.

### 10. Formato, saltos de línea y documentación de código

- Archivos/carpetas snake_case; tipos UpperCamelCase; miembros lowerCamelCase; privacidad de biblioteca con _. No transportar nomenclatura Kotlin/Java a Dart.
- UTF-8 y acentos correctos. Utilizar dart format; no insertar escapes de nueva línea como texto literal ni comprimir varias instrucciones en una línea para reducir el archivo. Dejar salto final y separar imports, tipos y miembros para facilitar lectura.
- Respetar nombres y formato del módulo existente cuando sean correctos. Usar llaves en ramas multilínea, evitar ternarios anidados ilegibles y extraer una condición con nombre cuando ayude a comprender una decisión.
- Mantener strings visibles en ARB, incluidas etiquetas, errores, diálogos y accesibilidad. Emplear placeholders tipados y plurales, no concatenaciones con gramática fija. Los IDs técnicos y valores de protocolo no son traducciones.
- Cada archivo Dart productivo propio explica su responsabilidad mediante Dartdoc /// en el tipo, entrada o contrato correspondiente. Documentar casos de uso y métodos públicos no obvios: entradas, resultado, efectos, fallos y restricciones relevantes, con referencias [Simbolo] cuando corresponda.
- Comentarios internos explican por qué existe una decisión, sus invariantes o una limitación comprobada. No narrar cada asignación ni añadir encabezados repetidos de relleno. Actualizar el comentario al cambiar el contrato; no documentar funciones futuras como si existieran.
- No editar archivos generados, esconder problemas con ignore_for_file o desactivar reglas globalmente para conseguir un análisis verde. Añadir una dependencia solo con consumidor real y justificarla en el registro cuando cambie la arquitectura.
- No llenar campos productivos con pacientes, contraseñas, cuentas, gráficos o resultados de ejemplo. Dobles y fixtures deben identificarse en test/support o tests, sin convertirse en adapters fake de producción.

### 11. Verificación y colaboración en la rama

Ejecutar desde la raíz del proyecto, con el SDK configurado localmente:

```sh
flutter pub get
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
```

Contra Spring local (Docker con TATA_DEMO_SEED=true) el emulador usa `--dart-define=TATA_API_BASE_URL=http://10.0.2.2:<puerto>/ --dart-define=TATA_ALLOW_LOCAL_HTTP=true`; solo el build debug admite HTTP y únicamente hacia hosts locales. `dart run tool/verify_local_pin_home.dart <fixture>` comprueba PIN y Home por TCP real con un fixture privado fuera del repositorio.

Ejecutar los tests pertinentes durante el cambio y la suite apropiada al cerrar el corte. Construir flutter build apk --debug cuando cambie integración/host/plugins o se entregue un APK; iOS se verifica con macOS/Xcode. Ejecutar probes Spring solo contra un host aislado con su fixture privado y limpieza; no crear cuentas de prueba ni enviar correos en producción para simular cobertura. No repetir verificaciones amplias sin cambios o riesgos nuevos que lo justifiquen. Un cambio exclusivo de documentación no requiere recompilar la aplicación.

Consultar git status y remoto antes de continuar temp. No pisar cambios ajenos, usar reset --hard o force-push para resolver divergencias sin revisar su contenido. No subir build, .dart_tool, archivos de máquina, fixtures privados, claves de firma, App Secrets ni tokens. Compartir configuraciones públicas por su mecanismo previsto y mantener secretos fuera del código. No usar ramas codex/; temp es la excepción acordada hasta dividir el Sprint Backlog en ramas GitFlow útiles por US. No modificar main/develop ni README como efecto secundario de ampliar este plan.

Antes de publicar: revisar diff, archivos nuevos, pruebas/resultados y conteo de variantes; actualizar el registro de continuidad con commit, alcance y siguientes pasos. Commits concretos y Conventional Commits. Una rama por US puede tener varios commits coherentes; no crear duplicados de la misma historia ni borrar sus evidencias para ordenar la lista de ramas.

### 12. Evidencia mínima para cerrar un recorrido

- Actor, entrada, opciones y navegación corresponden al caso real.
- Recibo HTTP y efecto persistente comprobados en el nivel de evidencia declarado.
- No se revela información de otro propietario ni una respuesta tardía restaura acceso anterior.
- Apariencia comparada con el nodo correcto, recursos cargados y controles nativos operativos.
- Casos de error, cancelación y reintento relevantes mantienen un estado comprensible.
- Código legible, imports correctos, Dartdoc actualizado y verificaciones pertinentes aprobadas.
- Registro funcional/visual actualizado, sin equiparar fixtures, render, Spring local, despliegue y dispositivo.

Si falta alguno, conservar el estado parcial y escribir el siguiente paso verificable. No dar por terminado un módulo por cantidad de archivos o un porcentaje supuesto.
