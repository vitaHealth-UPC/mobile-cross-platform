# API contract guidelines

Los adaptadores convierten respuestas HTTP en contratos de aplicación. BLoC y dominio no consumen respuestas HTTP, DTO de transporte ni diagnósticos del proveedor. La sesión Tata autoriza las operaciones; una identidad Firebase por sí sola no concede acceso clínico.

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

## Validación

Cada operación comprueba payload, estado HTTP, propietario y recibo antes de actualizar la vista. Se distinguen carga, vacío, permiso denegado, error transitorio y confirmación. Las pruebas locales y la comprobación del servicio desplegado se registran por separado.
