# Tata Cross-Platform: plan único de arquitectura, archivos y progreso

Actualizado: 02-11-2026. Rama de trabajo compartida: temp. El inventario describe archivos previstos y sus responsabilidades; el checkpoint final identifica la implementación comprobada.
Fuente normativa: material-del-curso/Trabajo Final_1ACC0238_202620.pdf, V4.0. El material 202610 es referencia técnica complementaria. Esta matriz sustituye la incertidumbre sobre la rúbrica de las notas previas.

## Alcance activo: misma aplicación y experiencia Tata

El enunciado 202620 pide un producto móvil nativo y multiplataforma (páginas 1-2), con coherencia de funcionalidad, diseño e interacción. Flutter es otro cliente de Tata, con el mismo backend, actores y nueve BC. No se pide traducción archivo-a-archivo de Kotlin ni igual cantidad de Screens. La paridad de capacidades se mide contra el Product Backlog. Flutter empieza con un scaffold, no con la cobertura funcional del Android terminado.

| Requisito actual | Ubicación | Decisión y aceptación |
| --- | --- | --- |
| Persistencia local | p2 | Drift para cache/cola por propietario; reinicio, replay y migraciones sin fuga |
| Recurso interno del dispositivo | p2 | Micrófono por puerto y adapter; permiso/cancelación/audio en dispositivo |
| REST propio | p2 | Spring existente; contrato, autorización, recibos e integración real |
| Servicio externo | p2 | Proveedor social o voz autorizado; prueba real distinta de fixtures |
| DDD | p2 | Contextos, cuatro responsabilidades y dependencias hacia contratos puros |
| Feature de aprendizaje autónomo | p2 | Candidato social Firebase/SDK con sesión Tata; comparar qué se enseñó este semestre, alternativas y aplicación. BLoC/Drift no cuentan automáticamente si se enseñan |
| Demostración en teléfono físico | p2 | Instalar antes de exposición y demostrar core; CI/simulador no bastan |
| Coherencia funcional y visual | p2 | Mismos actores, acciones y diseño proporcional; variantes equivalentes |
| Todos participan en nativo y cross | p2 | Backlog y commits auténticos, cada participante puede explicar su trabajo |
| i18n y accesibilidad | sección propia | Español base/inglés, ARB, escala/contraste/semántica/teclado |
| Flutter/Dart o alternativa KMP | tecnología | Flutter elegido por usuario; BLoC es decisión técnica sustentada en clases, no mandato literal del enunciado |
| GitFlow, Conventional Commits y SemVer | SCM y tecnología | main/develop; temp local hasta refinar US; releases propias por cliente |
| AV2/Sprint 2 | p34-35 | Backend 100% publicado y core; evidencia de producto y aprendizaje |
| TB2/Sprint 3 | p35 | Todas las funciones del backlog y distribución tipo AppDistribution; demo física |

El anexo Stripe/ACME es ejemplo de Spike, no obligación de implementar pagos en Tata. No se inventan cobros, videos, fechas o aportes. Report queda fuera de esta preparación. No se deduce una app Swift independiente ni un número fijo de pantallas. La evidencia de iOS físico se acuerda en el backlog, sin equipararla al build de simulador.

---

# Preparación y decisiones de base

Fecha: 27-10-2026.
Estado: scaffold oficial aportado en tata.zip y primer recorrido de acceso implementados en mobile-cross-platform. SDK Flutter 3.47.8 instalado. Plan e implementación funcional locales, compartida en temp.

## 1. Alcance y procedencia

El usuario aclara que el material corresponde al semestre anterior, otro profesor y otra sección. Se usa como referencia de aprendizaje, no como rúbrica vigente. La elección final de entregables, plataformas y restricciones corresponde al curso actual.

Carpeta revisada:
material-del-curso/CURSOS UPC/Aplicaciones para Dispositivos Moviles - 1ACC0238

| Evidencia | Hallazgo | Implicación para Tata |
| --- | --- | --- |
| Sílabo 1ACC0238-Aplicaciones_para_Dispositivos_Moviles-3687.pdf, páginas 7-9 | Unidad 3, semanas 9-12: Dart/Flutter, widgets, networking REST, sqflite y Drift. Unidad 4, semanas 13-16: iOS, HIG, networking, persistencia y aprendizaje continuo | No asumir que ambas unidades son exclusivamente Flutter ni que se exige otra app nativa iOS |
| Semana 9, intro flutter & dart v2, sección arquitectura | Presenta BLoC como patrón | BLoC es una referencia real del material, no una obligación confirmada del semestre actual |
| Semana 11, flutter-networking v2, secciones BLoC pattern/library | Eventos, estados, streams, BlocBuilder y BlocProvider. Ejemplo flutter_bloc ^4.0.0 | Adoptar flutter_bloc con API y versiones actuales compatibles, sin copiar versiones ni APIs antiguas |
| Semana 9, Flutter_UI_Architecture.pdf, láminas 4-14 inspeccionadas visualmente | UI declarativa, Row/Column/Stack/Container, adaptabilidad, assets, listas diferidas y slivers | Widgets reales, composición sencilla y adaptación; el documento no prescribe un árbol DDD de cuatro o cinco carpetas |
| Semana 12, persistence-p1/p2 y Guía drift 20260619 A | SQLite con sqflite y posteriormente Drift tipado, generación .g.dart y CRUD | Proponer Drift para cache/cola local. Estudiar sqflite sin mantener dos persistencias equivalentes en Tata |
| Enunciado final 202610, páginas 1, 3 y 31-32 | DDD, almacenamiento local, recurso del dispositivo, REST interno, servicio externo, GitFlow. Cross-platform permite Flutter/Dart o KMP/Kotlin | Referencia antigua: no convertir alternativas o porcentajes de esa entrega en requisitos actuales |

ZIP inspeccionados directamente, sin ejecutar código:
- app_sem9_primerpy, routes y wordgenerator: ejemplos concentrados en main.dart.
- app_s10_s1_py_login: formulario local; no prueba una autenticación apta para Tata.
- app_sem10_s2_networking_miv2: main y dos vistas con http.
- wasa_remix_v3: models/, ui/, util/db_helper.dart, sqflite.
- app_sem13_pymovie: models/, ui/, utils/http_helper.dart y db_helper.dart; Flutter aparece incluso entre los recursos de unidad 4.
- app_sem12_pydrift.zip: contiene plataformas, pubspec y test/widget_test.dart, pero NO incluye lib/. No es una plantilla de aplicación reutilizable completa.

Estos ejercicios muestran conceptos puntuales y estructuras diferentes. No prueban que el curso exija una arquitectura única de cinco capas. No se trasladan instrucciones de entregas antiguas a acciones actuales.

## 2. Nombre y repositorio propuesto

Organización: vitaHealth-UPC.
Nombre recomendado por preferencia del usuario: mobile-cross-platform.
URL prevista: https://github.com/vitaHealth-UPC/mobile-cross-platform
Carpeta local propuesta: [referencia de entorno local]
Nombre de paquete Dart propuesto: tata.
Producto visible: Tata.

mobile-cross-platform es el nombre confirmado por el usuario, coherente con mobile-android; no una nomenclatura atribuida al profesor. El usuario creó el repositorio vacío; la base se prepara allí en esta ejecución.

Mantener mobile-android y web-services independientes. Flutter reutiliza contratos REST, diseño, reglas y escenarios de aceptación; no copia Kotlin/Compose ni crea otro backend.

## 3. Decisión arquitectónica propuesta

Una aplicación Flutter, un pubspec.yaml, organización por bounded context dentro de lib/features/. Sin monorepo de paquetes ni capas vacías de entrada.

Conservar cuatro responsabilidades lógicas para dar continuidad al DDD de Tata:
- domain: entidades, value objects, invariantes del cliente y contratos de repositorios de dominio.
- application: casos de uso, puertos y modelos de lectura. usecases/ plano dentro del contexto; sin carpetas inventadas por cada operación. Separar comandos/consultas cuando exista una necesidad concreta, no duplicar cada llamada con dos wrappers.
- infrastructure: HTTP, DTO/mappers, implementaciones de repositorios, Drift, almacenamiento seguro y servicios de plataforma.
- presentation: screens/, bloc/, widgets/ y navigation/ cuando el contexto realmente lo requiera. Tema general en shared/presentation/theme/.

Esta distribución es una adaptación de Tata, NO las cuatro capas oficiales de Flutter ni una exigencia textual del curso. Flutter recomienda separar UI/datos y repositorios, con dominio adicional cuando la complejidad lo justifica. La guía oficial de BLoC presenta Presentation, Business Logic y Data; no obliga a replicar esos nombres como carpetas.

Los Bloc de Tata se ubican en presentation/bloc/ como controladores del estado del flujo: reciben eventos, invocan casos de uso y emiten estados inmutables. No contienen SQL, solicitudes HTTP, almacenamiento de tokens ni reglas clínicas del servidor. La lógica de aplicación compleja vive en application y las invariantes en domain. No añadir ViewModel más Bloc para la misma pantalla.

Dependencias:
- application depende de domain y sus propios puertos.
- infrastructure implementa esos contratos.
- presentation utiliza application y modelos necesarios del dominio.
- domain no importa Flutter, flutter_bloc, http ni Drift.
- app compone implementaciones, rutas globales y colaboraciones entre contextos.
- Un BC no importa app ni las implementaciones internas de otro BC. Las colaboraciones se ensamblan en app/integration/ con contratos explícitos.
- shared contiene resultados, sesión, transporte y diseño comunes; no reglas clínicas ni un shared/domain vacío.

## 4. Árbol de archivos previsto

El árbol describe el destino, no carpetas que deban crearse vacías hoy.

```text
mobile-cross-platform/
  README.md
  pubspec.yaml
  pubspec.lock
  analysis_options.yaml
  .gitignore
  .metadata
  l10n.yaml
  android/                       generado por Flutter
  ios/                           generado por Flutter
  assets/
    fonts/
    images/
    icons/
  lib/
    main.dart                    entrada mínima
    app/
      tata_app.dart              configuración del host
      bootstrap.dart             composición inicial
      config/app_config.dart     API URL y opciones de entorno
      di/app_dependencies.dart
      navigation/app_router.dart
      integration/               solo colaboraciones efectivas
    shared/
      common/result/app_result.dart
      application/session/session_store.dart
      infrastructure/network/api_client.dart
      infrastructure/security/secure_session_store.dart
      presentation/theme/tata_theme.dart
      presentation/theme/tata_colors.dart
      presentation/theme/tata_typography.dart
      presentation/widgets/      componentes realmente compartidos
    l10n/
      app_es.arb
      app_en.arb
    features/
      identity_subscription/
        domain/entities/session.dart
        domain/repositories/session_repository.dart
        application/usecases/sign_in.dart
        application/usecases/sign_out.dart
        application/usecases/request_password_recovery.dart
        application/usecases/complete_password_recovery.dart
        infrastructure/remote/session_api.dart
        infrastructure/remote/session_dto.dart
        infrastructure/mappers/session_mapper.dart
        infrastructure/repositories/remote_session_repository.dart
        presentation/bloc/access/access_bloc.dart
        presentation/bloc/access/access_event.dart
        presentation/bloc/access/access_state.dart
        presentation/screens/login_screen.dart
        presentation/widgets/access_form.dart
      care_link/
      treatment_management/
      intake_execution/
      inventory_replenishment/
      family_monitoring/
      adherence_analytics/
      accessibility_preferences/
      omission_escalation/
  test/                          refleja responsabilidades de lib/
  integration_test/
  .github/workflows/flutter-ci.yml
```

El árbol detallado de Identity muestra el patrón, no obliga a todos los BC a tener archivos iguales. Un DTO no se usa como entidad ni como estado UI. Datos fake son válidos en tests, no sustitutos del backend en producción. Archivos generados .g.dart se gestionan con una política única y verificable; pubspec.lock se versiona por ser una aplicación.

## 5. Archivos iniciales por contexto y responsabilidad

| Contexto | Primeros archivos orientativos | Autoridad y límites |
| --- | --- | --- |
| Identity & Subscription | session_repository.dart, sign_in.dart, restore_session.dart, access_bloc/event/state, login_screen.dart; después registro/PIN/recuperación/planes | La credencial Google/Meta se intercambia por sesión Tata. Nunca autorizar solo porque Firebase tenga un usuario |
| Care Link | care_link_repository.dart, request_care_link.dart, register_consent.dart, withdraw_consent.dart, link_bloc, link_screen, consent_screen | Vínculos y permisos se validan en Spring; revocación limpia el alcance clínico |
| Treatment Management | medication.dart, treatment.dart, treatment_repository.dart, configure_treatment.dart, treatment_wizard_bloc, treatment_review_screen.dart | Conservar el borrador al volver. Activación, pausa y reanudación requieren recibo real |
| Intake Execution | intake_repository.dart, confirm_dose.dart, pending_confirmation_table.dart, intake_local_store.dart, replay_pending_confirmations.dart, agenda_bloc, agenda_screen.dart | Cola por usuario, clave idempotente y estado pendiente real. Backend decide el resultado definitivo |
| Inventory & Replenishment | inventory_repository.dart, replenish_inventory.dart, inventory_api.dart, inventory_bloc, inventory_screen.dart | No descontar dos veces por reintento ni fabricar stock en el cliente |
| Family Monitoring | monitoring_reader.dart, alert_reader.dart, record_follow_up.dart, notes_api.dart, alerts_bloc, alert_detail_screen.dart | No conservar datos sensibles tras cambio de cuenta o vínculo revocado |
| Adherence Analytics | adherence_reader.dart, get_adherence_summary.dart, analytics_api.dart, analytics_bloc, adherence_screen.dart | Contexto de consultas; no comandos artificiales. Diferenciar datos vacíos de error o falta de permiso |
| Accessibility & Preferences | preferences_repository.dart, update_accessibility.dart, preferences_table.dart, accessibility_bloc, accessibility_screen.dart | Persistencia por propietario, texto escalable, contraste, español base e inglés explícito |
| Omission & Escalation | push_device_repository.dart, register_push_device.dart, unregister_push_device.dart, messaging_adapter.dart, notification_intent_mapper.dart | No inventar pantallas propias: notificaciones y coordinación; generación clínica en backend |

El primer corte no crea todos estos archivos. Cada flujo incorpora únicamente los que usa.

## 6. Dependencias y herramientas

- Flutter stable y Dart incluido en ese SDK. Fijar la versión del SDK al iniciar, registrar flutter --version y conservarla en CI. No tomar las restricciones de SDK de un ZIP como recomendación actual.
- flutter_bloc para eventos/estados. Empezar con Bloc en flujos funcionales; Cubit es opcional para estado sencillo y no se introduce como segundo patrón global.
- package:http para REST, alineado con los ejemplos. Un cliente común con timeouts y autenticación por solicitud. DTO y clasificación de errores pertenecen a cada BC: el backend actual no usa la misma envoltura de error en todos los contextos.
- Drift para persistencia offline real y migraciones; añadirlo cuando comience Intake/Preferences. No sustituirlo por persistir tokens en SQLite.
- Almacenamiento seguro de plataforma para sesiones, mediante adaptador. Sin tokens en logs, ARB, estado serializado ni archivos versionados.
- go_router propuesto para rutas, restauración y redirecciones según sesión; no lógica HTTP dentro de redirects ni IDs de otro usuario reutilizados.
- flutter_localizations y ARB para español base/inglés. Flutter widgets para texto, formularios y botones; assets solo para ilustraciones, fotos e iconos necesarios.
- Inyección explícita por constructores y RepositoryProvider/BlocProvider. Sin service locator global añadido por costumbre.
- flutter_test, bloc_test e integration_test para comportamiento relevante. Fixtures solo en tests.

Las versiones de paquetes se resolverán contra el SDK seleccionado y se registrarán en pubspec.lock. No se instalan dependencias ni se fijan números antiguos en este plan.

## 7. Scaffold y alcance de plataformas

Se utiliza el scaffold oficial aportado en tata.zip; NO ejecutar flutter create sobre esta carpeta para regenerar plataformas. El SDK está instalado en [referencia de entorno local]

Identificador confirmado: com.vitahealth.tata. Identificador confirmado por el usuario, igual al cliente nativo. No se presupone instalación simultánea: usar dispositivos o perfiles separados si firma/versionCode impiden reemplazar el otro cliente. No copiar google-services.json o local.properties de Android como si fueran configuración multiplataforma.

Objetivo inicial: Android e iOS. Web/escritorio solo si el docente o alcance del producto lo requieren; Flutter soportarlos no significa que debamos generarlos todos. Android se desarrolla aquí en Windows. El build y validación iOS requieren equipo macOS/Xcode o CI macOS apropiado; generar ios/ no acredita que funcione en iPhone.

## 8. GitFlow de arranque

- main: base mínima verificable; develop: integración.
- El scaffold inicial se publica en main por petición del usuario y develop parte de esa base. feature/flutter-bootstrap se reserva para host, tema, navegación y primer flujo posterior. Cada cambio pasa analyze/test/build. No copiar el tag v1.1.0 de Android a una app que recién empieza.
- Primer versionado del nuevo producto: 0.1.0+1 propuesto, independiente del backend y de mobile-android. Publicar release solo cuando exista un corte funcional comprobado.
- Después usar las ramas de TS/US que realmente correspondan a Flutter, una por unidad de trabajo. No duplicar ramas por pruebas de implementación ni usar prefijos codex/.
- Conventional Commits: chore: initialize Flutter project; feat: implement caregiver access; fix: preserve owner-scoped cache.
- No modificar ni reescribir historias del backend, Android o report por esta preparación.

## 9. Secuencia de implementación

1. Bootstrap oficial: SDK fijado, host, tema, idioma, navegación, configuración API y CI. Sin pantallas que aparenten autenticación funcional.
2. Primer flujo completo: acceso/restauración/cierre y selección del adulto autorizado. Pantalla Figma equivalente, estado de carga/error, sesión real y permisos comprobados.
3. Treatment e Intake: alta/pauta, agenda, confirmar, volver y refrescar. Contrastarlo con los contratos ya publicados; no portar Kotlin literalmente.
4. Persistencia offline por propietario con Drift: cola idempotente de confirmaciones, reintentos, cambio de cuenta y migración. Backend mantiene stock y reglas transaccionales.
5. Inventory y Monitoring: stock/reposición, alertas/detalle/notas/contacto, revocación de consentimiento. Validar colaboración junto al flujo que la necesita.
6. Analytics y Preferences: datos reales, vacíos, idioma, tamaño de texto, contraste y persistencia. No reemplazar métricas por valores del mockup.
7. Integraciones de plataforma: recurso nativo demostrable (por ejemplo micrófono), proveedor externo y notificaciones cuando el alcance y las cuentas lo permitan. Planificar permisos y ciclo de vida desde el flujo, no al final del producto.
8. Verificación Android e iOS, evidencia visual/funcional separada y release propia del cliente Flutter.

Cada corte incluye funcionalidad y contraste visual juntos. Las 70 variantes Android/Figma son un inventario de referencia reutilizable, no 70 pantallas Flutter implementadas ni una meta de 70 archivos distintos.

## 10. Criterios de aceptación y decisiones por confirmar

Por flujo: referencias Figma, opciones/estados, ruta, Bloc, caso de uso, repositorio, endpoint, resultado de pruebas y captura equivalente. Separar widget tests, HTTP real, dispositivo y fidelidad visual. No reabrir estilos aprobados de Android sin evidencia de un problema Flutter.

Gate propuesto al iniciar:
- dart format --output=none --set-exit-if-changed .
- flutter analyze
- flutter test
- flutter build apk --debug
- Prueba de integración del primer flujo con backend local aislado.
- Compilación/ejecución iOS en entorno macOS cuando se declare soporte validado.

Por confirmar con el material actual: Flutter obligatorio o KMP permitido; BLoC exigido o sugerido; rúbrica de AV2/TB2; número de sprints y pantallas; nivel de prueba iOS; necesidad de una app Swift separada. No bloquea preparar el repositorio y la estructura.

## 11. Referencias actuales consultadas

Flutter, recomendaciones de arquitectura (consultado 27-10-2026):
https://docs.flutter.dev/app-architecture/recommendations

BLoC, arquitectura y responsabilidades:
https://bloclibrary.dev/architecture/

Flutter, creación oficial de la aplicación:
https://docs.flutter.dev/reference/create-new-app

Drift, setup:
https://drift.simonbinder.eu/setup/

Flutter, preparación de iOS:
https://docs.flutter.dev/platform-integration/ios/setup

Extracciones e inventario de los ZIP conservados localmente:
evidencia-local-no-publicada/tata-flutter-course-review-20261027/


## 12. Auditoría de la base recibida y alcance de la revisión

Fuente original: material-del-curso/tata.zip, 144 entradas. Se extrajo sin regenerar plataformas. Se conservan .metadata original, configuración de Gradle, proyectos Xcode, imágenes de lanzamiento, análisis estático y lockfile. El ZIP no se sube al repositorio. .idea, .iml, local.properties, Flutter ephemeral, registrants generados, claves y configuraciones de proveedores permanecen ignorados.

Diferencias intencionales respecto del ZIP:
- Identificador generado com.vitahealth.tata.tata corregido a com.vitahealth.tata en namespace/applicationId, paquete y ubicación de MainActivity y configuraciones iOS/RunnerTests. El usuario confirma mantener la identidad del producto, sin sufijo crossplatform.
- Versión 0.1.0+1: base nueva del cliente Flutter, sin adoptar la release de otro repositorio.
- Demo del contador sustituida por TataApp mínimo. main.dart solo inicia el árbol. No se crean pantallas falsas de login, datos clínicos ni BC vacíos.
- Widget test actualizado al arranque mínimo, sin contador.
- README de ejecución y CI Android/iOS con Flutter3.47.8 fijado. .metadata no se edita manualmente.

Se inventariaron y extrajeron los 48 PDF presentes, con SHA256, página y ubicación en all-pdfs/inventory.json. La extracción permite buscar y clasificar, NO acredita lectura visual completa de todos ellos. Las láminas UI Architecture y Adaptive Flutter Design, predominantemente imágenes, se renderizaron y revisaron completas. El libro de 483 páginas se consulta por capítulos pertinentes y no se presenta como leído íntegramente. Documentos de entrevistas, Lean, exámenes, ética o Student Outcome no imponen un árbol de código Flutter.

### Matriz de evidencia y adopción

| Grupo revisado | Decisión aplicable | Lo que no se traslada literalmente |
| --- | --- | --- |
| Unidad1, tecnologías/nativas/cross, Lean y ética | Aplicación cliente multiplataforma, trazabilidad al producto y tratamiento responsable de datos | Elección de librerías de ejercicios, requisitos antiguos o indicadores de progreso inventados |
| Unidad2, fundamentos/UI/UX/recursos | Ciclo de vida, tamaños de texto, recursos adecuados, inputs y navegación explícita | Compose/XML, arquitectura Gradle o ViewModels de Android copiados a Dart |
| Unidad2, networking/data/Room | Separación presentación/datos, asincronía, DTO, fuente remota/local, repositorios y migraciones | Room, Retrofit, DataStore o handlers Spring como dependencias Flutter |
| Unidad3, intro/widgets/stateful/stateless | Composición con widgets, ownership del estado local, const y build sin efectos | UI/HTTP/SQLite en un único main.dart por parecerse a una demo |
| Unidad3, networking/BLoC | Eventos/estados y flutter_bloc, repositorios y llamadas asíncronas comprobables | mapEventToState y versiones flutter_bloc4 de las diapositivas antiguas |
| Unidad3, sqflite/Drift y laboratorios | Persistencia SQLite, entidades locales, CRUD y código generado | Dos bases de datos para lo mismo, migraciones destructivas o copiar un ZIP sin lib/ |
| UI Architecture, láminas4-14 | Row/Column/Stack, listas diferidas, slivers donde hay scroll compuesto y assets declarados | Crear widgets wrapper para todo o sustituir controles por capturas de pantalla |
| Adaptive Design, láminas6-16 | Medir espacio con LayoutBuilder/MediaQuery, SafeArea, entradas adaptativas, respetar navegación nativa | Usar siempre600 como breakpoint universal, bloquear orientación o detectar tablet por hardware |
| Unidad4, iOS/HIG/persistencia/IA | Permisos, convenciones iOS, pruebas de plataforma y revisión de código generado | Una app Swift obligatoria, CoreData dentro de Flutter o que un PDF genere por sí solo una decisión válida |
| Libro Flutter Projects, capítulo10 BLoC/Sembast | Entender separación de lógica/streams, ciclo de vida y pruebas | Sembast junto a Drift, APIs obsoletas ni todos los proyectos de muestra como arquitectura de Tata |
| Enunciado y evaluaciones anteriores | Checklist orientativo de REST, persistencia, dispositivo y terceros | Fechas, entregas, porcentajes o nomenclaturas asumidos para el semestre actual |

## 13. Registro de decisiones iniciales

| ID | Decisión | Motivo y alternativa | Evidencia para revisarla |
| --- | --- | --- | --- |
| CP001 | Una aplicación, no paquetes Dart por BC de entrada | Nueve contextos se separan por responsabilidades sin overhead de publicación | Un ciclo real de dependencia o necesidad de reutilización independiente |
| CP002 | BLoC para presentación de flujos | Material networking lo enseña; permite eventos/estados y pruebas | Instrucción vigente del profesor o complejidad demostrada; no cambiar por moda |
| CP003 | Cuatro capas lógicas DDD por contexto | Continuidad con Tata y contratos servidor, no mandato Flutter | Eliminar una abstracción sin consumidores; no uniformar carpetas vacías |
| CP004 | Casos de uso en application/usecases, organización plana | Evita duplicar command/query/handler/usecase para una misma acción | Separar subflujos solo cuando el volumen real lo justifique |
| CP005 | BLoC en presentation/bloc, no domain | Representa estados y efectos de un flujo de interfaz, con dominio puro | Si se detecta lógica de negocio, extraerla a application/domain, no mover todos los Bloc |
| CP006 | HTTP primero con package:http | Alineación pedagógica y sustitución sencilla de cliente en tests | Requisitos concretos de streaming/interceptores que justifiquen otra librería |
| CP007 | Drift en persistencia offline | Tipado, consultas reactivas y migraciones; enseñado en semana12 | Compatibilidad plataforma o restricción académica concreta |
| CP008 | Sesión segura y propietario explícito | Previene contaminación entre adulto/cuidador y caches | Nunca relajar por facilidad de demo |
| CP009 | BLoC no depende de otro BLoC | Coordinar mediante casos de uso/repositorios y eventos de dominio reales | Un mecanismo compartido de lectura con ciclo de vida definido |
| CP010 | Identidad com.vitahealth.tata | Corrección explícita del usuario | Solo cambiar por requisitos de distribución aceptados |
| CP011 | Validación visual proporcional | Preserva composición, opciones y accesibilidad sin copiar errores de Figma | Diferencias mostradas con captura equivalente |
| CP012 | Dependencias bajo demanda | Scaffold sin HTTP/BLoC/Drift no usados; evita decorado arquitectónico | Primer flujo incorpora librería y sus pruebas juntas |

## 14. Matriz de ownership y ubicación de contratos

- Repositorio de dominio: interface en domain/repositories si entrega/guarda entidades; implementación en infrastructure/repositories.
- Lector de proyecciones: contrato application/ports, datos application/readmodels. No inventar agregado de analytics para justificar un repositorio.
- Fuente remota: infrastructure/remote, DTO explícitos para falta/null y mappers con validación semántica. No exponer Response/http al Bloc.
- Fuente local: infrastructure/local, tablas/DAO/migraciones. Drift genera implementación técnica, no entidades de dominio.
- Fachada coordinadora: application/usecases cuando necesita varias operaciones; app/integration cuando combina BC diferentes mediante sus contratos públicos.
- Event de Bloc: intención de UI o ciclo de vida, distinto de un Domain Event o comando HTTP. Un toque no prueba que el servidor confirmó.
- Estado de Bloc: inmutable, no guarda contraseña/token ni exception.toString visible. Diferencia initial/loading/data/empty/error/submitting según flujo.
- Efectos: BlocListener para navegación, snackbars y diálogos de resultado; BlocBuilder dibuja. No disparar escritura desde build ni repetir navegación en rebuild.
- Widget local: controla foco, controller y animación de su ciclo de vida; StatefulWidget es válido para UI efímera. No todo control necesita Bloc.
- Navegación: contratos de rutas tipados y argumentos mínimos; no transportar DTO completos ni credenciales. Revalidar permiso al abrir destino y en reanudación relevante.

## 15. Plan de archivos por corte

Cada fila define archivos previstos y aceptación. No son carpetas creadas por adelantado.

| Corte | Archivos principales | Criterio de salida |
| --- | --- | --- |
| CP00 Base | main.dart, app/tata_app.dart, widget_test.dart, CI, archivos de plataforma aportados | Analyze/widget/APK; iOS build en macOS; ningún flujo ficticio |
| CP01 Host visual | app/navigation/app_router.dart, shared/presentation/theme/{tata_theme,tata_colors,tata_typography}.dart, l10n/app_es.arb, app_en.arb, l10n.yaml | Tema fiel, español inicial, entradas accesibles, navegación/idioma widget tests |
| CP02 Acceso | session.dart, session_repository.dart, access_credentials.dart, sign_in.dart, restore_session.dart, session_api.dart, session_dto.dart, session_mapper.dart, remote_session_repository.dart, access_bloc/event/state.dart, login_screen.dart | Credenciales reales, restore/expiración/signout y errores sin éxito anticipado |
| CP03 Onboarding | register_caregiver.dart, verify_email.dart, request_verification.dart, register_bloc/event/state, registration_screen.dart, verification_screen.dart | No sesión antes de verificación; reenvío/código/reintento; errores equivalentes |
| CP04 CareLink | care_link.dart, linking_code.dart, care_link_reader.dart, request_link.dart, accept_link.dart, register_consent.dart, revoke_link.dart, link_api.dart, link_mapper.dart, link_bloc, consent_bloc, link_screen, consent_screen | Código, consentimiento y revocación real; datos ajenos ocultos |
| CP05 Treatment | medication.dart, treatment.dart, regimen.dart, treatment_repository.dart, register_medication.dart, create_treatment.dart, configure_regimen.dart, activate/pause/resume_treatment.dart, treatment_api/dto/mapper, wizard_bloc, management_bloc, wizard screens | Borrador y navegación conservan entradas; recibos validados; pantalla de gestión actualiza estado |
| CP06 Intake | intake.dart, confirmation.dart, agenda_reader.dart, confirm_dose.dart, intake_api/dto/mapper, agenda_bloc, next_dose_bloc, agenda/next_dose/detail screens | Agenda del tratamiento real, confirmación idempotente y transición vacía/rechazo |
| CP07 Offline | intake_database.dart, pending_confirmations.dart, intake_dao.dart, migrations/, offline_intake_repository.dart, replay_pending_confirmations.dart, connectivity_observer.dart | Red caída no fabrica éxito servidor, cola por propietario, replay con efecto único, migración y cambio de cuenta |
| CP08 Inventory | inventory_stock.dart, inventory_reader.dart, initialize_stock.dart, replenish_stock.dart, inventory_api/dto/mapper, inventory_bloc, initial_stock/replenishment/inventory screens | Stock10+5-1=14 con confirmación repetida, lotes y errores reales |
| CP09 Monitoring | linked_person_reader.dart, alerts_reader.dart, close_alert.dart, record_follow_up.dart, notes_repository.dart, monitoring/alerts/notes_api.dart, profile/alerts/detail/notes_bloc, screens | Permisos, filters, estado de alerta, notas, contacto y timeline solo evidencia conocida |
| CP10 Analytics | adherence_reader.dart, recommendations_reader.dart, get_summary.dart, get_treatment_summary.dart, analytics_api/dto/mapper, analytics_bloc, history/summary/trend screens | Período/zona correctos, tendencia por tratamiento, vacíos y errores distinguibles |
| CP11 Preferences | accessibility_preferences.dart, notification_policy.dart, preferences_repository.dart, update_preferences.dart, preferences_remote/local/mapper, preferences_bloc, accessibility/notification screens | Persistencia propietario, reconocimiento del toggle confirmado, texto/contraste/quiet hours |
| CP12 Plataforma | audio_recorder.dart, microphone_permission.dart, voice_confirmation.dart, platform_recorder.dart, voice_bloc/screen; messaging_adapter, push_devices_api, notification_intent_mapper | Permisos denegados, lifecycle, multipart correcto, transporte real certificado por separado |
| CP13 Social | social_identity_provider.dart, sign_in_social.dart, link_social_identity.dart, firebase_social_provider.dart, social_access_bloc | Token verificado en Spring, sesión Tata y vínculo explícito; nunca apropiación por correo |
| CP14 Release | matriz de aceptación, integración real, firma privada, versión propia, CI/iOS | Android+iOS según alcance confirmado, sin atribuir login real a fixtures |

Los nombres finales se normalizan a snake_case y el ubiquitous language de los contratos. No se crean cinco archivos por cada endpoint si no añaden una responsabilidad comprobable.

## 16. Inventario de flujos y evidencia

Por variante registrar: BC, actor, referencia Figma, pantalla/estado, acción, caso de uso, contrato HTTP, tipo de fixture, captura, resultado local y remoto, pendiente concreto. La matriz inicial parte de las 70 variantes Android; Flutter empieza en cero aceptadas. No repartir porcentajes por cantidad de archivos.

Estados transversales: acceso anónimo, sesión adulta/cuidadora, alta pendiente, consentimiento pendiente/revocado, carga inicial, empty real, error recuperable, error de validación, 401,403,404,409,429,5xx, timeout, cancelación, respuesta fuera de orden, rotación/pausa/reanudación, texto grande y teclado.

Reglas temporales: Instant en UTC para transporte, zona explícita para presentar/agrupar y límites de período. No convertir LocalDate a instante sin zona ni comparar fechas con now en tests sin reloj controlado. Payload tardío no se aplica a una sesión o selección distinta.

Política de errores: mapper por BC según código estable real; Inventory utiliza code/message y otros endpoints title/detail. Nunca decidir únicamente por texto español del servidor;401/403 prevalecen. No convertir 404 en lista vacía salvo contrato explícito.

## 17. Seguridad, offline y lifecycle desde el inicio

- Sesión: ownerId+role+generation; guardar secretos solo mediante puerto seguro. Limpiar estado sensible al logout/revocación/expiración; invalidar solicitudes pendientes antes de persistir respuesta.
- Offline: clave de idempotencia estable por operación; persistencia separada por propietario; distinguir pendiente local de recibo servidor. Reintentar errores transitorios, detener permisos/recurso eliminado y no reproducir con otro usuario.
- Formularios: controllers y focus se liberan con dispose; contraseña no se recorta; código y contraseña se borran tras éxito/salida; bloquear doble submit; cancelar no envía.
- Push: opt-in por entorno, token cambia de propietario mediante recibos y cleanup. Desuscripción de tópicos legacy si existen; ocultar notificación no protege transporte. Nunca loguear token.
- Recursos nativos: permisos Android e iOS específicos; no añadir permiso a scaffolding si no hay consumidor. Audio temporal se borra, formato/mime/longitud coinciden con backend.
- Transporte: HTTPS para backend remoto. AccesoHTTPloopback solo en configuración de desarrollo para integrar; sin permitir cleartext global productivo por facilidad.
- Datos del servidor: cache inválida no se presenta como vigente; refrescar tras mutación/retorno/foreground cuando corresponda. Servidor conserva autoridad de consentimiento, stock, omisiones y cálculos clínicos.

## 18. Fidelidad y adaptación práctica

Mantener tokens de Tata, fuentes originales licenciadas y assets adecuados a resolución. Nada de rasterizar formularios completos. Widgets Material/Cupertino se adaptan cuando su comportamiento lo requiere, sin sustituir la identidad visual por estilos arbitrarios de plataforma.

MediaQuery y LayoutBuilder usan píxeles lógicos y restricciones reales, no dimensiones fijas del frame ni tipo de hardware.600 de las láminas es un ejemplo, no estándar universal. Comprobar anchos360/390/600 y teclado/texto grande; listas con buildercuando hace falta. Scroll compuesto con slivers solo si aporta. SafeArea e insets evitan pie/teclado sobre controles. Botón anclado no corta contenido ni tapa errores.

## 19. Gate y progreso por responsabilidad

Estados por tarea: proposed, implemented, analyzed, unit/widgetpassed, integrationpassed, visualaccepted, platformvalidated, published. Cada avance lleva commit/fecha/comando/log y alcance. No equivalencia automática entre build y funcionamiento.

| Gate | Qué prueba | Qué no prueba |
| --- | --- | --- |
| dart format | Formato reproducible | Arquitectura/función |
| flutter analyze | Tipos/lints y errores estáticos | Permisos o contrato remoto |
| flutter test | Comportamiento de casos de uso/Bloc/widgets bajo inputs declarados | Proveedor o dispositivo real |
| build apk | Toolchain Android y empaquetado | Funciones clínicas |
| build ios simulator | Toolchain iOS en macOS | Firma/dispositivo físico |
| integration_test con Spring local | UI-adaptador-servidor en entorno aislado | Render/proveedores externos |
| captura equivalente Figma | Jerarquía, componentes y estados | Persistencia/seguridad |

No escribir pruebas espejo de un color o getter; sí escenarios de ownership, transacciones HTTP, filtros, reloj, conservación de wizard, retries y revocación. Fakes explícitos solo en test/ o integration_test fixtures. El primer corte con BLoC incorpora bloc_test y flujos asíncronos reales sin repetir operadores de estado en tests.

## 20. GitFlow y continuidad

CP00 se publica directamente en main como scaffold inicial autorizado; develop parte del mismo commit. Implementación posterior en feature/flutter-bootstrap o rama TS correspondiente. No múltiples ramas por la misma TS. Fix solo para defecto identificado. Sin tag de release ficticio para un scaffold.

Antes de cada push: diff check, stage explícito, verificar no secretos/caches/config local ni material PDF de terceros. main se integra únicamente con gates claros. Publicar la aplicación Flutter no modifica tags o código de Android/backend.

El plan se comparte en docs/cross-platform-plan.md en temp; README explica solo ejecución y responsabilidades básicas. Este es el único log de decisiones/progreso de la preparaciónFlutter, actualizable por corte. La procedencia, inventoryjsony renders quedan fuera del repo. Handoff de futuras sesiones: leer este plan, git status/remoto, material vigente y últimos gates antes de actuar.

## 21. Orden de cierre de esta preparación

1. Verificar scaffold del ZIP e identificadores según usuario.
2. Analyze/widget/build Android y CI iOS independiente.
3. Publicar main con base mínima y develop en mismo punto; confirmar remoto.
4. Registrar SHA y gates aquí. No declarar flujos de negocio implementados.
5. Próximo trabajo autorizado: primer flujo, no arquitectura vacía masiva.


## Anexo A. Inventario íntegro de PDF

Inventario/extracción de todos los PDF, no afirmación de revisión visual integral. E=texto indexado; V=láminas inspeccionadas visualmente; R=secciones pertinentes revisadas.

| PDF | Páginas | Alcance |
| --- | ---: | --- |
| 1ACC0238-Aplicaciones_para_Dispositivos_Moviles-3687.pdf | 15 | E+R (temas pertinentes) |
| upc-pre-si397-lean-foundation_v3.pdf | 39 | E |
| 1ACC0238_final-project-statement-version final (202610).pdf | 52 | E+R (temas pertinentes) |
| 1ACC0238-about-the-course_v3.pdf | 13 | E |
| 1ACC0238-mobile-technologies_v4.pdf | 46 | E |
| upc-pre-1ACC0238-ethics_v2.pdf | 29 | E |
| 1ACC0238-cross-plattform apps_v5.pdf | 41 | E |
| 1ACC0238-native apps_v5.pdf | 44 | E |
| 1ACC0238-Adaptive_Android_Architecture.pdf | 17 | E |
| 1ACC0238-android-foundation V2.pdf | 30 | E |
| 1ACC0238-android-ux V2.pdf | 21 | E |
| 1ACC0238-Android_UI_for_Web_Developers.pdf | 17 | E |
| 1ACC0238-android-networking v2.pdf | 29 | E |
| 1ACC0238-android-resources V2.pdf | 26 | E |
| 1ACC0238-Mobile_Networking.pdf | 11 | E |
| 1ACC0238-android-storage-part-1 v2.pdf | 27 | E |
| 1ACC0238-android-storage-part-2 v2.pdf | 20 | E |
| upc-pre-202610-1acc0238-pc1-3687.pdf | 2 | E |
| 1ACC0238-android-storage-Room v2.pdf | 17 | E |
| 1ACC0238-Android_Data_Architecture.pdf | 15 | E |
| 1ACC0238-Room_Persistence.pdf | 15 | E |
| 1ACC0238-best_practices v3.pdf | 10 | E |
| 1ACC0238-t&c v3.pdf | 8 | E |
| EAC_Student Outcome 7.pdf | 13 | E |
| upc-pre-202610-1acc0238-ea-3687.pdf | 2 | E |
| 1ACC0238-Challenge - codelab.pdf | 1 | E+R (temas pertinentes) |
| 1ACC0238-widgets v2.pdf | 15 | E+R (temas pertinentes) |
| 1ACC0238-flutter-networking v2.pdf | 33 | E+R (temas pertinentes) |
| Guía de Lab Persistencia parte1.pdf | 21 | E+R (temas pertinentes) |
| Guía de Lab Persistencia parte2.pdf | 7 | E+R (temas pertinentes) |
| 1ACC0238-flutter-persistence-p1 v2.pdf | 19 | E+R (temas pertinentes) |
| 1ACC0238-flutter-persistence-p2 v2.pdf | 13 | E+R (temas pertinentes) |
| Guía drift 20260619 A.pdf | 9 | E+R (temas pertinentes) |
| 1ACC0238-Adaptive_Flutter_Design.pdf | 17 | E+V |
| 1ACC0238-Flutter_UI_Architecture.pdf | 16 | E+V |
| 1ACC0238-intro flutter & dart v2.pdf | 25 | E+R (temas pertinentes) |
| 1ACC0238-resumen y links importantes flutter sem 9 v2.pdf | 3 | E+R (temas pertinentes) |
| 1ACC0238-stateless & stateful Widgets v2.pdf | 25 | E+R (temas pertinentes) |
| Packt.Flutter.Projects.pdf | 483 | E+R (temas pertinentes) |
| 1ACC0238-AI-Assisted iOS Development.pdf | 20 | E+R (temas pertinentes) |
| 1ACC0238-iOS UX and Design with HIG.pdf | 42 | E+R (temas pertinentes) |
| 1ACC0238-iOS-platform-foundation.pdf | 40 | E+R (temas pertinentes) |
| Guía de Lab Nro 9 Netw + BD - 2dap.pdf | 13 | E+R (temas pertinentes) |
| Guía de Lab Nro 9 Netw + BD - 3rap.pdf | 7 | E+R (temas pertinentes) |
| upc-pre-202610-1acc0238-pc2-3687.pdf | 2 | E+R (temas pertinentes) |
| 1ACC0238-iOS Local Data Persistence in iOS.pdf | 25 | E+R (temas pertinentes) |
| Student Outcome 7.pdf | 13 | E+R (temas pertinentes) |
| upc-pre-202610-1acc0238-eb-3687.pdf | 3 | E+R (temas pertinentes) |


## 22. Progreso CP00 y registro de cambios

27-10-2026: main y develop publicados inicialmente con e55b58c; consolidación final ed44709 (chore: initialize Flutter scaffold), 69 archivos. Repositorio https://github.com/vitaHealth-UPC/mobile-cross-platform. Árbol base procedente del ZIP original. .metadata preservada; plataformas Android/iOS conservadas. Identificador final com.vitahealth.tata, paquete Dart tata, versión 0.1.0+1.

Análisis estático local sin incidencias; widget de arranque 1/1 aprobado. Primer dart format previo a pub get produjo advertencia de resolución de lints; pub get posterior resolvió las dependencias y analyze pasó. El primer APK se interrumpió para corregir el identificador por indicación del usuario; no cuenta como build aprobado. Build definitivo local en curso. Jobs CI main 40478631269 y develop 40478648314 verifican formato/analyze/test/APK en Ubuntu y compilación simulador iOS en macOS. No afirmar certificación iOS de dispositivo o firma por ese job.

CP00 implementado; BLoC/Drift/HTTP y flujos CP01-14 todavía no implementados. La presencia del plan no aumenta el porcentaje de producto. Próxima rama propuesta feature/flutter-bootstrap, desde develop cuando se inicie host/tema/primer flujo. No se crea hasta que haya trabajo concreto autorizado.

## 23. Responsabilidades Flutter frente a backend y cliente nativo

El backend publicado com.vitahealth.tata conserva los contratos y políticas. El cliente Flutter no migra tablas de Spring ni copia la organización técnica del proyecto Android. Las entidades Dart modelan identidad y estado necesario para la experiencia del cliente; el lenguaje ubicuo y las invariantes de formulario permanecen claros sin replicar motores clínicos del servidor.

- AccountSession es sesión Tata, no FirebaseUser. La cuenta del cuidador, el perfil adulto y un CareLink son identidades diferentes.
- Stock es un read model con escrituras autorizadas. No usar un caché como cálculo de consumo permanente.
- Adherencia global y por tratamiento son consultas distintas; no reemplazar una por otra cuando falta endpoint.
- Alerta generada/entregada/atendida son hechos diferentes. El timeline solo dibuja evidencia persistida.
- Preferencias de usuario se separan por propietario; la UI global observa la preferencia activa sin exponer las de otro.
- ScheduledIntake, PendingConfirmation y ConfirmedIntake no son un booleano con éxito optimista permanente.

Antes de portar un BC: leer su contrato API y pruebas del backend vigente, el flujo Android aprobado y su referencia Figma. Registrar diferencias de plataforma. No asumir que un cliente previo es la fuente de verdad de todos los errores. Usar Spring como autoridad de permisos y recibos, Figma para composición y material para objetivos de aprendizaje.

## 24. Evaluación de decisiones del material

BLoC no es la arquitectura completa de la aplicación: define flujo de estado; DDD define límites del negocio; las capas separan dependencias. La propuesta combina estos conceptos explícitamente. No añadir carpeta interfaces además de presentation sin responsabilidad concreta. La API REST no se implementa en Dart como servidor; los contratos del cliente están en ports/repositories y el transporte en infrastructure.

Las guías oficiales de Flutter proponen MVVM y dominio opcional, no cuatro capas exactas. La guía BLoC presenta tres responsabilidades generales. Tata usa aplicación/dominio puros porque ya tiene reglas, offline y colaboración entre nueve BC; esa es una decisión justificada del producto, no una norma universal.

El material de interfaces generado con NotebookLM tiene esquemas y afirmaciones simplificadas. Se usa para conceptos de layout y adaptación, no para fijar detalles internos del motor, métricas de performance o defaults que pueden variar por versión. Las reglas del SDK y las APIs se verifican en la documentación oficial antes de usarlas.

## 25. Criterio para mantener el scaffold pequeño

El scaffold original aporta main.dart y app/tata_app.dart; el checkpoint describe los recorridos que ya amplían esa base. No inventar interfaces de repositorio sin consumidores ni carpetas de contexto con README para simular implementación. Agregar assets solo desde fuentes originales y con licencias verificadas; no copiar PNG de capturas de Compose.

El Android host utiliza Kotlin y el nuevo AGP del scaffold. No añadir manualmente el plugin Kotlin dos veces si el generado ya lo maneja. Mantener settings.gradle.kts, wrapper y Gradle de Flutter hasta que una incompatibilidad real requiera cambio. iOS conserva AppDelegate, SceneDelegate, Info.plist, proyectos/workspaces y Tests; plugins pueden regenerar sus registrants. No subir archivos de máquina para aparentar que faltan menos archivos.


## 26. Trazabilidad verificada de fuentes y preservación

Referencias exactas dentro de los PDF locales:
- Sílabo: unidad 3 página 7; unidad 4 páginas 8-9.
- Intro Flutter&Dart: patrón BLoC página 22.
- Flutter Networking: eventos/estados página 18, BlocBuilder/Provider página 24 y dependencia antigua flutter_bloc 4 página 27. Son evidencia pedagógica y no constraint de paquetes actual.
- Flutter Persistence II: SQLite tipado/generación página 5; definición Drift página 7.
- Enunciado anterior: enfoque DDD página 2 y alternativa Flutter/KMP página 31.
- UI Architecture: render completo de 16 páginas; Adaptive Flutter Design: render completo de 17 páginas. Se revisaron las láminas, no solo la extracción OCR/texto vacía.

Comparación automatizada del scaffold con tata.zip:
- .metadata idéntica byte a byte.
- 69 archivos versionados; 24 archivos originales quedan correctamente ignorados por Git.
- Modificaciones originales: .gitignore, android/app/build.gradle.kts, ios/Runner.xcodeproj/project.pbxproj, lib/main.dart, pubspec.yaml, README.md y test/widget_test.dart.
- MainActivity original se reubica a android/app/src/main/kotlin/com/vitahealth/tata/MainActivity.kt y cambia su package de com.vitahealth.tata.tata a com.vitahealth.tata. No es un archivo funcional omitido.
- Archivos añadidos: lib/app/tata_app.dart y .github/workflows/flutter-ci.yml; pubspec.lock resuelto con SDK correcto.
- Comparación local: evidencia-local-no-publicada/tata-flutter-base-comparison-20261027.json.

No se ejecutan consignas de exámenes, tareas antiguas o prompts dentro de PDFs como instrucciones actuales. Las decisiones de producto proceden del usuario y las referencias técnicas se verifican con documentación oficial.


## 27. Inventario del scaffold versionado y función

El inventario corresponde al commit ed44709. La función indicada no presume que los archivos generados deban editarse a mano.

| Archivo o grupo | Responsabilidad | Política |
| --- | --- | --- |
| .metadata | Procedencia y capacidades/migración Flutter | Preservar; lo mantiene la herramienta |
| pubspec.yaml | Identidad Dart, SDK y dependencias de la aplicación | Versionar; añadir solo dependencias usadas |
| pubspec.lock | Resolución reproducible de paquetes | Versionar por ser app |
| analysis_options.yaml | Reglas de análisis del SDK/lints | Versionar; no silenciar reglas globalmente para ocultar problemas |
| .gitignore | Excluir caches, IDE, configuración local y firma | Incluye .kotlin creado por compilación actual |
| lib/main.dart | Inicio del proceso | Sin negocio ni HTTP |
| lib/app/tata_app.dart | Composición MaterialApp y host mínimo | Crece solo con responsabilidades del host |
| test/widget_test.dart | Arranque del scaffold | Se conserva como smoke gate, no cuenta como aceptación del producto |
| .github/workflows/flutter-ci.yml | Verificación Ubuntu/Android y macOS/iOS | SDK fijo; sin secretos de firma |
| android/settings.gradle.kts | Resolución del SDK Flutter y plugins Android | Mantener base generada |
| android/build.gradle.kts | Configuración Gradle del host | Sin dependencias de módulos backend |
| android/app/build.gradle.kts | App ID, SDK/Java/Kotlin y plugin Flutter | ID corregido; firma release real se configura fuera del repo |
| android/gradle.properties | Parámetros propios del host Gradle | Distinguir ajustes de entorno de requisitos del equipo |
| android/gradle/wrapper/gradle-wrapper.properties | Distribución Gradle | Wrapper generado por Flutter según template; no inventar rutas absolutas |
| android/app/src/main/kotlin/com/vitahealth/tata/MainActivity.kt | Actividad anfitriona de Flutter | Sin pantallas Compose ni negocio |
| android/app/src/main/AndroidManifest.xml | Identidad y arranque nativo | Permisos se añaden con cada función |
| android/app/src/debug y profile | Opciones de build de desarrollo | No trasladarlas a producción por costumbre |
| android/app/src/main/res | Splash, iconos y estilos de plataforma | Preservar; cambiar solo cuando se definan recursos finales |
| ios/Runner.xcodeproj y xcworkspace | Build settings, targets y proyecto Xcode | Versionar archivos compartidos, excluir estado del usuario |
| ios/Flutter/{Debug,Release}.xcconfig y AppFrameworkInfo.plist | Configuración del engine y builds | Generated.xcconfig es local y regenerable |
| ios/Runner/{AppDelegate,SceneDelegate}.swift | Ciclo de vida del host iOS | Plugins/navegación nativa solo cuando son necesarios |
| ios/Runner/{Info.plist,Runner-Bridging-Header.h} | Metadatos y puente del host | Usage descriptions de permisos con funciones reales |
| ios/Runner/Assets.xcassets y Base.lproj | Iconos y launch/main storyboard del host | No equivalen a pantallas Flutter |
| ios/RunnerTests/RunnerTests.swift | Base de pruebas nativas | No sustituye widget/integration tests |
| README.md | Cómo ejecutar y verificar | Sin plan local ni material académico de terceros |

Generados fuera de Git: .idea, .iml, android/local.properties, gradlew/gradlew.bat y wrapper JAR excluidos por la propia plantilla aportada, .dart_tool, build, registrants de plugins y configuraciones ephemeral. flutter pub get y el toolchain reconstruyen sus artefactos; no presentar un binario regenerable omitido como una carencia arquitectónica.


## Inventario individual de archivos: destino, responsabilidad y corte

Cada fila nombra un archivo completo. Son destinos previstos, no carpetas vacías a crear. Las firmas se contrastan con backend antes de implementar cada flujo. No generar command/query/handler/usecase redundantes: los casos de uso puros expresan intención; BLoC representa estado de presentación. Los puertos de proyección van en application; repositorios de entidades en domain. Sin dominio artificial en contextos de consultas.

Estado inicial de estas filas: PLANIFICADO, salvo registro de implementación posterior. Los archivos base presentes en ZIP ya están inventariados en sección 27. Archivos generados .g.dart y assets no son clases de negocio adicionales.

### Archivos de HOST

| Archivo completo | Responsabilidad |
| --- | --- |
| `lib/app/config/app_config.dart` | Validar API URL, entorno y flags; HTTP solo para loopback de desarrollo |
| `lib/app/bootstrap.dart` | Crear/cerrar recursos y cargar preferencias iniciales |
| `lib/app/di/app_dependencies.dart` | Composición de adapters y casos de uso, sin lógica clínica |
| `lib/app/navigation/app_router.dart` | Rutas y guards por sesión, sin HTTP dentro del redirect |
| `lib/app/navigation/app_destinations.dart` | Destinos y argumentos de identidad sin credenciales |
| `lib/app/integration/session/session_cleanup.dart` | Invalidar cache/cola/push al cambiar actor |
| `lib/app/integration/clinical/medication_overview.dart` | Componer catálogo, pauta y próxima toma mediante puertos |
| `lib/app/integration/consent/consent_withdrawal.dart` | Revocar vínculo y limpiar sesión/datos afectados |
| `lib/app/integration/monitoring/linked_person.dart` | Componer perfil/contacto/tratamientos sin imports de infraestructura de otro BC |
| `lib/app/integration/push/push_navigation.dart` | Resolver notificación a ruta con permiso revalidado |
| `lib/l10n/app_es.arb` | Mensajes base español con placeholders |
| `lib/l10n/app_en.arb` | Traducciones explícitas con las mismas claves |

### Archivos de shared

| Archivo completo | Responsabilidad |
| --- | --- |
| `lib/shared/common/result/app_result.dart` | Éxito/fallo tipado con diagnóstico seguro |
| `lib/shared/application/session/session_owner.dart` | Identidad y rol sin token |
| `lib/shared/application/session/stored_session.dart` | Credencial/expiry con diagnóstico redactado |
| `lib/shared/application/session/session_store.dart` | Leer, guardar, invalidar y observar generación |
| `lib/shared/application/time/clock.dart` | Reloj inyectable para expiración y períodos |
| `lib/shared/infrastructure/network/api_client.dart` | HTTP/JSON/timeouts y autenticación capturada por solicitud |
| `lib/shared/infrastructure/network/api_response.dart` | Status/cuerpo como frontera interna sin filtrar HTTP al dominio |
| `lib/shared/infrastructure/security/secure_session_store.dart` | Guardar secretos y descartar formato inválido/expirado |
| `lib/shared/presentation/theme/tata_colors.dart` | Tokens de color y contraste |
| `lib/shared/presentation/theme/tata_typography.dart` | Fuentes licenciadas y escala |
| `lib/shared/presentation/theme/tata_theme.dart` | Theme claro/oscuro coherente |
| `lib/shared/presentation/widgets/tata_primary_button.dart` | Botón accesible con busy y disabled |
| `lib/shared/presentation/widgets/tata_feedback.dart` | Error/resultado visible y semántico |
| `lib/shared/presentation/widgets/caregiver_navigation_bar.dart` | Barra cuidador con callbacks y selección |
| `lib/shared/presentation/widgets/older_adult_navigation_bar.dart` | Barra adulto con alcance y contraste |

### Archivos de identity_subscription

| Archivo completo | Responsabilidad |
| --- | --- |
| `lib/features/identity_subscription/domain/entities/account_session.dart` | Sesión Tata autenticada con actor único |
| `lib/features/identity_subscription/domain/value_objects/email_address.dart` | Sintaxis y normalización de correo |
| `lib/features/identity_subscription/domain/repositories/session_repository.dart` | Autenticar/restaurar/revocar sesión de dominio |
| `lib/features/identity_subscription/application/ports/account_registration.dart` | Alta y verificación sin sesión prematura |
| `lib/features/identity_subscription/application/ports/password_recovery.dart` | Solicitud uniforme y completar por código |
| `lib/features/identity_subscription/application/ports/social_identity_provider.dart` | Credencial externa transitoria sin dependencia del SDK |
| `lib/features/identity_subscription/application/ports/subscription_reader.dart` | Catálogo y suscripción autorizados |
| `lib/features/identity_subscription/application/ports/subscription_updater.dart` | Cambio de plan con recibo real |
| `lib/features/identity_subscription/application/readmodels/plan_summary.dart` | Precio/capacidades de catálogo, no pago ejecutado |
| `lib/features/identity_subscription/application/readmodels/subscription_summary.dart` | Plan efectivo de la cuenta |
| `lib/features/identity_subscription/application/usecases/sign_in.dart` | Validar entrada, autenticar y no recortar contraseña |
| `lib/features/identity_subscription/application/usecases/restore_session.dart` | Vigencia local y current remoto |
| `lib/features/identity_subscription/application/usecases/sign_out.dart` | Revocar y limpiar alcance local |
| `lib/features/identity_subscription/application/usecases/register_caregiver.dart` | Crear cuenta pendiente con datos válidos |
| `lib/features/identity_subscription/application/usecases/verify_email.dart` | Consumir código y confirmar verificación |
| `lib/features/identity_subscription/application/usecases/request_verification.dart` | Solicitar reenvío y reconocer errores |
| `lib/features/identity_subscription/application/usecases/request_password_recovery.dart` | Aceptar solicitud sin enumerar cuentas |
| `lib/features/identity_subscription/application/usecases/complete_password_recovery.dart` | Cambiar contraseña sin auto-login |
| `lib/features/identity_subscription/application/usecases/sign_in_with_pin.dart` | Acceso adulto y alcance de PIN |
| `lib/features/identity_subscription/application/usecases/register_pin.dart` | Alta de PIN autorizada y secreto efímero |
| `lib/features/identity_subscription/application/usecases/sign_in_social.dart` | IDtoken a sesión Tata emitida por Spring |
| `lib/features/identity_subscription/application/usecases/link_social_identity.dart` | Vínculo explícito desde sesión capturada, no asociación automática por correo |
| `lib/features/identity_subscription/application/usecases/change_subscription.dart` | Seleccionar, cambiar y refrescar plan |
| `lib/features/identity_subscription/infrastructure/remote/session_api.dart` | sessions/current/PIN/social con contratos HTTP |
| `lib/features/identity_subscription/infrastructure/remote/session_dto.dart` | Parseo estricto de token/expiry/account/adult |
| `lib/features/identity_subscription/infrastructure/remote/registration_api.dart` | accounts, verification y resend públicos |
| `lib/features/identity_subscription/infrastructure/remote/registration_dto.dart` | Cuenta pendiente/activa sin defaults falsos |
| `lib/features/identity_subscription/infrastructure/remote/password_recovery_api.dart` | POST de solicitud 202 y confirmación 204 anónimos |
| `lib/features/identity_subscription/infrastructure/remote/subscription_api.dart` | GET de planes y GET/PUTsubscription |
| `lib/features/identity_subscription/infrastructure/remote/subscription_dto.dart` | Campos numéricos y recibo de plan |
| `lib/features/identity_subscription/infrastructure/mappers/session_mapper.dart` | Identidad única, expiry válida y actor conocido |
| `lib/features/identity_subscription/infrastructure/mappers/identity_failure_mapper.dart` | title/detail y HTTP401/403/409 sin depender del idioma |
| `lib/features/identity_subscription/infrastructure/mappers/subscription_mapper.dart` | Proyección validada por cuenta/plan solicitado |
| `lib/features/identity_subscription/infrastructure/repositories/remote_session_repository.dart` | HTTP y store con descarte de respuesta obsoleta |
| `lib/features/identity_subscription/infrastructure/repositories/remote_account_registration.dart` | Alta/verificación reales, no email simulado |
| `lib/features/identity_subscription/infrastructure/repositories/remote_password_recovery.dart` | Código/reintento y limpieza de secretos |
| `lib/features/identity_subscription/infrastructure/repositories/remote_subscription_repository.dart` | Planes/cambio con owner y recibos |
| `lib/features/identity_subscription/infrastructure/social/firebase_social_identity_provider.dart` | SDK de Google/Meta, cancelación y cierre de credencial |

### Archivos de care_link

| Archivo completo | Responsabilidad |
| --- | --- |
| `lib/features/care_link/domain/entities/care_link.dart` | IDs de actores y estado de consentimiento |
| `lib/features/care_link/domain/value_objects/linking_code.dart` | Código temporal y validación |
| `lib/features/care_link/application/ports/caregiver_profiles_reader.dart` | Perfiles autorizados del cuidador |
| `lib/features/care_link/application/ports/care_link_writer.dart` | Alta/vínculo/consentimiento/revocación |
| `lib/features/care_link/application/ports/linked_person_profile_reader.dart` | Perfil y contacto sin acoplar clínica |
| `lib/features/care_link/application/readmodels/older_adult_profile.dart` | Perfil/relación/contacto con owner |
| `lib/features/care_link/application/usecases/register_older_adult.dart` | Alta validada del perfil |
| `lib/features/care_link/application/usecases/generate_linking_code.dart` | Código con dueño/estado comprobados |
| `lib/features/care_link/application/usecases/accept_care_link.dart` | Aceptar vínculo y recibo correcto |
| `lib/features/care_link/application/usecases/register_consent.dart` | Aceptar/rechazar explícitamente |
| `lib/features/care_link/application/usecases/withdraw_consent.dart` | Revocar y disparar invalidación del alcance |
| `lib/features/care_link/application/usecases/update_linked_person_contact.dart` | Cambiar contacto sin alterar campos básicos |
| `lib/features/care_link/infrastructure/remote/care_link_api.dart` | carelinks/linkingcodes/consent/olderadults |
| `lib/features/care_link/infrastructure/remote/care_link_dto.dart` | Vínculo/código con estado explícito |
| `lib/features/care_link/infrastructure/remote/older_adult_profile_dto.dart` | Perfil/contacto con metadatos |
| `lib/features/care_link/infrastructure/mappers/care_link_mapper.dart` | IDs/estado y valores válidos |
| `lib/features/care_link/infrastructure/repositories/remote_care_link_repository.dart` | Adapter con sesión capturada y guardas |

### Archivos de treatment_management

| Archivo completo | Responsabilidad |
| --- | --- |
| `lib/features/treatment_management/domain/entities/medication.dart` | Identidad, dueño y disponibilidad |
| `lib/features/treatment_management/domain/entities/treatment.dart` | Identidad, dueño y estado |
| `lib/features/treatment_management/domain/value_objects/regimen.dart` | Dosis, frecuencia, horas e indicaciones |
| `lib/features/treatment_management/domain/value_objects/reminder_settings.dart` | Preaviso y seguimiento null distinto de 0 |
| `lib/features/treatment_management/domain/repositories/treatment_repository.dart` | Medicamento y borrador de tratamiento |
| `lib/features/treatment_management/application/ports/treatment_reader.dart` | Detalle/catálogo autorizados |
| `lib/features/treatment_management/application/ports/treatment_lifecycle.dart` | Pauta y transiciones con recibo |
| `lib/features/treatment_management/application/readmodels/treatment_detail.dart` | Pauta efectiva y estado remoto |
| `lib/features/treatment_management/application/usecases/register_medication.dart` | Alta de medicamento y owner |
| `lib/features/treatment_management/application/usecases/create_treatment.dart` | Borrador sin activación implícita |
| `lib/features/treatment_management/application/usecases/configure_regimen.dart` | Guardar pauta conservando tiempos |
| `lib/features/treatment_management/application/usecases/activate_treatment.dart` | Activación solo tras pauta válida |
| `lib/features/treatment_management/application/usecases/pause_treatment.dart` | Pausa autorizada con estado recibido |
| `lib/features/treatment_management/application/usecases/resume_treatment.dart` | Reanudar explícitamente sin reactivar medicamento |
| `lib/features/treatment_management/application/usecases/deactivate_medication.dart` | Desactivación dirigida sin borrar historial |
| `lib/features/treatment_management/application/usecases/reactivate_medication.dart` | Reactivar sin reanudar tratamientos automáticamente |
| `lib/features/treatment_management/infrastructure/remote/treatment_api.dart` | Catálogo/pauta/lifecycle |
| `lib/features/treatment_management/infrastructure/remote/medication_dto.dart` | Campos de medicamento sin default activo |
| `lib/features/treatment_management/infrastructure/remote/treatment_dto.dart` | Pauta/reminders/estado con parseo estricto |
| `lib/features/treatment_management/infrastructure/mappers/treatment_mapper.dart` | Recibo contra solicitud, dueño e identidad |
| `lib/features/treatment_management/infrastructure/repositories/remote_treatment_repository.dart` | Adapter alta/borrador/lectura |
| `lib/features/treatment_management/infrastructure/repositories/remote_treatment_lifecycle.dart` | Configurar/transicionar e invalidar revocado |
| `lib/features/treatment_management/presentation/state/treatment_draft.dart` | Borrador local por tratamiento y propietario |

### Archivos de intake_execution

| Archivo completo | Responsabilidad |
| --- | --- |
| `lib/features/intake_execution/domain/entities/intake.dart` | Toma y evidencia definitiva de confirmación |
| `lib/features/intake_execution/domain/value_objects/confirmation_channel.dart` | Canales táctil/voz conocidos |
| `lib/features/intake_execution/application/ports/agenda_reader.dart` | Agenda por adulto e intervalo UTC |
| `lib/features/intake_execution/application/ports/next_dose_reader.dart` | Próxima toma o vacío autoritativo |
| `lib/features/intake_execution/application/ports/dose_confirmation_repository.dart` | Confirmar identidad solicitada idempotentemente |
| `lib/features/intake_execution/application/ports/audio_recorder.dart` | Grabar/cancelar/limpiar audio acotado |
| `lib/features/intake_execution/application/ports/voice_confirmation_repository.dart` | Multipart y reconocimiento remoto |
| `lib/features/intake_execution/application/ports/sync_scheduler.dart` | Solicitar sync sin depender del plugin |
| `lib/features/intake_execution/application/readmodels/dose_detail.dart` | Detalle/tiempo/resultado de toma |
| `lib/features/intake_execution/application/readmodels/pending_confirmation.dart` | Operación por propietario y clave idempotente |
| `lib/features/intake_execution/application/usecases/get_agenda.dart` | Intervalo/zona y orden por adulto |
| `lib/features/intake_execution/application/usecases/get_next_dose.dart` | Vacío distinto de fallo de red |
| `lib/features/intake_execution/application/usecases/confirm_dose.dart` | Recibo o pendiente offline explícito |
| `lib/features/intake_execution/application/usecases/confirm_voice.dart` | Audio válido y recibo de la misma toma |
| `lib/features/intake_execution/application/usecases/replay_pending_confirmations.dart` | Reintento por dueño con efecto único |
| `lib/features/intake_execution/infrastructure/remote/intake_api.dart` | agenda/next/detail/confirmation/voice |
| `lib/features/intake_execution/infrastructure/remote/intake_dto.dart` | IDs/fecha/status/evidencia obligatorios |
| `lib/features/intake_execution/infrastructure/mappers/intake_mapper.dart` | Fechas/canales/estado/recibos y errores |
| `lib/features/intake_execution/infrastructure/local/intake_database.dart` | Drift y versión de esquema |
| `lib/features/intake_execution/infrastructure/local/tables/cached_intakes.dart` | Cache de agenda por propietario |
| `lib/features/intake_execution/infrastructure/local/tables/pending_confirmations.dart` | Cola duradera owner/operation/nextretry |
| `lib/features/intake_execution/infrastructure/local/dao/intake_dao.dart` | Cambios atómicos de cache y cola |
| `lib/features/intake_execution/infrastructure/local/migrations/intake_migrations.dart` | Migración no destructiva comprobada |
| `lib/features/intake_execution/infrastructure/repositories/offline_intake_repository.dart` | Coordinar remote/local sin éxito remoto ficticio |
| `lib/features/intake_execution/infrastructure/audio/platform_audio_recorder.dart` | Plugin/permiso/lifecycle/archivos temporales |
| `lib/features/intake_execution/infrastructure/sync/intake_sync_coordinator.dart` | Red validada/foreground y replay serializado |

### Archivos de inventory_replenishment

| Archivo completo | Responsabilidad |
| --- | --- |
| `lib/features/inventory_replenishment/domain/value_objects/inventory_quantity.dart` | Cantidad/umbral y reposición positiva |
| `lib/features/inventory_replenishment/domain/value_objects/inventory_lot.dart` | Normalizar lote opcional con límite |
| `lib/features/inventory_replenishment/application/ports/inventory_repository.dart` | Proyección stock sin agregado cliente inventado |
| `lib/features/inventory_replenishment/application/readmodels/inventory_stock.dart` | Stock/cobertura/lotes, alta distinta de reposición |
| `lib/features/inventory_replenishment/application/usecases/get_inventory.dart` | Leer medicamento autorizado |
| `lib/features/inventory_replenishment/application/usecases/register_initial_stock.dart` | Alta de cantidad/umbral |
| `lib/features/inventory_replenishment/application/usecases/register_replenishment.dart` | Reposición y conflicto concurrente |
| `lib/features/inventory_replenishment/infrastructure/remote/inventory_api.dart` | inventories/replenishments |
| `lib/features/inventory_replenishment/infrastructure/remote/inventory_dto.dart` | Ausencia distinta de 0/false |
| `lib/features/inventory_replenishment/infrastructure/mappers/inventory_mapper.dart` | IDs/lotes/fechas y code/message |
| `lib/features/inventory_replenishment/infrastructure/repositories/remote_inventory_repository.dart` | Lecturas/escrituras con recibo real |

### Archivos de family_monitoring

| Archivo completo | Responsabilidad |
| --- | --- |
| `lib/features/family_monitoring/application/ports/family_monitoring_reader.dart` | Resumen y perfil clínico autorizado |
| `lib/features/family_monitoring/application/ports/alerts_reader.dart` | Filtros, detalle e historial real |
| `lib/features/family_monitoring/application/ports/alert_actions.dart` | Atender/cerrar/seguimiento con recibo |
| `lib/features/family_monitoring/application/ports/notes_repository.dart` | Notas propias y de cuidado con alcance |
| `lib/features/family_monitoring/application/readmodels/family_summary.dart` | Miembros y estado conocido |
| `lib/features/family_monitoring/application/readmodels/alert_detail.dart` | Alerta/acciones/contacto |
| `lib/features/family_monitoring/application/readmodels/alert_timeline_event.dart` | Hechos confirmados sin entrega inferida |
| `lib/features/family_monitoring/application/readmodels/care_note.dart` | Autor/fecha/owner y texto |
| `lib/features/family_monitoring/application/usecases/get_family_summary.dart` | Descartar respuesta de owner anterior |
| `lib/features/family_monitoring/application/usecases/get_alert_detail.dart` | Detalle de identidad coherente |
| `lib/features/family_monitoring/application/usecases/update_alert_status.dart` | Cambio explícito y refresco |
| `lib/features/family_monitoring/application/usecases/record_follow_up.dart` | Seguimiento sin cierre automático |
| `lib/features/family_monitoring/application/usecases/save_care_note.dart` | Validación y persistencia en vínculo apropiado |
| `lib/features/family_monitoring/infrastructure/remote/monitoring_api.dart` | summary/status/perfil |
| `lib/features/family_monitoring/infrastructure/remote/alerts_api.dart` | lista/detail/status/timeline/followup |
| `lib/features/family_monitoring/infrastructure/remote/notes_api.dart` | Notas personales/cuidador según endpoint |
| `lib/features/family_monitoring/infrastructure/remote/monitoring_dto.dart` | Resumen/alertas con campos válidos |
| `lib/features/family_monitoring/infrastructure/remote/note_dto.dart` | Entrada y recibo con dueño/instante |
| `lib/features/family_monitoring/infrastructure/mappers/monitoring_mapper.dart` | Proyección sin datos ficticios |
| `lib/features/family_monitoring/infrastructure/repositories/remote_monitoring_repository.dart` | Consultas/acciones con sesión capturada |
| `lib/features/family_monitoring/infrastructure/repositories/remote_notes_repository.dart` | CRUD sin fuga entre perfiles |

### Archivos de adherence_analytics

| Archivo completo | Responsabilidad |
| --- | --- |
| `lib/features/adherence_analytics/application/ports/adherence_reader.dart` | Resumen/tendencia global o por tratamiento |
| `lib/features/adherence_analytics/application/ports/recommendations_reader.dart` | Insights del servidor, vacío legítimo |
| `lib/features/adherence_analytics/application/readmodels/adherence_summary.dart` | Conteos/porcentajes/período/cambios |
| `lib/features/adherence_analytics/application/readmodels/adherence_trend_point.dart` | Punto temporal y valor válido |
| `lib/features/adherence_analytics/application/readmodels/adherence_recommendation.dart` | Patrón y texto reales |
| `lib/features/adherence_analytics/application/usecases/get_adherence_summary.dart` | Período y zona del adulto |
| `lib/features/adherence_analytics/application/usecases/get_treatment_adherence.dart` | Tratamiento específico, sin resumen global sustituto |
| `lib/features/adherence_analytics/application/usecases/get_recommendations.dart` | Consultar sin generar criterio clínico local |
| `lib/features/adherence_analytics/infrastructure/remote/analytics_api.dart` | summary/treatment-summary/insight |
| `lib/features/adherence_analytics/infrastructure/remote/adherence_dto.dart` | Conteos y ausencia detectables |
| `lib/features/adherence_analytics/infrastructure/mappers/adherence_mapper.dart` | Rangos/series/zona/períodos |
| `lib/features/adherence_analytics/infrastructure/repositories/remote_adherence_repository.dart` | Lecturas protegidas, empty distinto de error |

### Archivos de accessibility_preferences

| Archivo completo | Responsabilidad |
| --- | --- |
| `lib/features/accessibility_preferences/domain/entities/user_preferences.dart` | Configuración de un solo owner |
| `lib/features/accessibility_preferences/domain/value_objects/accessibility_preferences.dart` | Escala/contraste/movimiento/lectura/voz/tema |
| `lib/features/accessibility_preferences/domain/value_objects/notification_policy.dart` | Canales/quiet hours y preservación de política |
| `lib/features/accessibility_preferences/domain/repositories/preferences_repository.dart` | Configuración por usuario |
| `lib/features/accessibility_preferences/application/usecases/get_preferences.dart` | Leer configuración vigente |
| `lib/features/accessibility_preferences/application/usecases/update_accessibility.dart` | Cambiar ajuste y confirmar recibo |
| `lib/features/accessibility_preferences/application/usecases/update_notification_policy.dart` | Horario/canales sin borrar otros ajustes |
| `lib/features/accessibility_preferences/application/usecases/change_language.dart` | Idioma ES/EN explícito y por usuario |
| `lib/features/accessibility_preferences/infrastructure/remote/preferences_api.dart` | preferences y notificationpolicy |
| `lib/features/accessibility_preferences/infrastructure/remote/preferences_dto.dart` | Campos obligatorios/owner |
| `lib/features/accessibility_preferences/infrastructure/mappers/preferences_mapper.dart` | Escala/canales/horario/nullvsfalse |
| `lib/features/accessibility_preferences/infrastructure/local/preferences_local_store.dart` | Persistencia por owner y revisión pendiente |
| `lib/features/accessibility_preferences/infrastructure/repositories/offline_preferences_repository.dart` | Estado local/remoto y sync por sesión |
| `lib/features/accessibility_preferences/infrastructure/platform/platform_reading_assistance.dart` | TTS/lectura cuando existe consumidor real |

### Archivos de omission_escalation

| Archivo completo | Responsabilidad |
| --- | --- |
| `lib/features/omission_escalation/application/ports/push_device_repository.dart` | Registro/retirada de instalación autorizada |
| `lib/features/omission_escalation/application/ports/push_token_source.dart` | Token y refresh sin dependencia del SDK |
| `lib/features/omission_escalation/application/ports/notification_presenter.dart` | Mostrar/cancelar según owner |
| `lib/features/omission_escalation/application/usecases/register_push_device.dart` | Asociar bajo sesión actual con recibo |
| `lib/features/omission_escalation/application/usecases/unregister_push_device.dart` | Retirar destinatario al cambiar sesión |
| `lib/features/omission_escalation/application/readmodels/notification_intent.dart` | Destino validado con IDs mínimos |
| `lib/features/omission_escalation/infrastructure/remote/push_devices_api.dart` | PUT/DELETE por installationId, owner desde bearer |
| `lib/features/omission_escalation/infrastructure/remote/push_device_dto.dart` | Token/plataforma/recibo, diagnóstico redactado |
| `lib/features/omission_escalation/infrastructure/messaging/firebase_messaging_adapter.dart` | FCM foreground/background/refresh |
| `lib/features/omission_escalation/infrastructure/local/push_installation_store.dart` | ID estable y cleanup pendiente |
| `lib/features/omission_escalation/infrastructure/platform/local_notification_presenter.dart` | Canales/permisos y presentación nativa |
| `lib/features/omission_escalation/infrastructure/navigation/notification_intent_mapper.dart` | Payload a destino con alcance revalidado |

### Presentación: cada archivo de flujo

Sin Bloc que controle otro Bloc, sin ViewModel duplicando Bloc. Widget local conserva foco/controller/animación. Los efectos de navegación usan listener; builder no escribe al servidor. Omission no inventa pantallas propias.

| Archivo completo | Responsabilidad |
| --- | --- |
| `lib/features/identity_subscription/presentation/bloc/onboarding/onboarding_bloc.dart` | Orquestar acciones/carga y descartar respuestas obsoletas: onboarding. |
| `lib/features/identity_subscription/presentation/bloc/onboarding/onboarding_event.dart` | Intenciones y entradas explícitas del flujo: onboarding. |
| `lib/features/identity_subscription/presentation/bloc/onboarding/onboarding_state.dart` | Estado inmutable de datos/carga/error/submitting sin secretos: onboarding. |
| `lib/features/identity_subscription/presentation/screens/role_selection_screen.dart` | Controles Flutter y variantes equivalentes de role_selection, con estados y opciones reales. |
| `lib/features/identity_subscription/presentation/screens/onboarding_screen.dart` | Controles Flutter y variantes equivalentes de onboarding, con estados y opciones reales. |
| `lib/features/identity_subscription/presentation/bloc/access/access_bloc.dart` | Orquestar acciones/carga y descartar respuestas obsoletas: access. |
| `lib/features/identity_subscription/presentation/bloc/access/access_event.dart` | Intenciones y entradas explícitas del flujo: access. |
| `lib/features/identity_subscription/presentation/bloc/access/access_state.dart` | Estado inmutable de datos/carga/error/submitting sin secretos: access. |
| `lib/features/identity_subscription/presentation/screens/login_screen.dart` | Controles Flutter y variantes equivalentes de login, con estados y opciones reales. |
| `lib/features/identity_subscription/presentation/screens/adult_pin_screen.dart` | Controles Flutter y variantes equivalentes de adult_pin, con estados y opciones reales. |
| `lib/features/identity_subscription/presentation/bloc/registration/registration_bloc.dart` | Orquestar acciones/carga y descartar respuestas obsoletas: registration. |
| `lib/features/identity_subscription/presentation/bloc/registration/registration_event.dart` | Intenciones y entradas explícitas del flujo: registration. |
| `lib/features/identity_subscription/presentation/bloc/registration/registration_state.dart` | Estado inmutable de datos/carga/error/submitting sin secretos: registration. |
| `lib/features/identity_subscription/presentation/screens/registration_screen.dart` | Controles Flutter y variantes equivalentes de registration, con estados y opciones reales. |
| `lib/features/identity_subscription/presentation/screens/email_verification_screen.dart` | Controles Flutter y variantes equivalentes de email_verification, con estados y opciones reales. |
| `lib/features/identity_subscription/presentation/bloc/recovery/recovery_bloc.dart` | Orquestar acciones/carga y descartar respuestas obsoletas: recovery. |
| `lib/features/identity_subscription/presentation/bloc/recovery/recovery_event.dart` | Intenciones y entradas explícitas del flujo: recovery. |
| `lib/features/identity_subscription/presentation/bloc/recovery/recovery_state.dart` | Estado inmutable de datos/carga/error/submitting sin secretos: recovery. |
| `lib/features/identity_subscription/presentation/screens/password_recovery_screen.dart` | Controles Flutter y variantes equivalentes de password_recovery, con estados y opciones reales. |
| `lib/features/identity_subscription/presentation/bloc/subscription/subscription_bloc.dart` | Orquestar acciones/carga y descartar respuestas obsoletas: subscription. |
| `lib/features/identity_subscription/presentation/bloc/subscription/subscription_event.dart` | Intenciones y entradas explícitas del flujo: subscription. |
| `lib/features/identity_subscription/presentation/bloc/subscription/subscription_state.dart` | Estado inmutable de datos/carga/error/submitting sin secretos: subscription. |
| `lib/features/identity_subscription/presentation/screens/plans_screen.dart` | Controles Flutter y variantes equivalentes de plans, con estados y opciones reales. |
| `lib/features/identity_subscription/presentation/screens/subscription_screen.dart` | Controles Flutter y variantes equivalentes de subscription, con estados y opciones reales. |
| `lib/features/identity_subscription/presentation/bloc/social_link/social_link_bloc.dart` | Orquestar acciones/carga y descartar respuestas obsoletas: social_link. |
| `lib/features/identity_subscription/presentation/bloc/social_link/social_link_event.dart` | Intenciones y entradas explícitas del flujo: social_link. |
| `lib/features/identity_subscription/presentation/bloc/social_link/social_link_state.dart` | Estado inmutable de datos/carga/error/submitting sin secretos: social_link. |
| `lib/features/identity_subscription/presentation/screens/social_link_screen.dart` | Controles Flutter y variantes equivalentes de social_link, con estados y opciones reales. |
| `lib/features/care_link/presentation/bloc/profiles/profiles_bloc.dart` | Orquestar acciones/carga y descartar respuestas obsoletas: profiles. |
| `lib/features/care_link/presentation/bloc/profiles/profiles_event.dart` | Intenciones y entradas explícitas del flujo: profiles. |
| `lib/features/care_link/presentation/bloc/profiles/profiles_state.dart` | Estado inmutable de datos/carga/error/submitting sin secretos: profiles. |
| `lib/features/care_link/presentation/screens/caregiver_profiles_screen.dart` | Controles Flutter y variantes equivalentes de caregiver_profiles, con estados y opciones reales. |
| `lib/features/care_link/presentation/screens/older_adult_registration_screen.dart` | Controles Flutter y variantes equivalentes de older_adult_registration, con estados y opciones reales. |
| `lib/features/care_link/presentation/bloc/link/link_bloc.dart` | Orquestar acciones/carga y descartar respuestas obsoletas: link. |
| `lib/features/care_link/presentation/bloc/link/link_event.dart` | Intenciones y entradas explícitas del flujo: link. |
| `lib/features/care_link/presentation/bloc/link/link_state.dart` | Estado inmutable de datos/carga/error/submitting sin secretos: link. |
| `lib/features/care_link/presentation/screens/link_person_screen.dart` | Controles Flutter y variantes equivalentes de link_person, con estados y opciones reales. |
| `lib/features/care_link/presentation/bloc/consent/consent_bloc.dart` | Orquestar acciones/carga y descartar respuestas obsoletas: consent. |
| `lib/features/care_link/presentation/bloc/consent/consent_event.dart` | Intenciones y entradas explícitas del flujo: consent. |
| `lib/features/care_link/presentation/bloc/consent/consent_state.dart` | Estado inmutable de datos/carga/error/submitting sin secretos: consent. |
| `lib/features/care_link/presentation/screens/consent_screen.dart` | Controles Flutter y variantes equivalentes de consent, con estados y opciones reales. |
| `lib/features/care_link/presentation/screens/consent_withdrawal_screen.dart` | Controles Flutter y variantes equivalentes de consent_withdrawal, con estados y opciones reales. |
| `lib/features/care_link/presentation/bloc/profile/profile_bloc.dart` | Orquestar acciones/carga y descartar respuestas obsoletas: profile. |
| `lib/features/care_link/presentation/bloc/profile/profile_event.dart` | Intenciones y entradas explícitas del flujo: profile. |
| `lib/features/care_link/presentation/bloc/profile/profile_state.dart` | Estado inmutable de datos/carga/error/submitting sin secretos: profile. |
| `lib/features/care_link/presentation/screens/linked_person_profile_screen.dart` | Controles Flutter y variantes equivalentes de linked_person_profile, con estados y opciones reales. |
| `lib/features/care_link/presentation/screens/emergency_contact_screen.dart` | Controles Flutter y variantes equivalentes de emergency_contact, con estados y opciones reales. |
| `lib/features/treatment_management/presentation/bloc/wizard/wizard_bloc.dart` | Orquestar acciones/carga y descartar respuestas obsoletas: wizard. |
| `lib/features/treatment_management/presentation/bloc/wizard/wizard_event.dart` | Intenciones y entradas explícitas del flujo: wizard. |
| `lib/features/treatment_management/presentation/bloc/wizard/wizard_state.dart` | Estado inmutable de datos/carga/error/submitting sin secretos: wizard. |
| `lib/features/treatment_management/presentation/screens/medication_details_screen.dart` | Controles Flutter y variantes equivalentes de medication_details, con estados y opciones reales. |
| `lib/features/treatment_management/presentation/screens/regimen_schedule_screen.dart` | Controles Flutter y variantes equivalentes de regimen_schedule, con estados y opciones reales. |
| `lib/features/treatment_management/presentation/screens/reminder_settings_screen.dart` | Controles Flutter y variantes equivalentes de reminder_settings, con estados y opciones reales. |
| `lib/features/treatment_management/presentation/screens/treatment_review_screen.dart` | Controles Flutter y variantes equivalentes de treatment_review, con estados y opciones reales. |
| `lib/features/treatment_management/presentation/bloc/management/management_bloc.dart` | Orquestar acciones/carga y descartar respuestas obsoletas: management. |
| `lib/features/treatment_management/presentation/bloc/management/management_event.dart` | Intenciones y entradas explícitas del flujo: management. |
| `lib/features/treatment_management/presentation/bloc/management/management_state.dart` | Estado inmutable de datos/carga/error/submitting sin secretos: management. |
| `lib/features/treatment_management/presentation/screens/treatment_management_screen.dart` | Controles Flutter y variantes equivalentes de treatment_management, con estados y opciones reales. |
| `lib/features/treatment_management/presentation/screens/treatment_detail_screen.dart` | Controles Flutter y variantes equivalentes de treatment_detail, con estados y opciones reales. |
| `lib/features/treatment_management/presentation/bloc/catalog/catalog_bloc.dart` | Orquestar acciones/carga y descartar respuestas obsoletas: catalog. |
| `lib/features/treatment_management/presentation/bloc/catalog/catalog_event.dart` | Intenciones y entradas explícitas del flujo: catalog. |
| `lib/features/treatment_management/presentation/bloc/catalog/catalog_state.dart` | Estado inmutable de datos/carga/error/submitting sin secretos: catalog. |
| `lib/features/treatment_management/presentation/screens/medication_catalog_screen.dart` | Controles Flutter y variantes equivalentes de medication_catalog, con estados y opciones reales. |
| `lib/features/intake_execution/presentation/bloc/home/home_bloc.dart` | Orquestar acciones/carga y descartar respuestas obsoletas: home. |
| `lib/features/intake_execution/presentation/bloc/home/home_event.dart` | Intenciones y entradas explícitas del flujo: home. |
| `lib/features/intake_execution/presentation/bloc/home/home_state.dart` | Estado inmutable de datos/carga/error/submitting sin secretos: home. |
| `lib/features/intake_execution/presentation/screens/next_dose_screen.dart` | Controles Flutter y variantes equivalentes de next_dose, con estados y opciones reales. |
| `lib/features/intake_execution/presentation/bloc/agenda/agenda_bloc.dart` | Orquestar acciones/carga y descartar respuestas obsoletas: agenda. |
| `lib/features/intake_execution/presentation/bloc/agenda/agenda_event.dart` | Intenciones y entradas explícitas del flujo: agenda. |
| `lib/features/intake_execution/presentation/bloc/agenda/agenda_state.dart` | Estado inmutable de datos/carga/error/submitting sin secretos: agenda. |
| `lib/features/intake_execution/presentation/screens/agenda_screen.dart` | Controles Flutter y variantes equivalentes de agenda, con estados y opciones reales. |
| `lib/features/intake_execution/presentation/bloc/dose/dose_bloc.dart` | Orquestar acciones/carga y descartar respuestas obsoletas: dose. |
| `lib/features/intake_execution/presentation/bloc/dose/dose_event.dart` | Intenciones y entradas explícitas del flujo: dose. |
| `lib/features/intake_execution/presentation/bloc/dose/dose_state.dart` | Estado inmutable de datos/carga/error/submitting sin secretos: dose. |
| `lib/features/intake_execution/presentation/screens/dose_detail_screen.dart` | Controles Flutter y variantes equivalentes de dose_detail, con estados y opciones reales. |
| `lib/features/intake_execution/presentation/screens/confirmation_result_screen.dart` | Controles Flutter y variantes equivalentes de confirmation_result, con estados y opciones reales. |
| `lib/features/intake_execution/presentation/bloc/voice/voice_bloc.dart` | Orquestar acciones/carga y descartar respuestas obsoletas: voice. |
| `lib/features/intake_execution/presentation/bloc/voice/voice_event.dart` | Intenciones y entradas explícitas del flujo: voice. |
| `lib/features/intake_execution/presentation/bloc/voice/voice_state.dart` | Estado inmutable de datos/carga/error/submitting sin secretos: voice. |
| `lib/features/intake_execution/presentation/screens/voice_confirmation_screen.dart` | Controles Flutter y variantes equivalentes de voice_confirmation, con estados y opciones reales. |
| `lib/features/inventory_replenishment/presentation/bloc/inventory/inventory_bloc.dart` | Orquestar acciones/carga y descartar respuestas obsoletas: inventory. |
| `lib/features/inventory_replenishment/presentation/bloc/inventory/inventory_event.dart` | Intenciones y entradas explícitas del flujo: inventory. |
| `lib/features/inventory_replenishment/presentation/bloc/inventory/inventory_state.dart` | Estado inmutable de datos/carga/error/submitting sin secretos: inventory. |
| `lib/features/inventory_replenishment/presentation/screens/inventory_screen.dart` | Controles Flutter y variantes equivalentes de inventory, con estados y opciones reales. |
| `lib/features/inventory_replenishment/presentation/screens/initial_stock_screen.dart` | Controles Flutter y variantes equivalentes de initial_stock, con estados y opciones reales. |
| `lib/features/inventory_replenishment/presentation/screens/replenishment_screen.dart` | Controles Flutter y variantes equivalentes de replenishment, con estados y opciones reales. |
| `lib/features/family_monitoring/presentation/bloc/family/family_bloc.dart` | Orquestar acciones/carga y descartar respuestas obsoletas: family. |
| `lib/features/family_monitoring/presentation/bloc/family/family_event.dart` | Intenciones y entradas explícitas del flujo: family. |
| `lib/features/family_monitoring/presentation/bloc/family/family_state.dart` | Estado inmutable de datos/carga/error/submitting sin secretos: family. |
| `lib/features/family_monitoring/presentation/screens/family_home_screen.dart` | Controles Flutter y variantes equivalentes de family_home, con estados y opciones reales. |
| `lib/features/family_monitoring/presentation/bloc/alerts/alerts_bloc.dart` | Orquestar acciones/carga y descartar respuestas obsoletas: alerts. |
| `lib/features/family_monitoring/presentation/bloc/alerts/alerts_event.dart` | Intenciones y entradas explícitas del flujo: alerts. |
| `lib/features/family_monitoring/presentation/bloc/alerts/alerts_state.dart` | Estado inmutable de datos/carga/error/submitting sin secretos: alerts. |
| `lib/features/family_monitoring/presentation/screens/alerts_screen.dart` | Controles Flutter y variantes equivalentes de alerts, con estados y opciones reales. |
| `lib/features/family_monitoring/presentation/screens/alert_detail_screen.dart` | Controles Flutter y variantes equivalentes de alert_detail, con estados y opciones reales. |
| `lib/features/family_monitoring/presentation/bloc/notes/notes_bloc.dart` | Orquestar acciones/carga y descartar respuestas obsoletas: notes. |
| `lib/features/family_monitoring/presentation/bloc/notes/notes_event.dart` | Intenciones y entradas explícitas del flujo: notes. |
| `lib/features/family_monitoring/presentation/bloc/notes/notes_state.dart` | Estado inmutable de datos/carga/error/submitting sin secretos: notes. |
| `lib/features/family_monitoring/presentation/screens/care_notes_screen.dart` | Controles Flutter y variantes equivalentes de care_notes, con estados y opciones reales. |
| `lib/features/family_monitoring/presentation/screens/personal_notes_screen.dart` | Controles Flutter y variantes equivalentes de personal_notes, con estados y opciones reales. |
| `lib/features/adherence_analytics/presentation/bloc/adherence/adherence_bloc.dart` | Orquestar acciones/carga y descartar respuestas obsoletas: adherence. |
| `lib/features/adherence_analytics/presentation/bloc/adherence/adherence_event.dart` | Intenciones y entradas explícitas del flujo: adherence. |
| `lib/features/adherence_analytics/presentation/bloc/adherence/adherence_state.dart` | Estado inmutable de datos/carga/error/submitting sin secretos: adherence. |
| `lib/features/adherence_analytics/presentation/screens/adherence_history_screen.dart` | Controles Flutter y variantes equivalentes de adherence_history, con estados y opciones reales. |
| `lib/features/adherence_analytics/presentation/screens/adherence_summary_screen.dart` | Controles Flutter y variantes equivalentes de adherence_summary, con estados y opciones reales. |
| `lib/features/adherence_analytics/presentation/screens/adherence_trend_screen.dart` | Controles Flutter y variantes equivalentes de adherence_trend, con estados y opciones reales. |
| `lib/features/adherence_analytics/presentation/screens/adherence_recommendations_screen.dart` | Controles Flutter y variantes equivalentes de adherence_recommendations, con estados y opciones reales. |
| `lib/features/accessibility_preferences/presentation/bloc/accessibility/accessibility_bloc.dart` | Orquestar acciones/carga y descartar respuestas obsoletas: accessibility. |
| `lib/features/accessibility_preferences/presentation/bloc/accessibility/accessibility_event.dart` | Intenciones y entradas explícitas del flujo: accessibility. |
| `lib/features/accessibility_preferences/presentation/bloc/accessibility/accessibility_state.dart` | Estado inmutable de datos/carga/error/submitting sin secretos: accessibility. |
| `lib/features/accessibility_preferences/presentation/screens/accessibility_screen.dart` | Controles Flutter y variantes equivalentes de accessibility, con estados y opciones reales. |
| `lib/features/accessibility_preferences/presentation/bloc/notifications/notifications_bloc.dart` | Orquestar acciones/carga y descartar respuestas obsoletas: notifications. |
| `lib/features/accessibility_preferences/presentation/bloc/notifications/notifications_event.dart` | Intenciones y entradas explícitas del flujo: notifications. |
| `lib/features/accessibility_preferences/presentation/bloc/notifications/notifications_state.dart` | Estado inmutable de datos/carga/error/submitting sin secretos: notifications. |
| `lib/features/accessibility_preferences/presentation/screens/notification_preferences_screen.dart` | Controles Flutter y variantes equivalentes de notification_preferences, con estados y opciones reales. |
| `lib/features/accessibility_preferences/presentation/bloc/language/language_bloc.dart` | Orquestar acciones/carga y descartar respuestas obsoletas: language. |
| `lib/features/accessibility_preferences/presentation/bloc/language/language_event.dart` | Intenciones y entradas explícitas del flujo: language. |
| `lib/features/accessibility_preferences/presentation/bloc/language/language_state.dart` | Estado inmutable de datos/carga/error/submitting sin secretos: language. |
| `lib/features/accessibility_preferences/presentation/screens/language_selection_screen.dart` | Controles Flutter y variantes equivalentes de language_selection, con estados y opciones reales. |

El inventario base enumera 320 destinos individuales de producción; la revisión siguiente añade 28 destinos explícitos. No es un mínimo de cantidad ni porcentaje de implementación. Cada destino se confirma al refinar US; si no tiene consumidor se elimina del inventario, no se materializa como placeholder. Componentes visuales específicos se extraen al validar el flujo, con nombre/consumidor registrados aquí.


## Revisión del inventario previsto por BC

La comparación se realiza contra las capacidades del cliente nativo, no contra el código Flutter ya implementado. Las cuatro capas expresan responsabilidades; no fijan una cantidad de archivos. Flutter no obliga a agrupar más que Kotlin. La diferencia admisible procede de decisiones explícitas: un caso de uso sustituye la pareja comando/handler cuando no hay despacho independiente, y las variantes de una misma pantalla comparten widgets y estado. Esto no permite omitir operaciones, contratos o adaptadores.

El inventario anterior necesita las siguientes precisiones. Estas filas forman parte del destino planificado y complementan las tablas por contexto. No autorizan crear clases vacías. Los nombres del inventario se reconcilian con los archivos existentes antes de implementar para evitar duplicar, por ejemplo, account_session/session o registration/caregiver_registration.

| Archivo completo | Responsabilidad y relaciones |
| --- | --- |
| `lib/features/identity_subscription/application/ports/onboarding_store.dart` | Leer y registrar la introducción completada por instalación; no equivale a autenticar. Consumido por el arranque/onboarding. |
| `lib/features/identity_subscription/application/usecases/complete_onboarding.dart` | Confirmar la finalización explícita y persistirla mediante onboarding_store. |
| `lib/features/identity_subscription/infrastructure/local/local_onboarding_store.dart` | Adaptador local para la marca de introducción, sin guardar credenciales. |
| `lib/features/identity_subscription/application/ports/remembered_adult_store.dart` | Recordar únicamente identificación mínima del acceso adulto; nunca PIN, bearer o autorización clínica. |
| `lib/features/identity_subscription/application/readmodels/remembered_adult.dart` | Nombre y referencia necesarios para el selector adulto; sujeto a nueva autenticación y consentimiento vigente. |
| `lib/features/identity_subscription/infrastructure/local/local_remembered_adult_store.dart` | Persistir y retirar esa referencia; no restaurar una sesión a partir de ella. |
| `lib/features/care_link/application/ports/care_link_consent.dart` | Aceptación, consulta y decisión del adulto con sesión restringida; separar de las operaciones del cuidador en care_link_writer. |
| `lib/features/care_link/application/ports/pending_link_store.dart` | Guardar y recuperar el alta en curso por cuidador y perfil; no guardar códigos expirados como vigentes. |
| `lib/features/care_link/infrastructure/local/local_pending_link_store.dart` | Persistencia mínima del alta incompleta; limpiar al completar, retirar o cambiar propietario. |
| `lib/features/care_link/application/usecases/update_linked_person_profile.dart` | Validar edición de datos básicos y comprobar recibo del perfil solicitado; independiente del contacto de emergencia. |
| `lib/features/care_link/infrastructure/repositories/remote_care_link_consent.dart` | Implementar care_link_consent, conservar el alcance LINK_SETUP y validar la transición a sesión adulta. |
| `lib/features/care_link/infrastructure/repositories/remote_linked_person_profile.dart` | Implementar lectura/edición de perfil y contacto; compartir transporte, no mezclar estados con el alta. |
| `lib/features/family_monitoring/application/ports/intake_history_reader.dart` | Historial por adulto, período y filtros; no confundirlo con porcentajes agregados de Analytics. |
| `lib/features/family_monitoring/application/readmodels/intake_history_entry.dart` | Toma, instante y resultado conocidos para el historial, sin inferir confirmaciones. |
| `lib/features/family_monitoring/application/usecases/get_intake_history.dart` | Validar selección/período y consultar intake_history_reader; descartar cambios de propietario. |
| `lib/features/family_monitoring/application/ports/contact_launcher.dart` | Abrir correo o teléfono permitido; abrir una aplicación no demuestra contacto realizado. |
| `lib/features/family_monitoring/application/usecases/contact_linked_person.dart` | Resolver contacto autorizado y solicitar apertura; resultado cancelado/no disponible explícito. |
| `lib/features/family_monitoring/infrastructure/platform/platform_contact_launcher.dart` | Adaptar URI y disponibilidad de la plataforma; sin datos de contacto hardcodeados en pantallas. |
| `lib/features/family_monitoring/application/usecases/get_care_notes.dart` | Consultar notas del vínculo activo mediante notes_repository con autoría y permisos. |
| `lib/features/family_monitoring/application/usecases/get_personal_notes.dart` | Consultar notas personales del actor sin sustituirlas por notas del cuidador. |
| `lib/features/family_monitoring/application/usecases/create_personal_note.dart` | Crear nota personal con validación del texto y categoría; save_care_note conserva el flujo de seguimiento del cuidador. |
| `lib/features/family_monitoring/infrastructure/repositories/remote_alert_actions.dart` | Implementar alert_actions; validar identidad y recibos de estado/seguimiento. remote_monitoring_repository conserva consultas. |
| `lib/features/accessibility_preferences/application/ports/preferences_local_store.dart` | Leer/observar preferencias y cambios pendientes por propietario, sin dependencia de Drift en application. |
| `lib/features/accessibility_preferences/application/ports/preferences_remote.dart` | Leer/escribir ajustes remotos con revisión; offline_preferences_repository coordina este puerto y el local. |
| `lib/features/accessibility_preferences/application/usecases/sync_preferences.dart` | Reconciliar campos pendientes preservando ajustes no editados; detener ante cambio de sesión o revocación. |
| `lib/features/accessibility_preferences/infrastructure/local/preferences_database.dart` | Esquema Drift de preferencias, versión y cierre; no compartir una base clínica mediante imports internos de Intake. |
| `lib/features/accessibility_preferences/infrastructure/local/tables/stored_preferences.dart` | Valores, propietario y campos pendientes; preferences_local_store.dart implementa el puerto homónimo. |
| `lib/features/accessibility_preferences/infrastructure/local/migrations/preferences_migrations.dart` | Migración no destructiva y conservación de cambios pendientes. |

### Relaciones y aceptación de las precisiones

- Identity: onboarding local no concede acceso. El perfil recordado solo facilita el formulario; PIN y sesión siguen sus contratos remotos. Aceptar reinicio, cambio de adulto y eliminación de referencia sin revelar secretos.
- Care Link: profiles/link coordinan alta del cuidador; consent coordina decisiones del adulto. El borrador recuperado vuelve a consultar su estado remoto antes de ofrecer código o consentimiento. Probar reinicio entre alta y código, expiración, rechazo y cuenta distinta.
- Monitoring: family/alerts/notes consumen casos de uso distintos según intención. Historial pertenece a Monitoring; agregados y tendencias a Analytics. Contactar no cierra alertas. Probar permisos, período, autoría de notas y ausencia de aplicación externa.
- Preferences: presentación envía cambios de campos; el repositorio combina fuentes mediante puertos. El sincronizador no sobrescribe ajustes ajenos con defaults. Probar offline, reinicio, edición concurrente y cambio de propietario.
- Los puertos de lectura de planes, perfiles, detalle de tratamiento, alertas y recomendaciones ya enumerados deben tener implementación asignada en los repositorios indicados; no quedar como interfaces sin consumidor. Las lecturas simples pueden consumirse desde el BLoC; validación de períodos, coordinación y reglas reutilizadas pasan por caso de uso.
- Las tablas de presentación enumeran controladores y pantallas, pero no todos sus widgets locales ni rutas. Cada corte registra el destino concreto de ambos al refinarse. Se extraen controles con responsabilidad reutilizable o interacción propia, no un archivo por Text/Row ni una pantalla por cada variante Figma.
- Analytics y Omission conservan puertos y proyecciones de aplicación; no se añade domain vacío para aparentar cuatro carpetas. Las reglas clínicas y la creación de omisiones pertenecen al servidor.

Para aceptar cualquier BC se enlaza cada capacidad del backlog con entrada UI o evento de plataforma, operación de aplicación, contrato, adaptador y evidencia. Una operación ausente en esta cadena es un hueco del plan aunque el número de archivos sea elevado. El conteo sirve para inspección, no como criterio de calidad ni porcentaje funcional.

## Incubación local y separación posterior por backlog

temp parte de 269f50c y no tiene upstream. No se ejecutan push --all/push --mirror ni se incluye temp en releases. El scaffold/README públicos quedan en main/develop; las implementaciones futuras de esta fase solo se guardan localmente. Cada incremento registra archivos y gate aquí, en un diff o commit local acotado. Al definir US, crear feature/us-XX desde develop y trasladar cambios de la unidad mediante cherry-pick o parche revisado. Integrar dependencias técnicas antes de consumidores y nunca separar artificialmente un mismo Bloc entre tres ramas.

La secuencia inicial de configuración, resultado, red, sesión e Identity ya tiene implementación y pruebas. Cada recorrido siguiente incorpora comportamiento y comparación visual en el mismo corte. Antes de diseñar Screens se consulta Figma MCP con la habilidad obligatoria. No se modifica backend/Android/report sin una necesidad explícita.

## Base pública verificada y contraste normativo

ed44709: scaffold con analyze/widget/APK local y CI main 40478631269 SUCCESS (Android y simulador iOS). README corregido después en 269f50c, mismo estilo del resto y UTF-8 verificado, sin mojibake. main/develop contienen 269f50c y temp lo incorpora localmente. Un build de simulador no acredita la demostración física exigida por V4.0.

El enunciado actual se extrajo íntegro en current-project-statement-202620.txt. Revisadas las secciones de alcance, tecnología, i18n/accesibilidad, SCM, AV2/TB2 y el feature autónomo. Las instrucciones/prompts del anexo de ejemplo no autorizan escribir pagos o añadir funcionalidades ajenas a Tata. Los PDF y el plan se mantienen fuera de GitHub.


## Pruebas y artefactos necesarios: rutas individuales

| Archivo | Conducta/gate |
| --- | --- |
| test/app/config/app_config_test.dart | URL/HTTPS, entorno local explícito y rechazo de credenciales en URL |
| test/shared/infrastructure/network/api_client_test.dart | Timeout, JSON, headers capturados, redirects y límite de cuerpo |
| test/shared/infrastructure/security/secure_session_store_test.dart | Persistencia, expiración, escritura serializada y compare-and-replace |
| test/identity_subscription/session_repository_test.dart | Login/current/logout, errores y respuesta de sesión obsoleta |
| test/identity_subscription/sign_in_test.dart | Validaciones, normalización y contraseña sin recorte |
| test/identity_subscription/access_bloc_test.dart | Loading/error/auth, doble envío y logout que invalida resultados tardíos |
| test/identity_subscription/registration_bloc_test.dart | Verificación antes de sesión y reenvío |
| test/identity_subscription/recovery_bloc_test.dart | Solicitud uniforme, rechazo, recibo y borrado de secretos |
| test/identity_subscription/subscription_bloc_test.dart | Catálogo, selección, cambio con recibo y conflicto |
| test/identity_subscription/social_identity_test.dart | Cancelación, proveedor no disponible, vínculo autorizado y no emailautolink |
| test/care_link/link_and_consent_test.dart | Aceptar/rechazar/retirar sin acceso prematuro |
| test/care_link/profile_contact_test.dart | Contacto persistido, cancelar sin writes y datos básicos conservados |
| test/care_link/authorization_test.dart | Actor equivocado/revoke durante carga |
| test/treatment_management/regimen_test.dart | Horas distintas/ordenadas y null frente a 0 en seguimiento |
| test/treatment_management/wizard_bloc_test.dart | Borrador al volver y aislamiento de tratamiento/owner |
| test/treatment_management/management_bloc_test.dart | Pausa/resume/reactivación y ocultación de datos revocados |
| test/intake_execution/intake_mapper_test.dart | Fechas/status/canal y recibo del mismo intake |
| test/intake_execution/offline_replay_test.dart | Idempotencia, cambio de actor y errores transitorios/permanentes |
| test/intake_execution/intake_database_migration_test.dart | Cache/cola preservados al migrar y separación por owner |
| test/intake_execution/next_dose_bloc_test.dart | Con datos a vacío real; error de red no se convierte en empty |
| test/intake_execution/voice_confirmation_test.dart | Permisos/grabación/cancelación/multipart |
| test/inventory_replenishment/inventory_mapper_test.dart | Null distinto de0/false, lotes repetidos y coverage |
| test/inventory_replenishment/inventory_bloc_test.dart | Alta/reposición/cancelación y errores 409 |
| test/family_monitoring/alerts_bloc_test.dart | Filtros/acciones/revoke y limpieza de datos |
| test/family_monitoring/notes_bloc_test.dart | Edición/empty/aislamiento y error conservando borrador |
| test/adherence_analytics/adherence_mapper_test.dart | Período/zona/rangos y tratamiento seleccionado |
| test/adherence_analytics/adherence_bloc_test.dart | Datos/empty/error y respuesta antigua descartada |
| test/accessibility_preferences/preferences_sync_test.dart | Persistencia y sync por owner, campos no editados preservados |
| test/accessibility_preferences/accessibility_widgets_test.dart | Texto/contraste/semántica y alcance de controles |
| test/omission_escalation/push_session_test.dart | Registro/retirada/tokenrefresh sin fuga de destinatario |
| test/omission_escalation/notification_intent_test.dart | Payload inválido/ajeno no navega |
| test/app/navigation/app_router_test.dart | Roles/restore/deeplink y retiro de backstack al salir |
| test/app/integration/session_cleanup_test.dart | Ownerchange limpia datos y no reproduce cola ajena |
| integration_test/access_recovery_test.dart | UIFlutter-HTTP-Spring: login/recovery/revocar/replay |
| integration_test/care_link_consent_test.dart | Vínculo/consentimiento con sesiones adult/cuidador |
| integration_test/clinical_journey_test.dart | Medicamento/pauta/agenda/confirmación repetida/stock 14 |
| integration_test/monitoring_notes_test.dart | Perfil/alertas/seguimiento/notas/timeline reales |
| integration_test/preferences_analytics_test.dart | Persistencia por owner/adherencia y acceso ajeno |
| integration_test/offline_owner_switch_test.dart | Caída de red/reinicio/replay/cambio de actor |
| integration_test/physical_device_smoke_test.dart | Core instalado y recurso físico exigido por V4.0 |

Configuración futura también se incorpora con consumidor: l10n.yaml (generación ARB), assets/fonts y assets/icons (inventario de recursos licenciados), permisos de AndroidManifest.xml, usage descriptions de ios/Runner/Info.plist y entitlements iOS requeridos por cada SDK. No se generan firebase_options.dart ni configuraciones de proveedores sin proyecto de plataforma real; nunca se copian secretos de Kotlin.

## Matriz de endpoints por primer recorrido

| Flujo | Contrato servidor comprobado por fuente actual | Gate |
| --- | --- | --- |
| Acceso | POST /api/v1/sessions, GET /api/v1/sessions/current, DELETE /api/v1/sessions | 200 y actor/expiry, current valida owner/rol; logout204/401 |
| Alta/verificación | POST /api/v1/accounts, /api/v1/accounts/verification, /api/v1/email-verification-requests | Cuenta pendiente/activa y código; no sesión inventada |
| Recovery | POST /api/v1/password-recovery-requests y /api/v1/password-recoveries |202 uniforme,204 sin auth, código de un uso y sesiones revocadas |
| Social | POST /api/v1/social-sessions y PUT /api/v1/me/social-identities | JWT Firebase verificado y sesión Tata, vínculo explícito |
| Planes | GET /api/v1/plans, GET/PUT /api/v1/accounts/{accountId}/subscription | Catálogo y plan efectivo por owner, sin cobro ficticio |
| Perfiles/vínculo | GET /api/v1/care-links, POST /api/v1/older-adults, /api/v1/care-links/linking-codes, /api/v1/care-links/acceptances | Adulto autorizado y código/consentimiento |
| Consentimiento | POST /api/v1/care-links/{careLinkId}/consent y operación de retirada según contrato de backend | Revoke invalida sesión/adulto y cuidador pierde acceso |
| Treatment | /api/v1/older-adults/{id}/medications y /treatments, /api/v1/treatments/{id}/regimen y activation/pause/resume | Recibo pauta/estado y agenda real |
| Intake | /api/v1/older-adults/{id}/intakes/agenda y next; /api/v1/intakes/{id}/confirmation | Intervalo UTC, confirmación idempotente |
| Inventory | /api/v1/inventories y /api/v1/inventories/{medicationId}/replenishments | Stock y lotes, code/message |
| Monitoring | /api/v1/older-adults/{id}/alerts/{alertId} y /status y /timeline | Estado y hechos reales, title/detail donde corresponde |
| Analytics | /api/v1/older-adults/{id}/adherence/summary, /adherence/treatments/{treatmentId}/summary y /adherence/insight | Zona/período/owner y vacío legítimo |
| Preferences | /api/v1/users/{id}/preferences y subrecursos; notification-preferences/policy | Owner/recibo y campos no editados |
| Push | PUT/DELETE /api/v1/push-devices/{installationId} | Propietario del bearer, cleanup/tokenrefresh |

Antes de implementar cada método se abre el controlador y resource vigentes para completar path exacto, payload y status; esta matriz no autoriza inventar endpoints. El primer corte de acceso ya contrasta SessionAccessResponse y CurrentSessionResponse del cliente Android y sus contratos Spring.


## Checkpoint compartido y backlog del sprint

La última suite completa registrada del corte de retirada tiene 69 pruebas aprobadas. Incluye confirmación/cancelación, error remoto y reintento de retirada desde Flutter. El análisis y pruebas actuales se ejecutan antes de publicar este checkpoint. El flujo clínico adulto y la persistencia del registro pendiente del cuidador siguen abiertos. El inventario Figma continúa en 1 completa aceptada, 3 parciales y 66 sin implementación específica, sobre 70 variantes; las extensiones de recuperación, invitación y retirada se registran aparte.

El enunciado 202620 V4.0 conserva Product Backlog en 2.4.3 y exige capítulo IV con Sprint 2 para AV2 y Sprint 3 para TB2. No exige duplicar todas las US por usar Flutter. Propuesta a confirmar con el profesor: mantener las US del producto y separar tareas, implementación y criterios por plataforma; crear nuevas historias cuando cambie la capacidad del producto. En el informe siguen implementación, pruebas, ejecución, documentación de servicios, despliegue y colaboración del nuevo sprint, además de versiones y Student Outcome.

La rama temp es ahora compartida y provisional. No reemplaza el backlog definitivo ni integra en main/develop. Tras acordar historias, inventariar responsabilidades y dependencias compartidas, establecer una base común y distribuir commits coherentes en feature/us-xx-descripcion. No basta renombrar temp: cherry-pick requiere commits cuyo alcance coincida con la US; los cambios mezclados deben dividirse y revisarse por diff. Conservar esta referencia hasta comprobar integración en develop.

La documentación de código usa Dartdoc en archivos propios; los generados no se editan. El flujo de dependencias es pantalla/evento -> BLoC -> caso de uso/puerto -> repositorio -> API/almacenamiento. AppDependencies compone adapters y cada ruta posee su BLoC. Identity y Care Link se conectan mediante callbacks de aplicación. Los tokens no se guardan en estados ni invitaciones; SessionOwner incluye rol, sujeto y careLinkId para separar acceso cuidador, adulto y LINK_SETUP. ApiClient codifica queryParameters y descarta redirecciones. Los recibos se validan antes de cambiar sesión; expectedGeneration impide aplicar respuestas de otro actor.

Próximos cierres: persistencia del setup cuidador sin repetir registros remotos; PIN resolviendo careLinkId mediante current; inicio clínico/agenda/tomas; tratamiento e inventario; seguimiento/alertas/analítica/preferencias; persistencia Drift por propietario; proveedores externos y dispositivo físico. Cada recorrido debe actualizar funcionalidad y fidelidad con evidencia Flutter propia, sin heredar aprobaciones Android.


### Contratos y capacidades implementadas del checkpoint

- Acceso: SignIn, RestoreSession y SignOut usan repositorio HTTP y SessionStore seguro; comparan el actor remoto y rechazan respuestas obsoletas mediante generación. El almacenamiento conserva un único registro coherente, no campos de identidad separados.
- Alta: RegisterCaregiver devuelve cuenta pendiente; VerifyEmail solo persiste sesión tras validar cuenta, correo, código y vencimiento. El reenvío mantiene la cuenta actual y limpia el código solo después del recibo correcto.
- Recovery: solicitud202 uniforme, cambio204 sin auto-login. El BLoC conserva el paso y los campos cuando falla un reenvío; las credenciales no entran al estado persistente de presentación.
- Caregiver setup: RegisterOlderAdult valida nombre y fecha calendario; GenerateLinkingCode conserva el actor cuidador. El listado representa vínculos consentidos, no todos los perfiles registrados. La pantalla utiliza nombre/fecha reales e iniciales cuando no hay imagen de perfil.
- Adulto: CareLinkInvitation transporta caregiverId/code en un sobre acotado tata-link:v1:, sin token. AcceptCareLink persiste solo LINK_SETUP. RegisterConsent concede acceso adulto únicamente con recibo confirmado; rechazo limpia acceso. SecureSessionStore restaura el consentimiento pendiente sin conceder acceso clínico.
- Retirada: WithdrawConsent y el BLoC requieren confirmación en ConsentManagementScreen.204 confirma revocación y limpia acceso;401 limpia credencial rechazada sin fingir éxito;503 conserva estado para retry. La respuesta tardía no borra la sesión de otro actor.
- La identidad local es (rol,sujeto,careLinkId). El cuidador no lleva careLinkId; adulto y setup lo requieren. Las tablas y colas futuras respetan esta partición. PIN deberá obtener el alcance de current antes de persistir la respuesta, que no incluye careLinkId.

Archivos concretos adicionales al manifiesto: application/readmodels/caregiver_link_summary.dart, application/ports/care_link_consent.dart, domain/value_objects/care_link_invitation.dart, infrastructure/repositories/remote_care_link_consent.dart, presentation/navigation/caregiver_setup_route.dart, consent_route.dart y consent_management_route.dart, presentation/screens/invitation_screen.dart, consent_screen.dart y consent_management_screen.dart, bajo lib/features/care_link/. El mapper real de estos recibos es infrastructure/mappers/care_link_mapper.dart. El formulario de alta permanece en caregiver_profiles_screen.dart hasta necesitar una ruta propia. Las extensiones implementan contratos reales, no pantallas ficticias para aumentar el conteo.

Los paths evidencia-local-no-publicada y material-del-curso identifican fuentes externas y no carpetas entregadas. Los fixtures privados no se incluyen. Las fuentes e iconos usados por producción sí están en assets con sus licencias. Se pueden reproducir capturas mediante los tests y TATA_CAPTURE_DIR; un render de widget no certifica instalación, cifrado nativo ni despliegue remoto.

Verificación del checkpoint compartido (02-11-2026): flutter pub get completado; flutter test con 69 casos aprobados; flutter analyze sin incidencias. Estas comprobaciones corresponden al código de esta rama y no equivalen a validación instalada o contra Render.


## Registro de continuidad

Actualizar esta sección al cerrar cada recorrido o checkpoint, junto con el estado de sus variantes. Antes de editar, sincronizar temp y revisar los cambios remotos. Anotar el commit base y los archivos en trabajo para evitar cambios simultáneos sobre el mismo alcance. Un archivo previsto en el manifiesto no se considera implementado por estar enumerado.

| Fecha | Alcance | Referencia | Verificación | Continuación |
| --- | --- | --- | --- | --- |
| 02-11-2026 | Identity y Care Link: onboarding, acceso, alta, recovery, vínculo y consentimiento con retirada | 58cb71b (código compartido); 4d5d7a9 (plan) | 69 tests aprobados; análisis limpio; evidencia Spring local de los cortes descritos | Persistencia del setup cuidador, PIN con alcance, inicio clínico y restantes contextos |
| 03-11-2026 | PIN (alta tras consentimiento y acceso con alcance de current), Home adulto (próxima toma y progreso diario) y olvido del atajo PIN al retirar consentimiento | Sobre ce70f0d; commit pendiente | 102 tests; análisis y formato limpios; build apk debug; tool/verify_local_pin_home.dart contra Spring local en Docker (seed demo); recorrido instalado en emulador Pixel_10 (API 37): invitación, consentimiento, alta de PIN, Home vacío y con toma real, refresco, cambio de cuenta, PIN incorrecto, PIN correcto, reinicio con sesión restaurada y retiro de consentimiento sin atajo; bloqueo 401x3/403 PIN_LOCKED comprobado en Spring; mismo recorrido instalado en teléfono físico POCO X6 Pro (Android 16) vía adb reverse, con conversión UTC a hora de Perú | Agenda, detalle y confirmación de tomas para activar atajos |
| 03-11-2026 | Agenda semanal, detalle de toma y confirmación táctil (US-24, US-21, US-06, resultado US-23) conectados desde Home | Sobre b2493b3; commit pendiente | 123 tests (botón Confirmar fijo abajo tras verlo cortado en el POCO); análisis y formato limpios; build apk debug; sonda Spring local: confirmación a tiempo, reintento idempotente, detalle y agenda; emulador Pixel_10: próxima toma, detalle, confirmar, resultado, Home 1/1 recargado, agenda con estado y detalle confirmado sin botón; mismo recorrido en teléfono físico POCO X6 Pro (Android 16) vía adb reverse, con día local correcto (03:11 UTC = martes 10:11 p. m.) y reingreso por PIN conservando 1/1 | Caso tardío y omisión en dispositivo; persistencia Drift de confirmaciones pendientes (TS-13) y voz (TS-11) |
| 11-11-2026 | TS-13: cache de tomas y cola offline de confirmaciones con Drift por adulto y vínculo, reenvío serializado, restauración de sesión del adulto sin red y borrado local al retirar consentimiento | Sobre 6d2d8ab; commit pendiente | 170 tests; análisis y formato limpios; build apk debug; Spring local y emulador Pixel_10 sin red: arranque en frío, confirmación guardada, cierre forzado, agenda "por enviar", reenvío automático con una sola confirmación en servidor y borrado de filas tras retirar consentimiento | Reenvío con la app cerrada (no implementado: solo primer plano); probar en teléfono físico y contra Render. La entrega offline informa confirmedAt con la hora del toque (contrato v1.1.0 del 11-11-2026); si el servidor rechaza esa hora, se reenvía con la hora de llegada. La confirmación en línea sigue sin enviarla |

### Plantilla de siguiente registro

Copiar este bloque para cada continuación y sustituir los campos con resultados comprobados:

- Fecha y responsable:
- Commit base y commit de entrega:
- Recorrido y variantes trabajadas:
- Archivos modificados y responsabilidad de cada cambio:
- Contratos, funciones o decisiones de arquitectura afectados:
- Funcionalidad comprobada (widget, adapter, Spring local, despliegue o dispositivo):
- Fidelidad visual (nodo Figma, captura, comparación y diferencias):
- Comandos de verificación y resultados:
- Cambios en conteos y denominadores:
- Riesgos, dependencias y siguiente paso concreto:

No registrar porcentajes estimados como validación. Separar implementación, comportamiento y apariencia; una prueba con dobles o fixtures no demuestra integración desplegada. Reabrir el estado si un cambio contradice una evidencia anterior. Conservar entradas previas y añadir la corrección, sin sobrescribir su resultado histórico.

## Registro de variantes Flutter

Inventario de referencia:70 variantes. Estado inicial compartido:1 completa aceptada,3 parciales comparadas,66 sin implementación específica. Tras el corte PIN + Home (03-11-2026): 1 completa, 8 parciales, 61 sin implementación específica. Tras agenda y confirmación (03-11-2026): 1 completa, 18 parciales, 51 sin implementación específica. La funcionalidad se registra por recorrido y actor, sin equiparar aprobación visual con cierre funcional. Las extensiones INV-01 (invitación), REC-01 (recuperación) y WDR-01 (retirada) tienen comportamiento implementado y pruebas propias; no amplían este denominador.

| # | Variante | Nodo Figma | Implementación | Fidelidad visual | Funcionalidad y evidencia |
| --- | --- | --- | --- | --- | --- |
| 1 | Landing - Value & Features | 563:1849 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 2 | Landing - Plans & Contact | 563:1913 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 3 | Onboarding | 563:5 | Completa | Aceptada proporcionalmente | Acciones y navegación comprobadas en widgets; onboarding_screen_test.dart; falta dispositivo |
| 4 | Caregiver Registration | 563:1398 | Parcial | Comparada, ajustes abiertos | Alta, verificación y reenvío; tests y probe Spring local; falta validación instalada |
| 5 | Link & Consent | 563:1440 | Parcial | Comparada, ajustes abiertos | Cuidador y adulto con decisiones y retirada; tests y Spring local; falta persistencia del setup cuidador y core adulto |
| 6 | PIN Access | 563:1338 | Parcial | Comparada, ajustes abiertos (iniciales en lugar de foto) | PinRoute/PinBloc.access con pin-sessions + current; tests, sonda Spring local y emulador (incorrecto y correcto); teléfono físico POCO X6 Pro comprobado |
| 7 | Login | 641:16 | Parcial | Comparada, ajustes abiertos | Password, restore y logout; social sin integrar; tests y Spring local |
| 8 | Home | 563:58 | Parcial | Comparada, ajustes abiertos (iniciales en lugar de foto; atajos voz/agenda y pestañas Medicamentos/Agenda/Notas ocultos hasta existir sus flujos) | AdultHomeRoute/HomeBloc con intakes/next y agenda del día; tests, sonda Spring local y emulador (vacío, toma real, refresco, reinicio); teléfono físico POCO X6 Pro comprobado |
| 9 | My Medications | 563:361 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 10 | Medication Detail | 563:142 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 11 | Weekly Schedule | 563:500 | Parcial | Comparada, ajustes abiertos (flechas de semana en lugar del icono de calendario) | AgendaRoute/AgendaBloc semana lunes-domingo con agenda?from&to; tests, sonda Spring local, emulador y teléfono físico POCO X6 Pro |
| 12 | Voice Confirmation | 563:242 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 13 | Dose Confirmed | 563:291 | Parcial | Comparada, ajustes abiertos (no afirma "familia notificada") | Resultado con hora registrada y próxima toma real; tests, sonda Spring local, emulador y teléfono físico POCO X6 Pro |
| 14 | Accessibility | 563:618 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 15 | Family Summary | 563:727 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 16 | Linked Person | 563:1121 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 17 | Alerts | 563:819 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 18 | Alert Detail | 563:918 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 19 | History & Insights | 563:1017 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 20 | Adherence Recommendations | 563:1767 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 21 | Notes - Adult | 576:2785 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 22 | Add Medication - Caregiver | 563:453 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 23 | Create Treatment | 563:1490 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 24 | Treatment Management | 563:1554 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 25 | Inventory & Restock | 563:1632 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 26 | Notification Preferences | 563:1219 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 27 | Notes - Caregiver | 576:2859 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 28 | Plan & Subscription | 563:1701 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 29 | PIN Setup | 563:1970 | Parcial | Comparada, ajustes abiertos | Alta tras consentimiento real en emulador con pin-credentials; PIN_ALREADY_REGISTERED comprobado en Spring; teléfono físico POCO X6 Pro comprobado |
| 30 | PIN Incorrect | 563:2034 | Parcial | Comparada, ajustes abiertos | INVALID_PIN 401 de Spring mostrado en emulador; dígitos limpiados; también en teléfono físico |
| 31 | PIN Temporarily Blocked | 563:2098 | Parcial | Sin comparar contra el nodo | Spring devuelve 401x3 y 403 PIN_LOCKED; mapeo y bloqueo de teclado en pin_flow_test.dart; sin captura en emulador |
| 32 | Duplicate Email | 563:2162 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 33 | Verification Expired | 563:2208 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 34 | Invalid Link Code | 563:2254 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 35 | Consent Required | 563:2308 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 36 | Medication Required Fields Error | 563:2404 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 37 | Medication Updated | 563:2455 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 38 | Medication Deactivated | 563:2537 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 39 | Medication Reminder Due | 563:2619 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 40 | Voice Not Recognized | 563:2707 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 41 | Dose Already Confirmed | 563:2760 | Parcial | Sin comparar en dispositivo | alreadyConfirmed del reintento y 409 releído como tomada; dose_flow_test.dart y sonda Spring |
| 42 | No Adherence Data | 563:2834 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 43 | Treatment Incomplete | 563:2942 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 44 | Treatment Paused | 563:3010 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 45 | Treatment Access Denied | 563:3092 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 46 | No Next Dose | 563:3178 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 47 | Dose Detail - Pending | 563:3266 | Parcial | Comparada, ajustes abiertos (sin fila "Para qué": el backend no la provee) | DoseRoute/DoseBloc con intakes/{id} y confirmación TOUCH; tests, sonda Spring local, emulador y teléfono físico POCO X6 Pro |
| 48 | Dose Detail - Confirmed | 563:3370 | Parcial | Comparada, ajustes abiertos | Estado confirmado sin botón de confirmar; tests, sonda Spring local, emulador y teléfono físico POCO X6 Pro |
| 49 | Dose Detail - Late | 563:3474 | Parcial | Sin comparar en dispositivo | Estado LATE con mensaje propio; tests (Spring local no genera tomas vencidas al activar) |
| 50 | Dose Detail - Omitted | 563:3578 | Parcial | Sin comparar en dispositivo | Sin botón de confirmar y mensaje de omisión; dose_flow_test.dart |
| 51 | Reinforced Reminder | 563:3682 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 52 | Late Dose Confirmed | 563:3770 | Parcial | Sin comparar en dispositivo | Recibo LATE mostrado como "Toma registrada"; dose_flow_test.dart |
| 53 | Omission Preserved | 563:3844 | Parcial | Sin comparar en dispositivo | 409 releído como OMITTED conserva la omisión; si la relectura falla no se afirma omisión; dose_flow_test.dart |
| 54 | Agenda With Statuses | 563:3918 | Parcial | Comparada, ajustes abiertos (sin barra inferior propia; se abre desde Home) | Estados confirmada/pendiente/tardía/omitida por toma y recarga al volver del detalle; tests, sonda Spring local, emulador y teléfono físico POCO X6 Pro |
| 55 | Empty Intake History | 563:4037 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 56 | Contact Unavailable | 563:4145 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 57 | Follow-up Note Saved | 563:4245 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 58 | Alert Attended | 563:4345 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 59 | Adherence Period Changed | 563:4445 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 60 | Insufficient Evidence | 563:4550 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 61 | Large Text Enabled | 563:4638 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 62 | High Contrast Enabled | 563:4751 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 63 | Reduced Motion Enabled | 563:4864 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 64 | Reading Assistance Enabled | 563:4977 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 65 | Notification Preferences Saved | 563:5090 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 66 | Invalid Inventory Quantity | 563:5213 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 67 | Stock Replenished | 563:5284 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 68 | Subscription Updated | 563:5354 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 69 | External Destination Unavailable | 563:5425 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 70 | Internationalization | 665:183 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |


## Procedimiento de implementación y revisión

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
