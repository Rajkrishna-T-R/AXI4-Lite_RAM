# AXI_RAM
AXI wrapped RAM design
AXI4-Lite version is used for a 2 port RAM design

Overview
--------


This project contains the verilog code for the AXI interfaced RAM. 
RAM has parameterised depth and data width. The system is wrapped along with VIO IP with which design was tested on PYNQZ2 board


The RAM design features a forwarding unit for preventing the READ and WRITE operation happenening on the same location at the same time.

This project is for learning how AXI4-lite works rather than a RAM design.

The design was synsthesized for 125MHZ clock frequency

-------------------------------------------------------------------------------


Verification
------------
Test bench is generated using cluade AI for initial verification of the design.

Test cases 
   ---
 1. test_reset_contents            --> Reset and check if memory contents are all zero 
 2. test_basic_write_read          --> Basic read and write operation
 3. test_overwrite                 --> Overwriting memory 
 4. test_fill_all_addresses        --> Sequential fill of every address, then read all back
 5. test_back_to_back_write_read   --> Write immediately followed by read of same address
 6. test_random_traffic;           --> Randomized write/read transactions


TIMING SUMMARY
-------------
Worst negative slack = 2.837ns   <br>
Total negative slack = 0.000ns   <br>
Worst hold negative slack = 0.047ns  <br>
Total hold slack = 0.000ns           <br>
Worst pulse width slack = 2.750ns    <br>
Total pulse width negative slack = 0.000ns  <br>


-------------------------------------------------------------------------------

Note
----
1.Encountered some DRC violations but it was seen that it is related to some debug module or something that was created by vivado and not related to the AXI RAM design
So they are ingnored.

2.The design is not yet integrated with any AXI master.

-------------------------------------------------------------------------------

Result
-----
Synthesis and Implementation was successfull and the generated bit stream was dumped to PYNQZ2(xc7z020clg400-1) and using the VIO funtionality was verified manually.


