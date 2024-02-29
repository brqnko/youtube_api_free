# YouTube API Free
Flutter(dart) implementation of YouTube API that can be used without API key

## Features
- Get search result
- Get recommendation about a video
- Get download URL of a video
- Get search suggestons

## Getting started
Prerequisites(See pubspec.yaml for more detail)
- Dart SDK >=3.3.0
- Flutter SDK
## Usage

```dart
// Create an instance of YouTube
final youtube = YouTubeAPI(Client());

// Start a first search
final searchResult1 = await youtube.search(SearchOption('blue roar'));

// Start a second search
final searchResult2 = await youtube.continueSearch(searchResult1.context!);

// Print all title in searchResult1
searchResult1.items.forEach((item) {
    if (item is ItemVideo) {
        print(item.title);
    }
});
```

## Additional information

This package basically works by parsing responses from youtube.  
For fetching download URL, it uses JavaScript runtime to decipher signature ciphers.  
