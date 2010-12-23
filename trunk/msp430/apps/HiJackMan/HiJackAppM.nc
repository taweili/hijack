/**
 *
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

