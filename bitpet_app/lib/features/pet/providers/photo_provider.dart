import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/photo_models.dart';
import '../data/photo_repository.dart';

final petPhotosProvider =
    FutureProvider.family<List<PetPhoto>, int>((ref, petId) {
  return ref
      .watch(photoRepositoryProvider)
      .getPhotos(entityType: 'PET', entityId: petId);
});
