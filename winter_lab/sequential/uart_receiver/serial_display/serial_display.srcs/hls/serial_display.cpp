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
#include "serial_display.h"


void ascii27segment(
		ap_uint<8> ascii_data,
		ap_uint<8> &seven_segment_data)
{
	ap_uint<8> data_index;
	if (ascii_data >47 && ascii_data < 57) {
		data_index = ascii_data - 48;
	} else if (ascii_data >64 && ascii_data < 71) {
		data_index = (ascii_data - 65) + 10;
	} else {
		data_index = 16;
	}

	seven_segment_data = seven_segment_code[data_index];
}


void serial_display(
		ap_uint<8> ascii_data,
		bool data_valid,
		ap_uint<8> &seven_segment_data,
		ap_uint<4> &seven_segment_enable )
{
#pragma HLS PIPELINE
#pragma HLS INTERFACE ap_none port=ascii_data
#pragma HLS INTERFACE ap_none port=data_valid
#pragma HLS INTERFACE ap_none port=seven_segment_data
#pragma HLS INTERFACE ap_none port=seven_segment_enable
#pragma HLS INTERFACE ap_ctrl_none port=return

	static ap_uint<8> ascii_data_local = 71;
	ap_uint<8> seven_segment_data_local;
	if (data_valid == 1) {
		ascii_data_local = ascii_data;
	}
	ascii27segment(ascii_data, seven_segment_data_local);

	seven_segment_data   = seven_segment_data_local;
	seven_segment_enable = 0b1110;



}
