import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'package:firabase_multimedia/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:firabase_multimedia/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:firabase_multimedia/features/auth/presentation/stores/auth_store.dart';
import 'package:firabase_multimedia/features/media/data/repositories/firebase_media_repository.dart';
import 'package:firabase_multimedia/features/media/domain/repositories/i_media_repository.dart';
import 'package:firabase_multimedia/features/media/presentation/stores/media_store.dart';

/// Service Locator global (Singleton).
final GetIt sl = GetIt.instance;

/// Registra todas las dependencias de la aplicación.
///
/// Sigue el principio de Inversión de Dependencias (SOLID-D):
/// las interfaces de dominio se registran con implementaciones concretas
/// de la capa de datos.
///
/// **Orden de registro:**
/// 1. Servicios externos (Firebase, utilidades)
/// 2. Repositorios (interfaz → implementación)
/// 3. Stores / ViewModels
void configureDependencies() {
  // ─── Servicios Externos ──────────────────────────────────────
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  sl.registerLazySingleton<ImagePicker>(() => ImagePicker());
  sl.registerLazySingleton<Uuid>(() => const Uuid());

  // ─── Repositorios (Inversión de Dependencias) ────────────────
  sl.registerLazySingleton<IAuthRepository>(
    () => FirebaseAuthRepository(sl<FirebaseAuth>()),
  );
  sl.registerLazySingleton<IMediaRepository>(
    () => FirebaseMediaRepository(
      sl<FirebaseStorage>(),
      sl<FirebaseFirestore>(),
      sl<Uuid>(),
    ),
  );

  // ─── Stores / ViewModels ─────────────────────────────────────
  // Se registran como Factory para obtener instancias frescas,
  // pero como se usan con Provider + ChangeNotifierProvider,
  // su ciclo de vida lo gestiona el widget tree.
  sl.registerFactory<AuthStore>(
    () => AuthStore(sl<IAuthRepository>()),
  );
  sl.registerFactory<MediaStore>(
    () => MediaStore(
      sl<IMediaRepository>(),
      sl<ImagePicker>(),
      sl<Uuid>(),
    ),
  );
}

