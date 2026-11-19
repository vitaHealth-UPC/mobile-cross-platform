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
| 11-11-2026 | Analítica de adherencia (US-32, US-33, US-34, US-09), con el módulo Kotlin como referencia de comportamiento: historial e insights con selector de 7 o 30 días y recomendaciones del servidor, para el cuidador de un vínculo o el propio adulto. Barra inferior del cuidador compartida en shared. Responsable: u20241a195-cmd | Sobre 6d2d8ab (temp); commits locales pendientes de publicar, de 5b64ca3 a la corrección del botón | 201 tests aprobados (123 previos y 78 propios: casos de uso, mapper, repositorio con sesión, blocs, pantallas, flujo y configuración de zona); análisis y formato limpios; capturas de widget con fuentes reales comparadas con 563:1017, 563:1767 y las variantes 563:2836, 563:4039 y 563:4552. La comparación encontró y corrigió el texto de un botón que perdía la fuente Inter. Sin sonda Spring, emulador, APK ni teléfono físico: el Android local no tiene cmdline-tools ni licencias aceptadas | Desviaciones del manifiesto: dos blocs (history y recommendations) en lugar de adherence_bloc; sin adherence_summary_screen, adherence_trend_screen ni get_treatment_adherence por falta de consumidor; la zona de calendario sale de TATA_CALENDAR_ZONE (America/Lima por defecto), no de la zona IANA del dispositivo. Pendiente: abrir el flujo desde Family Monitoring, conectar "Aplicar ajustes" con Treatment, validar contra Spring/Render y en dispositivo |
| 11-11-2026 | TS-13: cache de tomas y cola offline de confirmaciones con Drift por adulto y vínculo, reenvío serializado, restauración de sesión del adulto sin red y borrado local al retirar consentimiento | Sobre 6d2d8ab; commit pendiente | 170 tests; análisis y formato limpios; build apk debug; Spring local y emulador Pixel_10 sin red: arranque en frío, confirmación guardada, cierre forzado, agenda "por enviar", reenvío automático con una sola confirmación en servidor y borrado de filas tras retirar consentimiento | Reenvío con la app cerrada (no implementado: solo primer plano); probar en teléfono físico y contra Render. La entrega offline informa confirmedAt con la hora del toque (contrato v1.1.0 del 11-11-2026); si el servidor rechaza esa hora, se reenvía con la hora de llegada. La confirmación en línea sigue sin enviarla |

| 11-11-2026 | Autorización de Home, alta de PIN existente y fidelidad de PIN, Home, agenda, detalle y resultados, integrados con offline del equipo | Sobre 00d611a | 206 tests; análisis y formato limpios; 26 escenarios de layout con escalas 1 y 1.5 y capturas revisadas frente a Figma; build APK debug correcto con Drift y la integración del equipo | Despliegue Render por el titular; integrar voz, medicamentos y notas según backlog |
| 13-11-2026 | TS-11 y US-06 por voz: grabación PCM16 mono 16 kHz en memoria con record, envoltura WAV propia, subida multipart a voice-confirmation, frase sugerida leída con flutter_tts, permiso de micrófono y estados de Figma 563:242 y 563:2707 desde el atajo de Home | Sobre 7c4b3a6; commit pendiente | 442 tests; análisis y formato limpios; build apk debug; Spring local en Docker y emulador Pixel_10: permiso negado y luego concedido, grabación con indicador del sistema, corte a los 8 s, el servidor aceptó el WAV y respondió PROVIDER_UNAVAILABLE (Google Speech apagado en local), sin registrar la toma | Probar reconocimiento real donde Google Speech esté activo (Render o credenciales locales) y en teléfono físico; escuchar la frase con TTS no se verificó de oído. La caché offline no guarda medicationId ni treatmentId del corte de catálogo |
| 13-11-2026 | TS-11 verificado con reconocimiento real: Render con backend v2.0.0 y Google Speech-to-Text v1 activo | Integrado sobre efc6d20; commit pendiente | 589 tests y análisis limpio tras integrar efc6d20. Sondas con WAV sintetizado contra Render: silencio da NOT_RECOGNIZED, una frase ajena da NOT_VALIDATED sin registrar la toma, "Ya tomé mi Metformina" da CONFIRMED y repetirla da ALREADY_CONFIRMED; build apk release apuntando a Render e instalado en teléfono físico Android: invitación, consentimiento y PIN, luego Confirmar con voz desde Home, permiso de micrófono concedido, frase dicha en voz alta, Validando… unos 7 s y pantalla de toma confirmada; la agenda del cuidador muestra la toma CONFIRMED con canal VOICE | Escuchar la frase con TTS sigue sin verificarse de oído. Ajustes de Figma abiertos en las variantes 12 y 40. La latencia de Render (arranque en frío de hasta 90 s) conviene despertarla antes de una demo |
| 14-11-2026 | Inventory & Replenishment (US-40 a US-43): nuevo contexto inventory_replenishment con dominio, casos de uso, API, repositorio de cuidador, InventoryBloc y pantalla de Figma 563:1632, 563:5213 y 563:5284; acceso desde cada medicamento en Medicamentos del cuidador mediante un callback opcional, sin acoplar contextos | Sobre ca0faf9; commit pendiente | 614 tests (25 nuevos) y análisis limpio; build apk debug; Spring local en Docker con imagen reconstruida desde main y emulador Pixel_10: formulario de stock inicial sin inventario (404), stock 5 con umbral 5 como Stock bajo y 5 días, cantidad vacía marcada en el campo, reposición de 30 con lote a 35 unidades, Stock disponible y 35 días, Última reposición con el lote; la consulta al backend devolvió el mismo estado | La API no expone la unidad del medicamento, por eso se muestran unidades genéricas. El enlace Definir stock inicial explica que ya existe y no reemplaza el stock porque el backend no tiene ese endpoint. No se probó contra Render ni en teléfono físico |
| 14-11-2026 | US-42 conectado con US-43: cada aviso de stock bajo de Atención en el resumen familiar abre el inventario de ese medicamento, y el resumen se vuelve a leer al regresar del inventario o de Agregar medicamento; callbacks opcionales en FamilySummaryScreen y en caregiverHome, sin cambiar el comportamiento cuando no se pasan | Sobre 270a898; commit pendiente | 616 tests (2 nuevos de navegación) y análisis limpio; build apk debug; Spring local en Docker y emulador Pixel_10: Losartán con stock 5 y umbral 5 mostró "Quedan 5 unidades de Losartán." con flecha, el toque abrió su inventario, la reposición de 30 dejó 35 unidades y al volver el resumen mostró "No hay alertas de reposición." | Volver desde Medicamentos abierto por el menú Más todavía no recarga el resumen; se actualiza al cambiar de pestaña |
| 17-11-2026 | US-20 sin próxima toma (Figma 563:3178): el inicio del adulto mayor reemplaza la tarjeta blanca por la tarjeta morada "Sin próxima toma" y cierra con el aviso "Agenda al día"; la variante 55 ya estaba cubierta por Analítica | Sobre e2c5d15; commit pendiente | 617 tests y análisis limpio; build apk debug; Spring local en Docker y emulador Pixel_10 con un adulto mayor vinculado por invitación y sin tratamientos: tarjeta "Sin próxima toma", progreso 0/0 "Sin tomas programadas" y aviso "Agenda al día" al final | El atajo de voz se ve igual aunque no tenga toma que confirmar (no responde al toque) |
| 17-11-2026 | US-44, US-45 y TS-14: plan y suscripción del cuidador en identity_subscription (dominio, casos de uso, API, repositorio que usa siempre la cuenta de la sesión, SubscriptionBloc y pantalla de Figma 563:1701 y 563:5354), abierta desde Ajustes | Sobre 39b4ec1; commit pendiente | 629 tests (12 nuevos) y análisis limpio; build apk debug; Spring local en Docker y emulador Pixel_10 con el cuidador demo: plan Esencial actual, elección de Familiar, diálogo de confirmación con el precio, cambio aceptado con renovación a 30 días y aviso Suscripción actualizada; el backend devolvió FAMILY activo | No hay pagos reales: el backend solo cambia el plan. El orden de las capacidades se fija en la app porque el servidor las envía como conjunto |
| 17-11-2026 | Pulido de Intake y Family Monitoring: el atajo Confirmar con voz se atenúa, se anuncia deshabilitado y explica "No hay una toma por confirmar ahora." cuando no hay próxima toma; la pantalla de voz usa el micrófono de Figma y sus barras se mueven solo mientras escucha (quietas si el sistema reduce el movimiento); el resumen familiar se vuelve a leer al cerrar cualquier flujo abierto desde Más | Sobre 564466a; commit pendiente | 634 tests (5 nuevos) y análisis limpio; build apk debug; Spring local en Docker y emulador Pixel_10: adulto sin tratamiento con el atajo atenuado que no responde al toque, el mismo atajo activo tras activar un tratamiento, barras en movimiento comparadas en dos capturas durante Escuchando..., y cuidador demo que registró stock 3 con umbral 5 desde Más > Medicamentos > Inventario y al volver vio "Quedan 3 unidades de Metformina." sin cambiar de pestaña | El inicio del adulto no se recarga solo cuando aparece una toma nueva mientras está abierto; se actualiza al reabrir o volver a la pestaña |
| 17-11-2026 | Estados de error 32 a 35 de Figma: aviso compartido StatusNotice (título y acción, rosa para rechazo y ámbar para un paso repetible, anunciado al aparecer) en el registro del cuidador (correo ya registrado; verificación vencida, donde la acción principal pasa a Solicitar nuevo código), en la invitación y el consentimiento del adulto (No se pudo vincular) y la tarjeta Seguimiento restringido del resumen familiar con el nombre de la persona | Sobre 10653fd; commit pendiente | 640 tests (6 nuevos y 2 ampliados) y análisis limpio; build apk debug; Spring local en Docker y emulador Pixel_10: registro con el correo del cuidador demo mostró Correo ya registrado (409 real), una invitación ya aceptada mostró No se pudo vincular (LINKING_CODE_EXPIRED_OR_USED real) y, tras retirar el consentimiento del adulto por la API, el cuidador vio Seguimiento restringido con el nombre | Verificación vencida no se probó en dispositivo: sin correo en local no hay código que dejar vencer; queda cubierta por el flujo de widgets con la respuesta 410 del servidor. El texto gris de Figma se oscureció para mantener contraste 4.5:1 |
| 17-11-2026 | Caché offline de Intake en esquema Drift 2: cached_intakes guarda medicationId y treatmentId en columnas opcionales añadidas por migración, sin borrar tomas ni la cola de confirmaciones; la próxima toma leída sin red conserva sus referencias. La recarga del Inicio visible queda con la versión de b2ca71e | Sobre b2ca71e; commit pendiente | 669 tests en la suite integrada con 9689c00 y b2ca71e (3 nuevos: migración desde un archivo del esquema 1 validado contra el esquema nuevo, relleno de referencias al refrescar y lectura offline) y análisis limpio; Spring local en Docker y emulador Pixel_10: un APK de cd772b4 creó la base en esquema 1 con una toma, el APK con la migración instalado encima la llevó a esquema 2 conservando la sesión y la semana quedó con ambas referencias; arranque en frío sin red y con el contenedor detenido mostró la caché migrada | Las filas migradas reciben las referencias en el siguiente refresco de agenda. Una vez, al reiniciar Spring justo mientras la app arrancaba, el acceso quedó cargando más de 90 s; no se reprodujo en dos intentos posteriores |
| 18-11-2026 | Variantes 39 y 51 (US-05 y US-22): el inicio del adulto avisa en la tarjeta ámbar compartida "Es hora de tu toma" con el medicamento cuando una toma del día llegó a su hora y sigue pendiente en el servidor y en el dispositivo, y "Segundo recordatorio" cuando sigue pendiente 15 minutos después; tocar el aviso abre esa toma para confirmarla. GetDailyProgress entrega la toma vencida más antigua desde la misma agenda del día, sin otra lectura | Sobre 03d2c86; commit pendiente | 673 tests (4 nuevos) y análisis limpio; build apk debug; Spring local en Docker y emulador Pixel_10: una toma de Metformina pendiente desde hacía 16 minutos mostró Segundo recordatorio y abrió su detalle, se confirmó con retraso y el aviso desapareció; una toma de Amlodipino programada por la API a 2 minutos mostró Es hora de tu toma tras la recarga del Inicio visible | Los 15 minutos replican el valor por defecto del backend (tata.intake.unconfirmed-after, PT15M); el retraso de seguimiento configurado por tratamiento no se lee desde la sesión del adulto. Son avisos dentro de la app abierta; con la app cerrada los cubren las notificaciones locales del corte siguiente |
| 18-11-2026 | Variantes 2 y 69 (US-48 y US-49): Comenzar abre Elige cómo empezar antes del registro, con el catálogo público real de /api/v1/plans leído sin sesión, ordenado por precio, el plan con más capacidades como Recomendado y la tabla Qué incluye cada plan; elegir un plan abre el registro y, verificada la cuenta, ApplyChosenPlan activa ese plan con la sesión nueva (no envía nada si coincide con el plan inicial del servidor) o avisa que puede cambiarse en Ajustes. El contacto sale de TATA_CONTACT_URL (solo https, mailto o tel); sin destino válido, o si ninguna app lo abre, el botón queda No disponible con una pista para lector de pantalla. Si el catálogo falla se ofrece reintentar o continuar al registro | Sobre 6b336c1; commit pendiente | 687 tests (14 nuevos: catálogo sin credencial, catálogo vacío o malformado, orden, plan elegido, validación del destino, pantalla, contacto que no abre, fallo y flujo completo Comenzar, plan, registro y activación) y análisis limpio; build apk debug sin y con TATA_CONTACT_URL; Spring local en Docker y emulador Pixel_10: planes reales S/ 9.90 y S/ 19.90, No disponible sin efecto al tocarlo, Elegir Familiar abrió el registro y, con destino mailto configurado, Contactar abrió la app de correo | La activación del plan tras verificar no se probó en dispositivo porque el código de verificación solo llega por correo (Resend); queda cubierta por el flujo de widgets y el cambio de plan ya verificado en el emulador el 17-11. El pie de Figma sobre escritorio y teclado no se muestra porque describe la landing web. Los iconos de teléfono y mensaje son de Material |
| 18-11-2026 | US-05 y US-22 con la app cerrada: notificaciones locales programadas (flutter_local_notifications 22, sin Firebase) desde la agenda guardada en Drift. IntakeReminderPolicy programa para cada toma pendiente de las próximas 48 horas un aviso a su hora y un refuerzo 15 minutos después (máximo 48); IntakeReminderSync observa los cambios de cached_intakes y pending_confirmations, así que refrescar la agenda, confirmar (también sin red) o borrar datos al retirar el consentimiento reprograma solo, y al cerrar sesión o cambiar de cuenta se cancela todo. Pide el permiso de notificaciones al llegar al Inicio, usa alarmas exactas si el sistema las permite y si no inexactas, sobrevive a reinicios (receptores de arranque) y el texto sigue el idioma elegido en la app. Tocar el aviso abre el detalle de esa toma, también si la app estaba cerrada | Sobre a439d17; commit pendiente | 698 tests (11 nuevos: política, sincronización con Drift en memoria, confirmación en cola, agenda sin cambios, consentimiento retirado, cierre y sesión ajena) y análisis limpio; build apk debug; Spring local en Docker y emulador Pixel_10 con la app cerrada: con alarmas inexactas el aviso de Amlodipino llegó 1 min tarde y el refuerzo 5 min tarde; con alarmas exactas permitidas el aviso de Atorvastatina llegó a las 03:54:02 para la toma de las 03:54, en español, y al tocarlo abrió su detalle; confirmar quitó el refuerzo de las 04:09 y Cambiar cuenta dejó la app sin alarmas pendientes | En Android 14 la alarma exacta requiere que el usuario la permita (Alarmas y recordatorios); sin ese permiso Android puede retrasar el aviso varios minutos. Al tocar el resumen de grupo que Android crea con dos avisos se abre el Inicio, no la toma. flutter_local_notifications 23 exige compileSdk 37, por eso se fija la versión 22. iOS no se probó. El icono de la notificación es el de Flutter porque la app aún no tiene icono propio |
| 18-11-2026 | Variante 16 (Figma 563:1121): la pestaña Persona del cuidador abre la ficha de la persona dentro del shell de Family Monitoring en lugar de volver a la lista. Muestra nombre, iniciales, edad y cumpleaños del perfil, Vinculada y la fecha del consentimiento, la tarjeta Nivel de adherencia (AdherenceLevelView de Analítica, ya existente y sin uso), Tratamiento actual con los medicamentos activos (ActiveMedicationsCard nueva de Treatment), accesos Llamar y Mensajes al diálogo de contacto, Ver medicación e Historial, y la nota más reciente que abre Notas; la flecha vuelve a la lista. El host compone las tarjetas de otros contextos mediante LinkedPersonSlots. Se corrige además un error previo del diálogo de contacto: al cerrarlo con el botón atrás también se salía de la pantalla, en el resumen y en la ficha | Sobre e604dd3; commit pendiente | 704 tests (6 nuevos: ficha con datos, accesos rápidos, regresión del botón atrás comprobada contra el código anterior y tarjeta de medicamentos activos) y análisis limpio; build apk debug; Spring local en Docker y emulador Pixel_10 con el cuidador demo: Rosa Vargas sin tratamiento ni evidencia mostró Sin datos suficientes y Sin medicamentos activos; Rosa Prueba mostró 50 % En seguimiento, Amlodipino 5 mg y Atorvastatina 20 mg, y la nota recién guardada; Llamar abrió Contactar a Rosa sin canal registrado y un solo atrás volvió a la ficha y al resumen | Editar y el acceso ↗ de Figma no se dibujan porque no existe edición del perfil del adulto ni un destino definido para ese acceso; el avatar usa iniciales porque el perfil no tiene foto. Llamar y Mensajes abren el mismo diálogo, que ofrece el canal registrado (teléfono o WhatsApp) |

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

Balance vigente (18-11-2026): 69 de 70 variantes representadas y 45 aceptadas visualmente de forma proporcional. Las 25 restantes incluyen Landing - Value & Features, que conserva su implementación específica abierta. La aceptación visual no equivale a integración desplegada ni a cierre funcional.

Inventario de referencia:70 variantes. Estado inicial compartido:1 completa aceptada,3 parciales comparadas,66 sin implementación específica. Tras el corte PIN + Home (03-11-2026): 1 completa, 8 parciales, 61 sin implementación específica. Tras agenda y confirmación (03-11-2026): 1 completa, 18 parciales, 51 sin implementación específica. Tras analítica de adherencia (11-11-2026): 1 completa, 20 parciales, 49 sin implementación específica. Tras integración del 12-11-2026: 1 completa, 27 parciales y 42 sin implementación específica; 15 variantes aceptadas visualmente de forma proporcional. La funcionalidad se registra por recorrido y actor, sin equiparar aprobación visual con cierre funcional. Las extensiones INV-01 (invitación), REC-01 (recuperación) y WDR-01 (retirada) tienen comportamiento implementado y pruebas propias; no amplían este denominador.

| # | Variante | Nodo Figma | Implementación | Fidelidad visual | Funcionalidad y evidencia |
| --- | --- | --- | --- | --- | --- |
| 1 | Landing - Value & Features | 563:1849 | Sin implementación específica | Sin comparar | Sin evidencia Flutter para esta variante |
| 2 | Landing - Plans & Contact | 563:1913 | Completa | Aceptada proporcionalmente en emulador (18-11-2026) con TATA_CONTACT_URL configurado; sin el pie de la landing web | PlanChoiceScreen entre Comenzar y el registro con /api/v1/plans público; plan_choice_test.dart y plan_registration_flow_test.dart |
| 3 | Onboarding | 563:5 | Completa | Aceptada proporcionalmente | Acciones y navegación comprobadas en widgets; onboarding_screen_test.dart; falta dispositivo |
| 4 | Caregiver Registration | 563:1398 | Parcial | Comparada, ajustes abiertos | Alta, verificación y reenvío; tests y probe Spring local; falta validación instalada |
| 5 | Link & Consent | 563:1440 | Parcial | Comparada, ajustes abiertos | Cuidador y adulto con decisiones y retirada; tests y Spring local; falta persistencia del setup cuidador y core adulto |
| 6 | PIN Access | 563:1338 | Parcial | Aceptada proporcionalmente en render ES (11-11-2026; normal y texto 150 %) | PinRoute/PinBloc.access con pin-sessions + current; tests, sonda Spring local y emulador (incorrecto y correcto); teléfono físico POCO X6 Pro comprobado Capturas de widgets revisadas contra Figma; no se agrega evidencia de Render ni dispositivo. |
| 7 | Login | 641:16 | Parcial | Comparada, ajustes abiertos | Password, restore y logout; social sin integrar; tests y Spring local |
| 8 | Home | 563:58 | Parcial | Aceptada proporcionalmente en render ES (11-11-2026; normal y texto 150 %) | Barra de cinco destinos e ilustraciones originales; Medicamentos enlaza al catálogo; voz y notas conservan su estado de integración anterior. Iniciales por adulto. Progreso sin permiso invalida Home. |
| 9 | My Medications | 563:361 | Parcial | Aceptada proporcionalmente en render ES (12-11-2026; normal; layout 150 % comprobado) | MyMedicationsBloc del equipo con catálogo adulto real, filtros y detalle. Referencia por medicationId al próximo intake; tests HTTP, estado y navegación. Sin evidencia nueva de Render/dispositivo. |
| 10 | Medication Detail | 563:142 | Parcial | Aceptada proporcionalmente en render ES (12-11-2026; normal; layout 150 % comprobado) | Detalle usa todas las pautas del catálogo y zona horaria recibida; abre intake real. No inventa finalidad clínica ni pronostica tomas desde horarios. Tests y capturas de widgets. |
| 11 | Weekly Schedule | 563:500 | Parcial | Aceptada proporcionalmente en render ES (18-11-2026; normal y texto 150 %) | Calendario nativo selecciona cualquier fecha y carga su semana lunes-domingo mediante agenda?from&to; iconos originales y estados de toma conservados. Notas enlaza al flujo existente. Conserva evidencia anterior Spring/emulador/POCO, sin nueva prueba instalada de este corte. |
| 12 | Voice Confirmation | 563:242 | Parcial | Aceptada proporcionalmente en emulador (17-11-2026; micrófono de Figma y barras animadas al escuchar) | VoiceRoute/VoiceBloc con record y voice-confirmation; tests, Spring local en emulador y reconocimiento real en Render desde teléfono físico |
| 13 | Dose Confirmed | 563:291 | Parcial | Aceptada proporcionalmente en render ES (11-11-2026; normal y texto 150 %) | Resultado con hora registrada y próxima toma real; tests, sonda Spring local, emulador y teléfono físico POCO X6 Pro Capturas de widgets revisadas contra Figma; no se agrega evidencia de Render ni dispositivo. |
| 14 | Accessibility | 563:618 | Parcial | Aceptada proporcionalmente en render ES (17-11-2026; claro/oscuro, contraste y texto ampliado) | Grupos Vista, Interacción y Ayuda comparados con 563:618; controles nativos, iconos originales, selección de cuatro tamaños e idioma y persistencia existentes conservados. Doce renders; sin nueva prueba de dispositivo. |
| 15 | Family Summary | 563:727 | Parcial | Aceptada proporcionalmente en render ES (18-11-2026; normal y texto 150 %) | Cabecera con selector real de persona y alertas; adherencia, progreso del día, próxima dosis y stock con datos autorizados. Ver agenda abre las tomas del día sin confirmar por el adulto. FamilySummaryCards, FollowedAgendaSheet y pruebas de representación/navegación; sin nueva comprobación desplegada ni de dispositivo. |
| 16 | Linked Person | 563:1121 | Parcial | Aceptada proporcionalmente en emulador por el equipo y render ES revisado (18-11-2026; iconos originales, texto 150 % y Editar); iniciales porque no hay fotografía contractual | LinkedPersonScreen en Persona con perfil, vínculo, adherencia, medicación activa, contacto por tipo y última nota. Editar usa PUT del perfil en Care Link y recarga nombre, ficha y listado. Pruebas HTTP simuladas y renders de la edición; la nueva escritura conserva verificación desplegada y de dispositivo pendiente. |
| 17 | Alerts | 563:819 | Parcial | Aceptación proporcional en 393x883 y 360x640, texto normal/150 %, 18-11-2026 | Tarjetas, cabecera, filtros y barra nativos; prioridades del servidor, horas confirmadas y dosis pendientes sin duplicar. Ver checkpoint de prioridades. |
| 18 | Alert Detail | 563:918 | Parcial | Aceptación proporcional en 393x883 y 360x640, texto normal/150 %, 18-11-2026 | Hero, perfil, eventos registrados y acciones nativas; cierre confirmado desde menú, prioridad consultable y regreso al shell sin duplicar rutas. |
| 19 | History & Insights | 563:1017 | Parcial | Comparada, ajustes abiertos (eje con 5 fechas proporcionales a los puntos; el brillo del fondo es casi invisible, como en el nodo) | AdherenceFlowRoute/HistoryBloc con adherence/summary de 7 o 30 días; estados contenido, sin datos (563:2836), sin resultados (563:4039), 7 días (563:4447, sin captura propia), carga y error; tests de caso de uso, mapper, repositorio con sesión, bloc y widget; falta entrada desde Family Monitoring, Spring/Render y dispositivo |
| 20 | Adherence Recommendations | 563:1767 | Parcial | Comparada, ajustes abiertos ("Aplicar ajustes" no se dibuja hasta que Treatment pueda recibir los ajustes) | RecommendationsBloc con adherence/insight de 30 días; estados contenido, evidencia insuficiente (563:4552), carga y error; sin recomendación local; tests de bloc, widget y flujo con Historial; falta Spring/Render y dispositivo |
| 21 | Notes - Adult | 576:2785 | Parcial | Aceptada proporcionalmente en render ES (18-11-2026; normal y texto 150 %) | Notas propias: creación reconocida, categorías, grupos por fecha y recibo visible. Cabecera y tarjetas nativas; recarga espera al servidor y el acceso perdido retira los datos. Sin nueva ejecución desplegada o física. |
| 22 | Add Medication - Caregiver | 563:453 | Parcial | Sin comparación visual certificada en este corte | Registro de medicamento del equipo, validación de campos y recibo real mediante repositorio; tests de contrato y flujo. Falta revisión Figma y prueba instalada. |
| 23 | Create Treatment | 563:1490 | Parcial | Aceptada proporcionalmente en render ES (12-11-2026; revisión normal y layout 150 %) | Asistente con cuatro grupos visuales y validación separada de dosis/horarios; alta, configuración y activación conservan los contratos del equipo. Nombre guardado de solo lectura al regresar al borrador. Pruebas de flujo y capturas, sin nueva evidencia de Render/dispositivo. |
| 24 | Treatment Management | 563:1554 | Parcial | Aceptada proporcionalmente en render ES (13-11-2026; normal y layout 150 %) | Gestión con edición, pausa, reanudación y desactivación confirmada. Adherencia del tratamiento por ruta dedicada y porcentaje de la persona por consulta separada; widgets y contratos HTTP probados. Sin nueva prueba de Render/dispositivo. |
| 25 | Inventory & Restock | 563:1632 | Parcial | Aceptada proporcionalmente en emulador (14-11-2026); difiere en unidades genéricas (la API no expone la unidad), etiqueta con presentación y botón de volver | InventoryRoute/InventoryBloc desde Medicamentos del cuidador; GET, stock inicial y reposición contra Spring local; días y stock bajo los decide el servidor |
| 26 | Notification Preferences | 563:1219 | Parcial | Sin comparación visual certificada en este corte | Preferencias de notificación del equipo con contratos, estado y pruebas; falta contraste Figma y verificar el efecto del sistema de notificaciones en dispositivo. |
| 27 | Notes - Caregiver | 576:2859 | Parcial | Sin aceptación visual específica registrada | NotesScreen, NotesBloc y NoteComposerCubit: Listado y creación de notas del cuidador para la persona vinculada. |
| 28 | Plan & Subscription | 563:1701 | Parcial | Aceptada proporcionalmente en emulador (17-11-2026); sin barra de pestañas porque se abre desde Ajustes | PlanSubscriptionScreen/SubscriptionBloc desde Ajustes del cuidador: plan actual, catálogo con capacidades que agrega cada plan, renovación y elección con confirmación; cuenta del dueño de la sesión |
| 29 | PIN Setup | 563:1970 | Parcial | Aceptada proporcionalmente en render ES (11-11-2026; normal y texto 150 %) | PIN_ALREADY_REGISTERED informa que no cambia el PIN; continuar requiere confirmación explícita del usuario. Se limpian dígitos y se propaga pérdida de permiso. |
| 30 | PIN Incorrect | 563:2034 | Parcial | Comparada, ajustes abiertos | INVALID_PIN 401 de Spring mostrado en emulador; dígitos limpiados; también en teléfono físico |
| 31 | PIN Temporarily Blocked | 563:2098 | Parcial | Sin comparar contra el nodo | Spring devuelve 401x3 y 403 PIN_LOCKED; mapeo y bloqueo de teclado en pin_flow_test.dart; sin captura en emulador |
| 32 | Duplicate Email | 563:2162 | Completa | Aceptada proporcionalmente en emulador (17-11-2026) | StatusNotice de error en CaregiverRegistrationScreen; registration_notices_test.dart y 409 real de Spring local |
| 33 | Verification Expired | 563:2208 | Completa | Comparada en widgets; sin captura en dispositivo | StatusNotice ámbar y acción Solicitar nuevo código; registration_flow_test.dart con 410 del servidor |
| 34 | Invalid Link Code | 563:2254 | Completa | Aceptada proporcionalmente en emulador (17-11-2026); el código se ingresa como invitación del adulto | StatusNotice No se pudo vincular en InvitationScreen y ConsentScreen; invitation_notice_test.dart y respuesta real de Spring local |
| 35 | Consent Required | 563:2308 | Completa | Aceptada proporcionalmente en emulador (17-11-2026) | Tarjeta Seguimiento restringido del resumen familiar con el nombre; monitoring_screens_test.dart y consentimiento retirado contra Spring local |
| 36 | Medication Required Fields Error | 563:2404 | Parcial | Sin aceptación visual específica registrada | MedicationRegistrationScreen: Validación local de campos obligatorios y rechazo del formulario sin envío. |
| 37 | Medication Updated | 563:2455 | Parcial | Sin aceptación visual específica registrada | MedicationManagementScreen: El recibo actualizado reemplaza la fila y genera el aviso MedicationNotice.updated. |
| 38 | Medication Deactivated | 563:2537 | Parcial | Sin aceptación visual específica registrada | MedicationManagementScreen: Desactivación confirmada, recibo y estado inactivo con aviso MedicationNotice.deactivated. |
| 39 | Medication Reminder Due | 563:2619 | Completa | Aceptada proporcionalmente en emulador (18-11-2026); el texto del aviso usa 14 y 13 px en lugar de 10 px para mantener legibilidad | DueIntakeReminder en el Inicio desde la agenda del día y notificación local a la hora de la toma con la app cerrada; abre la toma; adult_home_test.dart, intake_reminders_test.dart y Spring local |
| 40 | Voice Not Recognized | 563:2707 | Parcial | Aceptada proporcionalmente en emulador (17-11-2026; micrófono de Figma y barras animadas al escuchar) | VoiceRoute/VoiceBloc con record y voice-confirmation; tests, Spring local en emulador y reconocimiento real en Render desde teléfono físico |
| 41 | Dose Already Confirmed | 563:2760 | Parcial | Aceptada proporcionalmente en render ES (11-11-2026; normal y texto 150 %) | alreadyConfirmed del reintento y 409 releído como tomada; dose_flow_test.dart y sonda Spring Capturas de widgets revisadas contra Figma; no se agrega evidencia de Render ni dispositivo. |
| 42 | No Adherence Data | 563:2834 | Parcial | Sin aceptación visual específica registrada | AdherenceHistoryScreen: Estado sin evidencia diferenciado de un fallo de transporte, sin porcentajes ficticios. |
| 43 | Treatment Incomplete | 563:2942 | Parcial | Aceptada proporcionalmente en render ES (13-11-2026; normal y layout 150 %) | Configuración rechazada muestra aviso y permite volver a Pauta sin recrear el borrador ni perder los valores. Pruebas de estado y capturas normal y texto 150 %. |
| 44 | Treatment Paused | 563:3010 | Parcial | Aceptada proporcionalmente en render ES (13-11-2026; normal y layout 150 %) | Pausa y reanudación usan recibos reconocidos; conservan zona horaria y muestran aviso de pausa. Capturas con gráfico de datos suministrados por el lector. |
| 45 | Treatment Access Denied | 563:3092 | Parcial | Aceptada proporcionalmente en render ES (13-11-2026; normal y layout 150 %) | Respuesta ACCESS_DENIED elimina nombre y datos clínicos y ofrece retorno a la persona de origen; sin acciones de gestión ni gráfico conservado. |
| 46 | No Next Dose | 563:3178 | Parcial | Aceptada proporcionalmente en emulador (17-11-2026); la tarjeta no muestra hora ni medicamento porque no hay toma pendiente | NoNextIntakeCard con el mismo fondo de la próxima toma y AgendaClearNotice al final del inicio; tests del inicio vacío y con toma pendiente |
| 47 | Dose Detail - Pending | 563:3266 | Parcial | Aceptada proporcionalmente en render ES (11-11-2026; normal y texto 150 %) | DoseRoute/DoseBloc con intakes/{id} y confirmación TOUCH; tests, sonda Spring local, emulador y teléfono físico POCO X6 Pro Capturas de widgets revisadas contra Figma; no se agrega evidencia de Render ni dispositivo. |
| 48 | Dose Detail - Confirmed | 563:3370 | Parcial | Aceptada proporcionalmente en render ES (11-11-2026; normal y texto 150 %) | Estado confirmado sin botón de confirmar; tests, sonda Spring local, emulador y teléfono físico POCO X6 Pro Capturas de widgets revisadas contra Figma; no se agrega evidencia de Render ni dispositivo. |
| 49 | Dose Detail - Late | 563:3474 | Parcial | Aceptada proporcionalmente en render ES (11-11-2026; normal y texto 150 %) | Estado LATE con mensaje propio; tests (Spring local no genera tomas vencidas al activar) Capturas de widgets revisadas contra Figma; no se agrega evidencia de Render ni dispositivo. |
| 50 | Dose Detail - Omitted | 563:3578 | Parcial | Aceptada proporcionalmente en render ES (11-11-2026; normal y texto 150 %) | Sin botón de confirmar y mensaje de omisión; dose_flow_test.dart Capturas de widgets revisadas contra Figma; no se agrega evidencia de Render ni dispositivo. |
| 51 | Reinforced Reminder | 563:3682 | Completa | Aceptada proporcionalmente en emulador (18-11-2026) | Misma tarjeta tras 15 minutos pendiente (valor por defecto del backend) y notificación local de refuerzo, cancelada al confirmar; adult_home_test.dart, intake_reminders_test.dart y Spring local |
| 52 | Late Dose Confirmed | 563:3770 | Parcial | Aceptada proporcionalmente en render ES (11-11-2026; normal y texto 150 %) | Recibo LATE con subtítulo de retraso y nota de clasificación. No afirma entrega a familiares. |
| 53 | Omission Preserved | 563:3844 | Parcial | Aceptada proporcionalmente en render ES (11-11-2026; normal y texto 150 %) | 409 releído como OMITTED conserva la omisión; si la relectura falla no se afirma omisión; dose_flow_test.dart Capturas de widgets revisadas contra Figma; no se agrega evidencia de Render ni dispositivo. |
| 54 | Agenda With Statuses | 563:3918 | Parcial | Aceptada proporcionalmente en render ES (11-11-2026; normal y texto 150 %) | Línea temporal, tarjetas nativas, marcas por enviar conservadas, barra compartida en Agenda y recarga al volver. |
| 55 | Empty Intake History | 563:4037 | Parcial | Sin comparación visual certificada en este corte | Ya resuelta por Analítica de adherencia (equipo): AdherenceEmptyCard con "Sin resultados" y el texto de Figma en el historial del cuidador; no se modificó en este corte |
| 56 | Contact Unavailable | 563:4145 | Parcial | Aceptada proporcionalmente en render ES (18-11-2026; normal y texto 150 %) | Contacto sin canal se representa como botón gris deshabilitado; no abre un destino y mantiene las acciones de seguimiento disponibles. |
| 57 | Follow-up Note Saved | 563:4245 | Parcial | Aceptada proporcionalmente en render ES (18-11-2026; normal y texto 150 %) | Confirmación verde persistente tras un recibo real del repositorio, con acceso a otra nota; sin mensaje flotante duplicado. Guarda, reabre y retira el borrador tras perder acceso. |
| 58 | Alert Attended | 563:4345 | Parcial | Aceptada proporcionalmente en render ES (18-11-2026; normal y texto 150 %) | ATTENDED procede del recibo, muestra la acción verde deshabilitada y conserva el cierre como transición separada. Las respuestas tardías no restauran datos revocados. |
| 59 | Adherence Period Changed | 563:4445 | Parcial | Sin aceptación visual específica registrada | HistoryPeriodSelected: Selector de 7 y 30 días con recarga y descarte de respuestas antiguas. |
| 60 | Insufficient Evidence | 563:4550 | Parcial | Sin aceptación visual específica registrada | AdherenceRecommendationsScreen: Evidencia insuficiente es un estado propio y no una recomendación fabricada. |
| 61 | Large Text Enabled | 563:4638 | Parcial | Sin aceptación visual específica registrada | AccessibilityScreen y Appearance: Cuatro tamaños persistidos; layout probado hasta escala conjunta 195 %. Sin aceptación específica del nodo 563:4638. |
| 62 | High Contrast Enabled | 563:4751 | Parcial | Sin aceptación visual específica registrada | Appearance y AccessibilityScreen: Tema de contraste y bandera MediaQuery propagados; iconos y barra adultos adaptados. No certifica todas las vistas del proyecto. |
| 63 | Reduced Motion Enabled | 563:4864 | Parcial | Sin aceptación visual específica registrada | Appearance y VoiceConfirmationScreen: Reduce movimiento en MediaQuery y barras de voz, con pruebas de estado y layout. |
| 64 | Reading Assistance Enabled | 563:4977 | Parcial | Sin aceptación visual específica registrada | Appearance y AccessibilityScreen: Ayuda de lectura cambia espacio entre líneas y letras; no se afirma resaltado semántico de textos. |
| 65 | Notification Preferences Saved | 563:5090 | Parcial | Sin aceptación visual específica registrada | NotificationPreferencesScreen: El guardado reconocido muestra pfPolicySaved; no implica entrega real de notificaciones. |
| 66 | Invalid Inventory Quantity | 563:5213 | Parcial | Aceptada proporcionalmente en emulador (14-11-2026) | Cantidad vacía o cero marca el campo sin enviar la solicitud; tests de caso de uso, BLoC y pantalla |
| 67 | Stock Replenished | 563:5284 | Parcial | Aceptada proporcionalmente en emulador (14-11-2026); fecha sin punto abreviado según intl | Reposición de 30 con lote: stock 35, Stock disponible, 35 días y Última reposición con el lote; el backend confirmó el mismo estado |
| 68 | Subscription Updated | 563:5354 | Parcial | Aceptada proporcionalmente en emulador (17-11-2026) | Cambio de Esencial a Familiar confirmado por el servidor: tarjeta del plan, Próxima renovación y aviso Suscripción actualizada; el backend devolvió FAMILY activo |
| 69 | External Destination Unavailable | 563:5425 | Completa | Aceptada proporcionalmente en emulador (18-11-2026) | Sin TATA_CONTACT_URL válido o si el destino no abre, Contactar pasa a No disponible deshabilitado con pista accesible; plan_choice_test.dart |
| 70 | Internationalization | 665:183 | Parcial | Sin aceptación visual específica registrada | AppearanceCubit y ARB es/en: Idioma por usuario aplicado a la app y controles traducidos; falta contraste visual completo con el prototipo EN. |


## Revisión del lote integrado (11-11-2026)

Home propaga pérdida de autenticación, sesión o consentimiento de cualquiera de sus dos consultas; una respuesta correcta de próxima toma no oculta una denegación en progreso. PIN_ALREADY_REGISTERED se presenta como estado propio, aclara que los dígitos nuevos no se guardan y exige pulsar Continuar con mi PIN actual. Las regresiones verifican ambas decisiones y la revocación durante el alta de PIN.

El componente shared/presentation/widgets/adult_navigation_bar.dart conserva cinco destinos y selección entre Home, Agenda y detalle. App conecta las acciones disponibles; los destinos sin integración quedan deshabilitados. Las tarjetas, línea temporal, botones y estados se componen con widgets. Se conservan las marcas de cola y el estado por enviar del compañero, sin presentarlos como recibo del servidor.

Los SVG de cápsula, notas, calendario, familia y éxito proceden de Figma; la cápsula conserva la rotación del nodo y los SVG sus dimensiones raíz. La tableta reutilizada tiene 352 x 352 píxeles. Water + Plant (100 x 100) y Confetti (150 x 60) conservan la resolución original disponible, sin fabricar detalle por reescalado. Las fotos de perfil no disponibles se representan mediante iniciales dinámicas.

adaptive_screens_test.dart comprueba 13 estados a 393 x 883 y escala 1, y a 360 x 640 y escala 1.5: PIN acceso/alta, Home, Agenda, cuatro detalles y cinco resultados. Nombre e insignia se redistribuyen sin fragmentar palabras; la hora de Home y su ilustración pasan a columna con texto grande. El helper de captura restaura las sombras del entorno de prueba. Las capturas permanecen como evidencia local reproducible, fuera de los assets productivos.

Son 12 variantes Figma corregidas y aceptadas proporcionalmente, más el estado offline por enviar fuera del denominador. Con el onboarding anterior suman 13 variantes aceptadas visualmente. No implica cierre de sus historias: la tabla conserva la funcionalidad parcial y distingue widgets, servidor local y Render. Este corte no integra en main/develop ni modifica el report.

## Corte integrado de catálogo y contribuciones (12-11-2026)

Base remota: 8735ece en temp. Se integran los commits de adherencia, tratamientos y preferencias sin reescribir sus evidencias. El borrador local anterior queda preservado; la implementación productiva reutiliza MyMedicationsBloc, GetMyMedicationsOverview, TreatmentApi y los repositorios del equipo, con una sola fuente para el catálogo.

| Archivos | Responsabilidad y relación |
| --- | --- |
| application/readmodels/treatment_readmodels.dart | MyMedication conserva todas las pautas configuradas; TreatmentDetail conserva recurrenceZone. MedicationNextDose lleva medicationId y el ID real del intake. MyMedicationsOverview separa el catálogo de un fallo al consultar la próxima toma. |
| infrastructure/mappers/treatment_mapper.dart | Valida dueño del catálogo, relación medicamento/tratamiento, pauta configurada e instrucciones; no sustituye datos malformados por ejemplos. |
| infrastructure/repositories/remote_treatment_readers.dart | GET /api/v1/me/medications usa la identidad adulta capturada por authorizedRequest y valida olderAdultId contra esa identidad. |
| application/usecases/treatment_usecases.dart y presentation/bloc/my_medications/my_medications_bloc.dart | Consultan catálogo y próxima toma, distinguen vacío de fallo y dan prioridad a la pérdida de acceso. Conservan filtros y descartan recargas antiguas. |
| presentation/screens/my_medications_screen.dart | Host de selección, vuelta al catálogo, actualización al regresar al primer plano y retirada de datos tras revocación. |
| presentation/screens/medication_catalog_screen.dart | Figma 563:361 con tarjetas nativas, filtros, cantidades reales, ilustración original e iconos de mañana/noche. |
| presentation/screens/medication_details_screen.dart | Figma 563:142 con todas las pautas, datos disponibles y preparación. La finalidad clínica ausente no se inventa. |
| presentation/navigation/treatment_navigation.dart y app/integration/adult_entry_route.dart | Conectan Home, Medicamentos, Agenda y detalle de toma mediante callbacks públicos. La composición entre contextos queda en app. |
| shared/presentation/widgets/adult_navigation_bar.dart | Barra pura compartida por Intake y Treatment; conserva cinco destinos y selección. Los destinos sin flujo integrado permanecen deshabilitados. |
| intake_execution/domain/entities/intake.dart e infrastructure/mappers/intake_mapper.dart | Conservan medicationId y treatmentId remotos, también en copias de confirmación local. Desde el esquema Drift 2 la caché offline también los guarda; las filas migradas del esquema 1 los reciben en el siguiente refresco de agenda. |
| assets/icons/catalog_morning.svg, catalog_night.svg y assets/illustrations/catalog_glow.svg | Recursos originales Figma, sin rasterizar controles. El filtro SVG no soportado se representa con ImageFiltered de Flutter y sigma 26; se conserva el viewBox. |
| test/treatment_management/catalog_repository_test.dart | Prueba ruta, bearer, roles, propietario, respuesta tardía, relaciones, horarios y catálogo vacío. |
| test/treatment_management/catalog_overview_test.dart | Prueba fallo parcial de agenda, prioridad de revocación y conservación de referencias en cola offline. |
| test/treatment_management/catalog_navigation_test.dart | Prueba selección, vuelta, historial y retirada del catálogo al perder permisos. |
| test/treatment_management/catalog_screens_test.dart y catalog_fixtures.dart | Render con fuentes y recursos reales en 393x883 y 360x640, texto 100 % y 150 %, scroll y apertura del intake verdadero. Los datos de ejemplo viven solo en tests. |

Las rutas de esta tabla son relativas a lib/features/treatment_management salvo prefijos app, shared, intake_execution, assets y test. No se agregan repositorios, entidades o blocs paralelos al trabajo del equipo.

Verificación integrada: 407 pruebas aprobadas; flutter analyze --no-pub sin incidencias. Formato comprobado en 323 archivos sin cambios. APK debug construido correctamente con los plugins del equipo y el catálogo integrado (assembleDebug: 340,5 s). El código de este corte se publica en 2cdd341; la evidencia de build se registra en este checkpoint posterior. Capturas de catálogo y detalle revisadas contra los nodos correctos; los layouts con texto ampliado se prueban sin overflow. El botón de alta queda deshabilitado para el adulto, cuyo catálogo es de consulta. Cuando el próximo intake global pertenece a otro medicamento, la pantalla indica información de próxima toma no disponible en lugar de asegurar que ese medicamento no tiene tomas. La cola local antigua no fuerza una migración de base únicamente para obtener estas referencias.

El catálogo no se declara probado contra Render ni en teléfono en este corte. Los flujos nuevos de tratamientos y preferencias pasan la suite integrada, pero conservan su contraste visual pendiente. El siguiente recorrido es revisar el asistente y la gestión de tratamientos con sus nodos Figma, manteniendo sus contratos existentes; después, preferencias y su efecto visual en las pantallas compartidas.

## Fidelidad del asistente de tratamientos (12-11-2026)

Sobre d8ee412 se contrasta Create Treatment con el contexto y captura del nodo 563:1490. La presentación muestra Datos, Pauta, Recordatorios y Revisar; las validaciones existentes de dosis/frecuencia y horarios permanecen separadas dentro de Pauta. Se conservan CreateTreatment, ConfigureTreatment y ChangeTreatmentStatus sin cambiar rutas ni duplicar casos de uso.

| Archivo | Responsabilidad |
| --- | --- |
| presentation/screens/treatment_setup_screen.dart | Formulario con nombre, medicamento elegido y acciones; conserva controladores al volver. El nombre reconocido por el servidor queda de solo lectura y se presenta con su valor recibido. |
| presentation/widgets/treatment_stepper.dart | Indicador nativo de cuatro grupos con semántica de selección; texto ampliado usa dos columnas para conservar las etiquetas completas. |
| presentation/widgets/treatment_setup_review.dart | Tarjetas de dosis, frecuencia, horarios, indicaciones y seguimiento. TreatmentSchedulePreview muestra solo horarios introducidos, sin barras de cumplimiento o tomas inventadas. |
| assets/icons/treatment_medication.svg | Recurso original de Figma, 24x24, usado como ilustración del medicamento; los demás controles se componen con widgets. |
| l10n/app_es.arb y app_en.arb | Títulos, ayuda de seguimiento, resumen con parámetro de minutos y vista previa localizados. El valor vacío conserva la política predeterminada del servidor. |
| test/treatment_management/treatment_setup_visual_test.dart | Cinco estados internos en 393x883 y 360x640, texto 100 % y 150 %, botones alcanzables y regreso al nombre ya guardado. |
| test/treatment_management/treatment_screens_test.dart | Valida campos vacíos, horario inválido, orden normalizado, política predeterminada y activación reconocida, con viewport móvil y desplazamiento hasta la acción. |

Las tres primeras rutas son relativas a lib/features/treatment_management. No se agrega un quinto paso visual ni un segundo flujo de configuración. La revisión no afirma recordatorios activos antes de activar el tratamiento y no rellena nombre de paciente, finalidad clínica, horas ni minutos con ejemplos productivos.

La variante 23 se acepta visualmente de forma proporcional; el registro pasa a 16 aceptadas de 70, con 28 variantes implementadas total o parcialmente. El módulo conserva estado funcional parcial hasta validar los recorridos contra Spring desplegado y dispositivo. La suite de Treatment Management mantiene sus 60 pruebas aprobadas; se revisan las capturas de los cinco estados y su versión de texto ampliado. El siguiente nodo es Treatment Management (563:1554), manteniendo los contratos y permisos existentes.

## Gestión de tratamientos y cierre acotado (13-11-2026)

La revisión remota parte de 7c4b3a6. Se contrastan los nodos 563:1554, 563:3010, 563:3092 y 563:2942, con capturas de activo, pausado, inactivo, acceso denegado y configuración rechazada en tamaño normal y texto 150 %. Los controles, tarjetas, avisos y barras del gráfico se componen con Flutter. La persona muestra sus iniciales porque el contrato del perfil no proporciona fotografía; no se asigna a otros usuarios la foto de ejemplo del mockup.

| Archivos y ámbito | Responsabilidad |
| --- | --- |
| Treatment presentation/screens/treatment_detail_screen.dart | Orquesta el formulario, confirma desactivación, oculta evidencia al perder acceso y permite regresar a la persona de origen. |
| Treatment presentation/widgets/treatment_management_card.dart y managed_person_card.dart | Pauta y estado reales, acciones autorizadas, identidad y cantidad de medicamentos activos. La insignia de adherencia se recibe del host. |
| Treatment presentation/widgets/regimen_editor.dart | Diálogo nativo con controladores propios hasta terminar su transición de cierre; entrega una intención de edición al bloc. |
| Treatment presentation/bloc/treatment_management/treatment_management_bloc.dart | Conserva recurrenceZone al cambiar de estado, además de los recibos y restricciones ya existentes. |
| Treatment presentation/bloc/treatment_setup y screens/treatment_setup_screen.dart | Un tratamiento que otro usuario pausó no se anuncia como activado. El rechazo de configuración permite corregir la pauta sin duplicar el borrador. Los controladores se inicializan desde los valores validados disponibles. |
| Adherence application/ports/adherence_reader.dart y usecases/get_adherence_summary.dart | Filtro de tratamiento opcional, sin cambiar el significado de las consultas generales; valida referencias vacías y períodos. |
| Adherence infrastructure/remote/analytics_api.dart y repositories/remote_adherence_repository.dart | Para un tratamiento usa GET /api/v1/older-adults/{adult}/adherence/treatments/{treatment}/summary, con days y zone. No cae a la consulta global si un despliegue anterior devuelve 404. |
| Adherence presentation/bloc/level y navigation/treatment_adherence_view.dart | Solicitan evidencia de siete días para la pauta elegida, distinguen carga, vacío y error y actualizan al regresar al primer plano. Las barras usan fechas y porcentajes recibidos. |
| Adherence presentation/navigation/adherence_badge_view.dart | Consulta independiente de la persona completa. La ausencia de evidencia no produce una insignia de 0 %. |
| app/di/app_dependencies.dart, app/integration/caregiver_care_route.dart y main.dart | Componen analítica general y filtrada con Treatment mediante widgets y callbacks; una invalidación retorna al host sin conservar la pantalla clínica. |
| shared/presentation/widgets/caregiver_tab_bar.dart | Aplica color blanco al icono seleccionado y gris a los demás, y deshabilita destinos no conectados conservando semántica y geometría. |
| test/treatment_management/treatment_management_visual_test.dart y treatment_setup_regressions_test.dart | Edición, ciclo de diálogo, confirmación/cancelación de desactivación, reactivación, conservación de zona y conflictos de activación. |
| test/adherence_analytics/presentation/adherence_badge_test.dart y infrastructure/remote_adherence_repository_test.dart | Separación entre porcentaje global y filtro de tratamiento, revocación al volver y ausencia de fallback a datos globales. |
| test/shared/presentation/caregiver_tab_bar_test.dart | Color seleccionado y ausencia de tap en destinos no conectados. |

Treatment y Adherence en esta tabla corresponden a lib/features/treatment_management y lib/features/adherence_analytics. Se conserva una sola implementación por responsabilidad y los módulos no importan la infraestructura de otro contexto. El gráfico y la insignia muestran consultas distintas, aunque sus porcentajes puedan coincidir. Los botones secundarios conservan Inter explícitamente para evitar que el estilo sustituya la tipografía del tema.

Verificación: 437 pruebas aprobadas en la suite integrada; análisis sin incidencias y formato limpio en 335 archivos. APK debug construido correctamente (assembleDebug: 40,5 s). Las nuevas capturas usan fuentes y recursos productivos. La evidencia funcional sigue separada de la prueba desplegada. El registro contiene 31 variantes con implementación total o parcial de 70 (44,3 %), y 20 aceptadas visualmente (28,6 %). Quedan 39 sin implementación específica y 50 sin aceptación visual registrada. Estas coberturas no equivalen a porcentaje de aplicación terminada: parte de los recorridos conserva validación desplegada o de dispositivo pendiente.

Los contextos presentes son Identity, Care Link, Treatment, Intake, Adherence y Accessibility. Inventory, Family Monitoring y Omission/Escalation no tienen todavía implementación Flutter específica; voz, acceso social y suscripciones también conservan trabajo pendiente. El siguiente bloque es la fidelidad de preferencias y el alta/edición de medicamentos, seguido por los contextos restantes. El reporte académico no se modifica en este corte.

## Revisión de contribuciones e integración (17-11-2026)

Base recibida: cd772b4 en temp, con los cambios posteriores a 157acea. Se integran voz, inventario, suscripción, Family Monitoring y Omission/Escalation, además de los estados de error y recargas documentados por el equipo. El registro de variantes conservaba varios flujos como ausentes pese a tener pantalla, estado y pruebas: se corrige su implementación a parcial sin convertir esa presencia en aceptación visual o en certificación desplegada.

La base recibida pasa 640 pruebas. El registro del equipo contiene pruebas de voz contra Render y en teléfono físico, e inventario, suscripción y estados de error contra Spring local y emulador. Esta revisión conserva esas evidencias como comprobaciones del equipo; no las presenta como nuevas ejecuciones propias contra producción.

### Correcciones de voz

- infrastructure/audio/microphone_voice_recorder.dart invalida permisos y aperturas de stream pendientes cuando se cancela. Cada captura conserva sus propios recursos: una respuesta anterior no puede cerrar una captura nueva. El audio permanece acotado en memoria y los errores del stream producen INVALID_AUDIO.
- presentation/bloc/voice/voice_bloc.dart impide inicios simultáneos, invalida el intento al cerrar o cancelar y no retorna a grabación por una respuesta tardía. La pérdida de acceso al consultar la próxima toma retira la evidencia clínica de pantalla y solicita revalidación.
- test/intake_execution/voice_lifecycle_test.dart añade siete regresiones de permiso tardío, stream tardío, captura reemplazada, error nativo, doble inicio, cierre y pérdida de permiso después de confirmar. Se conservan las pruebas del flujo existente y la decisión final del backend.

Las dos primeras rutas son relativas a lib/features/intake_execution. El adaptador real de grabación se mantiene: no se reemplaza por un mock ni se mueve la validación de voz al cliente.

### Accesibilidad con Figma

Se consulta el nodo 563:618 mediante Figma y se conserva la aplicación de preferencias implementada por el equipo. Los grupos Vista, Interacción y Ayuda usan Material, ListTile, SwitchListTile, Switch y RadioGroup. El selector por fila mantiene los cuatro tamaños; el interruptor ofrece el cambio rápido grande/mediano. El idioma queda en una tarjeta accesible por scroll y el banner abre la ayuda nativa.

Los seis recursos assets/icons/accessibility_{text_size,contrast,dark_mode,reduce_motion,voice,reading}.svg se descargan desde Figma y conservan sus dimensiones 24x24. Los fondos circulares e interruptores se construyen con Flutter. La descripción de ayuda de lectura refleja el efecto real de espaciado, sin prometer un resaltado que no implementa el tema.

Appearance.wrap propaga highContrast junto con escala y movimiento reducido; AdultNavigationBar adopta los colores del tema en oscuro o contraste, conservando el aspecto claro. La cabecera usa el ancho completo con escalas grandes para evitar letras aisladas. PreferencesNavigation admite un pie de navegación aportado por app y AdultEntryRoute conecta los destinos ya disponibles, sin importar otro contexto dentro de la pantalla de ajustes.

Se renderizan seis configuraciones con tamaños 393x883 y 360x640: predeterminada, oscuro, contraste, texto máximo, movimiento reducido y lectura. La escala máxima conjunta probada es 195 %. Los tests conservan sincronización offline, selección de tamaños, idioma y ciclo de cierre de los blocs. No se marcan automáticamente aceptadas las variantes 61 a 64: sus estados están implementados, pero requieren su contraste específico.

### Estado y siguiente recorrido

La suite integrada actual pasa 659 pruebas y el análisis no reporta incidencias. El formato queda limpio en 444 archivos y el APK debug compila correctamente con los nuevos plugins de audio y enlaces. La compilación advierte compatibilidad futura de Kotlin y diferencias entre herramientas del SDK; no impide generar el APK. El inventario contiene 64 de 70 variantes con implementación total o parcial: 5 completas y 59 parciales. Se registran 32 aceptaciones visuales proporcionales de 70. Estas cifras miden representación funcional y revisión visual respectivamente, no finalización de extremo a extremo.

Quedan sin implementación específica las variantes 1 y 2 (landing), 16 (persona vinculada), 39 y 51 (avisos de toma y recordatorio reforzado) y 69 (destino externo no disponible). Los nueve contextos tienen código, pero Omission/Escalation conserva NotConfiguredPushTokenSource y NotConfiguredOmissionNotifier: este build no registra un token FCM ni muestra notificaciones de sistema reales. El acceso social de Flutter también permanece sin el adaptador cliente. No se equipara un cambio de plan con un cobro real.

El siguiente recorrido funcional es enlazar un adaptador real de push/notificaciones y cerrar la ficha de persona; en paralelo, continuar el contraste de notificaciones, resumen familiar, alertas y notas. El Home también descubre nuevas tomas mientras permanece visible mediante la política de actualización descrita en el siguiente corte. Las validaciones en Render, iOS y teléfono se mantienen separadas por recorrido. Backend y Android nativo no presentan cambios remotos nuevos en esta revisión; el informe académico no se modifica.

## Actualización del Inicio visible (17-11-2026)

Base: 9689c00 en temp, sin novedades remotas al comenzar este corte. Se resuelve el caso en que el cuidador programa una toma mientras el adulto mantiene abierta la pantalla de Inicio. La actualización se limita a lectura: el backend conserva la programación y clasificación de las tomas.

| Archivo | Responsabilidad y comportamiento |
| --- | --- |
| lib/features/intake_execution/presentation/navigation/adult_home_route.dart | Administra un Timer de un minuto mientras la aplicación está resumed. Una ruta cubierta no consulta; inactive, hidden, paused y dispose cancelan el temporizador. La pérdida de acceso detiene nuevas recargas periódicas. Se conservan las recargas al volver y los avisos de sincronización offline. |
| lib/features/intake_execution/presentation/bloc/home/home_event.dart | HomeRequested diferencia una consulta periódica de una recarga explícita. |
| lib/features/intake_execution/presentation/bloc/home/home_bloc.dart | Conserva la tarjeta lista durante una consulta periódica y omite consultas periódicas superpuestas. Una recarga explícita prevalece sobre respuestas anteriores. Los fallos siguen produciendo un estado de error; no se conservan datos clínicos después de perder permiso. |
| test/intake_execution/home_refresh_test.dart | Siete regresiones: toma nueva desde el estado vacío, lectura lenta sin parpadeo ni solicitudes superpuestas, ruta cubierta, ciclo de vida completo, pérdida de permiso, cambio de día y respuesta antigua después de una recarga explícita. |

Verificación de este corte: 18 pruebas del Inicio aprobadas, 666 pruebas en la suite integrada, análisis sin incidencias, formato limpio en 445 archivos y APK debug generado correctamente. No se atribuye a estas pruebas una ejecución nueva en Render ni en teléfono físico.

La pantalla mantiene sus componentes Flutter y sus datos de sesión. No se modifica su composición ni se suma una aceptación visual por este cambio funcional. La consulta periódica no sustituye las notificaciones de sistema: no avisa con la aplicación cerrada.

Se consultan asimismo los nodos 563:1121 y 563:727 para preparar la ficha de persona y la revisión del resumen familiar. Esa consulta no acredita implementación ni aceptación visual. La ficha requiere reunir perfil, vínculo, adherencia, medicación, notas y contacto con permisos vigentes; no se incorporan fechas, fotografías, tratamientos ni porcentajes del ejemplo como datos productivos. Continúa el recuento de 64 variantes representadas y 32 aceptadas visualmente.

## Revisión remota y edición de la persona (18-11-2026)

Se reciben diez commits de temp, de b2ca71e a a0aa276: referencias de medicamento/tratamiento en el caché, recordatorios en Inicio y con la aplicación cerrada, catálogo público de planes/contacto y ficha Persona. La base recibida pasa 704 pruebas. El borrador local de la ficha queda conservado; se utiliza la pantalla y composición por slots del equipo, incorporando únicamente la edición de Care Link y los cuatro SVG originales que aún faltan. No se duplica el recorrido.

Los textos secundarios de Persona usan #5B6475 sobre superficies claras; se conserva ese contraste. Se revisan capturas con fuentes reales, tarjetas productivas de Analítica y Treatment, iconos SVG de 24x24 y escala de texto normal/150 %. Las áreas interactivas, tarjetas y formulario son widgets Flutter. La imagen de Rosa del mockup no se asigna a usuarios reales. El acceso lateral ↗ no tiene un destino contractual definido y no se presenta como función implementada.

### Responsabilidades y correcciones

| Área y archivos | Responsabilidad |
| --- | --- |
| Care Link: application/ports/caregiver_profile_editor.dart y application/usecases/update_caregiver_profile.dart | Puerto de lectura/escritura y validación de nombre, referencia y fecha calendario. La edición no reasigna cuidador ni consentimiento. |
| Care Link: infrastructure/remote/care_link_api.dart e infrastructure/repositories/remote_care_link_repository.dart | GET y PUT del perfil ya existentes en backend; bearer del cuidador capturado. El recibo debe coincidir en persona, cuidador, nombre y fecha. Se rechazan respuestas posteriores a un cambio de cuenta. |
| Care Link: presentation/bloc/profile_editor/profile_editor_cubit.dart, presentation/screens/profile_editor_screen.dart y presentation/navigation/profile_editor_route.dart | Formulario con TextFormField, ListTile, DatePicker, FilledButton y BLoC/Cubit. Cancelar no escribe; un fallo conserva los campos; doble envío no duplica escrituras y una respuesta tras cerrar no restaura el formulario. Solo un recibo válido retorna el perfil actualizado. |
| Family Monitoring: LinkedPersonSlots, LinkedPersonScreen y FamilySummaryBloc | El host ofrece Editar y devuelve el nombre confirmado. Ficha, resumen y tarjetas se recargan. Una lectura fallida de perfil oculta las tarjetas clínicas; perder permiso al consultar contacto también retira esos datos. |
| Family Monitoring: FamilyContactRequested y diálogo de contacto | Llamar filtra teléfono y Mensajes filtra WhatsApp. Un canal diferente no se ofrece como si correspondiera a la acción elegida. Reintentar conserva el filtro. El contacto genérico del resumen conserva ambos tipos. |
| app y CaregiverSetupRoute | Composición explícita de la edición mediante el host y recarga del listado de vínculos al volver de la zona de seguimiento. |

El registro anterior del equipo indicaba que no existía edición del perfil. El controlador OlderAdultsController ya expone PUT /api/v1/older-adults/{olderAdultId}; esta revisión conecta ese contrato sin modificar el backend. La edición se considera parcial hasta probar su escritura contra el servidor y dispositivo, además de las comprobaciones locales. La lectura y las pruebas de Spring/emulador previas del equipo se conservan con su alcance original.

### Verificación del corte

La suite integrada pasa 723 pruebas, incluidas 13 pruebas nuevas de edición y seis de integración/representación de Persona. El análisis final no reporta incidencias y la comprobación de formato queda limpia en 469 archivos. El APK debug compila con las dependencias recibidas; conserva avisos del entorno de Kotlin y herramientas del SDK. Se revisan los renders de Persona y del formulario con escala normal/150 %. No se ejecuta una nueva escritura en Render ni en teléfono físico.

### Estado de los repositorios y continuidad

La rama de trabajo Flutter continúa en temp. main conserva el scaffold 269f50c y no se crea una release ni se integra main/develop como efecto de esta revisión. Backend permanece en main 9f6fd73 y develop/fix 9154233; Android mantiene main d04ca0e y develop d2baab3. Se consultan los remotos y no hay cambios nuevos en esos dos repositorios. El informe académico no se modifica.

El inventario contiene 69 de 70 variantes representadas, 9 completas y 60 parciales; quedan 37 aceptaciones visuales proporcionales. La única variante sin implementación específica es Landing - Value & Features (563:1849). Estos recuentos no equivalen a finalización de la aplicación: siguen abiertas la validación visual de variantes, el acceso social Flutter, push FCM familiar y la verificación remota/dispositivo de recorridos concretos. Los recordatorios locales del equipo sí existen, programan desde la agenda almacenada y tienen evidencia del equipo con la app cerrada; no equivalen a recibir nuevas programaciones del servidor con la app cerrada ni a push familiar.

Siguiente recorrido: revisar la fidelidad del resumen familiar con 563:727, completar las comparaciones específicas pendientes y verificar la escritura del perfil en un host aislado. El corte conserva separadas las evidencias de HTTP simulado, render, Spring, Render y dispositivo.

## Resumen familiar y agenda de consulta (18-11-2026)

Base: 879d1c5 en temp, sin cambios remotos adicionales al comenzar. Se contrasta Family Summary con el nodo 563:727 mediante Figma MCP y se revisan renders de 393x883 y 360x640 con fuentes productivas y escala de texto normal/150 %. La cabecera ofrece selección del familiar y alertas; las tarjetas conservan la jerarquía de adherencia semanal, progreso del día, próxima dosis, reposición y tres accesos rápidos.

### Composición y comportamiento

- presentation/widgets/family_summary_cards.dart contiene las tarjetas con Material, Ink, InkWell, Column, Row, Expanded, Wrap y LinearProgressIndicator. La barra de progreso representa las dosis reales del día. Una semana sin evidencia no se convierte en 0 % ni en un mensaje de felicitación; se muestran sus contadores o ausencia de datos. La ilustración del corazón es decorativa y no sustituye la cifra calculada por el servidor.
- presentation/screens/family_summary_screen.dart conserva errores, consentimiento requerido y contacto. El selector vuelve a la lista de familiares, la campana abre Alertas y cada aviso de stock mantiene la medicación correcta. El alta de medicamentos sigue disponible como acción secundaria; no sustituye al acceso a agenda de Figma.
- presentation/screens/followed_agenda_sheet.dart muestra la agenda del día como consulta del cuidador. Reutiliza el AlertsBloc y el timeline autorizado del shell, sin crear otra autoridad de datos ni llamar HTTP desde la pantalla. Presenta todas las dosis, también las pendientes vencidas y omitidas que el filtro de Alertas no representa como próximas. Se ordenan por hora, se conservan los resultados del servidor y no hay acción de confirmar por el adulto. El error de autorización retira los datos previos y propaga FamilySummaryAccessLost al resumen; sus revisiones invalidan respuestas anteriores y la pérdida de permiso se traslada también a Notas. Cerrar la agenda no restaura tarjetas clínicas anteriores. Permite relectura y cierre mediante controles nativos.
- presentation/navigation/family_monitoring_navigation.dart abre la hoja mediante showModalBottomSheet y presta su bloc existente con BlocProvider.value; cerrar la hoja no cierra el bloc del shell. La agenda sigue siendo del día, no se presenta como una agenda semanal implementada para el cuidador.

Las rutas de los cuatro puntos anteriores son relativas a lib/features/family_monitoring. Se usan los cinco SVG originales de campana, agenda, historial, contacto y medidor en sus dimensiones lógicas de 22x22 y 112x84. El resplandor SVG contiene un filtro no soportado por flutter_svg; se exporta solo esa decoración a PNG transparente a escala 2 (632x772, visible como 316x386 por el recorte del marco original). No se rasterizan tarjetas ni controles. Los recursos quedan locales, sin URLs temporales productivas. Se conservan iniciales dinámicas porque el perfil no ofrece una fotografía.

Los textos secundarios mantienen contraste sobre fondos claros y las superficies crecen con el texto. La próxima dosis usa hora de doce horas en el idioma seleccionado. Se revisan el PNG con desenfoque real, las cinco posiciones de los SVG, la barra inferior seleccionada y la ausencia de recortes en texto ampliado. Los controles táctiles nativos y el contenido adicional producen pequeñas diferencias proporcionales respecto al mockup.

### Evidencia y continuidad

Se añaden dos renders de referencia y tres regresiones de navegación: todos los resultados de la agenda, legibilidad con texto ampliado y pérdida de permiso sin conservar la dosis previa. Se conservan las pruebas de inventario, consentimiento, contacto, edición del perfil y regreso de otros recorridos. La verificación de este corte no equivale a una ejecución nueva en Render, Spring ni teléfono físico.

Verificación: 728 pruebas en la suite integrada y 105 de Family Monitoring/app tras reforzar la pérdida de acceso; análisis sin incidencias, formato limpio en 471 archivos y APK debug construido correctamente. La suite global conserva un aviso de filtro SVG ajeno al resumen: history_glow_blue.svg, onboarding_glow_blue.svg, onboarding_glow_warm.svg y dose_success.svg contienen filtros que requieren revisión en sus recorridos. El resumen ya utiliza su PNG de desenfoque y sus capturas no muestran ese aviso.

El inventario permanece en 69 variantes representadas y pasa a 38 aceptadas visualmente. Continúan pendientes el contraste específico de Alertas y su detalle, ampliar el recorrido semanal del cuidador, la vista Landing - Value & Features y las integraciones ya registradas. El informe académico, backend, Android nativo, main y develop no se modifican.

## Alertas y prioridad de seguimiento (18-11-2026)

Se consulta el remoto antes del corte y no hay commits nuevos sobre temp 622c1a7. Se contrasta Alertas con Figma 563:819 y se revisan capturas con fuentes productivas en 393x883 y 360x640, texto normal/150 %. Se conservan controles Flutter nativos, superficies que crecen con el texto y el contraste de etiquetas secundarias. Se acepta proporcionalmente esta variante; el detalle 563:918 conserva su revisión visual específica abierta.

### Responsabilidades y contrato

- domain/value_objects/alert_severity.dart representa UNKNOWN, STANDARD, HIGH y CRITICAL. infrastructure/mappers/monitoring_mapper.dart lee la clasificación recibida; un backend anterior sin el campo produce UNKNOWN. Un valor inválido se rechaza. El cliente no deduce prioridad por antigüedad ni riesgo médico.
- presentation/widgets/alert_timeline_card.dart compone tarjetas con Material, InkWell, Row, Column y Wrap. presentation/screens/alerts_screen.dart aporta los datos reales, nombre del familiar, fecha localizada, filtros y acciones distintas de alerta y dosis. El diálogo de dosis es de consulta del cuidador. La hora de confirmación procede de confirmedAt; cuando no existe se identifica expresamente la hora programada.
- presentation/bloc/alerts/alerts_bloc.dart incluye las pendientes vencidas sin alerta asociada y evita duplicarlas cuando ya tienen alerta. Las omitidas sin alerta siguen visibles. CRITICAL atendida permanece en el contador hasta el cierre. La lectura periódica de la pantalla visible consulta la prioridad actual del servidor, no solapa otra lectura periódica, se detiene en segundo plano y no insiste tras perder acceso.
- El aviso verde requiere ausencia comprobada de alertas críticas y clasificación disponible. La evidencia desconocida muestra prioridad por verificar. Las tarjetas conservan su estado pendiente aunque la prioridad sea STANDARD; atender y cerrar siguen siendo acciones diferentes.

Las rutas anteriores son relativas a lib/features/family_monitoring. Se incorporan seis SVG originales para los iconos de Alertas, con slots de 22/24 y 6 píxeles. alerts_botanical.png conserva la fuente original de 70x86 y se muestra a 58x72; ampliar ese archivo no añadiría resolución. Solo el resplandor decorativo 563:822 se exporta aislado a PNG transparente 582x752 a escala 2. No se convierten textos, tarjetas ni botones en imágenes.

### Backend y evidencia

Family Monitoring obtiene la prioridad mediante su puerto AlertSeverityPort y el facade publicado por Omission & Escalation. Se usa el máximo nivel de escalamiento persistido: 0 STANDARD, 1/2 HIGH, 3 CRITICAL; sin caso asociado, UNKNOWN. Es prioridad operativa de seguimiento, no valoración clínica. La consulta se limita al adulto autorizado, agrupa identificadores en lotes y no añade columnas. Estado, detalle y recibos de atender/cerrar publican el mismo campo. La prioridad histórica permanece al cerrar, pero la alerta cerrada deja de integrar las abiertas.

Las pruebas con Spring/H2 y HTTP cubren persistencia real, alcance entre adultos, actualización del escalamiento y estados atendido/cerrado. El backend completa 1.087 pruebas sin fallos y genera el paquete. Se publica desde fix/backend-architecture, conservando los mensajes minor changes y propagando a develop, release/v1.1.0 y main; los tags existentes v1.1.0 y v2.0.0 apuntan al nuevo main 7c8f79a. El worktree local antiguo de develop y sus borradores se conservan. Esta publicación no acredita por sí sola el despliegue de Render ni una ejecución en teléfono físico.

Family Monitoring pasa 103 pruebas, incluida la recepción de una prioridad nueva con la pantalla abierta, la pausa al salir y el cese de consultas tras ACCESS_DENIED. Se verifican también contratos anteriores sin severity, valores inválidos, filtros, confirmaciones y navegación. La suite completa Flutter pasa 742 pruebas y el análisis final no reporta incidencias; el formato queda limpio en 471 archivos. El APK debug compila con los avisos existentes de herramientas Android/Kotlin. El inventario queda en 69 variantes representadas y 39 aceptadas visualmente. Continúan la revisión del detalle de alertas, cuatro recursos SVG con filtros ya registrados, agenda semanal del cuidador, Landing - Value & Features y las integraciones pendientes del inventario. Android nativo conserva compatibilidad con el campo aditivo; este corte no añade allí su representación visual. El informe académico no se modifica.

## Detalle de Alertas y continuidad del CI (18-11-2026)

Sobre temp 3c8ffd3 se consulta Figma 563:918 y se implementa la tarjeta de medicamento, perfil con inicial dinámica, línea de tiempo registrada y superficie de acciones. Ver perfil y la barra inferior vuelven al shell existente; una prueba verifica que no dejan una ruta de detalle duplicada. El menú superior ofrece cerrar alerta con confirmación y respeta el envío en curso. Atender, contactar y agregar nota conservan sus recibos y errores. La información técnica y la prioridad del servidor quedan consultables en una sección desplegable.

presentation/widgets/alert_detail_cards.dart agrupa las superficies, etiqueta de estado, hero y línea de tiempo del detalle; screens/alert_detail_screen.dart conserva composición y acciones. Las rutas son relativas a lib/features/family_monitoring. El histórico solo muestra eventos recibidos, ordenados por su instante real. No crea recordatorios adicionales ni sustituye la fecha de programación por una hora ficticia. La dosis se obtiene de la consulta autorizada; si no está disponible, no se inventa una cantidad. El retrato de ejemplo no sustituye datos del perfil.

alert_tablet.png es el original de 248x248 a escala 2: se representa a 124x124 dentro del slot lógico de 88x88, con los márgenes de sombra del diseño. Los tres iconos originales conservan ancho/alto 22x22, trazos y colores; se retira únicamente el rectángulo blanco que ocupaba todo su fondo, comprobando que los elementos path permanecen idénticos. Son recursos vectoriales, no capturas de controles. La cabecera coloca la etiqueta de estado debajo del título para conservar palabras completas al ampliar el texto.

Se revisan los renders de 393x883 y 360x640, escala normal/150 %, y los controles siguen accesibles mediante desplazamiento. La suite global pasa 745 pruebas, incluidas tres regresiones nuevas de composición y navegación. El análisis global detecta un import sobrante, se retira y el análisis final del módulo y sus pruebas queda sin incidencias. El formato queda limpio y el APK debug compila, conservando los avisos existentes del entorno Android/Kotlin. El inventario conserva 69 variantes representadas y alcanza 40 aceptadas visualmente. El aviso global de filtros SVG corresponde a los cuatro recursos pendientes ya registrados, no a los iconos del detalle. La ejecución contra Render y teléfono físico sigue separada de esta evidencia local. El corte se publica en temp; no se modifica el informe ni main/develop de Flutter.

Se prioriza una corrección del CI del backend: el run 44361799769 falla porque los contextos Spring con create-drop compartían la base H2 llamada tata. application-test.properties utiliza ahora un identificador aleatorio por contexto, manteniendo el tiempo de espera de bloqueos. Se publica desde fix/backend-architecture 6e7ab8c a develop y release/v1.1.0, con main daae868 y los mismos tags. Los runs 44363642463 (main) y 44363642695 (develop) terminan correctamente. La suite local fuerza una caché de dos contextos para ejercitar su cierre y pasa las 1.087 pruebas sin fallos ni errores. Esta corrección afecta solo al aislamiento de pruebas, no a la base de producción ni al contrato móvil.

## Agenda semanal y selección de fecha (18-11-2026)

Sobre temp 685b66f se consulta Figma 563:500 y se revisan renders de 393x883 y 360x640, con texto normal/150 %. La cabecera conserva título, intervalo y calendario; los siete días, las tarjetas de toma, el consejo y la barra se componen con widgets nativos. Las superficies crecen con el contenido y el desplazamiento mantiene accesibles las tomas y el consejo. El miércoles usa la abreviatura del idioma del dispositivo, sin copiar una inicial ambigua del ejemplo.

- intake_execution/presentation/screens/agenda_screen.dart abre showDatePicker en la fecha seleccionada. Cancelar no envía cambios. La selección confirmada se comunica mediante AgendaDaySelected; las flechas y su evento específico se retiran. El intervalo distingue los meses y añade año cuando corresponde. AlwaysScrollableScrollPhysics permite recargar también una semana corta o vacía.
- presentation/bloc/agenda/agenda_bloc.dart selecciona localmente dentro de la semana ya leída y solicita otra semana cuando la fecha queda fuera. Conserva el descarte de respuestas antiguas. GetWeekAgenda sigue usando lunes incluido y lunes siguiente excluido, con fechas locales convertidas a UTC. Se contrasta el handler vigente del backend: lectura autorizada con un intervalo máximo de ocho días, sin generar datos al navegar a otra fecha.
- presentation/navigation/agenda_route.dart presta al screen el destino de Notas. app/integration/adult_entry_route.dart vuelve al shell y abre las notas propias existentes; al regresar no queda una segunda agenda debajo. La prueba del host recorre Inicio, Agenda, Notas y regreso, y conserva el acceso anterior desde Más.

Las dos primeras rutas de presentación pertenecen a lib/features/intake_execution. Los cuatro SVG locales de calendario, mañana, noche y consejo conservan sus slots de 22x22. En mañana y noche se retira únicamente el rectángulo opaco del fondo, manteniendo idénticos los path; no se cambian los iconos compartidos de otras vistas aceptadas. Los degradados y marcas se dibujan con Material, Ink y widgets; los estados confirmado, pendiente, tardío, omitido y por enviar proceden del modelo, sin confirmaciones decorativas. Los tintes por hora solo organizan visualmente el día.

Pasan cuatro pruebas nuevas: cancelación y selección de otro mes, respuestas de semanas fuera de orden y dos renders. La suite integrada pasa 749 pruebas y el formato queda limpio en 473 archivos. Tras corregir dos avisos de llaves, el análisis final de Intake, su integración y pruebas queda sin incidencias. El APK debug compila con los avisos existentes de herramientas Android/Kotlin. El inventario conserva 69 variantes representadas y alcanza 41 aceptadas visualmente. La consulta pública a v3/api-docs en Render agota sus 30 segundos de espera y no se registra como evidencia desplegada. El backend y el informe no se modifican; no se atribuye al cambio una nueva ejecución física o contra Render.

## Notas propias y recibos visibles (18-11-2026)

Sobre temp 1aeea68 se consulta Figma 576:2785 y se revisan renders de 393x883 y 360x640, con texto normal/150 %. La cabecera incluye el botón más, los filtros conservan ancho intrínseco y las notas se distribuyen entre Hoy y Notas recientes según su instante real. Las tarjetas de hoy usan el marcador circular; las recientes alternan superficies blanca y azul. No se copian los ejemplos de notas al contenido productivo ni se dibuja la línea vertical ajena al contenido de notas que conserva el frame.

- family_monitoring/presentation/screens/personal_notes_screen.dart compone cabecera, filtros, grupos y formulario. El reloj permite agrupar por calendario local sin alterar recordedAt. El formulario conserva campos y categoría al fallar. Los dos accesos a crear se deshabilitan durante la lectura inicial o el guardado y después de perder acceso.
- presentation/widgets/personal_note_card.dart representa título, texto y fecha sin recortar el contenido. Hoy y Ayer se calculan como fechas locales; el resto usa día de la semana reciente o fecha completa. El círculo y su punto se dibujan con widgets; la barra reutiliza el componente adulto existente. Las tarjetas no se rasterizan.
- presentation/bloc/personal_notes/personal_notes_bloc.dart ordena las notas visibles por recordedAt e identificador, sin mutar el resultado del repositorio. Un recibo válido conserva el resto de notas y vuelve al filtro Todas para que la nueva nota no quede oculta. El aviso Nota guardada depende de la transición de guardado reconocida, no del toque del botón.
- La recarga espera a que termine la lectura protegida y conserva las tarjetas conocidas mientras llega la respuesta. Si la lista falla pero después se reconoce una creación, la nota aparece junto al aviso de lista incompleta; no se convierte el conjunto conocido en una lista supuestamente completa. La denegación de sesión mantiene el borrado de datos y ofrece Ingresar con PIN.

Las rutas abreviadas de presentación son relativas a lib/features/family_monitoring. MonitoringFilterChip admite un tamaño de texto opcional y MonitoringError una etiqueta de acción opcional; sus valores predeterminados mantienen las vistas anteriores. No cambia el contrato de list/create ni el backend. Se añaden seis pruebas: dos renders, filtro tras crear, recibo con lista incompleta, duración real de la recarga y cierre con Atrás. La última reproduce la pantalla de notas como una ruta real: el reinicio de composición solo cierra el diálogo si sigue siendo la ruta actual, evitando un segundo pop sobre la pantalla. Se conservan las regresiones de texto tras un fallo y salida por pérdida de sesión. El inventario queda en 69 variantes representadas y 42 aceptadas visualmente. La evidencia del corte es local, separada de Render y teléfono físico.

Verificación final: 755 pruebas en la suite completa, análisis del módulo y sus pruebas sin incidencias después de retirar un import sobrante, formato limpio y APK debug construido. Se conservan los avisos conocidos de filtros SVG y del entorno Android/Kotlin.

## Variantes de seguimiento y pérdida de acceso (18-11-2026)

Sobre temp 3b8d0b8 se consultan Figma 563:4145, 563:4245 y 563:4345. Se revisan seis renders: tres estados en 393x883 y tres composiciones con texto 150 % en 360x640, desplazadas hasta las acciones. El detalle conserva los recursos originales ya registrados; los datos personales y la dosis proceden de los puertos, sin sustituirlos por la fotografía o los textos de ejemplo.

- presentation/screens/alert_detail_screen.dart dibuja Contacto no disponible como botón deshabilitado y el recibo Atendida con contraste verde. Nota guardada permanece en la tarjeta solo cuando NoteComposerState contiene una nota reconocida; el botón más permite otra nota. Se suprime el mensaje flotante duplicado en este detalle. Una denegación del guardado invalida el detalle y retira el borrador; la denegación de una lectura también limpia el compositor.
- presentation/widgets/follow_up_note_dialog.dart conserva un DialogRoute propio en NoteComposerHost. Solo cierra esa ruta, incluso si está cubierta por otra, y sincroniza el cierre mediante Atrás con el cubit para permitir reabrir. El formulario admite desplazamiento con texto ampliado. El comportamiento predeterminado del aviso de guardado se conserva para NotesScreen, que no representa el recibo en línea.
- presentation/bloc/alert_detail/alert_detail_bloc.dart recibe AlertDetailAccessLost. Los recibos de cambio y la relectura por conflicto verifican la revisión antes de emitir, de modo que una respuesta anterior no restaura alerta, persona, dosis, contacto ni eventos después de la denegación.
- presentation/navigation/family_monitoring_navigation.dart propaga ACCESS_DENIED al resumen y limpia también el compositor compartido del shell. Atender y cerrar siguen siendo estados diferentes; el corte no altera la clasificación de prioridad ni da por resuelta una alerta crítica al atenderla.

Las rutas son relativas a lib/features/family_monitoring. Diez pruebas nuevas cubren los seis renders, reapertura tras Atrás, denegación del guardado y dos respuestas tardías (mutación y relectura por conflicto). La suite completa pasa 765 pruebas; el análisis global termina sin incidencias, el formato queda limpio y el APK debug compila con los avisos existentes de herramientas Android/Kotlin. El inventario conserva 69 variantes representadas y alcanza 45 aceptadas visualmente. La evidencia corresponde a widgets y estado con repositorios de prueba; no acredita una nueva operación contra Render o dispositivo. No se modifica backend ni informe.

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
