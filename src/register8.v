// ============================================================
// NEANDER - Registrador de 8 bits
// Projeto: Processador Neander em Verilog
// Módulo: register8
//
// Função:
//   Armazena um valor de 8 bits e permite sua atualização
//   controlada pelo sinal de carga.
//
// Será utilizado para:
//   - AC  -> Acumulador
//   - REM -> Registrador de Endereço da Memória
//   - RDM -> Registrador de Dados da Memória
//   - IR  -> Registrador de Instrução
//
// ============================================================

module register8 (
    input  wire       clk,
    input  wire       rst,
    input  wire       carga,
    input  wire [7:0] din,
    output reg  [7:0] dout
);

    // --------------------------------------------------------
    // Registrador
    // --------------------------------------------------------
    always @(posedge clk) begin

        // Se o reset estiver ativo,
        // o registrador recebe zero.
        if (rst) begin
            dout <= 8'b00000000;
        end

        // Se a carga estiver ativa,
        // o registrador recebe o valor da entrada.
        else if (carga) begin
            dout <= din;
        end

        // Caso contrário:
        // mantém o valor armazenado.
    end

endmodule