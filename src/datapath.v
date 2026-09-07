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
//   - N e Z (flags da ULA)
//
// MUXes:
//   - MUX REM: seleciona PC ou RDM
//   - MUX RDM: seleciona memória ou AC
//
// Caminho do PC:
//   - PC pode ser incrementado internamente
//   - PC pode receber diretamente o valor do RDM
//
// Caminho da memória:
//   REM -> endereço da memória
//   memória -> RDM
//   RDM -> dado escrito na memória
//
// Caminho da instrução:
//   RDM -> RI
//
// O AC recebe sempre o resultado da ULA: o LDA usa a operação ID,
// que devolve o Y da ULA (ligado ao RDM), então não é preciso um
// MUX na entrada do AC.
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
    input wire rdm_sel,
    input wire ri_carga,
    input wire ac_carga,

    // --------------------------------------------------------
    // Controle da ULA
    // --------------------------------------------------------

    input wire [2:0] op_ula,

    // --------------------------------------------------------
    // Controle das flags N e Z
    // --------------------------------------------------------

    input wire nz_carga,

    // --------------------------------------------------------
    // Entrada de dados da memória
    // --------------------------------------------------------

    input wire [7:0] mem_din,

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

    // Entrada do RDM
    wire [7:0] rdm_din;

    // Resultado da ULA
    wire [7:0] ula_resultado;

    // Flags geradas pela ULA, antes de serem registradas
    wire n_ula;
    wire z_ula;


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
    // MUX DO RDM
    //
    // rdm_sel = 0 -> dado vindo da memória (leitura)
    // rdm_sel = 1 -> AC (usado pelo STA, antes da escrita)
    // ========================================================

    mux mux_rdm (

        .data_a (mem_din),
        .data_b (ac_out),
        .sel    (rdm_sel),
        .dout   (rdm_din)

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
        .N         (n_ula),
        .Z         (z_ula)

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
    // Recebe o dado escolhido pelo MUX: memória ou AC.
    // ========================================================

    register8 rdm_inst (

        .clk   (clk),
        .rst   (rst),
        .carga (rdm_carga),
        .din   (rdm_din),
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
    // Recebe sempre o resultado da ULA. Para o LDA, a unidade de
    // controle seleciona a operação ID, que devolve o Y (o RDM).
    // ========================================================

    register8 ac_inst (

        .clk   (clk),
        .rst   (rst),
        .carga (ac_carga),
        .din   (ula_resultado),
        .dout  (ac_out)

    );


    // ========================================================
    // FLAGS N E Z
    //
    // A ULA gera N e Z de forma combinacional, refletindo sempre a
    // operação do momento. Os desvios condicionais precisam das flags
    // da última operação executada, por isso elas são guardadas aqui,
    // sob o comando de nz_carga.
    // ========================================================

    reg n_flag;
    reg z_flag;

    always @(posedge clk) begin

        if (rst) begin
            n_flag <= 1'b0;
            z_flag <= 1'b0;
        end

        else if (nz_carga) begin
            n_flag <= n_ula;
            z_flag <= z_ula;
        end

    end

    assign N = n_flag;
    assign Z = z_flag;


    // ========================================================
    // INTERFACE COM A MEMÓRIA
    // ========================================================

    // Endereço enviado à memória.
    assign mem_addr = rem_out;

    // Dado enviado à memória: vem do RDM, que o STA carrega com o AC.
    assign mem_dout = rdm_out;


endmodule