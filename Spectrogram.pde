/**
 * 2-sockets Spectrogram Analyzer
 * Copyright(c) 2013-2017 SabaMotto.
 */

import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;

static int WINDOW_SIZE = 1024;

Minim minim;
InterpolatedSpectrum is;

SpectrumStream[] streams = new SpectrumStream[2];
int tgt = 0;

int helpTime = 0;
boolean autoplay = false;

class SD implements StreamStruct {
  int time = -1;
  
  float maxPeek = 0;
  float maxFreq = 0;
  
  float maxPeek500ms = 0f;
  float maxFreq500ms = 0;
  int maxPos500ms = 0;
}

void setup() {
  size(1200, 640, P3D);
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
  
  selectSound();
}

void selectSound() {
  streams[tgt].stop();
  selectInput("Please choose your wav(PCM) or mp3 file", "fileSelected");
}

void fileSelected(File selection) {
  if (selection == null) return;
  
  String file = selection.getAbsolutePath();
  SpectrumStream stream = streams[tgt];
  
  stream.close();
  stream.initFile(file);
  stream.struct = new SD();
  // lazy play for optimizing draw method
  //stream.start();
  autoplay = true;
  
  is.setFFT(stream.getFFT());
}

void selectAudioInput() {
  SpectrumStream stream = streams[tgt];
  
  stream.close();
  stream.initInput();
  stream.struct = new SD();
  
  is.setFFT(stream.getFFT());
}

void draw() {
  SpectrumStream stream = streams[tgt];
  SD s = (SD) stream.struct;
  
  drawStatus();
  
  if (!stream.isInitialized()) return;
  if (!autoplay && !stream.isStreaming()) return;
  
  if (stream.hasBuffered()) drawSpectrogram();
}

void drawSpectrogram() {
  SpectrumStream stream = streams[tgt];
  SD s = (SD) stream.struct;
  
  is.load(stream.getFFT());
  
  int shei = (height-32)/2;
  s.maxFreq = s.maxPeek = 0f;
  stroke(0); line(0.5f+s.time, shei*tgt, 0.5f+s.time, shei*(tgt+1));
  for (int i = 0; i < shei; ++i)
  {
    float freqRatio = (float)(i) / shei;
    float freqIndex = is.getIndex(freqRatio);
    float power = is.getPower(freqIndex);
    
    color c = color(max(0, 360*power*power), 100, 200*power);
    set(s.time, shei*(tgt+1)-i, c);
    set(s.time+1, shei*(tgt+1)-i, c);
    
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
  stroke(255); line(0.5f+s.time, shei*tgt, 0.5f+s.time, shei*(tgt+1));
  
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
  noStroke();
  fill(0);
  rect(0,height-32, width,height);
  fill(240);
  if (millis() - helpTime >= 5000) {
    SpectrumStream stream = streams[tgt];
    SD s = (SD) stream.struct;
    
    helpTime = 0;
    if (!stream.isInitialized()) return;
    text(
      "Graph"+(tgt+1)+
      "  Sf="+stream.sampleRate()+
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
  SpectrumStream stream = streams[tgt];
  
  boolean keyChecked = true;
  if (key == 'o' || key == 'O') selectSound();
  else if (key == 'i' || key == 'I') selectAudioInput();
  else if (key == '1') {
    stream.stop(); tgt = 0;
    if (!streams[tgt].isInitialized()) selectSound();
  } else if (key == '2') {
    stream.stop(); tgt = 1;
    if (!streams[tgt].isInitialized()) selectSound();
  } else
    keyChecked = false;
  
  if (!stream.isInitialized()) return;
  
  if (key == 'r' || key == 'R') stream.restart();
  else if (key == 'm' || key == 'M')
    if (stream.isMuted()) stream.unmute();
    else stream.mute();
  else if (keyCode == RETURN || keyCode == ENTER) {
    if (stream.isStreaming()) stream.stop();
    else stream.start();
  } else if (keyCode == LEFT) stream.seekRelative(-2000);
  else if (keyCode == RIGHT) stream.seekRelative(1000);
  
  else if (key == 'z' || key == 'Z') is.interpolation = !is.interpolation;
  else if (key == 'x' || key == 'X') is.logScaleFreq = !is.logScaleFreq;
  else if (key == 'c' || key == 'C') is.logScalePower = !is.logScalePower;
  
  else if (!keyChecked) {
    if (helpTime > 0) helpTime = 0;
    else helpTime = millis();
  }
}

void stop() {
  for (SpectrumStream stream : streams) stream.close();
  minim.stop();
  super.stop();
}