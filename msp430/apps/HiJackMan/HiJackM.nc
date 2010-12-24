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

#include <Msp430Timer.h>
//#include <printf.h>

module HiJackM
{
  uses {
      interface Boot;
      interface Leds;

      interface Msp430Timer as Timer;
      interface HplMsp430GeneralIO as Gpio;

      // Generate Comm
      interface Msp430TimerControl as GenTimerControl;
      interface Msp430Compare as GenTimerCompare;
      interface HplMsp430GeneralIO as FskOut;


      interface HplMsp430GeneralIO as FskIn;
      interface Msp430TimerControl as DecControlFsk;
      interface GpioCapture as DecCaptureFsk;  // used to measure frequency

  }
  provides
  {
      interface HiJack;
  }

}
implementation
{

#define FSYM0 0
#define FSYM1 1
//#define INTERVAL 732 // about 366us
#define INTERVAL 11 // about 366us

// SMCLK clock intervals
//#define SHORTINTERVAL 540  // anything shorter than this is a short interval
//#define LONGINTERVAL 900
// ACLK clock intervals
#define SHORTINTERVAL 17  // anything shorter than this is a short interval
#define LONGINTERVAL 34


    uint8_t currentSym; // saves the current symbol that's output on the frequency pin.
    uint8_t currentPin;
    uint16_t lastTime;   // saves the time stamp of the last 0-crossing
    uint8_t zeros;
    uint8_t ones;
    uint8_t startBit;
    uint8_t bitCounter;
    uint8_t uartByteTx;
    uint8_t uartByteRx;
    uint8_t busy;
    uint8_t txParity;
    uint8_t rxParity;
    //uint16_t diffs[128];
    //uint8_t diffsn = 0;

    uint8_t txState;
    uint8_t txBit;
    uint8_t sendingByteTx;

    uint8_t state;

    enum
    {
        STARTBIT,
        STARTBIT_FALL,
        DECODE,
        STOPBIT,
        BYTE,
        IDLE,
    };

    uint8_t sampleTimes[10];
    uint8_t sampleNum;
    uint8_t samplePeriod;

    msp430_compare_control_t y_both = {
         cm     : 3,  // capture on both edge
         //cm     : 1,  // capture rising
         ccis   : 1,  // capture input select
         clld   : 0,  // TBCL1 loads on write to TBCCR1
         cap    : 1,  // capture mode
         outmod : 0,  // toggle out pin
         ccie   : 1,  // capture compare interrupt enable
    };
    msp430_compare_control_t y_falling = {
         cm     : 2,  // capture falling edge
         ccis   : 1,  // capture input select
         clld   : 0,  // TBCL1 loads on write to TBCCR1
         cap    : 1,  // capture mode
         outmod : 0,  // toggle out pin
         ccie   : 1,  // capture compare interrupt enable
    };
    msp430_compare_control_t y_rising = {
         cm     : 1,  // capture rising edge
         ccis   : 1,  // capture input select
         clld   : 0,  // TBCL1 loads on write to TBCCR1
         cap    : 1,  // capture mode
         outmod : 0,  // toggle out pin
         ccie   : 1,  // capture compare interrupt enable
    };
    // configuration for the comparator. We use the "toggle" output mode.
    // There is no TinyOS interface to set only this mode, thus a full
    // reconfiguration.
    msp430_compare_control_t x = {
         cm     : 1,  // capture on rising edge
         ccis   : 1,  // capture/compare input select
         clld   : 0,  // TBCL1 loads on write to TBCCR1
         cap    : 0,  // compare mode
         outmod : 1,  // set out pin
         ccie   : 1,  // capture compare interrupt enable
    };


    void startFSK()
    {
        atomic
        {
            currentSym = 1;
            currentPin = 1;
            txState = IDLE;
            // enable UART in at pin p1.2
            // Note, UART is high if nothing happens...
            call GenTimerCompare.setEventFromNow( INTERVAL );
            call GenTimerControl.enableEvents();
        }
    }

    void stopFSK()
    {
        // wait for the TX buffer to be empty
        //call TimerControl.disableEvents();
    }

    event void Boot.booted()
    {
        //uint16_t i;



        atomic
        {
            zeros = 0;
            ones = 0;
            lastTime = 0;
            startBit = 0;
            uartByteTx = 0;
            busy = 0;
            sampleNum = 0;
            samplePeriod = 10;
        }

        //for(i=0; i<128; i++)
        //    diffs[i] = 0;

        // enable the timer compare on port P4.3 (TB3, epic port 66)
        call FskOut.makeOutput();
        call FskOut.selectModuleFunc();

        call Gpio.makeOutput();

        // setup the timer comparator
        call GenTimerControl.setControlAsCompare();
        atomic call GenTimerControl.setControl(x);

        // setup Comparator A
        CACTL1 = CARSEL+CAREF_2;                     // Comp. A Int. Ref. enable on CA1
                                                     // Comp. A Int. Ref. Select 2 : 0.5*Vcc
        CACTL2 = P2CA0+CAF;                          // Comp. A Connect External Signal to CA0
                                                     // Comp. A Enable Output Filter
        // enable comparator CA0 on P2.3 (P40 on epic)
        call FskIn.makeInput();
        call FskIn.selectModuleFunc();

        //call CAOut.makeOutput();
        //call CAOut.selectModuleFunc();

        // Initialize Timer!!!
        //BCSCTL2 = SELM_0 | DIVM_0 | DIVS_3; // MCLK=DCO/1, SMCLK=DCO/8 (~2MHz)
        call Timer.clear();
        call Timer.disableEvents();
        //call Timer.setClockSource(MSP430TIMER_SMCLK);
        call Timer.setClockSource(MSP430TIMER_ACLK);
        call Timer.setInputDivider(MSP430TIMER_CLOCKDIV_1); // div by 1
        call Timer.clear();
        call Timer.enableEvents();

        //call CaptureFsk.captureRisingEdge();
        // Initialize_Demodulator
        // HACK: don't know how to configure this mode in TinyOS...
        //atomic TACCTL1 = CM_3+CCIS_1+SCS+CAP;               // Capture mode: 3 - both edges
                                                     // Capture input select: 1 - CCIxB from Comp.A
                                                     // Capture sychronize
                                                     // Capture Mode
        // we know we start with a '1'. So look for falling edge.
        atomic state = STARTBIT;
        call DecControlFsk.setControl(y_rising);

        // Start_Timer
        call Timer.setMode(MSP430TIMER_CONTINUOUS_MODE); // go!

        // enable comparator
        CACTL1 |= CAON;

        //call Leds.led2Toggle();
        startFSK();

        call Gpio.set();
        call Gpio.clr();
        call Gpio.set();
        call Gpio.clr();

    }

    async command error_t HiJack.send( uint8_t byte )
    {

        atomic
        {
            if (txState != IDLE)
            {
                return EBUSY;
            }
            txState = STARTBIT;
            sendingByteTx = byte;
            txBit = 0;
            return SUCCESS;
        }
    }

    /*
     * Used to generate the FSK
     */
    async event void GenTimerCompare.fired()
    {
        atomic
        {

            call GenTimerCompare.setEventFromPrev( INTERVAL );
            if(currentPin == 1)
            {
                // first iteration check for symbol
                if( currentSym == 0 )
                {
                    // have to set
                    x.outmod = 1;
                    call GenTimerControl.setControl(x);
                    currentPin = 2;
                    call Gpio.clr();
                }
                else
                {
                    // have to reset
                    x.outmod = 5;
                    call GenTimerControl.setControl(x);
                    currentPin = 2;
                    call Gpio.set();
                }
            }
            else
            {
                // second time, just toggle the pin
                x.outmod = 4;
                call GenTimerControl.setControl(x);
                currentPin = 1;

                switch(txState)
                {
                    case STARTBIT:
                        currentSym = 0;
                        txState = BYTE;
                        txBit = 0;
                        txParity = 0;
                        break;
                    case BYTE:

                        if(txBit < 8)
                        {
                            currentSym = (sendingByteTx >> txBit) & 0x01;
                            txBit++;
                            txParity += currentSym;
                        } else if (txBit == 8)
                        {
                            currentSym = txParity & 0x01;
                            txBit++;
                        } else if(txBit > 8)
                        {
                            // next bit is the stop bit
                            currentSym = 1;
                            txState = STOPBIT;
                        }
                        break;
                    case STOPBIT:
                        signal HiJack.sendDone(sendingByteTx, SUCCESS);
                    case IDLE:
                        currentSym = 1;
                        txState = IDLE;
                        break;
                }
            }
        }
    }


    async event void Timer.overflow() {};

/*
    void task debug()
    {

        uint8_t i;

        for(i=0; i<128; i++)
        {
            if(diffs[i] != 0)
            {
                printf("%d:%d\n", i, diffs[i]);
            }
            else
                break;
        }
        printf("\n");
        printfflush();
        for(i=0; i<128; i++)
            diffs[i] = 0;
    }
*/

    // Manchaster Decoder
    async event void DecCaptureFsk.captured(uint16_t time)
    {
        /*
         * 1. Detect Start Bit (1->0 transition)
         */

        uint16_t diff;
        atomic
        {
            diff = time - lastTime;

            switch(state)
            {
                case STARTBIT:
                    // configure for falling edge
                    call DecControlFsk.setControl(y_falling);
                    state = STARTBIT_FALL;
                    //diffsn = 0;
                    break;
                case STARTBIT_FALL:
                    if ((SHORTINTERVAL < diff) && (diff < LONGINTERVAL))
                    {
                        if( ones < 3)
                        {
                            // we didn't have enough ones
                            ones = 0;
                            call DecControlFsk.setControl(y_rising);
                            state = STARTBIT;
                        } else {
                            // looks like we got a 1->0 transition.
                            // become sensitive for both edges
                            //diffs[diffsn] = diff;
                            //diffsn++;
                            call DecControlFsk.setControl(y_both);
                            bitCounter = 0;
                            uartByteRx = 0;
                            //call UartOut.clr();
                            state = DECODE;
                        }
                    }
                    else
                    {
                        // no, we have to search again
                        call DecControlFsk.setControl(y_rising);
                        //call UartOut.set();
                        state = STARTBIT;
                        if(diff < SHORTINTERVAL)
                        {
                            // count the number of shorts for robustness
                            ones++;
                        }
                    }
                    break;
                case DECODE:
                    if ((SHORTINTERVAL < diff) && (diff < LONGINTERVAL))
                    {
                        //diffs[diffsn] = diff;
                        //diffsn++;
                        if (bitCounter >= 8)
                        {
                            // we got the whole byte. output stop bit and search
                            // for startbit
                            call DecControlFsk.setControl(y_rising);
                            signal HiJack.receive(uartByteRx);
                            //call UartOut.set();
                            //post debug();
                            state = STARTBIT;
                            ones = 0;
                            return;
                        }
                        // Check what transition it was
                        if (TACCTL1 & CCI)
                        {
                            // we read a 1
                            //call UartOut.set();
                            uartByteRx = (uartByteRx >> 1) + (1<<7);
                        }
                        else
                        {
                            // we got a 0
                            //call UartOut.clr();
                            uartByteRx = (uartByteRx >> 1);
                        }
                        bitCounter++;
                    }
                    else if (diff >= LONGINTERVAL)
                    {
                        // Something is wrong. start search again
                        //diffs[diffsn] = diff;
                        //diffsn++;
                        call DecControlFsk.setControl(y_rising);
                        //call UartOut.set();
                        //post debug();
                        state = STARTBIT;
                        ones = 0;
                    }
                    else
                    {
                        // return here and don't update the time!
                        return;
                    }
                    break;
                default:
                    break;
            }

            lastTime = time;
        }
    }

    default async event void HiJack.sendDone( uint8_t byte, error_t error ){}

    default async event void HiJack.receive( uint8_t byte) {}


}

