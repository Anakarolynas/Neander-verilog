// ============================================================
// NEANDER - Datapath
// Projeto: Processador Neander em Verilog
// Módulo: Datapath
//
// Função:
//   Interliga os principais registradores e caminhos de dados
//   do processador Neander.
//
// Registradores:
//   - PC
//   - REM
//   - RDM
//   - RI
//   - AC
//
// MUXes:
//   - MUX REM: seleciona PC ou RDM
//   - MUX AC : seleciona ULA ou RDM
//
// Caminho do PC:
//   - PC pode ser incrementado internamente
//   - PC pode receber diretamente o valor do RDM
//
// Caminho da memória:
//   REM -> endereço da memória
//   memória -> RDM
//
// Caminho da instrução:
//   RDM -> RI
// ============================================================

module datapath (

    input wire clk,
    input wire rst,

    // --------------------------------------------------------
    // Controle do PC
    // --------------------------------------------------------

    input wire pc_carga,
    input wire pc_inc,

    // --------------------------------------------------------
    // Controle do REM
    // --------------------------------------------------------

    input wire rem_carga,
    input wire rem_sel,

    // --------------------------------------------------------
    // Controle dos registradores
    // --------------------------------------------------------

    input wire rdm_carga,
    input wire ri_carga,
    input wire ac_carga,

    // --------------------------------------------------------
    // Controle da ULA
    // --------------------------------------------------------

    input wire [2:0] op_ula,

    // --------------------------------------------------------
    // Entrada de dados da memória
    // --------------------------------------------------------

    input wire [7:0] mem_din,

    // --------------------------------------------------------
    // Seleção da entrada do AC
    // --------------------------------------------------------

    input wire ac_sel,

    // --------------------------------------------------------
    // Saídas dos registradores
    // --------------------------------------------------------

    output wire [7:0] pc_out,
    output wire [7:0] rem_out,
    output wire [7:0] rdm_out,
    output wire [7:0] ri_out,
    output wire [7:0] ac_out,

    // --------------------------------------------------------
    // Interface com a memória
    // --------------------------------------------------------

    output wire [7:0] mem_addr,
    output wire [7:0] mem_dout,

    // --------------------------------------------------------
    // Flags da ULA
    // --------------------------------------------------------

    output wire N,
    output wire Z

);


    // ========================================================
    // FIOS INTERNOS
    // ========================================================

    // Entrada do REM
    wire [7:0] rem_din;

    // Resultado da ULA
    wire [7:0] ula_resultado;

    // Entrada do AC após o MUX
    wire [7:0] ac_din_mux;


    // ========================================================
    // MUX DO REM
    //
    // rem_sel = 0 -> PC
    // rem_sel = 1 -> RDM
    // ========================================================

    mux mux_rem (

        .data_a (pc_out),
        .data_b (rdm_out),
        .sel    (rem_sel),
        .dout   (rem_din)

    );


    // ========================================================
    // MUX DO AC
    //
    // ac_sel = 0 -> resultado da ULA
    // ac_sel = 1 -> RDM
    // ========================================================

    mux mux_ac (

        .data_a (ula_resultado),
        .data_b (rdm_out),
        .sel    (ac_sel),
        .dout   (ac_din_mux)

    );


    // ========================================================
    // ULA
    //
    // X = AC
    // Y = RDM
    // ========================================================

    ula ula_inst (

        .X         (ac_out),
        .Y         (rdm_out),
        .op_ula    (op_ula),
        .resultado (ula_resultado),
        .N         (N),
        .Z         (Z)

    );


    // ========================================================
    // PC
    //
    // O PC recebe diretamente o RDM quando pc_carga = 1.
    // O incremento é feito internamente pelo módulo pc.
    // ========================================================

    pc pc_inst (

        .clk   (clk),
        .rst   (rst),
        .carga (pc_carga),
        .inc   (pc_inc),
        .din   (rdm_out),
        .dout  (pc_out)

    );


    // ========================================================
    // REM
    // ========================================================

    register8 rem_inst (

        .clk   (clk),
        .rst   (rst),
        .carga (rem_carga),
        .din   (rem_din),
        .dout  (rem_out)

    );


    // ========================================================
    // RDM
    //
    // Recebe o dado vindo da memória.
    // ========================================================

    register8 rdm_inst (

        .clk   (clk),
        .rst   (rst),
        .carga (rdm_carga),
        .din   (mem_din),
        .dout  (rdm_out)

    );


    // ========================================================
    // RI
    //
    // Recebe a instrução armazenada no RDM.
    // ========================================================

    register8 ri_inst (

        .clk   (clk),
        .rst   (rst),
        .carga (ri_carga),
        .din   (rdm_out),
        .dout  (ri_out)

    );


    // ========================================================
    // AC
    //
    // Recebe:
    //   - ULA, quando ac_sel = 0
    //   - RDM, quando ac_sel = 1
    // ========================================================

    register8 ac_inst (

        .clk   (clk),
        .rst   (rst),
        .carga (ac_carga),
        .din   (ac_din_mux),
        .dout  (ac_out)

    );


    // ========================================================
    // INTERFACE COM A MEMÓRIA
    // ========================================================

    // Endereço enviado à memória.
    assign mem_addr = rem_out;

    // Dado enviado à memória.
    assign mem_dout = ac_out;


endmodule