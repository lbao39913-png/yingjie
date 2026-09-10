import 'video.dart';

class HomeFeed {
  const HomeFeed({
    this.banners = const [],
    this.hot = const [],
    this.latest = const [],
    this.movies = const [],
    this.series = const [],
    this.anime = const [],
    this.variety = const [],
  });

  final List<Video> banners;
  final List<Video> hot;
  final List<Video> latest;
  final List<Video> movies;
  final List<Video> series;
  final List<Video> anime;
  final List<Video> variety;

  bool get isEmpty =>
      banners.isEmpty &&
      hot.isEmpty &&
      latest.isEmpty &&
      movies.isEmpty &&
      series.isEmpty &&
      anime.isEmpty &&
      variety.isEmpty;
}
