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
 *
 */

module MotePlatformC @safe() {
  provides interface Init;
  uses interface Init as SubInit;
}
implementation {

  command error_t Init.init() {
    // reset all of the ports to be input and using i/o functionality
    atomic
      {
	P1SEL = 0;
	P2SEL = 0;
	P3SEL = 0;
	P4SEL = 0;
	//P5SEL = 0x20; // output SMCLK on P5.5
    P5SEL = 0;
	P6SEL = 0;

    /*
	P1OUT = 0x00;
	P1DIR = 0xe0;

	P2OUT = 0x30;
	P2DIR = 0x7b;

	P3OUT = 0x00;
	P3DIR = 0xf1;

	P4OUT = 0xdd;
	P4DIR = 0xfd;

	P5OUT = 0xff;
	P5DIR = 0xff;

	P6OUT = 0x00;
	P6DIR = 0xff;
*/
    /*
	P1OUT = 0x00;
	P1DIR = 0xf9;

	P2OUT = 0x00;
	P2DIR = 0xd3;

	P3OUT = 0x00;
	P3DIR = 0x5f;

	P4OUT = 0x00;
	P4DIR = 0xfe;

	P5OUT = 0x00;
	P5DIR = 0xff;

	P6OUT = 0x00;
	P6DIR = 0xff;
*/
	P1OUT = 0x00;
	P1DIR = 0x00;

	P2OUT = 0x00;
	P2DIR = 0x00;

	P3OUT = 0x00;
	P3DIR = 0x00;

	P4OUT = 0x00;
	P4DIR = 0x00;

	P5OUT = 0x00;
	//P5DIR = 0x20;
	P5DIR = 0x00;

	P6OUT = 0x00;
	P6DIR = 0x00;

	P1IE = 0;
	P2IE = 0;

	// the commands above take care of the pin directions
	// there is no longer a need for explicit set pin
	// directions using the TOSH_SET/CLR macros

      }//atomic
    return call SubInit.init();
  }

 default command error_t SubInit.init() { return SUCCESS; }
}
