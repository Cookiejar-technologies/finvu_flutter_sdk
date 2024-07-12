class FinvuConfig {
  FinvuConfig({
    required this.finvuEndpoint,
    this.certificatePins,
  });

  /// The endpoint of the Finvu API.
  String finvuEndpoint;

  /// The certificate pins to perform SSL pinning. These pins will need
  /// to be updated regularly.
  List<String>? certificatePins;
}
