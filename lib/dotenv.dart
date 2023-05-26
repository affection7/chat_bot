import 'package:flutter_dotenv/flutter_dotenv.dart';

class DotEnvSingleton {
  static final DotEnvSingleton _singleton = DotEnvSingleton._();

  factory DotEnvSingleton() {
    return _singleton;
  }

  DotEnvSingleton._() {
    dotenv.load();
  }

  String get token {
    return dotenv.env['TOKEN'] ?? '';
  }
}

final DotEnvSingleton dotEnv = DotEnvSingleton();
