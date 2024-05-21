`timescale 1ps/1ps

module fifo #(
  parameter WIDTH = 8,
            DEPTH = 8
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

  localparam POINTER_WIDTH = $clog2(DEPTH);

// =======================================================================

  logic [POINTER_WIDTH : 0] wr_ptr;
  logic [POINTER_WIDTH : 0] rd_ptr;

  logic [WIDTH-1 : 0] data [DEPTH-1 : 0];

// =======================================================================

  assign full_o  = {~wr_ptr[POINTER_WIDTH], wr_ptr[POINTER_WIDTH-1 : 0]} == rd_ptr;
  assign empty_o = (wr_ptr == rd_ptr);

// =======================================================================

  always_ff @ (posedge clk_i) begin
    if (rst_i) begin
      wr_ptr <= '0;
      rd_ptr <= '0;
    end else begin
      if (push_i) wr_ptr <= wr_ptr + 1'b1;
      if (pop_i)  rd_ptr <= rd_ptr + 1'b1;
    end
  end

// =======================================================================

  always_ff @ (posedge clk_i) begin
    if (push_i) data [wr_ptr] <= write_data_i;
  end

  assign read_data_o = data;

endmodule