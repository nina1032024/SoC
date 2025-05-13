#include "fir.h"

void __attribute__ ( ( section ( ".mprjram" ) ) ) initfir() {
	//initial your fir to 0
	for(int i = 0; i < N; i++){
		inputbuffer[i] = 0;
		outputsignal[i] = 0;
	}
}

int* __attribute__ ( ( section ( ".mprjram" ) ) ) fir(){
	// initialize
	initfir();

	// signal processing
	for(int i = 0; i < N ; i++){
		// signal input
		for(int j = N - 1; j > 0; j--){
			inputbuffer[j] = inputbuffer[j - 1]; 
		}
		inputbuffer[0] = inputsignal[i];
		
		// calculation
		for(int k = 0; k < N; k++){
			outputsignal[i] += inputbuffer[k] * taps[k];
		}
	}
	return outputsignal;
}
		
