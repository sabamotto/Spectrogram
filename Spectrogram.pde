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

void setup() {
  size(1024, 640, P3D);
  colorMode(HSB, 360, 100, 100);
  frameRate(30);
  
  minim = new Minim(this);
  
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

AudioPlayer song;
FFT fft;

int helpTime = 0;
int time = -1;
int bpos = 0;
int tgt = 1;
boolean autoplay = false;

float maxPeek = 0;
float maxFreq = 0;

float maxPeek500ms = 0f;
float maxFreq500ms = 0;
int maxPos500ms = 0;

void selectSound() {
  //if (song != null) song.close();
  if (song != null && song.isPlaying()) song.pause();
  selectInput("Please choose your wav(PCM) or mp3 file", "fileSelected");
}

void fileSelected(File selection) {
  if (selection == null) return;
  
  String file = selection.getAbsolutePath();
  
  if (song != null) song.close();
  song = minim.loadFile(file, WINDOW_SIZE);
  // lazy play for optimizing draw method
  //song.play();
  autoplay = true;
  
  fft = new FFT(song.bufferSize(), song.sampleRate());
  fft.window(FFT.HAMMING);
  is.setFFT(fft);
  
  time = 0; bpos = -1;
}

void draw() {
  if (time < 0) {
    background(0);
    time = 0;
  }
  
  drawStatus();
  
  if (song == null) return;
  if (!autoplay && !song.isPlaying()) return;
  
  if (song.position() <= bpos) return;
  bpos = song.position();
  
  drawSpectrogram();
}

void drawSpectrogram() {
  fft.forward(song.mix);
  is.load();
  int shei = (height-32)/2;
  maxFreq = maxPeek = 0f;
  stroke(0); line(0.5f+time, shei*(tgt-1), 0.5f+time, shei*tgt);
  for (int i = 0; i < shei; ++i)
  {
    float freqRatio = (float)(i) / shei;
    float freqIndex = is.getIndex(freqRatio);
    float power = is.getPower(freqIndex);
    
    color c = color(max(0, 360*power*power), 100, 200*power);
    set(time, shei*tgt-i, c);
    set(time+1, shei*tgt-i, c);
    
    if (maxPeek < power) {
      maxFreq = freqIndex;
      maxPeek = power;
    }
  }
  
  if (song.position() - maxPos500ms > 500 || maxPeek500ms < maxPeek) {
    maxPeek500ms = maxPeek;
    maxFreq500ms = maxFreq;
    maxPos500ms = song.position();
  }
  
  time+=2; if (time >= width) time = 0;
  stroke(255); line(0.5f+time, shei*(tgt-1), 0.5f+time, shei*tgt);
  
  line(0, shei, width, shei);
  line(0, shei*2, width, shei*2);
  
  // display wave
  //stroke(0, 0, 255);
  //for (int i = 0; i < song.left.size()-1; i++)
  //{
  //  line(i, height/6 + song.mix.get(i)*100, i+1, height/6 + song.mix.get(i+1)*100);
  //}
  
  if (autoplay) {
    song.play();
    autoplay = false;
  }
}

void drawStatus() {
  noStroke();
  fill(0);
  rect(0,height-32, width,height);
  fill(240);
  if (millis() - helpTime >= 5000) {
    helpTime = 0;
    if (song == null) return;
    text(
      "Graph"+tgt+
      "  Sf="+song.sampleRate()+
      ", WindowWidth="+floor(fft.timeSize())+
      ", Time="+nfc(song.position())+"ms"+
      ", Peek="+nfs(is.dbPower(maxPeek), 2, 3)+"dB"+
      "("+nf(is.indexToFreq(maxFreq), 5, 1)+"Hz)"+
      ", 500ms="+nfs(is.dbPower(maxPeek500ms), 2, 3)+
      "dB("+nf(is.indexToFreq(maxFreq500ms), 5, 1)+"Hz)"
      , 8, height-8);
  } else {
    text(
      "Keys: [O]pen File (to Graph[1] or [2]), [R]eplay"+
      ", [↵]Pause/Play, [←]Move Backward, [→]Move Forward"+
      ", Change [I]nterpolation, Change Linear/Log-scale for [F]req./[P]ower"
      , 8, height-8);
  }
}

void keyPressed() {
  if (key == 'o' || key == 'O') selectSound();
  else if (key == '1') { tgt = 1; selectSound(); }
  else if (key == '2') { tgt = 2; selectSound(); }
  
  if (song == null) return;
  
  if (key == 'r' || key == 'R') song.play(0);
  else if (keyCode == RETURN || keyCode == ENTER) {
    if (song.isPlaying()) song.pause();
    else song.play();
  } else if (keyCode == LEFT) song.cue(max(0,song.position()-2000));
  else if (keyCode == RIGHT) song.skip(1000);
  
  else if (key == 'i' || key == 'I') is.interpolation = !is.interpolation;
  else if (key == 'f' || key == 'F') is.logScaleFreq = !is.logScaleFreq;
  else if (key == 'p' || key == 'P') is.logScalePower = !is.logScalePower;
  
  else if (helpTime > 0) helpTime = 0;
  else helpTime = millis();
}

void stop() {
  if (song != null) song.close();
  minim.stop();
  super.stop();
}