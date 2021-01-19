//
// SPDX-License-Identifier: CERN-OHL-S-2.0+
//
// Copyright (C) 2020-21 Embecosm Limited <www.embecosm.com>
// Contributed by:
// Byron Theobald <bt4g16@soton.ac.uk>
//
// This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY,
// INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR
// A PARTICULAR PURPOSE. Please see the CERN-OHL-S v2 for applicable
// conditions.
// Source location: https://github.com/AI-Vector-Accelerator
//

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
    tb->base_addr_i = 4;
    tb->stride = 8;
    tb->vl_i = 4;
    tb->vsew_i = 2;
    tb->load_first = 0;
    tb->next_cycle = 0;
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
        if(main_time == 15) tb->load_first = 1;
        if(main_time == 17) tb->load_first = 0;

        if(main_time == 21) tb->next_cycle = 1;
        if(main_time == 23) tb->next_cycle = 0; 

        if(main_time == 27) tb->next_cycle = 1;
        if(main_time == 29) tb->next_cycle = 0;
        
        if(main_time == 33) tb->next_cycle = 1;
        if(main_time == 35) tb->next_cycle = 0;

        if(main_time == 39) tb->next_cycle = 1;
        if(main_time == 41) tb->next_cycle = 0;
        
        if(main_time == 45) tb->next_cycle = 1;
        if(main_time == 47) tb->next_cycle = 0;
	}
    tb->final();
    delete(tb);

    return 0;
}
