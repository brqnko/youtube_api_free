import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:youtube_api_free/youtube_api_free.dart';

void main() async {

  printItemTitle(Item item) {
    if (item is ItemVideo) {
      print(item.title);
    } else if (item is ItemVideoCompact) {
      print(item.title);
    } else if (item is ItemVideo) {
      print(item.title);
    } else if (item is ItemPlaylist) {
      print(item.title);
    }
  };

  test('search', () async {

    final youtube = YouTubeAPI(Client());

    final searchResult1 = await youtube.search(SearchOption('blue roar'));
    print('[!] Passed first search');
    final searchResult2 = await youtube.continueSearch(searchResult1.context!);
    print('[!] Passed second search');

    print('\n[!] First search result');
    searchResult1.items.forEach(printItemTitle);
    print('\n[!] Second search result');
    searchResult2.items.forEach(printItemTitle);
  });

  test('recommend', () async {

    final youtube = YouTubeAPI(Client());

    final recommendation1 = await youtube.recommendations('urH09Bu4NLo');
    print('[!] Passed first recommendation');
    final recommendation2 = await youtube.continueRecommendations(recommendation1.context!);
    print('[!] Passed second recommendation');

    print('\n[!] First recommendation result');
    recommendation1.items.forEach(printItemTitle);
    print('\n[!] Second recommendation result');
    recommendation2.items.forEach(printItemTitle);
  });

  test('download', () async {

    final youtube = YouTubeAPI(Client());

    final download = await youtube.downloadURL(DownloadOption('urH09Bu4NLo', DownloadMediaType.mp3));
    print('[!] Passed fetching download URL');

    print('\n[!] Download URL');
    print(download);
  });

  test('search suggestions', () async {

    final youtube = YouTubeAPI(Client());

    final searchSuggestion = await youtube.searchSuggestions('blue roar');
    print('[!] Passed fetching search suggestions');

    print('\n[!] Search suggestions');
    searchSuggestion.forEach(print);
  });
}
