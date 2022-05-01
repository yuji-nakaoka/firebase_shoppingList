import 'package:hooks_riverpod/hooks_riverpod.dart';

class CustomException implements Exception {
  final String? message;

  const CustomException({this.message = '問題発生'});

  @override
  String toString() => 'CustomException{message:$message}';
}
