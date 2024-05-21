`timescale 1ps/1ps

module data_communication_net #(
  parameter T_DATA_WIDTH = 1,
            T_DATA_RATIO = 2
) (
  // main signals
  input  logic [T_DATA_WIDTH-1 : 0] s_data_i,
  input  logic                      s_last_i,
  input  logic                      s_valid_i,
  output logic                      s_ready_o,

  output logic [T_DATA_WIDTH-1 : 0] m_data_o [T_DATA_RATIO-1 : 0],
  output logic [T_DATA_RATIO-1 : 0] m_keep_o,
  output logic                      m_last_o,
  output logic                      m_valid_o,
  input  logic                      m_ready_i,

  // from fifo
  input  logic                    fifo_empty,
  input  logic                    fifo_full,
  input  logic [T_DATA_WIDTH : 0] down_data [T_DATA_RATIO-2 : 0],

  output logic                    fifo_push,
  output logic                    fifo_pop,
  output logic [T_DATA_WIDTH : 0] up_data
);

  logic last_pkt;

// =======================
//  PREP SIGNALS FOR FIFO
// =======================   

  assign last_pkt  = s_valid_i && s_last_i;
  assign up_data   = {s_valid_i, s_data_i};
  assign fifo_push = s_valid_i && !s_last_i && !fifo_full;
  assign fifo_pop  = fifo_full || last_pkt;

// =======================
//  OUTPUT SIGNALS
// ======================= 

  logic [T_DATA_RATIO-1 : 0] m_keep;
  logic [T_DATA_WIDTH-1 : 0] m_data [T_DATA_RATIO-1 : 0]
  generate
    for (genvar i; i < $size(down_data); i = i + 1) begin
      assign m_keep[i]  = down_data[i][T_DATA_WIDTH];
      assign m_data[i]  = down_data[i][T_DATA_WIDTH-1 : 0];    
    end
  endgenerate
  
  assign m_keep_o  = {1'b1, m_keep};
  assign m_data_o  = {s_data_i, m_data};
  assign m_last_o  = last_pkt;
  assign m_valid_o = s_valid_i && (fifo_full || s_last_i);  
  
  assign s_ready_o = m_valid_o && m_ready_i;

endmodule