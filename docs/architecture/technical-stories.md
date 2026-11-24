# Technical story integration map

Las TS conservan sus identificadores del catálogo de producto. En Flutter identifican el consumidor móvil y sus adaptadores; no trasladan procesos de Spring al dispositivo. Cada rama referencia commits originales, con sus autores e historia intactos. Los commits que implementan varias US o TS mantienen ese alcance compartido.

| Rama | Corte original | Responsabilidad Flutter |
| --- | --- | --- |
| `feature/ts-01-pin-backend-integration` | `b2493b3` | PIN y sesión del adulto |
| `feature/ts-02-care-link-backend-integration` | `ce70f0d` | Perfiles, vínculo y consentimiento |
| `feature/ts-03-treatment-backend-integration` | `8735ece` | Medicamentos, pauta y ciclo del tratamiento |
| `feature/ts-04-intake-confirmation-integration` | `6d2d8ab` | Confirmación táctil y recibos |
| `feature/ts-06-push-integration` | `e6fdb40` | Registro y política; fuente FCM preparada, recepción completa en desarrollo |
| `feature/ts-07-identity-backend-integration` | `65c95b4` | Sesión Tata, cuenta y acceso social |
| `feature/ts-08-agenda-backend-integration` | `6d2d8ab` | Consulta de la agenda generada por el servidor |
| `feature/ts-09-monitoring-backend-integration` | `efc6d20` | Resumen familiar, alertas, contacto y notas |
| `feature/ts-10-adherence-backend-integration` | `341810e` | Proyecciones de adherencia, historial y recomendaciones |
| `feature/ts-11-voice-integration` | `ca0faf9` | Grabación y contrato de confirmación hablada |
| `feature/ts-12-inventory-backend-integration` | `270a898` | Stock y reposición |
| `feature/ts-13-offline-sync` | `03d2c86` | Persistencia Drift y sincronización por propietario |
| `feature/ts-14-subscription-backend-integration` | `564466a` | Planes y suscripción de la cuenta |

TS-05 corresponde al proceso automático de tomas sin confirmar del backend. Flutter consume sus resultados y no ejecuta un segundo clasificador clínico. TS-08 conserva la generación de agenda en el servidor; su rama móvil documenta la integración de lectura. TS-06 tiene adaptadores en desarrollo y no acredita entrega push remota completa.

Las ramas TS complementan las 45 ramas US. El Sprint Backlog identifica la selección de trabajo, sus tareas y aceptación por plataforma. Los cortes históricos se integraron en el flujo publicado; estas referencias identifican su responsabilidad sin fabricar commits o fechas. Las modificaciones funcionales nuevas incorporan sus merges en la siguiente integración de `temp`, `develop`, release y `main`.
