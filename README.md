
MultiComp
=========

FPGA based modular micro computer.  This is a fork of the work provided by Grant Searle, targetting
the DE0-CV board.  See http://searle.hostei.com/grant/Multicomp/index.html

Building and Running
--------------------
1) Install Altera Quartus version 13.0sp
2) Add the quartus bin directory to your search path
3) Check out this code
4) Make a `build` directory and change into there (this is due to the number of intermeediate files created)
5) `make -f ../Makefile clean all program`

If you would like to permanently write to the onboard flash, use `make -f ../Makefile flash`

What's next
-----------
- I'd like to try to get the SDRAM working as an alternative to plugging in an SRAM into GPIO.
- Support for other multiple boards


