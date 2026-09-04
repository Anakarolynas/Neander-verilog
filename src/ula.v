// ============================================================
// NEANDER - Unidade lógica e aritmética 
// Projeto: Processador Neander em Verilog
// Módulo: ULA
//
// Função:
//   Calcula o resultado das operações
//
// Operações:
//   - ADD:  X + Y   => OP: 000
//   - AND:  X & Y   => OP: 001
//   - OR:   X | Y   => OP: 010
//   - NOT:  ~X      => OP: 011
//   - ID:   Y       => OP: 100
//
// Flags: 
//   - N -> resultado negativo 
//   - Z -> resultado igual a zero
// ============================================================

module ula ( 
    input  wire       [7:0] X, 
    input  wire       [7:0] Y, 
    input  wire       [2:0] op_ula,
    
    output  reg       [7:0] resultado, 
    output  wire      N, 
    output  wire      Z
); 

    always @(*) begin 
        
        // ADD: 
        if (op_ula == 3'b000) begin 
            resultado = X + Y; 
        end 

        // AND:
        else if (op_ula == 3'b001) begin 
            resultado = X & Y; 
        end 

        // OR:
        else if (op_ula == 3'b010) begin 
            resultado = X | Y; 
        end 

        // NOT:
        else if (op_ula == 3'b011) begin 
            resultado = ~X; 
        end

        // ID:
        else if (op_ula == 3'b100) begin 
            resultado = Y; 
        end 

        // Caso op_ula receba uma operação inválida:
        else begin
            resultado = 8'b00000000;
        end 
    end 

    //Flags N e Z: 
    assign N = resultado[7];
    assign Z = (resultado == 8'b00000000);

endmodule