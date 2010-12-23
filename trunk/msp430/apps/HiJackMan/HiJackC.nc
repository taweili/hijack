// $Id$

configuration HiJackC
{
}
implementation
{
  components MainC as Main, HiJackM, LedsC, Msp430TimerC;
  HiJackM.Boot -> Main;
  HiJackM.Leds -> LedsC;
  HiJackM.Timer -> Msp430TimerC.TimerA;

  components HplMsp430GeneralIOC as GeneralIOC;


  HiJackM.Gpio -> GeneralIOC.Port17; // GPIO0 

  // Used to Generate Comm
  HiJackM.GenTimerControl -> Msp430TimerC.ControlB0;
  HiJackM.GenTimerCompare -> Msp430TimerC.CompareB0;
  HiJackM.FskOut -> GeneralIOC.Port40; // output signal to phone CCI0B

  // Used to decode
  components new GpioCaptureC() as CaptureFSKC;
  HiJackM.DecControlFsk -> Msp430TimerC.ControlA1;
  CaptureFSKC.Msp430TimerControl -> Msp430TimerC.ControlA1;
  CaptureFSKC.Msp430Capture -> Msp430TimerC.CaptureA1;
  CaptureFSKC.GeneralIO -> GeneralIOC.Port23; // we use the same as for FskIn since we just enable the function...
  HiJackM.FskIn -> GeneralIOC.Port23; // input signal from phone CCI1B

  HiJackM.DecCaptureFsk -> CaptureFSKC;

  components HiJackAppM;
  components new TimerMilliC() as Timer0;
  HiJackAppM.ADCTimer -> Timer0;
  HiJackAppM.ADCIn -> GeneralIOC.Port66; // ADC6
  HiJackAppM.HiJack -> HiJackM;
  HiJackAppM.Boot -> Main;
  HiJackAppM.Leds -> LedsC;
}

