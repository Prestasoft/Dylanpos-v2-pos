class FullReservation {
  final String id;
  final Map<String, dynamic> reservation;
  final Map<String, dynamic>? dress;
  final Map<String, dynamic>? service;

  FullReservation({
    required this.id,
    required this.reservation,
    this.dress,
    this.service,
  });
}
