# Bounded contexts

La aplicación organiza sus nueve contextos en `lib/features/`. Los nombres de archivos de esta tabla son referencias de responsabilidad; el inventario de desarrollo identifica los destinos previstos.


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
