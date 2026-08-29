//MASTER

module spi_master #(parameter DW=12, parameter CPOL=0, parameter CPHA=0, parameter CLK_DIV=4)

(input logic clk,
input logic rst,
input logic newd, // pulse: start a transfer
input logic [DW-1:0] din, // data master -> slave
input logic miso, // data slave  -> master
output logic sclk,
output logic cs,  // active-low 
output logic mosi,
output logic [DW-1:0] dout, // data received from slave
output logic done);

localparam IDLE=2'd0, LOAD=2'd1, XFER=2'd2, FIN=2'd3;
logic [1:0] state;

//sclk generator
logic [$clog2(CLK_DIV+1)-1:0] div_cnt;
logic sclk_en;
logic leading_edge, trailing_edge;
always_ff @(posedge clk) begin
if(rst||!sclk_en) begin
  div_cnt<='0;
  sclk<=CPOL[0];
  leading_edge<=1'b0;
  trailing_edge<=1'b0;
  end 
else begin
  leading_edge<=1'b0;
  trailing_edge<=1'b0;
  if(div_cnt==CLK_DIV-1) begin
     div_cnt<='0;
     sclk<=~sclk;
     if (sclk==CPOL[0]) leading_edge<=1'b1;     // leaving idle level
     else  trailing_edge<=1'b1;    // returning to idle level
  end 
  else begin
     div_cnt<=div_cnt+1'b1;
  end
 end
end

//transfer FSM
logic [$clog2(DW+1)-1:0] bitcnt;
logic [DW-1:0] tx_shift;
logic [DW-1:0] rx_shift;

always_ff @(posedge clk) begin
if(rst) begin
 state<=IDLE;
 cs<=1'b1;
 mosi<=1'b0;
 sclk_en<=1'b0;
 done<=1'b0;
 bitcnt<='0;
 tx_shift<='0;
 rx_shift<='0;
 dout<='0;
end 
else begin
done<=1'b0;
case(state)
  
  IDLE: begin
  cs<=1'b1;
  sclk_en<=1'b0;
  if(newd) begin
    tx_shift<=din;
    bitcnt<='0;
    cs<=1'b0;
    state<=LOAD;
  end
  end

  LOAD: begin
    sclk_en<=1'b1;
    if(CPHA==0)
    mosi<=tx_shift[DW-1];
    state<=XFER;
  end

  XFER: begin
  if(CPHA==0) begin
  if(leading_edge)
    rx_shift<={rx_shift[DW-2:0], miso};
  if(trailing_edge) begin
  if(bitcnt==DW-1) begin
    state<=FIN;
  end 
  else begin
    mosi<=tx_shift[DW-2-bitcnt];
    bitcnt<=bitcnt+1'b1;
  end
  end
  end 
  else begin
  if(leading_edge)
    mosi<=tx_shift[DW-1-bitcnt];
  if(trailing_edge) begin
    rx_shift<={rx_shift[DW-2:0], miso};
  if(bitcnt==DW-1)
    state<=FIN;
  else
    bitcnt<=bitcnt+1'b1;
  end
  end
  end

  FIN: begin
  sclk_en<=1'b0;
  cs<=1'b1;
  mosi<=1'b0;
  dout<=rx_shift;
  done<=1'b1;
  state<=IDLE;
  end
                
  default: state<=IDLE;
endcase
end
end
endmodule





// SLAVE  

module spi_slave #(parameter DW   = 12, parameter CPOL = 0, parameter CPHA = 0)
(input  logic sclk,
 input  logic cs,     // active low
 input  logic mosi,
 input  logic [DW-1:0] din,    // data slave -> master (loaded when cs falls)
 output logic miso,
 output logic [DW-1:0] dout,   // data received from master
 output logic done);

//Sample edge=leading edge (CPHA=0) or trailing edge (CPHA=1).
//Leading edge=rising if CPOL=0, falling if CPOL=1.

localparam bit SAMPLE_ON_POSEDGE=(CPOL==CPHA);
logic [DW-1:0] tx_shift;
logic [DW-1:0] rx_shift;
logic [$clog2(DW+1)-1:0] bitcnt;

// Preload first output bit on select — needed for CPHA=0 since there's
// no prior shift edge before the first sampling edge.

generate
   if(CPHA==0) begin: g_preload
     always_ff @(negedge cs) begin
        miso <= din[DW-1];
     end
   end
endgenerate

//Split into two single-edge blocks — dual-edge (posedge/negedge together)

generate
if(SAMPLE_ON_POSEDGE) begin: g_sample_posedge
   always_ff @(posedge sclk or posedge cs) begin
   if(cs) begin
     bitcnt<='0;
     done<=1'b0;
   end 
   else begin
     rx_shift<={rx_shift[DW-2:0], mosi};
     if (bitcnt==DW-1) begin
       dout<={rx_shift[DW-2:0], mosi};
       done<=1'b1;
       bitcnt<='0;
     end 
     else begin
       bitcnt<=bitcnt+1'b1;
       done<=1'b0;
     end
   end
end

always_ff @(negedge sclk or posedge cs) begin
if(cs) begin
  miso<=1'b0;
end 
else begin
if(CPHA==0) begin
  if(bitcnt!=0)
   miso<=tx_shift[DW-1-bitcnt];
  end 
else begin
   miso<=(bitcnt==0)?din[DW-1]:tx_shift[DW-1-bitcnt];
   end
end
end

end else begin:g_sample_negedge

always_ff @(negedge sclk or posedge cs) begin
if(cs) begin
  bitcnt<='0;
  done<=1'b0;
end 
else begin
  rx_shift<={rx_shift[DW-2:0], mosi};
  if(bitcnt==DW-1) begin
    dout<={rx_shift[DW-2:0], mosi};
    done<=1'b1;
    bitcnt<='0;
  end
  else begin
    bitcnt<=bitcnt + 1'b1;
    done<=1'b0;
  end
end
end

always_ff @(posedge sclk or posedge cs) begin
if(cs) begin
 miso<=1'b0;
end 
else begin
 if(CPHA==0) begin
   if (bitcnt!=0)
    miso<=tx_shift[DW-1-bitcnt];
   end 
   else begin
    miso<=(bitcnt==0)?din[DW-1]:tx_shift[DW-1-bitcnt];
   end
 end
end
end
endgenerate

always_ff @(negedge cs) begin
tx_shift<=din;
end
endmodule





//TOP:wires master and slave together

module top #(parameter DW=12, parameter CPOL=0, parameter CPHA=0, parameter CLK_DIV=4)
(input  logic clk,
 input  logic rst,
 input  logic newd,
 input  logic [DW-1:0] m_din,    // master -> slave data
 input  logic [DW-1:0] s_din,    // slave  -> master data
 output logic [DW-1:0] m_dout,   // data master received 
 output logic [DW-1:0] s_dout,   // data slave received  
 output logic master_done,
 output logic slave_done);
logic sclk, cs, mosi, miso;

spi_master #(.DW(DW), .CPOL(CPOL), .CPHA(CPHA), .CLK_DIV(CLK_DIV)) m1 (.clk(clk), .rst(rst), .newd(newd), .din(m_din), .miso(miso), .sclk(sclk), .cs(cs), .mosi(mosi), .dout(m_dout), .done(master_done));

spi_slave #(.DW(DW), .CPOL(CPOL), .CPHA(CPHA)) s1 (.sclk(sclk), .cs(cs), .mosi(mosi), .din(s_din), .miso(miso), .dout(s_dout), .done(slave_done));

endmodule