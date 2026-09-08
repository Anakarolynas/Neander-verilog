// ============================================================
// NEANDER - Execucao do programa condicional1
// Projeto: Processador Neander em Verilog
//
// condicional1: se/senao decidido pela flag N
//
// Testa o sinal de um valor e grava um marcador diferente conforme o caminho tomado.
//
// Este testbench instancia uma unica CPU e gera sim/condicional1.vcd, com as
// formas de onda apenas deste programa. A verificacao completa dos seis
// programas fica em tb/cpu/cpu_tb.v; aqui o objetivo e ter um arquivo de
// ondas limpo para analisar no GTKWave.
// ============================================================

`timescale 1ns/1ps

module condicional1_tb;

    reg clk = 1'b0;
    reg rst = 1'b1;

    wire [7:0] pc;
    wire [7:0] ac;
    wire [7:0] ri;
    wire       n;
    wire       z;

    cpu #(.PROGRAMA("programas/condicional1.mem")) neander (

        .clk (clk),
        .rst (rst),
        .pc  (pc),
        .ac  (ac),
        .ri  (ri),
        .n   (n),
        .z   (z)

    );

    // Clock com periodo de 10 unidades de tempo
    always #5 clk = ~clk;

    // ========================================================
    // ARQUIVO DE ONDAS
    //
    // Abra com: gtkwave sim/condicional1.vcd
    // ========================================================

    initial begin
        $dumpfile("sim/condicional1.vcd");
        $dumpvars(0, condicional1_tb);
    end

    initial begin
        $display("-- condicional1: se/senao decidido pela flag N --");

        // O reset precisa valer por pelo menos um ciclo completo, porque
        // os registradores e o PC tem reset sincrono.
        repeat (2) @(negedge clk);
        rst = 1'b0;

        // Ciclos suficientes para o programa terminar no HLT
        repeat (45) @(negedge clk);

        $display("   AC          = %0d   (esperado 2)", ac);
        $display("   memoria[43] = %0d   (esperado 2)",
                 neander.memoria.memory[43]);

        if (ac === 8'd2 && neander.memoria.memory[43] === 8'd2)
            $display("   ok");
        else
            $display("   ERRO: o programa nao terminou com os valores esperados");

        $finish;
    end

endmodule
