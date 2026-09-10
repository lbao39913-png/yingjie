import '../../models/category.dart';
import '../../models/episode.dart';
import '../../models/play_source.dart';
import '../../models/video.dart';

/// Creative Commons sample catalog from Blender Foundation open movies.
/// These titles are used only as legal placeholders until a licensed API is connected.
class MockCatalog {
  MockCatalog._();

  static const sampleHost =
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample';
  static const _sampleHost = sampleHost;

  static final List<Category> categories = [
    const Category(id: 'movie', name: '电影'),
    const Category(id: 'series', name: '电视剧'),
    const Category(id: 'anime', name: '动漫'),
    const Category(id: 'variety', name: '综艺'),
  ];

  static final List<Video> videos = [
    Video(
      id: 'big-buck-bunny',
      title: 'Big Buck Bunny',
      subtitle: 'Blender Foundation',
      cover: '$_sampleHost/images/BigBuckBunny.jpg',
      backdrop: '$_sampleHost/images/BigBuckBunny.jpg',
      description:
          'A Creative Commons short film by the Blender Foundation. Used as a legal sample title in development.',
      year: 2008,
      region: 'Netherlands',
      category: 'movie',
      genres: const ['动画', '短片'],
      director: 'Sacha Goedegebure',
      actors: const ['Big Buck Bunny'],
      rating: 8.1,
      durationMinutes: 10,
      updatedAt: DateTime(2024, 1, 8),
      sources: [
        const PlaySource(
          id: 'source-mp4',
          name: '线路 1 · MP4',
          episodes: [
            Episode(
              id: 'bbb-1',
              name: '正片',
              url: '$_sampleHost/BigBuckBunny.mp4',
              quality: '720p',
            ),
          ],
        ),
      ],
    ),
    Video(
      id: 'elephants-dream',
      title: 'Elephants Dream',
      subtitle: 'Blender Foundation',
      cover: '$_sampleHost/images/ElephantsDream.jpg',
      backdrop: '$_sampleHost/images/ElephantsDream.jpg',
      description:
          'The first open movie created with Blender. Licensed under Creative Commons.',
      year: 2006,
      region: 'Netherlands',
      category: 'movie',
      genres: const ['动画', '科幻'],
      director: 'Bassam Kurdali',
      actors: const ['Emo', 'Proog'],
      rating: 7.4,
      durationMinutes: 11,
      updatedAt: DateTime(2024, 2, 12),
      sources: [
        const PlaySource(
          id: 'source-mp4',
          name: '线路 1 · MP4',
          episodes: [
            Episode(
              id: 'ed-1',
              name: '正片',
              url: '$_sampleHost/ElephantsDream.mp4',
              quality: '720p',
            ),
          ],
        ),
      ],
    ),
    Video(
      id: 'sintel',
      title: 'Sintel',
      subtitle: 'Blender Foundation',
      cover: '$_sampleHost/images/Sintel.jpg',
      backdrop: '$_sampleHost/images/Sintel.jpg',
      description:
          'A Creative Commons fantasy short about a girl and a baby dragon.',
      year: 2010,
      region: 'Netherlands',
      category: 'anime',
      genres: const ['动画', '奇幻'],
      director: 'Colin Levy',
      actors: const ['Sintel'],
      rating: 7.5,
      durationMinutes: 15,
      updatedAt: DateTime(2024, 3, 4),
      sources: [
        const PlaySource(
          id: 'source-mp4',
          name: '线路 1 · MP4',
          episodes: [
            Episode(
              id: 'sintel-1',
              name: '正片',
              url: '$_sampleHost/Sintel.mp4',
              quality: '720p',
            ),
          ],
        ),
      ],
    ),
    Video(
      id: 'tears-of-steel',
      title: 'Tears of Steel',
      subtitle: 'Blender Foundation',
      cover: '$_sampleHost/images/TearsOfSteel.jpg',
      backdrop: '$_sampleHost/images/TearsOfSteel.jpg',
      description:
          'A Creative Commons live-action / CGI short produced by the Blender Institute.',
      year: 2012,
      region: 'Netherlands',
      category: 'series',
      genres: const ['科幻', '短片'],
      director: 'Ian Hubert',
      actors: const ['Celia', 'Thom'],
      rating: 7.1,
      durationMinutes: 12,
      updatedAt: DateTime(2024, 4, 18),
      sources: [
        const PlaySource(
          id: 'source-mp4',
          name: '线路 1 · MP4',
          episodes: [
            Episode(
              id: 'tos-1',
              name: '第 1 集',
              url: '$_sampleHost/TearsOfSteel.mp4',
              quality: '1080p',
            ),
          ],
        ),
        const PlaySource(
          id: 'source-alt',
          name: '线路 2 · 备用',
          episodes: [
            Episode(
              id: 'tos-alt-1',
              name: '第 1 集',
              url: '$_sampleHost/TearsOfSteel.mp4',
              quality: '720p',
            ),
          ],
        ),
      ],
    ),
    Video(
      id: 'for-bigger-joyrides',
      title: 'For Bigger Joyrides',
      subtitle: 'Google sample clip',
      cover: '$_sampleHost/images/ForBiggerJoyrides.jpg',
      backdrop: '$_sampleHost/images/ForBiggerJoyrides.jpg',
      description:
          'A publicly provided sample clip from Google sample videos, used only for player development.',
      year: 2013,
      region: 'USA',
      category: 'variety',
      genres: const ['演示'],
      director: 'Sample',
      actors: const ['Sample'],
      rating: 6.8,
      durationMinutes: 1,
      updatedAt: DateTime(2024, 5, 1),
      sources: [
        const PlaySource(
          id: 'source-mp4',
          name: '线路 1 · MP4',
          episodes: [
            Episode(
              id: 'joy-1',
              name: '正片',
              url: '$_sampleHost/ForBiggerJoyrides.mp4',
              quality: '720p',
            ),
          ],
        ),
      ],
    ),
    _sampleClip(
      id: 'for-bigger-blazes',
      title: 'For Bigger Blazes',
      file: 'ForBiggerBlazes',
      category: 'movie',
    ),
    _sampleClip(
      id: 'for-bigger-escapes',
      title: 'For Bigger Escapes',
      file: 'ForBiggerEscapes',
      category: 'series',
    ),
    _sampleClip(
      id: 'for-bigger-fun',
      title: 'For Bigger Fun',
      file: 'ForBiggerFun',
      category: 'anime',
    ),
    _sampleClip(
      id: 'for-bigger-meltdowns',
      title: 'For Bigger Meltdowns',
      file: 'ForBiggerMeltdowns',
      category: 'variety',
    ),
    _sampleClip(
      id: 'subaru-outback',
      title: 'Subaru Outback',
      file: 'SubaruOutbackOnStreetAndDirt',
      category: 'movie',
    ),
    _sampleClip(
      id: 'volkswagen-gti',
      title: 'Volkswagen GTI Review',
      file: 'VolkswagenGTIReview',
      category: 'variety',
    ),
    _sampleClip(
      id: 'bullrun',
      title: 'We Are Going On Bullrun',
      file: 'WeAreGoingOnBullrun',
      category: 'series',
    ),
    _sampleClip(
      id: 'what-car',
      title: 'What Car Can You Get For A Grand',
      file: 'WhatCarCanYouGetForAGrand',
      category: 'movie',
    ),
    _sampleSeries(
      id: 'sample-series-a',
      title: '示例剧集 A',
      files: const [
        'ForBiggerBlazes',
        'ForBiggerEscapes',
        'ForBiggerFun',
      ],
    ),
    _sampleSeries(
      id: 'sample-series-b',
      title: '示例剧集 B',
      files: const [
        'ForBiggerMeltdowns',
        'SubaruOutbackOnStreetAndDirt',
        'VolkswagenGTIReview',
        'WeAreGoingOnBullrun',
      ],
    ),
  ];
}

Video _sampleClip({
  required String id,
  required String title,
  required String file,
  required String category,
}) {
  const host = MockCatalog.sampleHost;
  return Video(
    id: id,
    title: title,
    subtitle: 'Google sample clip',
    cover: '$host/images/$file.jpg',
    backdrop: '$host/images/$file.jpg',
    description:
        'A publicly provided sample clip used only for player and catalog development.',
    year: 2013,
    region: 'USA',
    category: category,
    genres: const ['演示'],
    director: 'Sample',
    actors: const ['Sample'],
    rating: 6.5,
    durationMinutes: 1,
    updatedAt: DateTime(2024, 6, 1),
    sources: [
      PlaySource(
        id: 'source-mp4',
        name: '线路 1 · MP4',
        episodes: [
          Episode(
            id: '$id-1',
            name: '正片',
            url: '$host/$file.mp4',
            quality: '720p',
          ),
        ],
      ),
    ],
  );
}

Video _sampleSeries({
  required String id,
  required String title,
  required List<String> files,
}) {
  const host = MockCatalog.sampleHost;
  final coverFile = files.first;
  return Video(
    id: id,
    title: title,
    subtitle: 'Google sample clips',
    cover: '$host/images/$coverFile.jpg',
    backdrop: '$host/images/$coverFile.jpg',
    description:
        'A Creative Commons / Google sample series used only for multi-episode player development.',
    year: 2013,
    region: 'USA',
    category: 'series',
    type: MediaType.tv,
    genres: const ['演示'],
    director: 'Sample',
    actors: const ['Sample'],
    rating: 6.6,
    durationMinutes: 1,
    updatedAt: DateTime(2024, 7, 1),
    sources: [
      PlaySource(
        id: 'source-mp4',
        name: '线路 1 · MP4',
        episodes: [
          for (var index = 0; index < files.length; index++)
            Episode(
              id: '$id-${index + 1}',
              name: '第${index + 1}集',
              url: '$host/${files[index]}.mp4',
              quality: '720p',
              episodeNumber: index + 1,
              mediaId: id,
            ),
        ],
      ),
    ],
  );
}
