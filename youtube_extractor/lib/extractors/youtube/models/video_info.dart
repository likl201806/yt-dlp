class VideoInfo {
  final String id;
  final String title;
  final String? description;
  final String? descriptionHtml;
  final String? channel;
  final String? channelId;
  final String? channelUrl;
  final String? channelHandle;
  final bool? channelVerified;
  final int? channelFollowerCount;
  final String? channelThumbnail;
  final String? uploader;
  final String? uploaderId;
  final String? uploaderUrl;
  final String? uploaderVerified;
  final String? uploadDate;
  final String? publishDate;
  final DateTime? uploadDateTime;
  final DateTime? publishDateTime;
  final int? viewCount;
  final int? likeCount;
  final int? dislikeCount;
  final int? repostCount;
  final int? commentCount;
  final String? averageRating;
  final List<String>? categories;
  final List<String>? tags;
  final List<String>? keywords;
  final String? license;
  final String? language;
  final List<String>? subtitleLanguages;
  final bool? isLive;
  final bool? wasLive;
  final String? liveStatus;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? concurrentViewers;
  final String? dashManifestUrl;
  final String? hlsManifestUrl;
  final int? duration;
  final int? ageLimit;
  final bool? isPrivate;
  final bool? isUnlisted;
  final bool? isFamilySafe;
  final bool? isAds;
  final bool? allowRatings;
  final bool? isDownloadable;
  final bool? isClip;
  final bool? isShort;
  final String? webpageUrl;
  final String? originalUrl;
  final String? embedUrl;
  final String? embedHtml;
  final List<ThumbnailInfo> thumbnails;
  final List<FormatInfo> formats;
  final Map<String, List<SubtitleInfo>>? subtitles;
  final Map<String, List<SubtitleInfo>>? automaticCaptions;
  final List<ChapterInfo>? chapters;
  final Map<String, dynamic>? storyboards;
  final Map<String, dynamic>? videoQualityInfo;
  final Map<String, dynamic>? audioQualityInfo;
  final Map<String, dynamic>? engagement;
  final Map<String, dynamic>? playerConfig;
  final Map<String, dynamic>? clientConfig;
  final Map<String, dynamic>? formatRestrictions;

  VideoInfo({
    required this.id,
    required this.title,
    this.description,
    this.descriptionHtml,
    this.channel,
    this.channelId,
    this.channelUrl,
    this.channelHandle,
    this.channelVerified,
    this.channelFollowerCount,
    this.channelThumbnail,
    this.uploader,
    this.uploaderId,
    this.uploaderUrl,
    this.uploaderVerified,
    this.uploadDate,
    this.publishDate,
    this.uploadDateTime,
    this.publishDateTime,
    this.viewCount,
    this.likeCount,
    this.dislikeCount,
    this.repostCount,
    this.commentCount,
    this.averageRating,
    this.categories = const [],
    this.tags = const [],
    this.keywords = const [],
    this.license,
    this.language,
    this.subtitleLanguages,
    this.isLive,
    this.wasLive,
    this.liveStatus,
    this.startTime,
    this.endTime,
    this.concurrentViewers,
    this.dashManifestUrl,
    this.hlsManifestUrl,
    this.duration,
    this.ageLimit,
    this.isPrivate,
    this.isUnlisted,
    this.isFamilySafe,
    this.isAds,
    this.allowRatings,
    this.isDownloadable,
    this.isClip,
    this.isShort,
    this.webpageUrl,
    this.originalUrl,
    this.embedUrl,
    this.embedHtml,
    this.thumbnails = const [],
    this.formats = const [],
    this.subtitles,
    this.automaticCaptions,
    this.chapters,
    this.storyboards,
    this.videoQualityInfo,
    this.audioQualityInfo,
    this.engagement,
    this.playerConfig,
    this.clientConfig,
    this.formatRestrictions,
  });

  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    return VideoInfo(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      descriptionHtml: json['descriptionHtml'] as String?,
      channel: json['channel'] as String?,
      channelId: json['channelId'] as String?,
      channelUrl: json['channelUrl'] as String?,
      channelHandle: json['channelHandle'] as String?,
      channelVerified: json['channelVerified'] as bool?,
      channelFollowerCount: json['channelFollowerCount'] as int?,
      channelThumbnail: json['channelThumbnail'] as String?,
      uploader: json['uploader'] as String?,
      uploaderId: json['uploaderId'] as String?,
      uploaderUrl: json['uploaderUrl'] as String?,
      uploaderVerified: json['uploaderVerified'] as String?,
      uploadDate: json['uploadDate'] as String?,
      publishDate: json['publishDate'] as String?,
      uploadDateTime: json['uploadDate'] != null
          ? DateTime.parse(json['uploadDate'] as String)
          : null,
      publishDateTime: json['publishDate'] != null
          ? DateTime.parse(json['publishDate'] as String)
          : null,
      viewCount: json['viewCount'] as int?,
      likeCount: json['likeCount'] as int?,
      dislikeCount: json['dislikeCount'] as int?,
      repostCount: json['repostCount'] as int?,
      commentCount: json['commentCount'] as int?,
      averageRating: json['averageRating'] as String?,
      categories: (json['categories'] as List?)?.cast<String>() ?? [],
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      keywords: json['keywords'] as List<String>?,
      license: json['license'] as String?,
      language: json['language'] as String?,
      subtitleLanguages: json['subtitleLanguages'] as List<String>?,
      isLive: json['isLive'] as bool?,
      wasLive: json['wasLive'] as bool?,
      liveStatus: json['liveStatus'] as String?,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      concurrentViewers: json['concurrentViewers'] as int?,
      dashManifestUrl: json['dashManifestUrl'] as String?,
      hlsManifestUrl: json['hlsManifestUrl'] as String?,
      duration: json['duration'] as int?,
      ageLimit: json['ageLimit'] as int?,
      isPrivate: json['isPrivate'] as bool?,
      isUnlisted: json['isUnlisted'] as bool?,
      isFamilySafe: json['isFamilySafe'] as bool?,
      isAds: json['isAds'] as bool?,
      allowRatings: json['allowRatings'] as bool?,
      isDownloadable: json['isDownloadable'] as bool?,
      isClip: json['isClip'] as bool?,
      isShort: json['isShort'] as bool?,
      webpageUrl: json['webpageUrl'] as String?,
      originalUrl: json['originalUrl'] as String?,
      embedUrl: json['embedUrl'] as String?,
      embedHtml: json['embedHtml'] as String?,
      thumbnails: (json['thumbnails'] as List?)
              ?.map((t) => ThumbnailInfo.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      formats: (json['formats'] as List?)
              ?.map((f) => FormatInfo.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      subtitles: json['subtitles'] as Map<String, List<SubtitleInfo>>?,
      automaticCaptions:
          json['automaticCaptions'] as Map<String, List<SubtitleInfo>>?,
      chapters: json['chapters'] as List<ChapterInfo>?,
      storyboards: json['storyboards'] as Map<String, dynamic>?,
      videoQualityInfo: json['videoQualityInfo'] as Map<String, dynamic>?,
      audioQualityInfo: json['audioQualityInfo'] as Map<String, dynamic>?,
      engagement: json['engagement'] as Map<String, dynamic>?,
      playerConfig: json['playerConfig'] as Map<String, dynamic>?,
      clientConfig: json['clientConfig'] as Map<String, dynamic>?,
      formatRestrictions: json['formatRestrictions'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'descriptionHtml': descriptionHtml,
      'channel': channel,
      'channelId': channelId,
      'channelUrl': channelUrl,
      'channelHandle': channelHandle,
      'channelVerified': channelVerified,
      'channelFollowerCount': channelFollowerCount,
      'channelThumbnail': channelThumbnail,
      'uploader': uploader,
      'uploaderId': uploaderId,
      'uploaderUrl': uploaderUrl,
      'uploaderVerified': uploaderVerified,
      'uploadDate': uploadDate,
      'publishDate': publishDate,
      'uploadDateTime': uploadDateTime?.toIso8601String(),
      'publishDateTime': publishDateTime?.toIso8601String(),
      'viewCount': viewCount,
      'likeCount': likeCount,
      'dislikeCount': dislikeCount,
      'repostCount': repostCount,
      'commentCount': commentCount,
      'averageRating': averageRating,
      'categories': categories,
      'tags': tags,
      'keywords': keywords,
      'license': license,
      'language': language,
      'subtitleLanguages': subtitleLanguages,
      'isLive': isLive,
      'wasLive': wasLive,
      'liveStatus': liveStatus,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'concurrentViewers': concurrentViewers,
      'dashManifestUrl': dashManifestUrl,
      'hlsManifestUrl': hlsManifestUrl,
      'duration': duration,
      'ageLimit': ageLimit,
      'isPrivate': isPrivate,
      'isUnlisted': isUnlisted,
      'isFamilySafe': isFamilySafe,
      'isAds': isAds,
      'allowRatings': allowRatings,
      'isDownloadable': isDownloadable,
      'isClip': isClip,
      'isShort': isShort,
      'webpageUrl': webpageUrl,
      'originalUrl': originalUrl,
      'embedUrl': embedUrl,
      'embedHtml': embedHtml,
      'thumbnails': thumbnails.map((t) => t.toJson()).toList(),
      'formats': formats.map((f) => f.toJson()).toList(),
      'subtitles': subtitles,
      'automaticCaptions': automaticCaptions,
      'chapters': chapters?.map((c) => c.toJson()).toList(),
      'storyboards': storyboards,
      'videoQualityInfo': videoQualityInfo,
      'audioQualityInfo': audioQualityInfo,
      'engagement': engagement,
      'playerConfig': playerConfig,
      'clientConfig': clientConfig,
      'formatRestrictions': formatRestrictions,
    };
  }

  String get bestThumbnail => thumbnails.isNotEmpty ? thumbnails.last.url : '';
  FormatInfo? get bestFormat => formats.isNotEmpty ? formats.last : null;
  bool get hasSubtitles => subtitles?.isNotEmpty ?? false;
  bool get hasAutomaticCaptions => automaticCaptions?.isNotEmpty ?? false;
  bool get hasChapters => chapters?.isNotEmpty ?? false;
  String get formattedDuration =>
      duration != null ? _formatDuration(duration!) : '';
  String get formattedViewCount =>
      viewCount != null ? _formatViewCount(viewCount!) : '';

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString()}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatViewCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class ThumbnailInfo {
  final String url;
  final int? width;
  final int? height;
  final String? id;
  final int? resolution;

  ThumbnailInfo({
    required this.url,
    this.width,
    this.height,
    this.id,
    this.resolution,
  });

  factory ThumbnailInfo.fromJson(Map<String, dynamic> json) {
    return ThumbnailInfo(
      url: json['url'] as String,
      width: json['width'] as int?,
      height: json['height'] as int?,
      resolution: json['resolution'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'width': width,
      'height': height,
      'id': id,
      'resolution': resolution,
    };
  }
}

class FormatInfo {
  final String formatId;
  final String url;
  final String? ext;
  final int? width;
  final int? height;
  final int? tbr;
  final String? vcodec;
  final String? acodec;
  final int? asr;
  final int? filesize;
  final String? format;
  final String? formatNote;
  final String? container;
  final String? protocol;
  final Map<String, dynamic>? httpHeaders;

  final int? fps;
  final String? resolution;
  final int? dynamicRange;
  final String? manifestUrl;
  final Map<String, String>? fragments;
  final bool? isDashMPD;
  final bool? isHLS;
  final int? quality;
  final int? sourcePriority;
  final bool? hasVideo;
  final bool? hasAudio;

  FormatInfo({
    required this.formatId,
    required this.url,
    this.ext,
    this.width,
    this.height,
    this.tbr,
    this.vcodec,
    this.acodec,
    this.asr,
    this.filesize,
    this.format,
    this.formatNote,
    this.container,
    this.protocol,
    this.httpHeaders,
    this.fps,
    this.resolution,
    this.dynamicRange,
    this.manifestUrl,
    this.fragments,
    this.isDashMPD,
    this.isHLS,
    this.quality,
    this.sourcePriority,
    this.hasVideo,
    this.hasAudio,
  });

  factory FormatInfo.fromJson(Map<String, dynamic> json) {
    return FormatInfo(
      formatId: json['formatId'] as String,
      url: json['url'] as String,
      ext: json['ext'] as String?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      tbr: json['tbr'] as int?,
      vcodec: json['vcodec'] as String?,
      acodec: json['acodec'] as String?,
      asr: json['asr'] as int?,
      filesize: json['filesize'] as int?,
      format: json['format'] as String?,
      formatNote: json['formatNote'] as String?,
      container: json['container'] as String?,
      protocol: json['protocol'] as String?,
      httpHeaders: json['httpHeaders'] as Map<String, dynamic>?,
      fps: json['fps'] as int?,
      resolution: json['resolution'] as String?,
      dynamicRange: json['dynamicRange'] as int?,
      manifestUrl: json['manifestUrl'] as String?,
      fragments: json['fragments'] as Map<String, String>?,
      isDashMPD: json['isDashMPD'] as bool?,
      isHLS: json['isHLS'] as bool?,
      quality: json['quality'] as int?,
      sourcePriority: json['sourcePriority'] as int?,
      hasVideo: json['hasVideo'] as bool?,
      hasAudio: json['hasAudio'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'formatId': formatId,
      'url': url,
      'ext': ext,
      'width': width,
      'height': height,
      'tbr': tbr,
      'vcodec': vcodec,
      'acodec': acodec,
      'asr': asr,
      'filesize': filesize,
      'format': format,
      'formatNote': formatNote,
      'container': container,
      'protocol': protocol,
      'httpHeaders': httpHeaders,
      'fps': fps,
      'resolution': resolution,
      'dynamicRange': dynamicRange,
      'manifestUrl': manifestUrl,
      'fragments': fragments,
      'isDashMPD': isDashMPD,
      'isHLS': isHLS,
      'quality': quality,
      'sourcePriority': sourcePriority,
      'hasVideo': hasVideo,
      'hasAudio': hasAudio,
    };
  }
}

class SubtitleInfo {
  final String url;
  final String ext;
  final String? name;
  final String content;

  SubtitleInfo({
    required this.url,
    required this.ext,
    required this.content,
    this.name,
  });
}

class ChapterInfo {
  final String title;
  final int startTime;
  final int? endTime;

  ChapterInfo({
    required this.title,
    required this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'startTime': startTime,
        'endTime': endTime,
      };
}
