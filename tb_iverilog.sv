`timescale 1ns/1ps

module tb_top;
localparam DW=12;
localparam NUM_TRANS=5;
int total_errors=0;
int total_trans=0;

logic clk=0;
always #5 clk=~clk;

// MODE 0:CPOL=0, CPHA=0

logic rst0, newd0;
logic [DW-1:0] m_din0, s_din0, m_dout0, s_dout0;
logic master_done0, slave_done0;

top #(.DW(DW), .CPOL(0), .CPHA(0), .CLK_DIV(4)) dut_mode0 (.clk(clk), .rst(rst0), .newd(newd0), .m_din(m_din0), .s_din(s_din0), .m_dout(m_dout0), .s_dout(s_dout0), .master_done(master_done0), .slave_done(slave_done0));

task automatic test_mode0;
logic [DW-1:0] expected_m_dout, expected_s_dout;
int errors;
errors=0;
//reset(10 clocks held, then 5 clocks settle)
rst0=1; newd0=0; m_din0='0; s_din0='0;
repeat (10) @(posedge clk);
rst0=0;
repeat (5) @(posedge clk);

for(int i=0;i<NUM_TRANS;i++) 
begin
 m_din0=$urandom_range(0, (1<<DW)-1);
 s_din0=$urandom_range(0, (1<<DW)-1);
 expected_m_dout=s_din0;   // master should receive what slave sent
 expected_s_dout=m_din0;   // slave should receive what master sent
 //pulse newd to start the transfer
 @(posedge clk); newd0=1;
 @(posedge clk); newd0=0;

// poll every clock until BOTH done flags are seen high together
for (int w=0;w<200;w=w+1) 
begin
     @(posedge clk);
     if(master_done0 && slave_done0) w=200;
end
// check the result
if(m_dout0!==expected_m_dout || s_dout0!==expected_s_dout) 
begin
    $display("[FAIL] Mode0 trans=%0d : m_dout=%0d (expected %0d)  s_dout=%0d (expected % 0d)", i, m_dout0, expected_m_dout, s_dout0, expected_s_dout);
     errors++;
end 
else begin
    $display("[PASS] Mode0 trans=%0d : m_din=%0d s_din=%0d -> m_dout=%0d s_dout=%0d", i, m_din0, s_din0, m_dout0, s_dout0);
end
total_trans++;
repeat(4) @(posedge clk);
end
total_errors += errors;
$display("Mode 0 DONE : %0d/%0d passed\n", NUM_TRANS-errors, NUM_TRANS);
endtask

//MODE 1:CPOL=0, CPHA=1
logic rst1, newd1;
logic [DW-1:0] m_din1, s_din1, m_dout1, s_dout1;
logic master_done1, slave_done1;

top #(.DW(DW), .CPOL(0), .CPHA(1), .CLK_DIV(4)) dut_mode1 (.clk(clk), .rst(rst1), .newd(newd1), .m_din(m_din1), .s_din(s_din1), .m_dout(m_dout1), .s_dout(s_dout1), .master_done(master_done1), .slave_done(slave_done1));

task automatic test_mode1;
logic [DW-1:0] expected_m_dout, expected_s_dout;
int errors;
errors=0;
rst1=1; newd1 = 0; m_din1 = '0; s_din1 = '0;
repeat (10) @(posedge clk);
rst1=0;
repeat(5) @(posedge clk);

for (int i=0; i<NUM_TRANS; i++) begin
m_din1=$urandom_range(0,(1<<DW)-1);
s_din1=$urandom_range(0,(1<<DW)-1);
expected_m_dout=s_din1;   
expected_s_dout=m_din1;        
@(posedge clk);
newd1=1;
@(posedge clk);
newd1=0;
for (int w=0;w<200;w=w+1) begin
@(posedge clk);
if(master_done1 && slave_done1) 
w=200;
end
if(m_dout1!==expected_m_dout || s_dout1!==expected_s_dout) begin
 $display("[FAIL] Mode1 trans=%0d : m_dout=%0d (expected %0d)  s_dout=%0d (expected %0d)",
                  i, m_dout1, expected_m_dout, s_dout1, expected_s_dout);
 errors++;
end 
else begin
$display("[PASS] Mode1 trans=%0d : m_din=%0d s_din=%0d -> m_dout=%0d s_dout=%0d",
                  i, m_din1, s_din1, m_dout1, s_dout1);
end
total_trans++;
repeat(4) @(posedge clk);
end
total_errors+=errors;
$display("---- Mode 1 (CPOL=0,CPHA=1) DONE : %0d/%0d passed ----\n", NUM_TRANS-errors, NUM_TRANS);
endtask

//MODE 2:CPOL=1,CPHA=0
logic rst2, newd2;
logic [DW-1:0] m_din2, s_din2, m_dout2, s_dout2;
logic master_done2, slave_done2;
top #(.DW(DW), .CPOL(1), .CPHA(0), .CLK_DIV(4)) dut_mode2 (.clk(clk), .rst(rst2), .newd(newd2), .m_din(m_din2), .s_din(s_din2), .m_dout(m_dout2), .s_dout(s_dout2), .master_done(master_done2), .slave_done(slave_done2));

task automatic test_mode2;
logic [DW-1:0] expected_m_dout, expected_s_dout;
int errors;
errors=0;
rst2=1; newd2=0; m_din2='0; s_din2='0;
repeat(10) @(posedge clk);
rst2=0;
repeat(5) @(posedge clk);
for (int i=0;i<NUM_TRANS;i++) begin
m_din2=$urandom_range(0,(1<<DW)-1);
s_din2=$urandom_range(0,(1<<DW)-1);
expected_m_dout=s_din2; 
expected_s_dout=m_din2; 
@(posedge clk);
newd2=1;
@(posedge clk);
newd2=0;
for(int w=0;w<200;w=w+1) begin
@(posedge clk);
   if(master_done2 && slave_done2) w=200;
end
if(m_dout2!==expected_m_dout || s_dout2!==expected_s_dout) begin
$display("[FAIL] Mode2 trans=%0d : m_dout=%0d (expected %0d)  s_dout=%0d (expected %0d)", i, m_dout2, expected_m_dout, s_dout2, expected_s_dout);
errors++;
end 
else begin
$display("[PASS] Mode2 trans=%0d : m_din=%0d s_din=%0d -> m_dout=%0d s_dout=%0d", i, m_din2, s_din2, m_dout2, s_dout2);
end
total_trans++;
repeat(4) @(posedge clk);
end
total_errors += errors;
$display("Mode 2 DONE: %0d/%0d passed\n", NUM_TRANS-errors, NUM_TRANS);
endtask

// MODE 3:CPOL=1, CPHA=1
logic rst3, newd3;
logic [DW-1:0] m_din3, s_din3, m_dout3, s_dout3;
logic master_done3, slave_done3;
top #(.DW(DW), .CPOL(1), .CPHA(1), .CLK_DIV(4)) dut_mode3 (.clk(clk), .rst(rst3), .newd(newd3), .m_din(m_din3), .s_din(s_din3), .m_dout(m_dout3), .s_dout(s_dout3), .master_done(master_done3), .slave_done(slave_done3));

task automatic test_mode3;
logic [DW-1:0] expected_m_dout, expected_s_dout;
int errors;
errors=0;
rst3=1; newd3=0; m_din3='0; s_din3='0;
repeat(10) @(posedge clk);
rst3=0;
repeat(5) @(posedge clk);
for(int i=0;i<NUM_TRANS;i++) begin
m_din3=$urandom_range(0,(1<<DW)-1);
s_din3=$urandom_range(0,(1<<DW)-1);
expected_m_dout=s_din3;   
expected_s_dout=m_din3;   
@(posedge clk); newd3 = 1;
@(posedge clk); newd3 = 0;
for(int w=0;w<200;w=w+1) begin
@(posedge clk);
if(master_done3 && slave_done3) w=200;
end
if(m_dout3!==expected_m_dout || s_dout3!==expected_s_dout) begin
$display("[FAIL] Mode3 trans=%0d : m_dout=%0d (expected %0d)  s_dout=%0d (expected %0d)", i, m_dout3, expected_m_dout, s_dout3, expected_s_dout);
errors++;
end 
else begin
$display("[PASS] Mode3 trans=%0d : m_din=%0d s_din=%0d -> m_dout=%0d s_dout=%0d",i, m_din3, s_din3, m_dout3, s_dout3);
end
total_trans++;
repeat(4) @(posedge clk);
end
total_errors+=errors;
$display("Mode 3 DONE: %0d/%0d passed\n", NUM_TRANS-errors, NUM_TRANS);
endtask

initial begin
$dumpfile("dump.vcd");
$dumpvars(0, tb_top);
$display("Full-Duplex SPI Verification\n");
test_mode0();
test_mode1();
test_mode2();
test_mode3();
$display("ALL 4 CPOL/CPHA COMBINATIONS COMPLETE");
$display("TOTAL TRANSACTIONS : %0d", total_trans);
$display("TOTAL ERROR COUNT  : %0d", total_errors);
$finish;
end
endmodule