import 'package:get_it/get_it.dart';
import '../database/database_helper.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());
}
