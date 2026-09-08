// ============================================================
// NEANDER - Execucao do programa soma2
// Projeto: Processador Neander em Verilog
//
// soma2: 10 + 20 + 7
//
// Acumula tres parcelas no AC e grava o total.
//
// Este testbench instancia uma unica CPU e gera sim/soma2.vcd, com as
// formas de onda apenas deste programa. A verificacao completa dos seis
// programas fica em tb/cpu/cpu_tb.v; aqui o objetivo e ter um arquivo de
// ondas limpo para analisar no GTKWave.
// ============================================================

`timescale 1ns/1ps

module soma2_tb;

    reg clk = 1'b0;
    reg rst = 1'b1;

    wire [7:0] pc;
    wire [7:0] ac;
    wire [7:0] ri;
    wire       n;
    wire       z;

    cpu #(.PROGRAMA("programas/soma2.mem")) neander (

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
    // Abra com: gtkwave sim/soma2.vcd
    // ========================================================

    initial begin
        $dumpfile("sim/soma2.vcd");
        $dumpvars(0, soma2_tb);
    end

    initial begin
        $display("-- soma2: 10 + 20 + 7 --");

        // O reset precisa valer por pelo menos um ciclo completo, porque
        // os registradores e o PC tem reset sincrono.
        repeat (2) @(negedge clk);
        rst = 1'b0;

        // Ciclos suficientes para o programa terminar no HLT
        repeat (50) @(negedge clk);

        $display("   AC          = %0d   (esperado 37)", ac);
        $display("   memoria[43] = %0d   (esperado 37)",
                 neander.memoria.memory[43]);

        if (ac === 8'd37 && neander.memoria.memory[43] === 8'd37)
            $display("   ok");
        else
            $display("   ERRO: o programa nao terminou com os valores esperados");

        $finish;
    end

endmodule
