// ============================================================
// NEANDER - Execucao do programa logica1
// Projeto: Processador Neander em Verilog
//
// logica1: 11110000 AND 00111100
//
// Aplica uma mascara de bits com a operacao AND.
//
// Este testbench instancia uma unica CPU e gera sim/logica1.vcd, com as
// formas de onda apenas deste programa. A verificacao completa dos seis
// programas fica em tb/cpu/cpu_tb.v; aqui o objetivo e ter um arquivo de
// ondas limpo para analisar no GTKWave.
// ============================================================

`timescale 1ns/1ps

module logica1_tb;

    reg clk = 1'b0;
    reg rst = 1'b1;

    wire [7:0] pc;
    wire [7:0] ac;
    wire [7:0] ri;
    wire       n;
    wire       z;

    cpu #(.PROGRAMA("programas/logica1.mem")) neander (

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
    // Abra com: gtkwave sim/logica1.vcd
    // ========================================================

    initial begin
        $dumpfile("sim/logica1.vcd");
        $dumpvars(0, logica1_tb);
    end

    initial begin
        $display("-- logica1: 11110000 AND 00111100 --");

        // O reset precisa valer por pelo menos um ciclo completo, porque
        // os registradores e o PC tem reset sincrono.
        repeat (2) @(negedge clk);
        rst = 1'b0;

        // Ciclos suficientes para o programa terminar no HLT
        repeat (40) @(negedge clk);

        $display("   AC          = %0d   (esperado 48)", ac);
        $display("   memoria[42] = %0d   (esperado 48)",
                 neander.memoria.memory[42]);

        if (ac === 8'd48 && neander.memoria.memory[42] === 8'd48)
            $display("   ok");
        else
            $display("   ERRO: o programa nao terminou com os valores esperados");

        $finish;
    end

endmodule
