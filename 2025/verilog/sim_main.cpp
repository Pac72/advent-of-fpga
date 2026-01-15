#include "Vtb_part1.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>

uint64_t main_time = 0;
double sc_time_stamp() {
    return main_time;
}

int main(int argc, char *argv[]) {

    const std::unique_ptr<VerilatedContext> contextp{new VerilatedContext};

    contextp->debug(0);

    contextp->randReset(2);

    contextp->traceEverOn(true);

    contextp->commandArgs(argc, argv);

    const std::unique_ptr<Vtb_part1> top{new Vtb_part1{contextp.get(), "TOP"}};

    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("waveform.vcd");

    while (!contextp->gotFinish()) {
        top->eval();
        tfp->dump(main_time);
        main_time++;
    }

    tfp->close();
    delete tfp;

    top->final();

    return 0;
}
