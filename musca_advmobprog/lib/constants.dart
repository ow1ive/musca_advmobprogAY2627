import 'package:flutter_dotenv/flutter_dotenv.dart';

final String host = (dotenv.env['HOST']?.trim().isNotEmpty ?? false)
    ? dotenv.env['HOST']!.trim()
    : 'https://dummyjson.com';

class AppStrings {
  static const String appTitle = 'musca_advmobprog';
  static const String homeTitle = 'Counter App';
}
