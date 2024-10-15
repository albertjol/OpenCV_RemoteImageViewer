# OpenCV_RemoteImageViewer
Simple image viewer to visualize cv::Mat's (or actually streamed jpegs) from a headless system

## Requirements
Uses: 
- Lazarus
- Synapse (install in Lazarus with Online Package Manager

## How it works
It expects an image encoded as JPEG, (ending with 0xFFD9) ([wiki](https://en.wikipedia.org/wiki/JPEG#Syntax_and_structure)), on a TCP Socket. Then it loads it as JPEG in a TImage.
For the client side: see examples

## Todo
- Make it robust against disconnects, etc.
- Maybe i'll extend it so you can use it like imshow, where it throws a window for every image
- Add controls so you can change parameters on the fly
