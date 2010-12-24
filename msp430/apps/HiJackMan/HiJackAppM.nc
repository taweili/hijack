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

module HiJackAppM
{
  uses {
      interface Boot;
      interface Leds;

      interface HplMsp430GeneralIO as ADCIn;

      interface Timer<TMilli> as ADCTimer;

      interface HiJack;
  }

}
implementation
{

    uint32_t samplePeriod;
    uint8_t uartByteTx;
    uint8_t uartByteRx;
    uint8_t busy;

    event void Boot.booted()
    {
        atomic
        {
            samplePeriod = 2000;
            busy = 0;
        }

        // enable ADC6
        call ADCIn.makeInput();
        call ADCIn.selectModuleFunc();

        // manually enable ADC12
        atomic
        {
            ADC12CTL0 = ADC12ON + SHT0_7;         // Turn on ADC12, set sampling time
            ADC12CTL1 = CSTARTADD_0 + SHP;              // use ADC12MEM0, use sampling timer
            ADC12MCTL0 = INCH_6;              // select A6, Vref=1.5V
            //ADC12IE = 0x01;                           // Enable ADC12IFG.0

            call ADCTimer.startOneShot(samplePeriod);
        }
    }

    void task sendTask()
    {
        uint8_t i;

        atomic
        {
            ADC12CTL0 |= ENC;                       // enable ADC conversion
            ADC12CTL0 |= ADC12SC;                   // start conversion
        }

        for(i=0; i<100; i++);

        atomic
        {
            uartByteTx = (uint8_t)(ADC12MEM0>>4); // use the top 8 bits only

            //uartByteTx = 0xaa;
            //uartByteTx = uartByteRx;
            //uartByteTx += 1;
            //uartByteTx = 0x55;
        }
        call HiJack.send(uartByteTx);
    }

    event void ADCTimer.fired()
    {
        atomic
        {
            if(!busy)
            {
                busy = 1;
                post sendTask();
            }
            call ADCTimer.startOneShot(samplePeriod);
        }

    }

    async event void HiJack.sendDone( uint8_t byte, error_t error )
    {
        atomic
        {
            busy = 0;
        }
    }

    async event void HiJack.receive( uint8_t byte) {
        atomic
        {
            // map the byte to sampling rate
            samplePeriod = (uint16_t)2560.0/(byte+1)/2;
            uartByteRx = byte;
            //call ADCTimer.stop();
            //call ADCTimer.startOneShot(samplePeriod);
        }
    }
}

