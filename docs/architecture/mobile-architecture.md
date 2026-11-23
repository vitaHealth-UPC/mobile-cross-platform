# Mobile architecture

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

## Ubicación de responsabilidades


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


## Servicios de plataforma compartidos

`shared/infrastructure/firebase/FirebaseRuntime` coordina la inicialización nativa entre identidad y mensajería. `shared/infrastructure/notifications/LocalNotificationPlatform` posee el callback del plugin y ofrece cancelación por canal o payload. Los contextos conservan sus permisos, contenido y reglas de navegación; estas utilidades no autorizan acceso clínico.
