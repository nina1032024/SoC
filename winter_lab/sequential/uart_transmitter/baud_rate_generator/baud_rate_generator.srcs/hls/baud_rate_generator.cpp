/************************************************
Copyright (c) 2021, Mohammad Hosseinabady
	mohammad@highlevel-synthesis.com.
	https://highlevel-synthesis.com/

All rights reserved.
Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its contributors
may be used to endorse or promote products derived from this software
without specific prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. // Copyright (c) 2020, Mohammad Hosseinabady.
************************************************/
#include "baud_rate_generator.h"


//9600 baud rate --> BAUD_RATE_NUMBER = (1s/9600)/10ns = (1000000000/9600)/10 = 10416
#define BAUD_RATE_NUMBER 10416

//for simulation
//#define BAUD_RATE_NUMBER 20

typedef enum{zero, one} baud_rate_states_type;
void baud_rate_generator(bool &baud_rate_signal) {
#pragma HLS INTERFACE ap_none port=baud_rate_signal
#pragma HLS INTERFACE ap_ctrl_none port=return


	static baud_rate_states_type state = zero;
	static unsigned int counter = BAUD_RATE_NUMBER-1;


	baud_rate_states_type next_state;
	unsigned int          next_counter;

	bool baud_rate_signal_local;

	switch(state) {
	case zero:
		if (counter == 1) {
			next_counter           = counter-1;
			next_state             = one;
		} else {
			next_counter           = counter-1;
			next_state             = zero;
		}
		baud_rate_signal_local = 0;
		break;
	case one:
		next_counter           = BAUD_RATE_NUMBER-1;
		next_state             = zero;
		baud_rate_signal_local = 1;

		break;
	default:
		break;
	}

	state = next_state;
	counter = next_counter;
	baud_rate_signal = baud_rate_signal_local;
}

