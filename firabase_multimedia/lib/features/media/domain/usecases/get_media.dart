import 'package:firabase_multimedia/features/media/domain/models/media_item.dart';
import 'package:firabase_multimedia/features/media/domain/repositories/i_media_repository.dart';

class GetMediaUseCase {
  final IMediaRepository _repository;

  GetMediaUseCase(this._repository);

  Future<List<MediaItem>> call() async {
    return await _repository.getMediaItems();
  }
}