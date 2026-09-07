// ============================================================
// NEANDER - Processador completo
// Projeto: Processador Neander em Verilog
// Módulo: cpu
//
// Função:
//   Junta as três partes do processador e faz a ligação entre elas:
//
//     - datapath      registradores, MUXes, ULA e flags
//     - RAM           256 posições de 8 bits
//     - Unit_Control  FSM + decodificador dos sinais de controle
//
// Ligações principais:
//   - Os sinais de controle saem da Unit_Control para o datapath.
//   - read e write vão da Unit_Control direto para a memória.
//   - O endereço (REM) e o dado a escrever (RDM) saem do datapath
//     para a memória; o dado lido volta para o datapath.
//   - O opcode vem dos 4 bits mais significativos do RI, e as flags
//     N e Z voltam do datapath para a Unit_Control.
//
// Carregar um programa:
//   cpu #(.PROGRAMA("programas/soma.mem")) neander (.clk(clk), .rst(rst));
//
// As saídas de observação (pc, ac, ri, n, z) não fazem parte do
// funcionamento do processador: existem para o testbench e para a
// visualização das formas de onda.
// ============================================================

module cpu #(

    parameter PROGRAMA = ""  // arquivo com o programa a ser carregado

)(

    input wire clk,
    input wire rst,

    // --------------------------------------------------------
    // Observação do estado interno
    // --------------------------------------------------------

    output wire [7:0] pc,
    output wire [7:0] ac,
    output wire [7:0] ri,
    output wire       n,
    output wire       z

);


    // ========================================================
    // SINAIS DE CONTROLE
    // ========================================================

    wire carga_rem;
    wire carga_rdm;
    wire carga_ri;
    wire carga_ac;
    wire carga_pc;
    wire carga_nz;
    wire incrementa_pc;
    wire sel_rem;
    wire sel_rdm;
    wire [2:0] sel_ula;
    wire read;
    wire write;
    wire goto0;


    // ========================================================
    // CAMINHOS DE DADOS
    // ========================================================

    wire [7:0] pc_out;
    wire [7:0] rem_out;
    wire [7:0] rdm_out;
    wire [7:0] ri_out;
    wire [7:0] ac_out;

    // Ligação com a memória
    wire [7:0] mem_addr;   // endereço, vindo do REM
    wire [7:0] mem_dout;   // dado a escrever, vindo do RDM
    wire [7:0] mem_din;    // dado lido, indo para o RDM

    // Flags registradas, do datapath para a unidade de controle
    wire flag_n;
    wire flag_z;


    // ========================================================
    // DATAPATH
    // ========================================================

    datapath datapath_inst (

        .clk       (clk),
        .rst       (rst),

        .pc_carga  (carga_pc),
        .pc_inc    (incrementa_pc),

        .rem_carga (carga_rem),
        .rem_sel   (sel_rem),

        .rdm_carga (carga_rdm),
        .rdm_sel   (sel_rdm),
        .ri_carga  (carga_ri),
        .ac_carga  (carga_ac),

        .op_ula    (sel_ula),
        .nz_carga  (carga_nz),

        .mem_din   (mem_din),

        .pc_out    (pc_out),
        .rem_out   (rem_out),
        .rdm_out   (rdm_out),
        .ri_out    (ri_out),
        .ac_out    (ac_out),

        .mem_addr  (mem_addr),
        .mem_dout  (mem_dout),

        .N         (flag_n),
        .Z         (flag_z)

    );


    // ========================================================
    // MEMÓRIA
    // ========================================================

    RAM #(.PROGRAMA(PROGRAMA)) memoria (

        .clk          (clk),
        .address      (mem_addr),
        .data_in      (mem_dout),
        .write_enable (write),
        .read_enable  (read),
        .data_out     (mem_din)

    );


    // ========================================================
    // UNIDADE DE CONTROLE
    //
    // O opcode são os 4 bits mais significativos do RI; os 4 bits
    // restantes não são usados pelo Neander.
    // ========================================================

    Unit_Control unit_control_inst (

        .clk           (clk),
        .rst           (rst),

        .opcode        (ri_out[7:4]),
        .Z             (flag_z),
        .N             (flag_n),

        .carga_rem     (carga_rem),
        .carga_rdm     (carga_rdm),
        .incrementa_pc (incrementa_pc),
        .sel_ula       (sel_ula),
        .carga_ri      (carga_ri),
        .sel_rem       (sel_rem),
        .sel_rdm       (sel_rdm),
        .read          (read),
        .write         (write),
        .carga_ac      (carga_ac),
        .carga_pc      (carga_pc),
        .carga_nz      (carga_nz),
        .goto0         (goto0)

    );


    // ========================================================
    // SAÍDAS DE OBSERVAÇÃO
    // ========================================================

    assign pc = pc_out;
    assign ac = ac_out;
    assign ri = ri_out;
    assign n  = flag_n;
    assign z  = flag_z;


endmodule
