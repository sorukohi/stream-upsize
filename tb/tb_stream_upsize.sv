`timescale 1ps/1ps

module tb_stream_upsize;

// ==========================
//  INIT DUT
//===========================

  localparam T_DATA_WIDTH = 4; 
  localparam T_DATA_RATIO = 2;

  logic                      clk;
  logic                      rst_n;

  logic [T_DATA_WIDTH-1 : 0] s_data;
  logic                      s_last;
  logic                      s_valid;
  logic                      s_ready;

  logic [T_DATA_WIDTH-1 : 0] m_data [T_DATA_RATIO-1 : 0];
  logic [T_DATA_RATIO-1 : 0] m_keep;
  logic                      m_last;
  logic                      m_valid;
  logic                      m_ready;

  stream_upsize #(
    .T_DATA_WIDTH ( T_DATA_WIDTH ),
    .T_DATA_RATIO ( T_DATA_RATIO )
  ) DUT (
    .clk       ( clk     ),
    .rst_n     ( rst_n   ),

    .s_data_i  ( s_data  ),
    .s_last_i  ( s_last  ),
    .s_valid_i ( s_valid ),
    .s_ready_o ( s_ready ),

    .m_data_o  ( m_data  ),
    .m_keep_o  ( m_keep  ),
    .m_last_o  ( m_last  ),
    .m_valid_o ( m_valid ),
    .m_ready_i ( m_ready )
);

// ==========================
//  LOCAL STRUCTS AND PARAMS
//===========================

  localparam CLK_PERIOD     = 2;
  localparam TIMEOUT_CYCLES = 20;

  int errors_cnt = 0;

// ==========================
//  EXECUTION
//===========================

  initial begin
    $display("| ================== |");
    $display("| STREAM UPSIZE TEST |");
    $display("| ================== |");
    $display("DATA_WIDTH = %0d", T_DATA_WIDTH);
    $display("DATA_RATIO = %0d", T_DATA_RATIO);
    $display("\n");

    fork
      reset_system();
      timeout();
      get_data();
    join_none
    
    wait(rst_n);
    @(posedge clk);
    set_data('d0, 0, 1, 1); // data, last, valid, ready
    set_data('d1, 0, 1, 1); 
    set_data('d2, 1, 1, 1); 
    set_data('hA, 0, 0, 1); 
    set_data('hA, 0, 1, 1); 
    set_data('hB, 1, 1, 1); 
    set_data('hF, 1, 0, 1); 

  // ----------- FINISH ----------
    if (errors_cnt) $display("\n FAILED test with %d errors!!!", errors_cnt); 
    else            $display("\n The test is over without erros!!!");
    $finish;
  end

// ==========================
//  TASKS AND OTHER FOR JOB
//===========================

  initial begin
    clk <= 0;
    forever #(CLK_PERIOD / 2) clk <= ~clk;
  end

  task reset_system;
    rst_n   <= 0;
    s_data  <= '0;
    s_valid <= 0;
    s_last  <= 0;
    s_ready <= 0;  
    m_ready <= 0;
    #CLK_PERIOD;
    rst_n   <= 1;
  endtask

  task timeout;
    repeat(TIMEOUT_CYCLES) @(posedge clk);
    $display("TIMEOUT!!!");
    $stop();
  endtask

  task set_data (
    logic [T_DATA_WIDTH-1 : 0] s_data_for_set,
    logic                      s_last_for_set,
    logic                      s_valid_for_set,
    logic                      m_ready_for_set
  );
    s_data  <= s_data_for_set;
    s_last  <= s_last_for_set;
    s_valid <= s_valid_for_set;
    m_ready <= m_ready_for_set;
    @(posedge clk);
  endtask 

  logic [T_DATA_WIDTH-1 : 0] ref_data [T_DATA_RATIO-1 : 0];
  logic [T_DATA_RATIO-1 : 0] ref_keep;

  task get_data;
    int i = 0;
    forever begin
      wait(!m_valid);
      ref_data = '{T_DATA_RATIO{'0}}; 
      ref_keep = '0; 

      while (!m_valid) begin
        wait(s_ready);
        @(negedge clk);
        ref_data[i] = s_data;
        ref_keep[i] = 1;
        i++;
      end
      i                        = 0;
      ref_data[T_DATA_RATIO-1] = s_data; 
      ref_keep[T_DATA_RATIO-1] = 1; 
    end
  endtask

// ==========================
//  ASSERTIONS
//===========================

  property sReadyCorrect;
    @(posedge clk) (s_valid && m_ready) |-> @(negedge clk) s_ready;
  endproperty

  property mValidCorrect;
    @(posedge clk) s_valid && (DUT.fifo_full || s_last) |-> @(negedge clk) m_valid;
  endproperty

  property mLastCorrect;
    @(posedge clk) s_valid && s_last |-> @(negedge clk) m_last;
  endproperty

  property mKeepCorrect;
    @(posedge clk) m_valid |-> @(negedge clk) m_keep == ref_keep;
  endproperty

  property mDataCorrect;
    @(posedge clk) m_valid |-> @(negedge clk) m_data == ref_data;
  endproperty

  sReadyStable : assert property (sReadyCorrect) else begin
    $display("Time: %0t | ERROR READY!!!", $time());
    $display("Time: %0t | m_ready = %0d, s_valid = %0d, s_ready = %0d", $time(), m_ready, s_valid, s_ready);
    errors_cnt++;
  end

  mValidStable : assert property (mValidCorrect) else begin
    $display("Time: %0t | ERROR VALID!!!", $time());
    $display("Time: %0t | s_valid = %0d, fifo_full = %0d, s_last = %0d, m_valid = %0d", $time(), s_valid, DUT.fifo_full, s_last, m_valid);
    errors_cnt++;
  end

  mLastStable : assert property (mLastCorrect) else begin
    $display("Time: %0t | ERROR LAST!!!", $time());
    $display("Time: %0t | s_valid = %0d, s_last = %0d, m_last = %0d", $time(), s_valid, s_last, m_last);
    errors_cnt++;
  end

  mKeepStable : assert property (mKeepCorrect) else begin
    $display("Time: %0t | ERROR KEEP!!!", $time());
    $display("Time: %0t | ref_keep = %0b, m_keep = %0b", $time(), ref_keep, m_keep);
    errors_cnt++;
  end

  mDataStable : assert property (mDataCorrect) else begin
    $display("Time: %0t | ERROR DATA!!!", $time());
    for (int i = 0; i < T_DATA_RATIO; i++) begin
      $display("Time: %0t | ref_data[%0d] = %0d, m_data[%0d] = %0d", $time(), i, ref_data[i], i, m_data[i]);
    end
    errors_cnt++;
  end

endmodule