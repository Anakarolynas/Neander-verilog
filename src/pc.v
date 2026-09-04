// ============================================================
// NEANDER - Program Counter
// Projeto: Processador Neander em Verilog
// Módulo: pc
//
// Função:
//   Armazena o endereço da próxima instrução.
//
// Operações:
//   - Reset: PC <- 0
//   - Load:  PC <- data_in
//   - Inc:   PC <- PC + 1
// ============================================================

module pc ( 
    input  wire       clk,
    input  wire       rst,
    input  wire       carga, 
    input  wire       inc,
    input  wire [7:0] din,
    output reg  [7:0] dout
);
    always @(posedge clk) begin 
        if (rst) begin 
            dout <= 8'b00000000; 
        end
        else if (carga) begin 
            dout <= din; 
        end 
        else if (inc) begin 
            dout <= dout + 8'b00000001; 
        end
    end
 endmodule