// ============================================================
// NEANDER - Testbench da Unidade Lógica e Aritmética
// Projeto: Processador Neander em Verilog
// Módulo: ULA
//
// Testa:
//   - ADD
//   - AND
//   - OR
//   - NOT
//   - ID
//
// Também testa todas as combinações possíveis das flags:
//   N=0 Z=0
//   N=0 Z=1
//   N=1 Z=0
//   N=1 Z=1 -> impossível
// ============================================================

`timescale 1ns/1ps

module ula_tb;

    // ========================================================
    // ARQUIVO DE ONDAS
    //
    // Gera sim/ula.vcd, para abrir no GTKWave:
    //     gtkwave sim/ula.vcd
    //
    // O 0 no $dumpvars manda registrar o testbench inteiro,
    // incluindo os sinais internos dos modulos instanciados.
    // ========================================================

    initial begin
        $dumpfile("sim/ula.vcd");
        $dumpvars(0, ula_tb);
    end


    // --------------------------------------------------------
    // Declaração dos sinais
    // --------------------------------------------------------

    reg [7:0] X;
    reg [7:0] Y;
    reg [2:0] op_ula;

    wire [7:0] resultado;
    wire N;
    wire Z;

    // --------------------------------------------------------
    // Instanciação da ULA
    // --------------------------------------------------------

    ula uut (
        .X(X),
        .Y(Y),
        .op_ula(op_ula),
        .resultado(resultado),
        .N(N),
        .Z(Z)
    );

    // --------------------------------------------------------
    // Testes
    // --------------------------------------------------------

    initial begin

        $display("======================================================================");
        $display("                     TESTE DA ULA - NEANDER                          ");
        $display("======================================================================");
        $display("| OP  | OPERACAO |    X    |    Y    | RESULTADO | N | Z |");
        $display("----------------------------------------------------------------------");


        // ====================================================
        // TESTE 1 - ADD
        // Resultado = 5 + 3 = 8
        // N = 0
        // Z = 0
        // ====================================================

        X = 8'd5;
        Y = 8'd3;
        op_ula = 3'b000;

        #10;

        $display("| 000 |   ADD    | %8d | %8d | %9d | %d | %d |",
                 X, Y, resultado, N, Z);


        // ====================================================
        // TESTE 2 - AND
        // 0101 AND 0011 = 0001
        // N = 0
        // Z = 0
        // ====================================================

        X = 8'b00000101;
        Y = 8'b00000011;
        op_ula = 3'b001;

        #10;

        $display("| 001 |   AND    | %8d | %8d | %9d | %d | %d |",
                 X, Y, resultado, N, Z);


        // ====================================================
        // TESTE 3 - OR
        // 0101 OR 0011 = 0111
        // N = 0
        // Z = 0
        // ====================================================

        X = 8'b00000101;
        Y = 8'b00000011;
        op_ula = 3'b010;

        #10;

        $display("| 010 |    OR    | %8d | %8d | %9d | %d | %d |",
                 X, Y, resultado, N, Z);


        // ====================================================
        // TESTE 4 - NOT
        // ~00000101 = 11111010
        // N = 1
        // Z = 0
        // ====================================================

        X = 8'b00000101;
        Y = 8'b00000000;
        op_ula = 3'b011;

        #10;

        $display("| 011 |   NOT    | %8d | %8d | %9d | %d | %d |",
                 X, Y, resultado, N, Z);


        // ====================================================
        // TESTE 5 - ID
        // resultado = Y = 10
        // N = 0
        // Z = 0
        // ====================================================

        X = 8'b00000000;
        Y = 8'd10;
        op_ula = 3'b100;

        #10;

        $display("| 100 |    ID    | %8d | %8d | %9d | %d | %d |",
                 X, Y, resultado, N, Z);


        // ====================================================
        // COMBINAÇÃO N=0 Z=1
        //
        // Resultado = 0
        // ====================================================

        X = 8'd5;
        Y = -8'd5;
        op_ula = 3'b000;

        #10;

        $display("| 000 |  ADD Z   | %8d | %8d | %9d | %d | %d |",
                 X, Y, resultado, N, Z);


        // ====================================================
        // COMBINAÇÃO N=1 Z=0
        //
        // Resultado = -5
        // ====================================================

        X = 8'd5;
        Y = -8'd10;
        op_ula = 3'b000;

        #10;

        $display("| 000 |  ADD N   | %8d | %8d | %9d | %d | %d |",
                 X, Y, resultado, N, Z);


        // ====================================================
        // COMBINAÇÃO N=0 Z=0
        //
        // Resultado positivo e diferente de zero
        // ====================================================

        X = 8'd10;
        Y = 8'd5;
        op_ula = 3'b000;

        #10;

        $display("| 000 |  N0 Z0   | %8d | %8d | %9d | %d | %d |",
                 X, Y, resultado, N, Z);


        // ====================================================
        // COMBINAÇÃO N=1 Z=1
        //
        // Esta combinação deve ser IMPOSSÍVEL.
        //
        // Um número não pode ser simultaneamente:
        //   - negativo (N=1)
        //   - igual a zero (Z=1)
        //
        // Portanto, não existe uma entrada válida que produza
        // N=1 e Z=1.
        // ====================================================

        $display("|     |  N1 Z1   |          IMPOSSIVEL          |");

        $display("======================================================================");

        $finish;

    end

endmodule