interface StreamStruct {}
class SpectrumStream {
  Minim minim;
  
  AudioPlayer player;
  AudioInput in;
  
  int windowSize;
  FFT fft;
  
  int previousPosition;
  int lastPosition;
  
  StreamStruct struct;

  SpectrumStream(Minim minim, int wsize) {
    this.minim = minim;
    this.windowSize = wsize;
    this.fft = null;

    this.player = null; 
    this.in = null;
    
    this.previousPosition = -1;
    this.lastPosition = 0;
  }
  
  void initFile(String file) {
    this.close();
    player = minim.loadFile(file, windowSize);
  }
  void initInput() {
    this.close();
    in = minim.getLineIn(Minim.MONO, windowSize);
    // MEMO: Position calculation should be implemented with in.addListener(..)
    previousPosition = lastPosition = millis();
  }
  
  FFT getFFT() {
    if (fft == null) {
      if (player != null)
        fft = new FFT(player.bufferSize(), player.sampleRate());
      else if (in != null)
        fft = new FFT(in.bufferSize(), in.sampleRate());
      else
        return null;
      fft.window(FFT.HAMMING);
    }

    if (player != null)
      fft.forward(player.mix);
    else if (in != null)
      fft.forward(in.mix);

    return fft;
  }
  
  void start() {
    if (player != null)
      player.play();
    else if (in != null)
      in.enableMonitoring();
    else
      println("warning: stream is not initialized");
  }
  
  void restart() {
    if (player != null)
      player.play(0);
    else
      this.start();
  }
  
  void stop() {
    if (player != null) {
      player.pause();
    } else if (in != null) {
      in.disableMonitoring();
      lastPosition = millis();
    }
  }
  
  void close() {
    if (player != null)
      player.close();
    else if (in != null)
      in.disableMonitoring();

    player = null;
    in = null;
    fft = null;
    
    previousPosition = -1;
    lastPosition = 0;
  }
  
  void seekRelative(int offset) {
    if (player == null) return;

    if (offset > 0)
      player.skip(offset);
    else if (offset < 0)
      player.cue(max(0,player.position()+offset));
  }
  
  int position() {
    if (player != null) {
      return player.position();
    } else if (in != null) {
      if (in.isMonitoring()) return millis() - previousPosition;
      else return lastPosition;
    } else {
      return 0;
    }
  }
  
  int bufferSize() {
    if (player != null)
      return player.bufferSize();
    else if (in != null)
      return in.bufferSize();
    else
      return windowSize;
  }
  
  float sampleRate() {
    if (player != null)
      return player.sampleRate();
    else if (in != null)
      return in.sampleRate();
    else
      return 44100;
  }
  
  boolean hasBuffered() {
    if (player != null) {
      boolean result = player.position() > previousPosition;
      previousPosition = player.position();
      return result;
    } else if (in != null) {
      return in.isMonitoring();
    } else {
      return false;
    }
  }
  
  boolean isStreaming() {
    if (player != null)
      return player.isPlaying();
    else if (in != null)
      return in.isMonitoring();
    else
      return false;
  }
  
  boolean isPlayer() {
    return player != null;
  }
  boolean isInput() {
    return in != null;
  }
  boolean isInitialized() {
    return player != null || in != null;
  }
}