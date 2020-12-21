#include <stdlib.h>
#include "Vbyte_enable.h"
#include "verilated.h"

vluint64_t main_time = 0;       // Current simulation time

double sc_time_stamp () {       // Called by $time in Verilog
    return main_time;           // converts to double, to match
}

int main(int argc, char **argv) {
	// Initialize Verilators variables
	Verilated::commandArgs(argc, argv); 
    Verilated::traceEverOn(true);

	// Create an instance of our module under test
	Vbyte_enable *tb = new Vbyte_enable;

    tb->clk_i = 0;
    tb->n_rst_i = 1;
    tb->base_addr_i = 3;
    tb->stride = 3;
    tb->vl_i = 16;
    tb->load_first = 0;
	tb->eval();
    main_time++;
    tb->n_rst_i = 0;
    tb->eval();
    main_time++;
    tb->n_rst_i = 1;
    tb->eval();
    main_time++;

	// Tick the clock until we are done
	while(!Verilated::gotFinish() && main_time < 100) {
        tb->clk_i = !(tb->clk_i);
		tb->eval();
        main_time++;
        if(main_time == 11) tb->load_first = 1;
        if(main_time == 13) tb->load_first = 0;
	}
    tb->final();
    delete(tb);

    return 0;
}