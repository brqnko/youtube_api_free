library youtube_api_free;

import 'dart:convert';

import 'package:flutter_js/flutter_js.dart';
import 'package:http/http.dart';

/// Define a global instance of host URL of YouTube
const String _hostUrl = 'https://www.youtube.com';

class _EscapeSequence {
  String start;
  String end;
  RegExp? startPrefix;

  _EscapeSequence({
    required this.start,
    required this.end,
    this.startPrefix,
  });
}

final _escapingSequences = [
  _EscapeSequence(
    start: '"',
    end: '"',
    startPrefix: null,
  ),
  _EscapeSequence(
    start: "'",
    end: "'",
    startPrefix: null,
  ),
  _EscapeSequence(
    start: "`",
    end: "`",
    startPrefix: null,
  ),
];

enum SearchFilter {
  all(''),
  video('EgIQAQ%253D%253D');

  final String tag;
  const SearchFilter(this.tag);
}

class SearchOption {
  final String query;
  final SearchFilter filter;

  const SearchOption(this.query, [this.filter = SearchFilter.all]);
}

enum DownloadQuality {
  highest(1),
  lowest(-1);

  final int factor;
  const DownloadQuality(this.factor);
}

enum DownloadMediaType {
  mp4('video/mp4'),
  mp3('audio/mp4');

  final String mimeType;
  const DownloadMediaType(this.mimeType);
}

class DownloadOption {
  final String videoId;
  final DownloadMediaType downloadMediaType;
  final DownloadQuality quality;

  const DownloadOption(this.videoId, this.downloadMediaType,
      [this.quality = DownloadQuality.lowest]);
}

class SearchContext {
  final Map<String, dynamic> _context;
  final String _continuation;
  final String _key;

  const SearchContext(this._context, this._continuation, this._key);
}

class Thumbnail {
  final String url;
  final int width, height;

  const Thumbnail(this.url, this.width, this.height);

  factory Thumbnail._fromJson(Map<String, dynamic> json) {
    return Thumbnail(json['url'], json['width'], json['height']);
  }
}

abstract class Item {
  const Item();
}

class ItemPlaylist extends Item {
  final String playlistId;
  final String title;
  final List<Thumbnail> thumbnails;
  final String publishers;
  final String videoCount;

  const ItemPlaylist(this.playlistId, this.title, this.thumbnails, this.publishers, this.videoCount);

  factory ItemPlaylist._fromJson(Map<String, dynamic> json) {
    final playlistId = json['playlistId'];
    final title = json['title'];
    final titleText = title['simpleText'];
    final thumbnail = json['thumbnail'];
    final thumbnails = thumbnail['thumbnails'] as List<dynamic>;
    final videoCountText = json['videoCountText'];
    final runs = videoCountText['runs'] as List<dynamic>;
    final videoCount = runs.first['text'];
    final longBylineText = json['longBylineText'];
    final publishers = longBylineText['simpleText'];
    final thumbnailsCast = thumbnails.map((e) => Thumbnail._fromJson(e)).toList();

    return ItemPlaylist(playlistId, titleText, thumbnailsCast, publishers, videoCount);
  }
}

class ItemUploaderCompact extends Item {
  final String text;
  final String channelId;

  const ItemUploaderCompact(this.text, this.channelId);

  factory ItemUploaderCompact._fromJson(Map<String, dynamic> json) {
    final runs = json['runs'] as List<dynamic>;
    final run = runs.first;
    final String text = run['text'];
    final navigationEndpoint = run['navigationEndpoint'];
    final commandMetadata = navigationEndpoint['commandMetadata'];
    final webCommandMetadata = commandMetadata['webCommandMetadata'];
    final url = webCommandMetadata['url'];

    return ItemUploaderCompact(text, url);
  }
}

class ItemUploader extends Item {
  final String text;
  final String channelId;
  final List<Thumbnail> thumbnails;
  final String description;
  final String subscriberCount;

  const ItemUploader(this.text, this.channelId, this.thumbnails, this.description, this.subscriberCount);

  factory ItemUploader._fromJson(Map<String, dynamic> json) {
    final navigationEndpoint = json['navigationEndpoint'];
    final commandMetadata = navigationEndpoint['commandMetadata'];
    final webCommandMetadata = commandMetadata['webCommandMetadata'];
    final channelId = webCommandMetadata['url'];
    final title = json['title'];
    final text = title['simpleText'];
    final thumbnail = json['thumbnail'];
    final thumbnails = thumbnail['thumbnails'] as List<dynamic>;
    final thumbnailsCast = thumbnails.map((e) => Thumbnail._fromJson(e)).toList();
    final descriptionSnippet = json['descriptionSnippet'];
    final runs = descriptionSnippet['runs'] as List<dynamic>;
    final run = runs[0] as Map<String, dynamic>;
    final description = run['text'];
    final videoCountText = json['videoCountText'];
    final subscriberCount = videoCountText['simpleText'];

    return ItemUploader(text, channelId, thumbnailsCast, description, subscriberCount);
  }
}

class ItemVideo extends Item {
  final String videoId;
  final String title;
  final String viewCount;
  final List<Thumbnail> thumbnails;
  final String punishedTime;
  final String length;
  final ItemUploaderCompact uploader;

  const ItemVideo(this.videoId, this.title, this.viewCount, this.thumbnails,
      this.punishedTime, this.length, this.uploader);

  factory ItemVideo._fromJson(Map<String, dynamic> json) {
    final viewCountText = json['viewCountText'];
    final videoId = json['videoId'];
    final titles = json['title'];
    final titleRuns = titles['runs'] as List<dynamic>;
    final titleRun = titleRuns.first;
    final title = titleRun['text'];
    final viewCount = viewCountText['simpleText'];
    final thumbnail = json['thumbnail'];
    final thumbnails = thumbnail['thumbnails'] as List<dynamic>;
    final thumbnails2 = thumbnails.map((e) => Thumbnail._fromJson(e)).toList();
    final publishedTimeText = json['publishedTimeText'];
    final punishedTime =
        publishedTimeText == null ? 'Live' : publishedTimeText['simpleText'];
    final ownerText = json['ownerText'];
    final uploader = ItemUploaderCompact._fromJson(ownerText);
    final lengthText = json['lengthText'];

    // TODO: Investigate the reason why accessibility can be null
    var length = 'Failed to fetch length';
    if (lengthText != null) {
      final accessibility = lengthText['accessibility'];
      final accessibilityData = accessibility['accessibilityData'];
      length = accessibilityData['label'];
    }

    return ItemVideo(
        videoId, title, viewCount, thumbnails2, punishedTime, length, uploader);
  }
}

class ItemVideoCompact extends Item {
  final String videoId;
  final List<Thumbnail> thumbnails;
  final String title;
  final String length;
  final String viewCount;
  final String punishedTime;
  final ItemUploaderCompact uploader;

  const ItemVideoCompact(this.videoId, this.thumbnails, this.title, this.length,
      this.viewCount, this.punishedTime, this.uploader);

  factory ItemVideoCompact._fromJson(Map<String, dynamic> json) {
    final videoId = json['videoId'];
    final thumbnail = json['thumbnail'];
    final thumbnails = thumbnail['thumbnails'] as List<dynamic>;
    final thumbnails2 = thumbnails.map((e) => Thumbnail._fromJson(e)).toList();
    final title = json['title'];
    final titleText = title['simpleText'];
    final viewCountText = json['viewCountText'];
    final viewCount = viewCountText['simpleText'];
    final lengthText = json['lengthText'];
    final accessibility = lengthText['accessibility'];
    final accessibilityData = accessibility['accessibilityData'];
    final length = accessibilityData['label'];
    final publishedTimeText = json['publishedTimeText'];
    final punishedTime = publishedTimeText['simpleText'];
    final shortBylineText = json['shortBylineText'];
    final uploader = ItemUploaderCompact._fromJson(shortBylineText);

    return ItemVideoCompact(videoId, thumbnails2, titleText, length, viewCount,
        punishedTime, uploader);
  }
}

class SearchResult {
  final SearchContext? context;
  final List<Item> items;

  const SearchResult(this.context, this.items);
}

class Subtitle {
  final String text;
  final int second;

  const Subtitle(this.text, this.second);
}

class YouTubeAPI {
  final Client _client;

  YouTubeAPI(this._client);

  Item? _parseItemFromElement(Map<String, dynamic> element) {
    if (element.containsKey('videoRenderer')) {
      return ItemVideo._fromJson(
          element['videoRenderer'] as Map<String, dynamic>);
    } else if (element.containsKey('compactVideoRenderer')) {
      return ItemVideoCompact._fromJson(
          element['compactVideoRenderer'] as Map<String, dynamic>);
    } else if (element.containsKey('radioRenderer')) {
      return ItemPlaylist._fromJson(element['radioRenderer'] as Map<String, dynamic>);
    } else if (element.containsKey('channelRenderer')) {
      return ItemUploader._fromJson(element['channelRenderer']);
    }
    return null;
  }

  List<Item> _parseItemsFromSearchContents(List<dynamic> contents) {
    return contents
        .where((element) =>
            element is Map<String, dynamic> &&
            element.containsKey('itemSectionRenderer'))
        .map((e) => e['itemSectionRenderer'] as Map<String, dynamic>)
        .map((e) => e['contents'] as List<dynamic>)
        .map((contents) {
          return contents
              .whereType<Map<String, dynamic>>()
              .map(_parseItemFromElement)
              .nonNulls;
        })
        .expand((element) => element)
        .toList();
  }

  List<Item> _parseItemsFromRecommendContents(List<dynamic> contents) {
    return contents
        .where((element) =>
            element is Map<String, dynamic> &&
            element.containsKey('compactVideoRenderer'))
        .map((e) => _parseItemFromElement(e))
        .nonNulls
        .toList();
  }

  String? _parseContinuationFromContents(List<dynamic> contents) {
    return contents
        .whereType<Map<String, dynamic>>()
        .where((element) => element.containsKey('continuationItemRenderer'))
        .map((e) => e['continuationItemRenderer'] as Map<String, dynamic>)
        .map((e) => e['continuationEndpoint'] as Map<String, dynamic>)
        .map((e) => e['continuationCommand'] as Map<String, dynamic>)
        .map((e) => e['token'] as String)
        .firstOrNull;
  }

  /// Fetch search suggestions from given query
  /// If no search result, returns empty list
  ///
  /// [query] query
  Future<List<String>> searchSuggestions(String query) async {
    // Send GET request
    final response = await _client.get(Uri.parse(
        'https://suggestqueries-clients6.youtube.com/complete/search?client=android&q=$query'));

    // Parse search suggestions from response
    final json = jsonDecode(response.body) as List<dynamic>;
    final suggestions = json[1] as List<dynamic>;

    return suggestions.whereType<String>().toList();
  }

  /// Fetch recommendations related to given video
  /// If no search result, returns empty list
  ///
  /// [videoId] video id
  Future<SearchResult> recommendations(String videoId) async {
    // Send GET request
    final response =
        await _client.get(Uri.parse('$_hostUrl/watch?v=${videoId}'));
    final body = response.body;

    // Parse JSON(contains search result data) from body
    final List<String> ytInitData = body.split('var ytInitialData =');
    if (ytInitData.isEmpty) {
      return const SearchResult(null, []);
    }
    final String s = ytInitData[1].split("</script>")[0];
    final Map<String, dynamic> initData =
        jsonDecode(s.substring(0, s.length - 1));

    // Parse key
    var key;
    if (body.split('innertubeApiKey').isNotEmpty) {
      key =
          body.split("innertubeApiKey")[1].trim().split(",")[0].split("\"")[2];
    }

    // Parse context
    var context;
    if (body.split("INNERTUBE_CONTEXT").isNotEmpty) {
      final String s2 = body.split("INNERTUBE_CONTEXT")[1].trim();
      context = jsonDecode(s2.substring(2, s2.length - 2));
    }

    // Parse items and continuation
    final contents = initData['contents'] as Map<String, dynamic>;
    final twoColumnSearchResultsRenderer =
        contents['twoColumnWatchNextResults'] as Map<String, dynamic>;
    final primaryContents = twoColumnSearchResultsRenderer['secondaryResults']
        as Map<String, dynamic>;
    final sectionListRenderer =
        primaryContents['secondaryResults'] as Map<String, dynamic>;
    final contents2 = sectionListRenderer['results'] as List<dynamic>;

    final continuation = _parseContinuationFromContents(contents2);

    final items = _parseItemsFromRecommendContents(contents2);

    // Wrap continuation, key and context in SearchContext
    var searchContext;
    if (continuation != null && key != null && context != null) {
      searchContext = SearchContext(context, continuation, key);
    }

    return SearchResult(searchContext, items);
  }

  /// Fetch next recommendations from given search context
  /// If no search result, returns empty list
  ///
  /// [searchContext] search context
  Future<SearchResult> continueRecommendations(
      SearchContext searchContext) async {
    // Create a JSON to tell YouTube out search context
    final bodyJSON = {
      'context': searchContext._context,
      'continuation': searchContext._continuation,
    };

    // Send POST request
    final response = await post(
      Uri.parse('$_hostUrl/youtubei/v1/search?key=${searchContext._key}'),
      body: jsonEncode(bodyJSON),
    );
    final body = response.body;
    final json = jsonDecode(body);

    // Parse continuation and items
    final contents = json['contents'];
    if (contents == null) {
      return SearchResult(null, []);
    }

    final twoColumnSearchResultsRenderer =
        contents['twoColumnSearchResultsRenderer'];
    final primaryContents = twoColumnSearchResultsRenderer['primaryContents'];
    final sectionListRenderer = primaryContents['sectionListRenderer'];
    final contents2 = sectionListRenderer['contents'] as List<dynamic>;
    final content = contents2.first;
    final itemSectionRenderer = content['itemSectionRenderer'];
    final contents3 = itemSectionRenderer['contents'] as List<dynamic>;
    final items = contents3
        .whereType<Map<String, dynamic>>()
        .map(_parseItemFromElement)
        .nonNulls
        .toList();

    final continuation = _parseContinuationFromContents(contents2);

    // Wrap continuation in SearchContext
    var nextSearchContext;
    if (continuation != null) {
      nextSearchContext = SearchContext(
          searchContext._context, continuation, searchContext._key);
    }

    return SearchResult(nextSearchContext, items);
  }

  /// Fetch search result from given search option
  /// If no search result, returns empty list
  ///
  /// [searchOption] search option
  Future<SearchResult> search(final SearchOption searchOption) async {
    // Send GET request
    final response = await _client.get(Uri.parse(
        '$_hostUrl/results?search_query=${searchOption.query}&sp=${searchOption.filter.tag}'));
    final body = response.body;

    // Parse JSON(contains search result data) from body
    final List<String> ytInitData = body.split('var ytInitialData =');
    if (ytInitData.isEmpty) {
      return SearchResult(null, []);
    }
    final String s = ytInitData[1].split("</script>")[0];
    final Map<String, dynamic> initData =
        jsonDecode(s.substring(0, s.length - 1));

    // Parse key
    var key;
    if (body.split('innertubeApiKey').isNotEmpty) {
      key =
          body.split("innertubeApiKey")[1].trim().split(",")[0].split("\"")[2];
    }

    // Parse context
    var context;
    if (body.split("INNERTUBE_CONTEXT").isNotEmpty) {
      final String s2 = body.split("INNERTUBE_CONTEXT")[1].trim();
      context = jsonDecode(s2.substring(2, s2.length - 2));
    }

    // Parse items and continuation
    final contents = initData['contents'] as Map<String, dynamic>;
    final twoColumnSearchResultsRenderer =
        contents['twoColumnSearchResultsRenderer'] as Map<String, dynamic>;
    final primaryContents = twoColumnSearchResultsRenderer['primaryContents']
        as Map<String, dynamic>;
    final sectionListRenderer =
        primaryContents['sectionListRenderer'] as Map<String, dynamic>;
    final contents2 = sectionListRenderer['contents'] as List<dynamic>;

    final continuation = _parseContinuationFromContents(contents2);

    final items = _parseItemsFromSearchContents(contents2);

    // Wrap continuation, key and context in SearchContext
    var searchContext;
    if (continuation != null && key != null && context != null) {
      searchContext = SearchContext(context, continuation, key);
    }

    return SearchResult(searchContext, items);
  }

  /// Fetch next search result from given search context
  /// If no search result, returns empty list
  ///
  /// [searchContext] search context
  Future<SearchResult> continueSearch(SearchContext searchContext) async {
    // Create a JSON to tell YouTube out search context
    final bodyJSON = {
      'context': searchContext._context,
      'continuation': searchContext._continuation,
    };

    // Send POST request
    final response = await post(
      Uri.parse('$_hostUrl/youtubei/v1/search?key=${searchContext._key}'),
      body: jsonEncode(bodyJSON),
    );
    final body = response.body;
    final json = jsonDecode(body);

    // Parse continuation and items
    final onResponseReceivedCommands =
        json['onResponseReceivedCommands'] as List<dynamic>;
    final onResponseReceivedCommand = onResponseReceivedCommands.first;
    final appendContinuationItemsAction =
        onResponseReceivedCommand['appendContinuationItemsAction'];
    final continuationItems =
        appendContinuationItemsAction['continuationItems'];

    final continuation = _parseContinuationFromContents(continuationItems);

    final items = _parseItemsFromSearchContents(continuationItems);

    // Wrap continuation in SearchContext
    var nextSearchContext;
    if (continuation != null) {
      nextSearchContext = SearchContext(
          searchContext._context, continuation, searchContext._key);
    }

    return SearchResult(nextSearchContext, items);
  }

  /// Fetch download URL from given download option
  ///
  /// [downloadOption] download option
  Future<String?> downloadURL(DownloadOption downloadOption) async {
    // Send GET request
    final response = await get(
      Uri.parse('$_hostUrl/watch?v=${downloadOption.videoId}'),
    );
    final String body = response.body;

    final Map<String, dynamic> playerJson =
        json.decode(_clip(body, 'var ytInitialPlayerResponse =', ';</script>'));

    final streamingData = playerJson['streamingData'];
    final adaptiveFormats = streamingData['adaptiveFormats'] as List<dynamic>;
    final matchedFormats = adaptiveFormats
        .whereType<Map<String, dynamic>>()
        .where((element) => element['mimeType']
            .startsWith(downloadOption.downloadMediaType.mimeType))
        .toList();
    matchedFormats.sort((f1, f2) =>
        downloadOption.quality.factor *
        (f1['averageBitrate'] as int).compareTo(f2['averageBitrate']));

    if (matchedFormats.isEmpty) {
      return null;
    }
    final bestFormat = matchedFormats.first;

    if (bestFormat.containsKey('url')) {
      return bestFormat['url'];
    }

    final String decodeURL = Uri.decodeFull(bestFormat['signatureCipher']);
    final flutterJs = getJavascriptRuntime();
    final scriptRes = await get(
      Uri.parse('https://www.youtube.com/${_getHtml5Player(body)}'),
    );
    final List<Map<String, String>> functions = [];
    _extractDecipher(scriptRes.body, functions);
    _extractNCode(scriptRes.body, functions);

    flutterJs.evaluate(functions[0]['body'] as String);
    final String sig = flutterJs
        .evaluate(
            '${functions[0]['name'] as String}("${_clip(decodeURL, 's=', '&sp=sig&url=')}")')
        .stringResult;
    return '${decodeURL.substring(decodeURL.indexOf("&sp=sig&url=") + "&sp=sig&url=".length)}&sig=$sig';
  }

  String? _getHtml5Player(String body) {
    final html5PlayerRegExp = RegExp(
        r'<script\s+src="([^"]+)"(?:\s+type="text\\//javascript")?\s+name="player_ias\\//base"\s*>|"jsUrl":"([^"]+)"');

    final match = html5PlayerRegExp.firstMatch(body);

    if (match != null) {
      final group2 = match.group(2);
      if (group2 != null) {
        return group2;
      } else {
        final group3 = match.group(3);
        if (group3 != null) {
          return group3;
        }
      }
    }

    return null;
  }

  String _extractManipulations(String body, String caller) {
    String functionName = _clip(caller, 'a=a.split("");', '.');
    if (functionName.isEmpty) {
      return '';
    }

    String functionStart = 'var $functionName={';
    int? ndx = body.indexOf(functionStart);
    if (ndx == -1) {
      return '';
    }

    String subBody = body.substring(ndx + functionStart.length - 1);

    String cutAfterSubBody = _cutAfterJs(subBody) ?? 'null';

    String returnFormattedString = 'var $functionName=$cutAfterSubBody';

    return returnFormattedString;
  }

  void _extractDecipher(String body, List<Map<String, String>> functions) {
    String functionName =
        _clip(body, 'a.set("alr","yes");c&&(c=', "(decodeURIC");

    if (functionName.isNotEmpty) {
      String functionStart = '$functionName=function(a)';
      int ndx = body.indexOf(functionStart);

      if (ndx != -1) {
        String subBody = body.substring(ndx + functionStart.length);

        String cutAfterSubBody = _cutAfterJs(subBody) ?? "{}";

        String functionBody = 'var $functionStart$cutAfterSubBody';

        functionBody =
            '${_extractManipulations(body, functionBody)};$functionBody;';

        functionBody = functionBody.replaceAll('\n', '');

        functions.add({"name": functionName, "body": functionBody});
      }
    }
  }

  void _extractNCode(String body, List<Map<String, String>> functions) {
    String functionBody;

    String functionNames = _extractFunctionNames(body);

    if (functionNames.isNotEmpty) {
      RegExp functionStartRegex = RegExp(r'$functionNames=function\(a\)');
      Match? startMatch = functionStartRegex.firstMatch(body);

      if (startMatch != null) {
        String subBody = body.substring(startMatch.end);

        String cutAfterSubBody = _cutAfterJs(subBody) ?? "{}";

        functionBody = 'var $functionNames$cutAfterSubBody;';
        functionBody = functionBody.replaceAll('\n', '');

        functions.add({"name": functionNames, "body": functionBody});
      }
    }
  }

  String _extractFunctionNames(String body) {
    String functionNames = _clip(
      body,
      '&&(b=a.get("n"))&&(b="#',
      '(b)',
    );

    String leftName = 'var ${functionNames.split('[').first}=[';

    if (functionNames.contains('[')) {
      functionNames = _clip(body, leftName, "]");
    }

    return functionNames;
  }

  /// Extracts the first valid JSON string from a mixed string containing JSON and JavaScript code
  ///
  /// [mixedJson] The mixed string containing both JSON and JavaScript code
  String? _cutAfterJs(String mixedJson) {
    String open, close;
    switch (mixedJson.substring(0, 1)) {
      case "[":
        open = "[";
        close = "]";
        break;
      case "{":
        open = "{";
        close = "}";
        break;
      default:
        return null;
    }

    _EscapeSequence? isEscapedObject;

    // States if the current character is escaped or not
    var isEscaped = false;

    // Current open brackets to be closed
    var counter = 0;

    var mixedJsonUnicode = mixedJson.split('');
    for (var i = 0; i < mixedJsonUnicode.length; i++) {
      var value = mixedJsonUnicode[i];

      if (!isEscaped &&
          isEscapedObject != null &&
          value == isEscapedObject.end) {
        isEscapedObject = null;
        continue;
      } else if (!isEscaped && isEscapedObject == null) {
        for (var escaped in _escapingSequences) {
          if (value != escaped.start) {
            continue;
          }

          var substringStartNumber = (i <= 10) ? 0 : i - 10;

          if (escaped.startPrefix == null ||
              (escaped.startPrefix != null &&
                  escaped.startPrefix!.hasMatch(
                      mixedJson.substring(substringStartNumber, i)))) {
            isEscapedObject = escaped;
            break;
          }
        }

        if (isEscapedObject != null) {
          continue;
        }
      }

      isEscaped = value == "\\" && !isEscaped;

      if (isEscapedObject != null) {
        continue;
      }

      if (value == open) {
        counter++;
      } else if (value == close) {
        counter--;
      }

      if (counter == 0) {
        return mixedJson.substring(0, i + 1);
      }
    }

    return null;
  }

  /// Extracts a substring from a target string based on two marker strings
  ///
  /// [target] The target string from which to extract the substring
  /// [first] The first marker string to delimit the start of the substring
  /// [last] The second marker string to delimit the end of the substring
  String _clip(final String target, final String first, final String last) {
    final int startIndex = (target.indexOf(first) + first.length);
    return target.substring(startIndex, target.indexOf(last, startIndex));
  }
}
