/// Test fixtures mirror the adult catalog response, never production fallback data.
Map<String, Object?> catalogJson({
  String id = 'med-1',
  bool active = true,
  String status = 'ACTIVE',
}) => {
  'medication': {
    'id': id,
    'olderAdultId': 'adult-A',
    'name': id == 'med-1' ? 'Losartán 50 mg' : 'Vitamina D',
    'presentation': 'Comprimido',
    'active': active,
  },
  'treatments': [
    {
      'id': 'treatment-$id',
      'olderAdultId': 'adult-A',
      'medicationId': id,
      'name': 'Tratamiento de prueba',
      'status': status,
      'dose': '1 tableta',
      'frequency': 'DAILY',
      'scheduledTimes': ['08:00:00'],
      'instructions': 'Con el desayuno',
      'recurrenceZone': 'America/Lima',
    },
  ],
};
