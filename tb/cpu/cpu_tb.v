// ============================================================
// NEANDER - Testbench da CPU
// Projeto: Processador Neander em Verilog
// Módulo: cpu
//
// Testa a integração das três partes do processador (datapath,
// memória e unidade de controle) executando programas completos.
//
// São sete instâncias da CPU, cada uma com o seu próprio programa
// carregado na memória. Todas partilham o clock e o reset, então
// executam em paralelo e os resultados são conferidos no final.
//
//   integracao    caminho completo, com os dois desfechos de um desvio
//   soma1         soma de dois valores
//   soma2         soma de três valores
//   logica1       AND (máscara de bits)
//   logica2       OR seguido de NOT
//   condicional1  se/senão decidido pela flag N
//   condicional2  laço decidido pela flag Z
//
// Os seis últimos são os programas de demonstração exigidos pelo
// projeto: duas somas, duas operações lógicas e duas estruturas
// condicionais.
// ============================================================

`timescale 1ns/1ps

module cpu_tb;

    // ========================================================
    // ARQUIVO DE ONDAS
    //
    // Gera sim/cpu.vcd, para abrir no GTKWave:
    //     gtkwave sim/cpu.vcd
    //
    // O 0 no $dumpvars manda registrar o testbench inteiro,
    // incluindo os sinais internos dos modulos instanciados.
    // ========================================================

    initial begin
        $dumpfile("sim/cpu.vcd");
        $dumpvars(0, cpu_tb);
    end


    reg clk = 1'b0;
    reg rst = 1'b1;

    integer erros = 0;

    // Clock com período de 10 unidades de tempo
    always #5 clk = ~clk;


    // ========================================================
    // INSTÂNCIAS DA CPU, UMA POR PROGRAMA
    // ========================================================

    wire [7:0] ac_integracao, pc_integracao, ri_integracao;
    wire       n_integracao,  z_integracao;

    cpu #(.PROGRAMA("programas/integracao.mem")) integracao (
        .clk (clk), .rst (rst),
        .pc  (pc_integracao), .ac (ac_integracao), .ri (ri_integracao),
        .n   (n_integracao),  .z  (z_integracao)
    );

    wire [7:0] ac_soma1;
    cpu #(.PROGRAMA("programas/soma1.mem")) soma1 (
        .clk (clk), .rst (rst),
        .pc  (), .ac (ac_soma1), .ri (), .n (), .z ()
    );

    wire [7:0] ac_soma2;
    cpu #(.PROGRAMA("programas/soma2.mem")) soma2 (
        .clk (clk), .rst (rst),
        .pc  (), .ac (ac_soma2), .ri (), .n (), .z ()
    );

    wire [7:0] ac_logica1;
    cpu #(.PROGRAMA("programas/logica1.mem")) logica1 (
        .clk (clk), .rst (rst),
        .pc  (), .ac (ac_logica1), .ri (), .n (), .z ()
    );

    wire [7:0] ac_logica2;
    wire       z_logica2;
    cpu #(.PROGRAMA("programas/logica2.mem")) logica2 (
        .clk (clk), .rst (rst),
        .pc  (), .ac (ac_logica2), .ri (), .n (), .z (z_logica2)
    );

    wire [7:0] ac_condicional1;
    cpu #(.PROGRAMA("programas/condicional1.mem")) condicional1 (
        .clk (clk), .rst (rst),
        .pc  (), .ac (ac_condicional1), .ri (), .n (), .z ()
    );

    wire [7:0] ac_condicional2;
    cpu #(.PROGRAMA("programas/condicional2.mem")) condicional2 (
        .clk (clk), .rst (rst),
        .pc  (), .ac (ac_condicional2), .ri (), .n (), .z ()
    );


    // ========================================================
    // VERIFICAÇÃO
    // ========================================================

    // Compara um valor com o esperado e contabiliza o erro
    task confere;
        input [7:0] obtido;
        input [7:0] esperado;
        input [8*34:1] descricao;
        begin
            if (obtido !== esperado) begin
                erros = erros + 1;
                $display("    ERRO  %0s: obtido %0d, esperado %0d",
                         descricao, obtido, esperado);
            end
            else begin
                $display("    ok    %0s = %0d", descricao, obtido);
            end
        end
    endtask


    initial begin
        $display("============================================================");
        $display(" Testbench da CPU");
        $display("============================================================");

        // O reset precisa valer por pelo menos um ciclo completo, porque
        // os registradores e o PC têm reset síncrono.
        repeat (2) @(negedge clk);
        rst = 1'b0;

        // Tempo suficiente para o mais longo dos programas: o laço do
        // condicional2 leva pouco mais de 200 ciclos.
        repeat (400) @(negedge clk);


        $display("");
        $display("-- integracao: LDA, ADD, STA, JZ (nao desvia), NOT, JN (desvia), HLT --");
        confere(ac_integracao,                       8'd247, "AC                    ");
        confere(integracao.memoria.memory[34],       8'd8,   "memoria[34] (5 + 3)   ");
        confere(integracao.memoria.memory[35],       8'd247, "memoria[35] (NOT do 8)");
        confere(pc_integracao,                       8'd17,  "PC (HLT do endereco 16)");
        confere({7'b0, n_integracao},                8'd1,   "flag N                ");
        confere({7'b0, z_integracao},                8'd0,   "flag Z                ");

        // O processador só pode ter parado com um HLT no RI
        if (ri_integracao[7:4] !== 4'b1111) begin
            erros = erros + 1;
            $display("    ERRO  o processador nao parou em um HLT (RI = %b)",
                     ri_integracao);
        end

        $display("");
        $display("-- soma1: 5 + 3 --");
        confere(ac_soma1,                  8'd8, "AC                    ");
        confere(soma1.memoria.memory[42],  8'd8, "memoria[42]           ");

        $display("");
        $display("-- soma2: 10 + 20 + 7 --");
        confere(ac_soma2,                  8'd37, "AC                    ");
        confere(soma2.memoria.memory[43],  8'd37, "memoria[43]           ");

        $display("");
        $display("-- logica1: 11110000 AND 00111100 --");
        confere(ac_logica1,                  8'h30, "AC                    ");
        confere(logica1.memoria.memory[42],  8'h30, "memoria[42]           ");

        $display("");
        $display("-- logica2: (11110000 OR 00001111) e depois NOT --");
        confere(ac_logica2,                  8'h00, "AC                    ");
        confere(logica2.memoria.memory[42],  8'h00, "memoria[42]           ");
        confere({7'b0, z_logica2},           8'd1,  "flag Z (resultado zero)");

        $display("");
        $display("-- condicional1: valor negativo, desvia pelo JN --");
        confere(ac_condicional1,                  8'd2, "AC (marcador negativo)");
        confere(condicional1.memoria.memory[43],  8'd2, "memoria[43]           ");

        $display("");
        $display("-- condicional2: laco somando 5 tres vezes --");
        confere(ac_condicional2,                  8'd15, "AC                    ");
        confere(condicional2.memoria.memory[42],  8'd15, "memoria[42] (resultado)");
        confere(condicional2.memoria.memory[40],  8'd0,  "memoria[40] (contador)");

        $display("");
        $display("============================================================");
        if (erros == 0)
            $display(" RESULTADO: todos os testes passaram");
        else
            $display(" RESULTADO: %0d erro(s) encontrado(s)", erros);
        $display("============================================================");

        $finish;
    end

endmodule
