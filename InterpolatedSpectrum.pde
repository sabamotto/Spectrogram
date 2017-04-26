static float LN10 = 2.30258509299f;

class InterpolatedSpectrum {
  public boolean logScaleFreq = false;
  public float coefFreq = 1f;

  public boolean logScalePower = true;
  public float coefPower = 1f;

  public boolean interpolation = true;
  public float interpolateRange = 1f;

  private FFT fft;
  private int specSize;
  private float[] spectrum;
  private float maxPower;

  public void setFFT(FFT fft) {
    this.fft = fft;
    this.specSize = fft.specSize();
    this.spectrum = new float[specSize];
    
    // calculate an integrated window function
    float[] wbuf = new float[fft.timeSize()];
    for (int i = 0; i < fft.timeSize(); ++i) wbuf[i] = 1f;
    FFT wfft = new FFT(fft.timeSize(), 44100);
    wfft.forward(wbuf);
    wfft.inverse(wbuf);
    this.maxPower = 0f;
    for (int i = 0; i < fft.timeSize(); ++i) this.maxPower += wbuf[i];
  }
  
  public void load(FFT fft) {
    if (this.fft != fft) this.setFFT(fft);
    for (int i = 0; i < this.specSize; ++i) spectrum[i] = fft.getBand(i);
  }
  
  public float getPower(float index) {
    float power = 0f;
    if (this.interpolation && index < this.specSize*interpolateRange) {
      // Lanczos-3 Interpolate
      int bFil = floor(index) - 2;
      if (bFil < 0) bFil = 0;
      int eFil = bFil + 5;
      if (eFil > this.specSize) eFil = this.specSize;
      for (int i = bFil; i < eFil; ++i) {
        power += this.spectrum[i] * lanczos3(index - i);
      }
    } else {
      power = this.spectrum[floor(index)];
    }
    power *= this.coefPower;
    
    return this.convertPowerToLinOrLog(power);
  }
  
  public float getMaxPower(float beginIndex, float endIndex) {
    if (endIndex-beginIndex < 0) {
      float tmp = beginIndex;
      beginIndex = endIndex;
      endIndex = tmp;
    }
    
    if (endIndex-beginIndex < 1f) {
      return this.getPower(endIndex);
    }
    
    float power = 0f;
    int floorBeginIndex = floor(beginIndex);
    if (beginIndex > floorBeginIndex) {
      if (this.interpolation && floorBeginIndex < this.specSize*interpolateRange) {
        // Lanczos-3 Interpolate
        int bFil = floor(beginIndex) - 2;
        if (bFil < 0) bFil = 0;
        int eFil = bFil + 5;
        if (eFil > this.specSize) eFil = this.specSize;
        for (int i = bFil; i < eFil; ++i) {
          power += this.spectrum[i] * lanczos3(beginIndex - i);
        }
      } else {
        power = this.spectrum[floorBeginIndex];
      }
    }
    for (int i = ceil(beginIndex); i < endIndex; i++) {
      power = max(power, this.spectrum[i]);
    }
    
    return this.convertPowerToLinOrLog(power);
  }
  
  public float getIndex(float g) {
    g *= this.coefFreq;
    
    float index = 0f;
    if (this.logScaleFreq) {
      // map from 0~1 to {Band width}~{SR/2}Hz
      index = pow(this.specSize, g);
    } else {
      index = g * this.specSize;
    }
    
    if (index < 0) index = 0;
    else if (index >= this.specSize-1) index = this.specSize-1;
    return index;
  }
  
  public float indexToFreq(float index) {
    return this.fft.getBandWidth() * index;
  }
  
  public float dbPower(float power) {
    if (this.logScalePower) {
      if (Float.isFinite(power)) {
        power = pow(maxPower, power) / this.maxPower;
      } else {
        return Float.NEGATIVE_INFINITY;
      }
    }
    return 20f * log(power / this.coefPower) / LN10;
  }
  
  protected float sinc_PI(float x) {
    if (x == 0) return 1f;
    else return sin(PI*x) / (PI*x);
  }
  protected float lanczos3(float x) {
    if (x <= -3 || x >= 3) return 0f;
    else return sinc_PI(x) * sinc_PI(x/3);
  }
  
  private float convertPowerToLinOrLog(float power) {
    if (this.logScalePower) {
      //if (power <= 1) power = 0f; // enabled signal filter
      return log(power) / log(this.maxPower);
    } else {
      return power / this.maxPower;
    }
  }
}