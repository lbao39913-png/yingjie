import '../../core/constants/app_constants.dart';
import '../../models/paged_result.dart';
import '../../models/video.dart';

abstract class MovieApiAdapter {
  Future<PagedResult<Video>> fetchMovies({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  });
}
