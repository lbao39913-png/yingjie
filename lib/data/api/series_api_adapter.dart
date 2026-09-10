import '../../core/constants/app_constants.dart';
import '../../models/paged_result.dart';
import '../../models/video.dart';

abstract class SeriesApiAdapter {
  Future<PagedResult<Video>> fetchSeries({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
  });
}
