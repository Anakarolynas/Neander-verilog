// ============================================================
// NEANDER - Multiplexador
// Projeto: Processador Neander em Verilog
// Módulo: MUX
//
// Função:
//   Seleciona uma entre duas entradas de 8 bits
//
// Operações:
//   sel = 0 → dout = data_a
//   sel = 1 → dout = data_b 
//
// Utilização no datapath:
//   - Seleção da entrada do REM
//   - Seleção da entrada do AC
//   - Seleção da entrada do PC
// ============================================================
 
module mux (
    input  wire       [7:0] data_a, 
    input  wire       [7:0] data_b, 
    input  wire       sel,
    
    output  reg       [7:0] dout  
); 

    always @(*) begin
        
        if (sel == 0) begin 
            dout = data_a;
        end 

        else begin 
            dout = data_b; 
        end 

    end 

endmodule