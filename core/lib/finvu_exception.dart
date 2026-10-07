class FinvuException implements Exception {
  final String code;
  final String? message;
  final String? operation;
  FinvuException(this.code, this.message, {this.operation});

  static FinvuException from(e, {String? operation}) {
    return FinvuException(e.code ?? '', e.message, operation: operation);
  }

  @override
  String toString() {
    if (operation != null) {
      return 'FinvuException(operation: $operation, code: $code, message: $message)';
    }
    return 'FinvuException(code: $code, message: $message)';
  }
}
