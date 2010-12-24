/**
 * Copyright (c) 2010 The Regents of the University of Michigan. All
 * rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 
 * - Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the
 *  distribution.
 * - Neither the name of the copyright holder nor the names of
 *  its contributors may be used to endorse or promote products derived
 *  from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Author: Thomas Schmid
 */

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

