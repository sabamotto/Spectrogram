import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;

Minim minim;
AudioPlayer song;
FFT         fft;
int time = -1, bpos = 0;
int tgt = 1;

void setup() {
  size(1024, 640, P3D);
  colorMode(HSB, 360, 100, 100);
  frameRate(30);
  
  minim = new Minim(this);
  selectSound();
}

synchronized void selectSound() {
//  if (song != null) song.close();
  if (song != null && song.isPlaying()) song.pause();
  selectInput("MP3かWAVを選択してください", "fileSelected");
}

void fileSelected(File selection) {
  if (selection == null) return;
  String file = selection.getAbsolutePath();
  
  if (song != null) song.close();
  song = minim.loadFile(file,1024);
  song.play();
  
  fft = new FFT(song.bufferSize(), song.sampleRate());
  fft.window(FFT.HAMMING);
  time = 0; bpos = -1;
}

void draw() {
  if (time < 0) {
    background(0);
    time = 0;
  }
  
  if (song == null) return;
  if (!song.isPlaying()) return;
  
  if (song.position() <= bpos) return;
  bpos = song.position();
  
  // display spectrum
  fft.forward(song.mix);
  int shei = (height-32)/2;
  int maxfreq = 0;
  float maxpeek = 0;
  stroke(0); line(0.5f+time, shei*(tgt-1), 0.5f+time, shei*tgt);
  for (int i = 0; i < fft.specSize(); i++)
  {
    float db = max(0, 100+log(0.0001f+fft.getBand(i)/16f)*18f);
//    float db = fft.getBand(i)*16f;
//    line( i, height/2, i, height/2+y );
//    int y = i*2*shei/fft.specSize();
    int y = i;
    if (y > shei) break;
    color c = color(fft.getBand(i)*12f, 100, db);
    set(time, shei*tgt-y, c);
    set(time+1, shei*tgt-y, c);
    
    if (maxpeek < fft.getBand(i)) {
      maxfreq = i;
      maxpeek = fft.getBand(i);
    }
  }
  time+=2; if (time >= width) time = 0;
  stroke(255); line(0.5f+time, shei*(tgt-1), 0.5f+time, shei*tgt);
  
  line(0, shei, width, shei);
  line(0, shei*2, width, shei*2);
  
  // display wave
//  stroke(0, 0, 255);
//  for (int i = 0; i < song.left.size()-1; i++)
//  {
//    line(i, height/6 + song.mix.get(i)*100, i+1, height/6 + song.mix.get(i+1)*100);
//  }
  
  // display information
  noStroke();
  fill(0);
  rect(0,height-32, width,height);
  fill(240);
  text(
    "GraphArea="+tgt+
    ", Sf="+song.sampleRate()+
    ", WindowWidth="+fft.timeSize()+
    ", Time="+song.position()+"ms"+
    ", Peek="+maxpeek+"("+fft.indexToFreq(maxfreq)+")"
    , 8, height-8);
}

void keyPressed() {
  if (key == 'o' || key == 'O') selectSound();
  else if (key == '1') {tgt = 1; selectSound();}
  else if (key == '2') {tgt = 2; selectSound();}
  
  if (song == null) return;
  if (key == 'r' || key == 'R') song.play(0);
  else if (keyCode == RETURN || keyCode == ENTER) {
    if (song.isPlaying()) song.pause();
    else song.play();
  } else if (keyCode == LEFT) song.cue(max(0,song.position()-2000));
  else if (keyCode == RIGHT) song.skip(1000);
}

void stop() {
  // the AudioPlayer you got from Minim.loadFile()
  if (song != null) song.close();
  minim.stop();
  super.stop();
}

