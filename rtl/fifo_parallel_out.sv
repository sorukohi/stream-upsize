`timescale 1ps/1ps

/*
  DESCRIPTION
*/
/*
  1. Сontinuously parallel access to all cells of fifo.
  2. The reading pointer is missing because of the 1-st point.
*/

module fifo_parallel_out #(
  parameter WIDTH = 4,
            DEPTH = 2
) (
  input  logic               clk_i,
  input  logic               rst_i,
  input  logic               push_i,
  input  logic               pop_i,
  input  logic [WIDTH-1 : 0] write_data_i,
  output logic [WIDTH-1 : 0] read_data_o [DEPTH-1 : 0],
  output logic               empty_o,
  output logic               full_o
);

// =======================================================================

  localparam POINTER_WIDTH = $clog2(DEPTH); // dim of ptr

// ================================================================================

  logic [POINTER_WIDTH : 0] wr_ptr; // POINTER_WIDTH+1 dim to detect FULL state.
                                    // This possible because DEPTH is pow of 2. 
  logic [WIDTH-1 : 0] data [DEPTH-1 : 0]; // cells of fifo

// ================================================================================

  assign full_o  = wr_ptr[POINTER_WIDTH]; // FULL state tracked by high ptr bit
  assign empty_o = ~|wr_ptr; // 

// =======================================================================

  always_ff @ (posedge clk_i) begin
    if      (rst_i)  wr_ptr <= '0;
    else if (push_i) wr_ptr <= wr_ptr + 1'b1;
    else if (pop_i)  wr_ptr <= '0;
  end

// =======================================================================

  always_ff @(posedge clk_i) begin
    if      (rst_i)  data         <= '{DEPTH{'0}};
    else if (push_i) data[wr_ptr] <= write_data_i;
    else if (pop_i)  data         <= '{DEPTH{'0}}; // during of reading fifo all cells reset
  end

  assign read_data_o = data; 

endmodule