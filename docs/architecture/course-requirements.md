# Course requirements

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
