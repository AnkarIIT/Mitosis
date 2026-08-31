import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neet_mitos/core/models/batch_model.dart';

class BatchService extends StateNotifier<UserBatch?> {
  BatchService() : super(null);

  UserBatch? get currentBatch => state;

  void saveBatch(UserBatch batch) {
    state = batch;
  }

  void clearBatch() {
    state = null;
  }
}
