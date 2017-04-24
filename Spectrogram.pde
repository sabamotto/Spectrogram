/**
 * 2-graphs Spectrogram Analyzer
 * Copyright(c) 2013-2017 SabaMotto.
 */

import ddf.minim.*;
import ddf.minim.analysis.*;

// Window Function Size for FFT
static int WINDOW_SIZE = 2048;//1024;

// Statusbar Height
static int STATUS_HEIGHT = 32;

// Brightness Coefficient (100:full-scale)
static float BRIGHTNESS_COEF = 180;

Minim minim;
InterpolatedSpectrum is;

SpectrumStream[] streams = new SpectrumStream[2];
int graph = 0;

int helpTime = 0;
boolean autoplay = false;

class SD implements StreamStruct {
  int time = -1;
  
  float maxPeek = 0f;
  float maxFreq = 0f;
  
  float maxPeek500ms = 0f;
  float maxFreq500ms = 0f;
  int maxPos500ms = 0;
  
  color[] spectrum;
  
  SD() {
    this.spectrum = new color[(height - STATUS_HEIGHT)/2];
  }
}

void setup() {
  size(1200, 800, P3D);
  colorMode(HSB, 360, 100, 100);
  background(0);
  frameRate(30);
  
  minim = new Minim(this);
  
  for (int i = 0; i < streams.length; i++) {
    streams[i] = new SpectrumStream(minim, WINDOW_SIZE);
    streams[i].struct = new SD();
  }
  
  // Spectrum Configure
  is = new InterpolatedSpectrum();
  is.logScaleFreq = true;
  is.coefFreq = 1.0f;
  is.logScalePower = true;
  is.coefPower = 1.0f;
  is.interpolation = true;
  is.interpolateRange = 0.5f;
  
  selectAudioFile();
}

void selectAudioFile() {
  streams[graph].stop();
  selectInput("Please choose your wav(PCM) or mp3 file", "fileSelected");
}

void fileSelected(File selection) {
  if (selection == null) return;
  
  String file = selection.getAbsolutePath();
  SpectrumStream stream = streams[graph];
  
  stream.close();
  stream.initFile(file);
  stream.struct = new SD();
  // lazy play for optimizing draw method
  //stream.start();
  autoplay = true;
  
  is.setFFT(stream.getFFT());
}

void selectAudioInput() {
  SpectrumStream stream = streams[graph];
  
  stream.close();
  stream.initInput();
  stream.struct = new SD();
  
  is.setFFT(stream.getFFT());
}

void draw() {
  SpectrumStream stream = streams[graph];
  
  drawStatus();
  
  if (!stream.isInitialized()) return;
  if (!autoplay && !stream.isStreaming()) return;
  
  if (stream.hasBuffered()) drawSpectrogram();
}

void drawSpectrogram() {
  SpectrumStream stream = streams[graph];
  SD s = (SD) stream.struct;
  
  is.load(stream.getFFT());
  
  int shei = (height-32)/2;
  s.maxFreq = s.maxPeek = 0f;
  stroke(0); line(0.5f+s.time, shei*graph, 0.5f+s.time, shei*(graph+1));
  for (int i = 0; i < shei; ++i)
  {
    float freqRatio = (float)(i) / shei;
    float freqIndex = is.getIndex(freqRatio);
    float power = is.getPower(freqIndex);
    // MEMO: Strictly calculation, it should be an integrated power
    
    color c = color(max(0, 360*power*power), 100, BRIGHTNESS_COEF*power);
    if (is.interpolation) {
      // Linear interpolation
      set(s.time, shei*(graph+1)-i, lerpColor(s.spectrum[i], c, .5));
    } else {
      set(s.time, shei*(graph+1)-i, c);
    }
    set(s.time+1, shei*(graph+1)-i, c);
    
    s.spectrum[i] = c;
    
    if (s.maxPeek < power) {
      s.maxFreq = freqIndex;
      s.maxPeek = power;
    }
  }
  
  if (stream.position() - s.maxPos500ms > 500 || s.maxPeek500ms < s.maxPeek) {
    s.maxPeek500ms = s.maxPeek;
    s.maxFreq500ms = s.maxFreq;
    s.maxPos500ms = stream.position();
  }
  
  s.time+=2; if (s.time >= width) s.time = 0;
  stroke(255); line(0.5f+s.time, shei*graph, 0.5f+s.time, shei*(graph+1));
  
  line(0, shei, width, shei);
  line(0, shei*2, width, shei*2);
  
  // display wave
  //stroke(0, 0, 255);
  //for (int i = 0; i < song.left.size()-1; i++)
  //{
  //  line(i, height/6 + song.mix.get(i)*100, i+1, height/6 + song.mix.get(i+1)*100);
  //}
  
  if (autoplay) {
    stream.start();
    autoplay = false;
  }
}

void drawStatus() {
  SpectrumStream stream = streams[graph];
  SD s = (SD) stream.struct;
  
  noStroke();
  fill(0);
  rect(0,height-32, width,height);
  fill(240);
  if (stream.isInitialized() && is.fft != null && millis() - helpTime >= 5000) {
    helpTime = 0;
    text(
      "Graph"+(graph+1)+
      "  Sf="+stream.sampleRate()+
      "  Gain="+nf(is.coefPower, 1, 1)+
      ", WindowWidth="+floor(stream.windowSize)+
      ", Time="+nfc(stream.position())+"ms"+
      ", Peek="+nfs(is.dbPower(s.maxPeek), 2, 3)+"dB"+
      "("+nf(is.indexToFreq(s.maxFreq), 5, 1)+"Hz)"+
      ", 500ms="+nfs(is.dbPower(s.maxPeek500ms), 2, 3)+
      "dB("+nf(is.indexToFreq(s.maxFreq500ms), 5, 1)+"Hz)"
      , 8, height-8);
  } else {
    text(
      "Keys: [O]pen File (to Graph[1] or [2]), Open [I]nput, [R]eplay"+
      ", [↵]Pause/Play, [M]ute, [←]Move Backward, [→]Move Forward"+
      ", Change [Z]Interpolation, Change Linear/Log-scale for [X]Freq./[C]Power"
      , 8, height-8);
  }
}

void keyPressed() {
  SpectrumStream stream = streams[graph];
  SD s = (SD) stream.struct;
  
  int roundedKey = key;
  if ('a' <= roundedKey && roundedKey <= 'z') roundedKey -= 'a' - 'A';
  switch (keyCode) {
    case RETURN: case ENTER: roundedKey = '\n'; break;
    case LEFT:  roundedKey = '<'; break;
    case RIGHT: roundedKey = '>'; break;
    case UP:    roundedKey = '+'; break;
    case DOWN:  roundedKey = '-'; break;
  }
  
  switch (roundedKey) {
    case 'O': selectAudioFile(); break;
    case 'I': selectAudioInput(); break;
    
    case '1': case '2':
      stream.stop();
      // change the target graph (mapping: 1~2 keys to 0~1)
      graph = roundedKey - '1';
      
      if (!streams[graph].isInitialized()) selectAudioFile();
      break;
    
    case 'R': stream.restart(); break;
    case 'M':
      if (stream.isMuted()) stream.unmute();
      else stream.mute();
      break;
    case '\n':
      if (stream.isStreaming()) stream.stop();
      else stream.start();
      break;
    case '<': stream.seekRelative(-2000); break;
    case '>': stream.seekRelative(1000); break;
    
    case '+':
      is.coefPower += .1;
      if (is.coefPower > 3f) is.coefPower = 3f;
      break;
    case '-':
      is.coefPower -= .1;
      if (is.coefPower < .1) is.coefPower = .1;
      break;
    case 'Z': is.interpolation = !is.interpolation; break;
    case 'X': is.logScaleFreq = !is.logScaleFreq; break;
    case 'C': is.logScalePower = !is.logScalePower; break;
    
    default:
      if (helpTime > 0) helpTime = 0;
      else helpTime = millis();
  }
}

void stop() {
  for (SpectrumStream stream : streams) stream.close();
  minim.stop();
  super.stop();
}