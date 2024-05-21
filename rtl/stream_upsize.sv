module stream_upsize #(
  parameter T_DATA_WIDTH = 1,
            T_DATA_RATIO = 2
) (
  input  logic                      clk,
  input  logic                      rst_n,

  input  logic [T_DATA_WIDTH-1 : 0] s_data_i,
  input  logic                      s_last_i,
  input  logic                      s_valid_i,
  output logic                      s_ready_o,

  output logic [T_DATA_WIDTH-1 : 0] m_data_o [T_DATA_RATIO-1 : 0],
  output logic [T_DATA_RATIO-1 : 0] m_keep_o,
  output logic                      m_last_o,
  output logic                      m_valid_o,
  input  logic                      m_ready_i
);

  logic [T_DATA_WIDTH : 0] up_data;
  logic                    fifo_push;
  logic                    fifo_pop;

  logic [T_DATA_WIDTH : 0] down_data [T_DATA_RATIO-2 : 0];
  logic                    fifo_empty;
  logic                    fifo_full;

  fifo #(
    .WIDTH ( T_DATA_WIDTH + 1 ),
    .DEPTH ( T_DATA_RATIO - 1 ) 
  ) fifo_inst (
    .clk_i        (  clk        ),
    .rst_i        ( ~rst_n      ),
    .push_i       (  fifo_push  ),
    .pop_i        (  fifo_pop   ),
    .write_data_i (  up_data    ),
    .read_data_o  (  down_data  ),
    .empty_o      (  fifo_empty ),
    .full_o       (  fifo_full  )
  );

  data_communication_net #(
    .T_DATA_WIDTH ( T_DATA_WIDTH ),
    .T_DATA_RATIO ( T_DATA_RATIO )
  ) net_inst (
  .s_data_i   ( s_data_i   ),
  .s_last_i   ( s_last_i   ),
  .s_valid_i  ( s_valid_i  ),
  .s_ready_o  ( s_ready_o  ),

  .m_data_o   ( m_data_o   ),
  .m_keep_o   ( m_keep_o   ),
  .m_last_o   ( m_last_o   ),
  .m_valid_o  ( m_valid_o  ),
  .m_ready_i  ( m_ready_i  ),

  .fifo_empty ( fifo_empty ),
  .fifo_full  ( fifo_full  ),
  .down_data  ( down_data  ),

  .fifo_push  ( fifo_push  ),
  .fifo_pop   ( fifo_pop   ),
  .up_data    ( up_data    )

);

endmodule