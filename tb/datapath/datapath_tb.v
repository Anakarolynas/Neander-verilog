// ============================================================
// NEANDER - Testbench do Datapath
// Projeto: Processador Neander em Verilog
// Módulo: datapath_tb
//
// Função:
//   Testar os principais caminhos de dados do processador.
//
// Caminhos testados:
//   1. PC -> REM
//   2. RDM -> REM
//   3. Memória -> RDM
//   4. RDM -> RI
//   5. RDM -> AC
//   6. AC + RDM -> AC
//   7. RDM -> PC
//   8. PC -> PC + 1
//   9. AC -> Memória
//  10. Flags N e Z
// ============================================================

`timescale 1ns/1ps

module datapath_tb;

    // ========================================================
    // SINAIS DO CLOCK E RESET
    // ========================================================

    reg clk;
    reg rst;

    // ========================================================
    // CONTROLE DO PC
    // ========================================================

    reg pc_carga;
    reg pc_inc;

    // ========================================================
    // CONTROLE DO REM
    // ========================================================

    reg rem_carga;
    reg rem_sel;

    // ========================================================
    // CONTROLE DOS REGISTRADORES
    // ========================================================

    reg rdm_carga;
    reg ri_carga;
    reg ac_carga;

    // ========================================================
    // CONTROLE DA ULA
    // ========================================================

    reg [2:0] op_ula;

    // ========================================================
    // MEMÓRIA
    // ========================================================

    reg [7:0] mem_din;

    // ========================================================
    // SELEÇÃO DA ENTRADA DO RDM
    // ========================================================

    reg rdm_sel;

    // ========================================================
    // CARGA DAS FLAGS N E Z
    // ========================================================

    reg nz_carga;

    // ========================================================
    // SAÍDAS DO DATAPATH
    // ========================================================

    wire [7:0] pc_out;
    wire [7:0] rem_out;
    wire [7:0] rdm_out;
    wire [7:0] ri_out;
    wire [7:0] ac_out;

    wire [7:0] mem_addr;
    wire [7:0] mem_dout;

    wire N;
    wire Z;

    // ========================================================
    // INSTÂNCIA DO DATAPATH
    // ========================================================

    datapath dut (

        .clk          (clk),
        .rst          (rst),

        .pc_carga     (pc_carga),
        .pc_inc       (pc_inc),

        .rem_carga    (rem_carga),
        .rem_sel      (rem_sel),

        .rdm_carga    (rdm_carga),
        .rdm_sel      (rdm_sel),
        .ri_carga     (ri_carga),
        .ac_carga     (ac_carga),

        .op_ula       (op_ula),
        .nz_carga     (nz_carga),

        .mem_din      (mem_din),

        .pc_out       (pc_out),
        .rem_out      (rem_out),
        .rdm_out      (rdm_out),
        .ri_out       (ri_out),
        .ac_out       (ac_out),

        .mem_addr     (mem_addr),
        .mem_dout (mem_dout),

        .N            (N),
        .Z            (Z)

    );

    // ========================================================
    // GERAÇÃO DO CLOCK
    //
    // Período = 10 ns
    // ========================================================

    always #5 clk = ~clk;

    // ========================================================
    // TESTES
    // ========================================================

    initial begin

        // ----------------------------------------------------
        // INICIALIZAÇÃO
        // ----------------------------------------------------

        clk = 0;
        rst = 1;

        pc_carga  = 0;
        pc_inc    = 0;

        rem_carga = 0;
        rem_sel   = 0;

        rdm_carga = 0;
        ri_carga  = 0;
        ac_carga  = 0;

        op_ula = 3'b100;

        mem_din = 8'b00000000;

        rdm_sel  = 0;
        nz_carga = 0;

        // ----------------------------------------------------
        // RESET
        // ----------------------------------------------------

        #10;

        rst = 0;

        // ====================================================
        // TESTE 1
        // PC -> REM
        // ====================================================

        $display("");
        $display("========================================");
        $display("TESTE 1: PC -> REM");
        $display("========================================");

        // Coloca 10 no RDM
        mem_din = 8'd10;
        rdm_carga = 1;

        #10;

        rdm_carga = 0;

        // PC <- RDM
        pc_carga = 1;

        #10;

        pc_carga = 0;

        // REM <- PC
        rem_sel   = 0;
        rem_carga = 1;

        #10;

        rem_carga = 0;

        $display("PC  = %d", pc_out);
        $display("REM = %d", rem_out);
        $display("Esperado: PC = 10, REM = 10");

        // ====================================================
        // TESTE 2
        // RDM -> REM
        // ====================================================

        $display("");
        $display("========================================");
        $display("TESTE 2: RDM -> REM");
        $display("========================================");

        // Coloca 20 no RDM
        mem_din = 8'd20;
        rdm_carga = 1;

        #10;

        rdm_carga = 0;

        // REM <- RDM
        rem_sel   = 1;
        rem_carga = 1;

        #10;

        rem_carga = 0;

        $display("RDM = %d", rdm_out);
        $display("REM = %d", rem_out);
        $display("Esperado: RDM = 20, REM = 20");

        // ====================================================
        // TESTE 3
        // MEMÓRIA -> RDM
        // ====================================================

        $display("");
        $display("========================================");
        $display("TESTE 3: MEMORIA -> RDM");
        $display("========================================");

        mem_din = 8'h55;

        rdm_carga = 1;

        #10;

        rdm_carga = 0;

        $display("MEM_DIN = %h", mem_din);
        $display("RDM         = %h", rdm_out);
        $display("Esperado: RDM = 55");

        // ====================================================
        // TESTE 4
        // RDM -> RI
        // ====================================================

        $display("");
        $display("========================================");
        $display("TESTE 4: RDM -> RI");
        $display("========================================");

        ri_carga = 1;

        #10;

        ri_carga = 0;

        $display("RDM = %h", rdm_out);
        $display("RI  = %h", ri_out);
        $display("Esperado: RI = 55");

        // ====================================================
        // TESTE 5
        // RDM -> AC
        // ====================================================

        $display("");
        $display("========================================");
        $display("TESTE 5: RDM -> AC");
        $display("========================================");

        // Coloca 25 no RDM
        mem_din = 8'd25;

        rdm_carga = 1;

        #10;

        rdm_carga = 0;

        // O AC recebe o RDM pela operação ID da ULA, que devolve o Y
        op_ula   = 3'b100;
        ac_carga = 1;

        #10;

        ac_carga = 0;

        $display("RDM = %d", rdm_out);
        $display("AC  = %d", ac_out);
        $display("Esperado: AC = 25");

        // ====================================================
        // TESTE 6
        // AC + RDM -> AC
        // ====================================================

        $display("");
        $display("========================================");
        $display("TESTE 6: AC + RDM -> AC");
        $display("========================================");

        // AC atualmente = 25
        // Coloca 5 no RDM

        mem_din = 8'd5;

        rdm_carga = 1;

        #10;

        rdm_carga = 0;

        // ULA = AC + RDM
        op_ula = 3'b000;

        ac_carga = 1;

        #10;

        ac_carga = 0;

        $display("AC  = %d", ac_out);
        $display("RDM = %d", rdm_out);
        $display("Esperado: AC = 30");

        // ====================================================
        // TESTE 7
        // RDM -> PC
        // ====================================================

        $display("");
        $display("========================================");
        $display("TESTE 7: RDM -> PC");
        $display("========================================");

        mem_din = 8'd100;

        rdm_carga = 1;

        #10;

        rdm_carga = 0;

        // PC <- RDM
        pc_carga = 1;

        #10;

        pc_carga = 0;

        $display("RDM = %d", rdm_out);
        $display("PC  = %d", pc_out);
        $display("Esperado: PC = 100");

        // ====================================================
        // TESTE 8
        // PC -> PC + 1
        // ====================================================

        $display("");
        $display("========================================");
        $display("TESTE 8: PC -> PC + 1");
        $display("========================================");

        $display("PC antes  = %d", pc_out);

        pc_inc = 1;

        #10;

        pc_inc = 0;

        $display("PC depois = %d", pc_out);
        $display("Esperado: PC depois = 101");

        // ====================================================
        // TESTE 9
        // AC -> MEMÓRIA
        // ====================================================

        $display("");
        $display("========================================");
        $display("TESTE 9: AC -> MEMORIA");
        $display("========================================");

        // O dado escrito na memória sai do RDM, então o STA primeiro
        // carrega o AC no RDM através do MUX (rdm_sel = 1).

        rdm_sel   = 1;
        rdm_carga = 1;

        #10;

        rdm_carga = 0;
        rdm_sel   = 0;

        $display("AC           = %d", ac_out);
        $display("MEM_DOUT = %d", mem_dout);
        $display("MEM_ADDR     = %d", mem_addr);
        $display("Esperado: MEM_DOUT = AC");

        // ====================================================
        // TESTE 10
        // FLAGS N E Z
        // ====================================================

        $display("");
        $display("========================================");
        $display("TESTE 10: FLAGS N E Z");
        $display("========================================");

        // ----------------------------------------------------
        // Caso 1: Resultado = 0
        // ----------------------------------------------------

        mem_din = 8'd0;

        rdm_carga = 1;

        #10;

        rdm_carga = 0;

        // ULA = RDM
        op_ula = 3'b100;

        // As flags agora sao registradas: precisam de nz_carga
        nz_carga = 1;

        #10;

        nz_carga = 0;

        $display("");
        $display("Caso 1 - Resultado zero");
        $display("RDM = %h | N = %b | Z = %b",
                 rdm_out,
                 N,
                 Z);
        $display("Esperado: N = 0, Z = 1");

        // ----------------------------------------------------
        // Caso 2: Resultado positivo
        // ----------------------------------------------------

        mem_din = 8'd10;

        rdm_carga = 1;

        #10;

        rdm_carga = 0;

        // As flags agora sao registradas: precisam de nz_carga
        nz_carga = 1;

        #10;

        nz_carga = 0;

        $display("");
        $display("Caso 2 - Resultado positivo");
        $display("RDM = %h | N = %b | Z = %b",
                 rdm_out,
                 N,
                 Z);
        $display("Esperado: N = 0, Z = 0");

        // ----------------------------------------------------
        // Caso 3: Resultado negativo
        //
        // Em complemento de 2:
        // 8'hFF representa -1
        // ----------------------------------------------------

        mem_din = 8'hFF;

        rdm_carga = 1;

        #10;

        rdm_carga = 0;

        // As flags agora sao registradas: precisam de nz_carga
        nz_carga = 1;

        #10;

        nz_carga = 0;

        $display("");
        $display("Caso 3 - Resultado negativo");
        $display("RDM = %h | N = %b | Z = %b",
                 rdm_out,
                 N,
                 Z);
        $display("Esperado: N = 1, Z = 0");

        // ====================================================
        // FINAL
        // ====================================================

        $display("");
        $display("========================================");
        $display("FIM DOS TESTES DO DATAPATH");
        $display("========================================");

        #10;

        $finish;

    end

endmodule