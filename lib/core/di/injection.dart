import 'package:get_it/get_it.dart';
import '../network/dio_client.dart';
import '../storage/secure_storage.dart';

final sl = GetIt.instance; // sl = service locator

Future<void> configureDependencies() async {
  // Core
  sl.registerLazySingleton<SecureStorage>(() => SecureStorage());
  sl.registerLazySingleton<DioClient>(() => DioClient(sl()));

  // Features — se irán agregando aquí
  // _registerAuth();
  // _registerRecipes();
  // _registerChatbot();
}