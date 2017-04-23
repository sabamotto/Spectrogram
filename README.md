# Spectrogram

![Example Screenshot](../example/spectrogram-example.png?raw=true)

The Spectrogram Analyzer with Processing3 and Minim.
It has 2 graph sockets for comparison with another sound.

## Environment
- Processing 3
- Minim library

## How to use
First, choose your wav(PCM) or mp3 audio file.
If any errors occurred, you should convert it.
Another way, you can use your audio input device with pressing 'M' key.

## Key control
- File
  * O : Open a file into current graph socket
  * I : Open an audio input device
- Graph
  * 1 : Change Graph-1
  * 2 : Change Graph-2. If it's empty, then open a file
- Player
  * Return/Enter : Pause or Play
  * M : Mute / Unmute
  * R : Replay -- Seek to first position
  * ← : Move backward
  * → : Move forward
- Spectrogram
  * Z : Enable/Disable Lanczos-3 Interpolation
  * X : Change Linear/Log-scale for Frequency-axis
  * C : Change Linear/dB for Power
- Help
  * Others : Display key control help for 5 secs

## Author
@sabamotto
