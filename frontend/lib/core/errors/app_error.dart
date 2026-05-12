class AppError implements Exception {
  const AppError({
    required this.message,
    this.debugDetails,
  });

  final String message;
  final String? debugDetails;

  @override
  String toString() => message;
}
