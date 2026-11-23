# Implementation inventory

Este inventario conserva los destinos y responsabilidades del plan de desarrollo. No acredita la existencia de cada archivo ni sustituye la estructura real del código. Al normalizar un contexto se actualizan sus rutas y consumidores conjuntamente.

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
| `lib/features/family_monitoring/presentation/screens/notes_screen.dart` | Componer cabecera, perfil, línea temporal y creación; esperar recarga y retirar editor tras revocación. |
| `lib/features/family_monitoring/presentation/widgets/follow_up_note_card.dart` | FollowUpPersonCard muestra perfil autorizado y edad; FollowUpNoteCard presenta texto original, fecha y autor del seguimiento propio. |
| `test/family_monitoring/caregiver_notes_visual_test.dart` | Comprobar renders, recarga completa, denegación de perfil y recibos tardíos tras revocación. |
| `lib/features/family_monitoring/presentation/screens/personal_notes_screen.dart` | Controles Flutter y variantes equivalentes de personal_notes, con estados y opciones reales. |
| `lib/features/adherence_analytics/presentation/bloc/adherence/adherence_bloc.dart` | Orquestar acciones/carga y descartar respuestas obsoletas: adherence. |
| `lib/features/adherence_analytics/presentation/bloc/adherence/adherence_event.dart` | Intenciones y entradas explícitas del flujo: adherence. |
| `lib/features/adherence_analytics/presentation/bloc/adherence/adherence_state.dart` | Estado inmutable de datos/carga/error/submitting sin secretos: adherence. |
| `lib/features/adherence_analytics/presentation/screens/adherence_history_screen.dart` | Controles Flutter y variantes equivalentes de adherence_history, con estados y opciones reales. |
| `lib/features/adherence_analytics/presentation/widgets/adherence_trend_chart.dart` | Dibujar puntos y área con fechas proporcionales; adaptar cabecera y densidad del eje al texto. |
| `lib/features/adherence_analytics/presentation/widgets/history_cards.dart` | Componer métricas, patrón y tomas recientes; mantener las cifras legibles al ampliar texto. |
| `test/adherence_analytics/presentation/history_visual_variants_test.dart` | Verificar el selector real, respuestas de ambos periodos y renders normal, 150 % y 195 %. |
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


## Distribución actual de responsabilidades públicas

Cada archivo agrupa una operación pública o una familia cohesiva. Los tipos de entrada, resultado y estado asociados permanecen con su operación cuando no tienen otro consumidor independiente.

| Archivo | Responsabilidad pública |
| --- | --- |
| `lib/features/accessibility_preferences/application/ports/accessibility_local_store.dart` | `AccessibilityLocalStore` |
| `lib/features/accessibility_preferences/application/ports/application_language_store.dart` | `ApplicationLanguageStore` |
| `lib/features/accessibility_preferences/application/ports/user_preferences_remote.dart` | `UserPreferencesRemote` |
| `lib/features/accessibility_preferences/application/ports/user_preferences_repository.dart` | `UserPreferencesRepository` |
| `lib/features/accessibility_preferences/application/usecases/observe_accessibility.dart` | `ObserveAccessibility` |
| `lib/features/accessibility_preferences/application/usecases/observe_application_language.dart` | `ObserveApplicationLanguage` |
| `lib/features/accessibility_preferences/application/usecases/sync_user_preferences.dart` | `SyncUserPreferences` |
| `lib/features/accessibility_preferences/application/usecases/update_accessibility.dart` | `UpdateAccessibility` |
| `lib/features/accessibility_preferences/application/usecases/change_application_language.dart` | `ChangeApplicationLanguage` |
| `lib/features/accessibility_preferences/application/usecases/get_notification_preferences.dart` | `GetNotificationPreferences` |
| `lib/features/accessibility_preferences/application/usecases/update_notification_preferences.dart` | `UpdateNotificationPreferences` |
| `lib/features/accessibility_preferences/application/usecases/update_notification_policy.dart` | `UpdateNotificationPolicy` |
| `lib/features/family_monitoring/application/ports/family_monitoring_repository.dart` | `FamilyMonitoringRepository` |
| `lib/features/family_monitoring/application/ports/alert_timeline_reader.dart` | `AlertTimelineReader` |
| `lib/features/family_monitoring/application/ports/alert_history_reader.dart` | `AlertHistoryReader` |
| `lib/features/family_monitoring/application/ports/monitored_dose_reader.dart` | `MonitoredDoseReader` |
| `lib/features/family_monitoring/application/ports/monitored_person_reader.dart` | `MonitoredPersonReader` |
| `lib/features/family_monitoring/application/ports/contact_option_reader.dart` | `ContactOptionReader` |
| `lib/features/family_monitoring/application/readmodels/family_summary.dart` | `OpenAlert`, `StockAttention`, `FamilySummary` |
| `lib/features/family_monitoring/application/readmodels/intake_history_entry.dart` | `IntakeHistoryOutcome`, `IntakeHistoryEntry` |
| `lib/features/family_monitoring/application/readmodels/recorded_alert_event.dart` | `RecordedAlertEventType`, `RecordedAlertEvent` |
| `lib/features/family_monitoring/application/readmodels/monitored_dose.dart` | `MonitoredDose` |
| `lib/features/family_monitoring/application/readmodels/monitored_person.dart` | `MonitoredPerson` |
| `lib/features/family_monitoring/application/readmodels/alert_timeline.dart` | `AlertTimeline` |
| `lib/features/family_monitoring/application/readmodels/contact_option.dart` | `ContactOption` |
| `lib/features/family_monitoring/application/usecases/get_open_alerts.dart` | `GetOpenAlerts` |
| `lib/features/family_monitoring/application/usecases/get_alert_detail.dart` | `GetAlertDetail` |
| `lib/features/family_monitoring/application/usecases/update_alert_status.dart` | `UpdateAlertStatus` |
| `lib/features/family_monitoring/application/usecases/get_alert_timeline.dart` | `GetAlertTimeline` |
| `lib/features/family_monitoring/application/policies/alert_ordering.dart` | `compareAlerts` |
| `lib/features/family_monitoring/application/usecases/get_follow_up_notes.dart` | `GetFollowUpNotes` |
| `lib/features/family_monitoring/application/usecases/register_follow_up_note.dart` | `RegisterFollowUpNote` |
| `lib/features/family_monitoring/application/usecases/get_personal_notes.dart` | `GetPersonalNotes` |
| `lib/features/family_monitoring/application/usecases/create_personal_note.dart` | `CreatePersonalNote` |
| `lib/features/family_monitoring/application/usecases/get_family_summary.dart` | `GetFamilySummary` |
| `lib/features/family_monitoring/application/usecases/get_family_history.dart` | `GetFamilyHistory` |
| `lib/features/family_monitoring/application/usecases/get_contact_option.dart` | `GetContactOption` |
| `lib/features/family_monitoring/domain/repositories/alerts_repository.dart` | `AlertsRepository` |
| `lib/features/family_monitoring/domain/repositories/contact_repository.dart` | `ContactRepository` |
| `lib/features/family_monitoring/domain/repositories/notes_repository.dart` | `NotesRepository` |
| `lib/features/family_monitoring/domain/repositories/personal_notes_repository.dart` | `PersonalNotesRepository` |
| `lib/features/identity_subscription/application/usecases/get_public_plans.dart` | `GetPublicPlans` |
| `lib/features/identity_subscription/application/usecases/apply_chosen_plan.dart` | `ApplyChosenPlan` |
| `lib/features/identity_subscription/application/usecases/get_subscription_overview.dart` | `GetSubscriptionOverview` |
| `lib/features/identity_subscription/application/usecases/change_subscription_plan.dart` | `ChangeSubscriptionPlan` |
| `lib/features/intake_execution/application/ports/intake_confirmation.dart` | `IntakeConfirmation` |
| `lib/features/intake_execution/application/ports/intake_confirmation_replay.dart` | `IntakeConfirmationReplay` |
| `lib/features/intake_execution/application/ports/voice_confirmation.dart` | `VoiceConfirmation` |
| `lib/features/intake_execution/application/ports/phrase_speaker.dart` | `PhraseSpeaker` |
| `lib/features/inventory_replenishment/application/usecases/get_inventory.dart` | `GetInventory` |
| `lib/features/inventory_replenishment/application/usecases/register_initial_inventory.dart` | `RegisterInitialInventory` |
| `lib/features/inventory_replenishment/application/usecases/register_replenishment.dart` | `RegisterReplenishment` |
| `lib/features/omission_escalation/application/ports/device_push_token_source.dart` | `DevicePushTokenSource` |
| `lib/features/omission_escalation/application/ports/device_token_registry.dart` | `DeviceTokenRegistry` |
| `lib/features/omission_escalation/application/ports/push_target_store.dart` | `PushTargetStore` |
| `lib/features/omission_escalation/application/ports/omission_notifier.dart` | `OmissionNotifier` |
| `lib/features/omission_escalation/application/usecases/resolve_push_destination.dart` | `ResolvePushDestinationQuery`, `ResolvePushDestination` |
| `lib/features/omission_escalation/application/usecases/follow_caregiver_alerts.dart` | `FollowCaregiverAlerts` |
| `lib/features/omission_escalation/application/usecases/follow_dose_reminders.dart` | `FollowDoseReminders` |
| `lib/features/omission_escalation/application/usecases/handle_incoming_omission_push.dart` | `HandleIncomingOmissionPush` |
| `lib/features/omission_escalation/application/failure_codes.dart` | `invalidFollowUpReference` |
| `lib/features/treatment_management/application/ports/treatment_reader.dart` | `TreatmentReader` |
| `lib/features/treatment_management/application/ports/my_medications_reader.dart` | `MyMedicationsReader` |
| `lib/features/treatment_management/application/readmodels/my_medications_overview.dart` | `MyMedication`, `MedicationNextDose`, `MyMedicationsOverview` |
| `lib/features/treatment_management/application/readmodels/treatment_detail.dart` | `TreatmentDetail` |
| `lib/features/treatment_management/application/usecases/register_medication.dart` | `RegisterMedication` |
| `lib/features/treatment_management/application/usecases/list_medications.dart` | `ListMedications` |
| `lib/features/treatment_management/application/usecases/update_medication.dart` | `UpdateMedication` |
| `lib/features/treatment_management/application/usecases/deactivate_medication.dart` | `DeactivateMedication` |
| `lib/features/treatment_management/application/usecases/reactivate_medication.dart` | `ReactivateMedication` |
| `lib/features/treatment_management/application/policies/medication_fields.dart` | `maxMedicationFieldLength`, `medicationFieldsTooLong` |
| `lib/features/treatment_management/application/usecases/set_dose_frequency.dart` | `RegimenBasics`, `SetDoseFrequency` |
| `lib/features/treatment_management/application/usecases/set_schedule_instructions.dart` | `ScheduleInstructions`, `SetScheduleInstructions` |
| `lib/features/treatment_management/application/usecases/set_reminder_policy.dart` | `SetReminderPolicy` |
| `lib/features/treatment_management/application/usecases/configure_treatment.dart` | `RegimenDraft`, `ConfigureTreatment` |
| `lib/features/treatment_management/application/usecases/change_treatment_status.dart` | `TreatmentLifecycleAction`, `ChangeTreatmentStatus` |
| `lib/features/treatment_management/application/usecases/create_treatment.dart` | `CreateTreatment` |
| `lib/features/treatment_management/application/usecases/list_treatments.dart` | `ListTreatments` |
| `lib/features/treatment_management/application/usecases/get_treatment_detail.dart` | `GetTreatmentDetail` |
| `lib/features/treatment_management/application/usecases/get_my_medications_overview.dart` | `GetMyMedicationsOverview` |
| `lib/features/treatment_management/domain/repositories/treatment_repository.dart` | `TreatmentRepository` |
| `lib/features/treatment_management/domain/repositories/medication_management_repository.dart` | `MedicationManagementRepository` |
| `lib/features/treatment_management/domain/repositories/treatment_lifecycle_repository.dart` | `TreatmentLifecycleRepository` |
