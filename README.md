# DRMPlayback

This is a sample app to showcase following instructions:

The objective is to create an app that downloads and plays DRM encrypted videos.

The key requirements are:
- It should be possible to stream the provided DRM encrypted videos
- The app must be able to download multiple video files concurrently and store them locally
- Download progress is shown via a progress bar
- It should be possible to have multiple videos stored at the same time
- Once the video has been downloaded, it should be possible to play them back from local storage
- It should be possible to delete downloaded videos
- The native iOS player (AVPlayer) should be used for video playback

Implementation:

- Done through MVP pattern.
- Used Swift 5 (with Xcode 10.2.1)
- The code is well organized and includes comments wherever appropriate.
- The visual design and UX is very simple, yet user-friendly.

Important Points:
- It supports online DRM/Clear content playback.
- The DRM used is Fairplay.
- The DRM contents can be downloaded. Multiple Download is supported(There is no limit to number of concurrent downloads).
- The offline DRM content playback is supported too.
- No external SDK is used. All are done using native AVPlayer itself.

Build Instructions:

In order to run the app, please use latest Xcode (atleast Xcode 10.2.1).
Cannot run on simulator as well. DRM contents playback is not supported in Simulator.
Must use actual device with OS > 11
