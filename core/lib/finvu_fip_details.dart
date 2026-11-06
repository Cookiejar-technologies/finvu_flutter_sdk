class FinvuFIPDetails {
  FinvuFIPDetails({
    required this.fipId,
    required this.typeIdentifiers,
    this.linkingOtpLength,
  });
  String fipId;
  List<FinvuFIPFiTypeIdentifier> typeIdentifiers;
  int? linkingOtpLength;
}

class FinvuFIPFiTypeIdentifier {
  FinvuFIPFiTypeIdentifier({
    required this.fiType,
    required this.identifiers,
    this.allowedCombinations,
  });
  String fiType;
  List<FinvuTypeIdentifier> identifiers;
  List<List<FinvuTypeIdentifier>>? allowedCombinations;
}

class FinvuTypeIdentifier {
  FinvuTypeIdentifier({
    required this.type,
    required this.category,
  });
  String type;
  String category;
}

class FinvuTypeIdentifierInfo {
  FinvuTypeIdentifierInfo({
    required this.category,
    required this.type,
    required this.value,
  });
  String category;
  String type;
  String value;
}
