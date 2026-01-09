enum SpanishDialect {
  castilian('Castilian Spanish', 'Spain'),
  mexican('Mexican Spanish', 'Mexico'),
  colombian('Colombian Spanish', 'Colombia'),
  argentine('Argentine Spanish', 'Argentina'),
  chilean('Chilean Spanish', 'Chile'),
  peruvian('Peruvian Spanish', 'Peru'),
  venezuelan('Venezuelan Spanish', 'Venezuela'),
  cuban('Cuban Spanish', 'Cuba');

  final String name;
  final String country;

  const SpanishDialect(this.name, this.country);

  @override
  String toString() => name;
}
