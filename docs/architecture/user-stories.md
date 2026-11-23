# User stories

Flutter implementa las mismas historias de producto US-01 a US-45 del cliente Android. El Product Backlog conserva los identificadores, actores y objetivos; la aceptación identifica la plataforma cubierta. El nuevo Sprint Backlog selecciona esas historias y descompone el trabajo de Flutter en tareas verificables.

El enunciado 202620 presenta un Product Backlog con estimación, prioridad y sprint (p. 16), una sección por sprint (p. 25) y un Sprint Backlog con historias seleccionadas y sus tareas (p. 28). No exige duplicar el Product Backlog ni repetir literalmente las tareas técnicas de Android. AV2 corresponde al Sprint 2 y TB2 al Sprint 3 (pp. 34-35).

Las TS conservan sus identificadores cuando el catálogo establece una misma tarea aplicable a ambos clientes; las tareas específicas de plataforma describen widgets, BLoC, persistencia y pruebas Flutter. El trabajo completado en Android no acredita automáticamente aceptación en Flutter. La selección y estimación del sprint se registran con el equipo, sin inventar retrospectivamente fechas o esfuerzos.

Los commits originales y sus autores se conservan. Un commit que cubre varias historias mantiene ese alcance al integrar; las ramas no se utilizan para atribuir trabajo inexistente.

La asignación definitiva de `feature/us-xx-*` se contrasta con el catálogo del informe y los cambios reales antes de publicar ramas. `temp` reúne la integración actual; `develop`, la release y `main` reciben los cambios validados.

La aceptación de una historia requiere comportamiento por actor, errores, permisos, persistencia cuando corresponda y revisión visual. El mapa Figma mide variantes y no sustituye esta aceptación.


## Catálogo funcional compartido

| Story | Capability | Flutter context | Integration or output |
| --- | --- | --- | --- |
| US-01 | Older-adult PIN setup and access | `identity_subscription` | PIN credentials, PIN sessions |
| US-02 | Caregiver/adult linking | `care_link` | Link code and care-link acceptance |
| US-03 | Register medication | `treatment_management` | Medication creation |
| US-04 | Edit and deactivate medication | `treatment_management` | Medication update and lifecycle |
| US-05 | Scheduled dose reminder | `intake_execution` | Next intake and reminder presentation |
| US-06 | Touch or voice dose confirmation | `intake_execution` | Idempotent backend confirmation |
| US-07 | Missed-dose alert | `omission_escalation` / `family_monitoring` | Notification routing and alert display |
| US-08 | Weekly adherence summary | `adherence_analytics` | Adherence summary API |
| US-09 | Recurring omission patterns | `adherence_analytics` | Backend insight resources |
| US-10 | Caregiver registration | `identity_subscription` | Account registration |
| US-11 | Email verification | `identity_subscription` | Verification requests and confirmation |
| US-12 | Older-adult profile | `care_link` | Adult profile registration and editing |
| US-13 | Care consent | `care_link` | Care-link consent and withdrawal |
| US-14 | Create treatment | `treatment_management` | Treatment creation |
| US-15 | Configure dose/frequency | `treatment_management` | Regimen configuration |
| US-16 | Configure schedule/instructions | `treatment_management` | Regimen configuration |
| US-17 | Configure treatment reminders | `treatment_management` | Reminder lead and follow-up delay |
| US-18 | Activate or pause treatment | `treatment_management` | Treatment lifecycle operations |
| US-19 | Treatment detail | `treatment_management` | Read treatment configuration and state |
| US-20 | Next scheduled dose | `intake_execution` | Next-intake query |
| US-21 | Dose detail by outcome | `intake_execution` | Intake detail and mapped UI status |
| US-22 | Reinforced reminder | `intake_execution` / `omission_escalation` | Pending-intake UI and notification routing |
| US-23 | Late dose confirmation | `intake_execution` | Backend late/omitted distinction |
| US-24 | Daily and weekly agenda | `intake_execution` | Time-zone-aware agenda query |
| US-25 | Recent family-care status | `family_monitoring` | Caregiver status resource |
| US-26 | Recent intake history | `family_monitoring` / `adherence_analytics` | History resources and adherence views |
| US-27 | Alert detail | `family_monitoring` | Protected alert detail |
| US-28 | Notification preferences | `accessibility_preferences` | Channel and policy configuration |
| US-29 | Contact from an alert | `family_monitoring` | Contact-channel API and device launcher |
| US-30 | Caregiver follow-up note | `family_monitoring` | Follow-up note API |
| US-31 | Alert follow-up status | `family_monitoring` | Alert status transition |
| US-32 | Adherence history by period | `adherence_analytics` | Summary and trend queries |
| US-33 | Late/omitted classification | `adherence_analytics` | Read authoritative intake outcomes |
| US-34 | Adherence recommendations | `adherence_analytics` | Insights and recommendation presentation |
| US-35 | Text size | `accessibility_preferences` | Local/remote accessibility preference |
| US-36 | High contrast | `accessibility_preferences` | Local/remote contrast preference |
| US-37 | Reduced motion | `accessibility_preferences` | Local/remote motion preference |
| US-38 | Reading assistance | `accessibility_preferences` | Local/remote reading preference |
| US-39 | Quiet hours and channels | `accessibility_preferences` | Notification preference API |
| US-40 | Initial inventory | `inventory_replenishment` | Create stock record |
| US-41 | Stock balance | `inventory_replenishment` | Inventory query |
| US-42 | Low-stock indication | `inventory_replenishment` | Server low-stock flag and threshold |
| US-43 | Replenishment | `inventory_replenishment` | Register stock batch |
| US-44 | Current subscription | `identity_subscription` | Plans and account subscription |
| US-45 | Change subscription | `identity_subscription` | Update account plan |

## Ramas y contribuciones

Las 45 ramas `feature/us-*` usan la nomenclatura del cliente Android. Referencian los commits originales que incorporan cada capacidad; no certifican por sí solas toda su aceptación en Flutter. Los ajustes posteriores se integran desde `temp`.

Algunas historias se implementaron juntas en un mismo commit original. En esos casos comparten el corte: se conservan los hashes y autores sin dividir artificialmente la contribución. Los merges de integración se realizan ahora; no representan un desarrollo histórico independiente de cada rama. Las tareas transversales de caché y presentación pública tienen referencias técnicas separadas.

| Rama | Corte original | Autor del corte |
| --- | --- | --- |
| `feature/us-01-pin-access` | `b2493b3` | u202415820 |
| `feature/us-02-care-link` | `ce70f0d` | David Joel Morales Venegas |
| `feature/us-03-register-medication` | `8cce4df` | Eduardo |
| `feature/us-04-update-deactivate-medication` | `8cce4df` | Eduardo |
| `feature/us-05-dose-reminder` | `e604dd3` | u202415820 |
| `feature/us-06-dose-confirmation` | `ca0faf9` | u202415820 |
| `feature/us-07-missed-dose-alert` | `efc6d20` | Eduardo |
| `feature/us-08-weekly-adherence-summary` | `911a8a2` | u20241a195-cmd |
| `feature/us-09-recurring-omission-pattern` | `643caf1` | u20241a195-cmd |
| `feature/us-10-caregiver-registration` | `ce70f0d` | David Joel Morales Venegas |
| `feature/us-11-email-verification` | `cd772b4` | u202415820 |
| `feature/us-12-older-adult-profile` | `a0aa276` | u202415820 |
| `feature/us-13-care-consent` | `ce70f0d` | David Joel Morales Venegas |
| `feature/us-14-create-treatment` | `8cce4df` | Eduardo |
| `feature/us-15-dose-frequency` | `7c4b3a6` | David Joel Morales Venegas |
| `feature/us-16-schedule-instructions` | `7c4b3a6` | David Joel Morales Venegas |
| `feature/us-17-treatment-reminders` | `157acea` | David Joel Morales Venegas |
| `feature/us-18-treatment-activation-pause` | `157acea` | David Joel Morales Venegas |
| `feature/us-19-treatment-detail` | `157acea` | David Joel Morales Venegas |
| `feature/us-20-next-dose` | `b2493b3` | u202415820 |
| `feature/us-21-dose-detail` | `6d2d8ab` | u202415820 |
| `feature/us-22-reinforced-reminder` | `6b336c1` | u202415820 |
| `feature/us-23-late-dose-confirmation` | `6d2d8ab` | u202415820 |
| `feature/us-24-daily-schedule` | `6d2d8ab` | u202415820 |
| `feature/us-25-recent-care-status` | `efc6d20` | Eduardo |
| `feature/us-26-intake-history` | `341810e` | u20241a195-cmd |
| `feature/us-27-alert-detail` | `efc6d20` | Eduardo |
| `feature/us-28-notification-preferences` | `c9533e4` | Eduardo |
| `feature/us-29-alert-contact` | `efc6d20` | Eduardo |
| `feature/us-30-followup-note` | `efc6d20` | Eduardo |
| `feature/us-31-alert-followup` | `efc6d20` | Eduardo |
| `feature/us-32-adherence-history` | `341810e` | u20241a195-cmd |
| `feature/us-33-late-omitted-classification` | `341810e` | u20241a195-cmd |
| `feature/us-34-adherence-recommendations` | `341810e` | u20241a195-cmd |
| `feature/us-35-text-size` | `c9533e4` | Eduardo |
| `feature/us-36-high-contrast` | `c9533e4` | Eduardo |
| `feature/us-37-reduced-motion` | `c9533e4` | Eduardo |
| `feature/us-38-reading-assistance` | `c9533e4` | Eduardo |
| `feature/us-39-quiet-hours-channels` | `c9533e4` | Eduardo |
| `feature/us-40-initial-inventory` | `270a898` | u202415820 |
| `feature/us-41-stock-status` | `270a898` | u202415820 |
| `feature/us-42-low-stock-alert` | `e2c5d15` | u202415820 |
| `feature/us-43-restock` | `270a898` | u202415820 |
| `feature/us-44-current-plan` | `564466a` | u202415820 |
| `feature/us-45-change-subscription` | `564466a` | u202415820 |
| `feature/offline-confirmation-cache` | `03d2c86` | u202415820 |
| `feature/public-plans` | `a439d17` | u202415820 |
