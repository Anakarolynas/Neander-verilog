// ============================================================
// NEANDER - Testbench da CPU
// Projeto: Processador Neander em Verilog
// Módulo: cpu
//
// Testa a integração das três partes do processador (datapath,
// memória e unidade de controle) executando um programa completo,
// carregado de programas/integracao.mem.
//
// O programa exercita:
//   - Leitura da memória (LDA)
//   - Operação da ULA sobre um operando da memória (ADD)
//   - Escrita na memória (STA)
//   - Desvio condicional não tomado (JZ com Z=0)
//   - Operação da ULA sem operando (NOT)
//   - Desvio condicional tomado (JN com N=1)
//   - Parada do processador (HLT)
//
// O teste confere o AC, as duas posições de memória escritas, as
// flags e o endereço onde o processador parou.
// ============================================================

`timescale 1ns/1ps

module cpu_tb;

    reg clk = 1'b0;
    reg rst = 1'b1;

    wire [7:0] pc;
    wire [7:0] ac;
    wire [7:0] ri;
    wire       n;
    wire       z;

    integer erros = 0;

    cpu #(.PROGRAMA("programas/integracao.mem")) neander (

        .clk (clk),
        .rst (rst),
        .pc  (pc),
        .ac  (ac),
        .ri  (ri),
        .n   (n),
        .z   (z)

    );

    // Clock com período de 10 unidades de tempo
    always #5 clk = ~clk;

    // Compara um valor com o esperado e contabiliza o erro
    task confere;
        input [7:0] obtido;
        input [7:0] esperado;
        input [8*40:1] descricao;
        begin
            if (obtido !== esperado) begin
                erros = erros + 1;
                $display("  ERRO  %0s: obtido %0d, esperado %0d",
                         descricao, obtido, esperado);
            end
            else begin
                $display("  ok    %0s = %0d", descricao, obtido);
            end
        end
    endtask

    initial begin
        $display("============================================================");
        $display(" Testbench da CPU - programa de integracao");
        $display("============================================================");
        $display("");
        $display("  LDA 32 (=5) ; ADD 33 (=3) ; STA 34 ; JZ 20 (nao desvia)");
        $display("  NOT ; JN 14 (desvia) ; STA 35 ; HLT");
        $display("");

        // O reset precisa valer por pelo menos um ciclo completo, porque
        // os registradores e o PC têm reset síncrono.
        repeat (2) @(negedge clk);
        rst = 1'b0;

        // Tempo suficiente para o programa inteiro: a instrução mais longa
        // leva 8 ciclos e o programa tem 8 instruções.
        repeat (100) @(negedge clk);

        $display("Estado final:");
        confere(ac,                        8'd247, "AC                    ");
        confere(neander.memoria.memory[34], 8'd8,   "memoria[34] (5 + 3)   ");
        confere(neander.memoria.memory[35], 8'd247, "memoria[35] (NOT do 8)");
        confere(pc,                        8'd17,  "PC (parou no HLT do 16)");
        $display("");

        $display("Flags apos o NOT (resultado 247, negativo):");
        confere({7'b0, n}, 8'd1, "N                     ");
        confere({7'b0, z}, 8'd0, "Z                     ");
        $display("");

        // Se o processador tivesse desviado no JZ ou passado direto pelo JN,
        // teria parado num HLT diferente e a memoria[35] ficaria zerada.
        if (ri[7:4] !== 4'b1111) begin
            erros = erros + 1;
            $display("  ERRO  o processador nao parou em um HLT (RI = %b)", ri);
        end

        $display("============================================================");
        if (erros == 0)
            $display(" RESULTADO: todos os testes passaram");
        else
            $display(" RESULTADO: %0d erro(s) encontrado(s)", erros);
        $display("============================================================");

        $finish;
    end

endmodule
