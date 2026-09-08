class VisitedCountry {
  const VisitedCountry({
    required this.id,
    required this.name,
    required this.code,
    this.cities = const [],
  });

  final String id;
  final String name;
  final String code;
  final List<VisitedCity> cities;
}

class VisitedCity {
  const VisitedCity({required this.id, required this.name});
  final String id;
  final String name;
}

class TravelFootprint {
  const TravelFootprint(this.countries);
  final List<VisitedCountry> countries;
  int get cityCount =>
      countries.fold(0, (sum, item) => sum + item.cities.length);
  int get countryCount => countries.length;
  double get worldPercent => countryCount / 195 * 100;
}
