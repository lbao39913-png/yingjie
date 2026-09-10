import 'episode.dart';
import 'json_values.dart';

class PlaySource {
  const PlaySource({
    required this.id,
    required this.name,
    this.episodes = const [],
  });

  final String id;
  final String name;
  final List<Episode> episodes;

  factory PlaySource.fromJson(Map<String, dynamic> json) {
    return PlaySource(
      id: JsonValues.string(json['id']),
      name: JsonValues.string(json['name']),
      episodes: JsonValues.maps(json['episodes'])
          .map(Episode.fromJson)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'episodes': episodes.map((item) => item.toJson()).toList(growable: false),
    };
  }
}
