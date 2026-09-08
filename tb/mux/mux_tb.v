`timescale 1ns/1ps

// ============================================================
// NEANDER - Testbench do Multiplexador
// Projeto: Processador Neander em Verilog
// Módulo testado: mux
//
// Função:
//   Verificar se o MUX seleciona corretamente uma das
//   duas entradas de 8 bits.
//
// Testes:
//   - sel = 0 -> dout deve ser igual a data_a
//   - sel = 1 -> dout deve ser igual a data_b
//   - Diferentes combinações de data_a e data_b
//
// ============================================================

module mux_tb;

    // ========================================================
    // ARQUIVO DE ONDAS
    //
    // Gera sim/mux.vcd, para abrir no GTKWave:
    //     gtkwave sim/mux.vcd
    //
    // O 0 no $dumpvars manda registrar o testbench inteiro,
    // incluindo os sinais internos dos modulos instanciados.
    // ========================================================

    initial begin
        $dumpfile("sim/mux.vcd");
        $dumpvars(0, mux_tb);
    end


    // --------------------------------------------------------
    // Sinais de entrada do MUX
    // --------------------------------------------------------

    reg [7:0] data_a;
    reg [7:0] data_b;
    reg       sel;

    // --------------------------------------------------------
    // Sinal de saída do MUX
    // --------------------------------------------------------

    wire [7:0] dout;

    // --------------------------------------------------------
    // Instância do MUX
    // --------------------------------------------------------

    mux dut (
        .data_a(data_a),
        .data_b(data_b),
        .sel(sel),
        .dout(dout)
    );

    // --------------------------------------------------------
    // Cabeçalho da tabela
    // --------------------------------------------------------

    initial begin
        $display("");
        $display("==========================================================");
        $display("              TESTBENCH - MULTIPLEXADOR");
        $display("==========================================================");
        $display(" data_a | data_b | sel | dout | esperado | resultado");
        $display("--------+--------+-----+------+----------+----------");
    end

    // --------------------------------------------------------
    // Testes
    // --------------------------------------------------------

    initial begin

        // ====================================================
        // TESTE 1
        // sel = 0 -> deve selecionar data_a
        // ====================================================

        data_a = 8'h10;
        data_b = 8'h25;
        sel    = 0;

        #10;

        if (dout == data_a)
            $display("  %02h   |  %02h   |  %b  |  %02h  |    %02h    | PASS",
                     data_a, data_b, sel, dout, data_a);
        else
            $display("  %02h   |  %02h   |  %b  |  %02h  |    %02h    | FAIL",
                     data_a, data_b, sel, dout, data_a);


        // ====================================================
        // TESTE 2
        // sel = 1 -> deve selecionar data_b
        // ====================================================

        data_a = 8'h10;
        data_b = 8'h25;
        sel    = 1;

        #10;

        if (dout == data_b)
            $display("  %02h   |  %02h   |  %b  |  %02h  |    %02h    | PASS",
                     data_a, data_b, sel, dout, data_b);
        else
            $display("  %02h   |  %02h   |  %b  |  %02h  |    %02h    | FAIL",
                     data_a, data_b, sel, dout, data_b);


        // ====================================================
        // TESTE 3
        // ====================================================

        data_a = 8'h00;
        data_b = 8'hFF;
        sel    = 0;

        #10;

        if (dout == data_a)
            $display("  %02h   |  %02h   |  %b  |  %02h  |    %02h    | PASS",
                     data_a, data_b, sel, dout, data_a);
        else
            $display("  %02h   |  %02h   |  %b  |  %02h  |    %02h    | FAIL",
                     data_a, data_b, sel, dout, data_a);


        // ====================================================
        // TESTE 4
        // ====================================================

        data_a = 8'h00;
        data_b = 8'hFF;
        sel    = 1;

        #10;

        if (dout == data_b)
            $display("  %02h   |  %02h   |  %b  |  %02h  |    %02h    | PASS",
                     data_a, data_b, sel, dout, data_b);
        else
            $display("  %02h   |  %02h   |  %b  |  %02h  |    %02h    | FAIL",
                     data_a, data_b, sel, dout, data_b);


        // ====================================================
        // TESTE 5
        // ====================================================

        data_a = 8'hAA;
        data_b = 8'h55;
        sel    = 0;

        #10;

        if (dout == data_a)
            $display("  %02h   |  %02h   |  %b  |  %02h  |    %02h    | PASS",
                     data_a, data_b, sel, dout, data_a);
        else
            $display("  %02h   |  %02h   |  %b  |  %02h  |    %02h    | FAIL",
                     data_a, data_b, sel, dout, data_a);


        // ====================================================
        // TESTE 6
        // ====================================================

        data_a = 8'hAA;
        data_b = 8'h55;
        sel    = 1;

        #10;

        if (dout == data_b)
            $display("  %02h   |  %02h   |  %b  |  %02h  |    %02h    | PASS",
                     data_a, data_b, sel, dout, data_b);
        else
            $display("  %02h   |  %02h   |  %b  |  %02h  |    %02h    | FAIL",
                     data_a, data_b, sel, dout, data_b);


        // ====================================================
        // TESTE 7
        // ====================================================

        data_a = 8'h12;
        data_b = 8'h34;
        sel    = 0;

        #10;

        if (dout == data_a)
            $display("  %02h   |  %02h   |  %b  |  %02h  |    %02h    | PASS",
                     data_a, data_b, sel, dout, data_a);
        else
            $display("  %02h   |  %02h   |  %b  |  %02h  |    %02h    | FAIL",
                     data_a, data_b, sel, dout, data_a);


        // ====================================================
        // TESTE 8
        // ====================================================

        data_a = 8'h12;
        data_b = 8'h34;
        sel    = 1;

        #10;

        if (dout == data_b)
            $display("  %02h   |  %02h   |  %b  |  %02h  |    %02h    | PASS",
                     data_a, data_b, sel, dout, data_b);
        else
            $display("  %02h   |  %02h   |  %b  |  %02h  |    %02h    | FAIL",
                     data_a, data_b, sel, dout, data_b);


        // ====================================================
        // FIM
        // ====================================================

        $display("==========================================================");
        $display("                 FIM DA SIMULACAO");
        $display("==========================================================");
        $display("");

        $finish;

    end

endmodule