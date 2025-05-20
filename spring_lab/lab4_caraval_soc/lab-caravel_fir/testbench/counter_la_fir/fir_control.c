//to run simulation, you should chage the file name in "run_sim" from fir.c to fir_control.c
#include <defs.h>  //Caravel Memory Map IO 

// User Project 
#define reg_fir_control (*(volatile uint32_t*) 0x30000000)
#define reg_fir_data_len (*(volatile uint32_t*) 0x30000010)
#define reg_fir_tap_num (*(volatile uint32_t*) 0x30000014)

#define reg_fir_x (*(volatile uint32_t*) 0x30000040)
#define reg_fir_y (*(volatile uint32_t*) 0x30000044)

#define reg_fir_coeff     (*(volatile uint32_t*) 0x30000080)
// #define tap0 (*(volatile uint32_t*) 0x30000080)
// #define tap1 (*(volatile uint32_t*) 0x30000084)
// #define tap2 (*(volatile uint32_t*) 0x30000088)
// #define tap3 (*(volatile uint32_t*) 0x3000008c)
// #define tap4 (*(volatile uint32_t*) 0x30000090)
// #define tap5 (*(volatile uint32_t*) 0x30000094)
// #define tap6 (*(volatile uint32_t*) 0x30000098)
// #define tap7 (*(volatile uint32_t*) 0x3000009c)
// #define tap8 (*(volatile uint32_t*) 0x300000A0)
// #define tap9 (*(volatile uint32_t*) 0x300000A4)
// #define tap10 (*(volatile uint32_t*) 0x300000A8)

#define TAP_NUM      11
#define DATA_LEN     64

static const int32_t init_taps[TAP_NUM] = { 
    10, -10, -9, 23, 56, 63, 56, 23, -9, -10, 0
};
int outputsignal[64];
////up can be fir.h///////////////////////////////////////////////////////////

void __attribute__ ( ( section ( ".mprjram" ) ) ) initfir() {
	//initial your fir
	reg_fir_data_len = DATA_LEN;             //progrm data_len
    	reg_fir_tap_num = TAP_NUM;               //progrm tap_num
	for (int i = 0; i < TAP_NUM; i++) {      //progrm coeff
        (&reg_fir_coeff)[i] = init_taps[i];
    }

	return;
}

int* __attribute__ ( ( section ( ".mprjram" ) ) ) fir(){
	initfir();
	reg_fir_control = 1;  //ap_start
	
	reg_mprj_datal = (0xA5 << 16);// start timer  0xA5 is StartMark

	//write down your fir
	//#pragma GCC unroll 64 (be slower) 
	uint32_t i;
	i = 0;
	reg_fir_x = 0;
	reg_fir_x = 1;
	// for (i = 0; i <= 61; i++) {
	// 	// while ((reg_fir_control >> 4) & 1 != 1) {} // wait until reg_fir_x (0x00 [4]) is ready
	// 	// while ((reg_fir_control >> 5) & 1 != 1) {} // wait until reg_fir_y (0x00 [5]) is ready
	// 	outputsignal[i] = reg_fir_y;
	// 	reg_fir_x = i + 2;
	// }
	while(i <= 61)
	{
		outputsignal[i] = reg_fir_y;
		i++;
		reg_fir_x = i+1;
	}
	outputsignal[62] = reg_fir_y;
	outputsignal[63] = reg_fir_y;

	// i = 63
	// while ((reg_fir_control >> 4) & 1 != 1) {}
	//reg_fir_x = 63;
	// while ((reg_fir_control >> 5) & 1 != 1) {}
	//outputsignal[63] = reg_fir_y;


	// output to mprj[31:24], and stop timer
	reg_mprj_datal = ((outputsignal[DATA_LEN - 1] & 0xFF) << 24) | (0x5A << 16); //
	//{reg_mprj_datal[31:24], reg_mprj_datal[23:16]} = {Yn[7:0], 0x5A}   0x5A is EndMark
	// while ((reg_fir_control & 0x02) != 0x02);// for 800ver.(fir.v version12) we need this line
	return outputsignal;
    }

