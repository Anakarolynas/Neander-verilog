// ============================================================
// NEANDER - Memória principal
// Projeto: Processador Neander em Verilog
// Módulo: RAM
//
// Função:
//   Armazena o programa e os dados. 256 posições de 8 bits,
//   endereçadas pelo REM.
//
// Operações:
//   - Leitura:  data_out <= memory[address]   (assíncrona)
//   - Escrita:  memory[address] <= data_in    (na borda do clock)
//
// IMPORTANTE - por que a leitura é assíncrona:
//   A unidade de controle ativa read e carga_rdm no MESMO ciclo
//   (estados t1, t4 e t6). Se a leitura fosse registrada, o dado só
//   ficaria disponível no ciclo seguinte e o RDM capturaria o valor
//   anterior. O endereço já está estável no REM desde o ciclo anterior,
//   então a leitura combinacional é válida.
//
// Carregar um programa:
//   Passe o nome do arquivo no parâmetro PROGRAMA ao instanciar:
//     RAM #(.PROGRAMA("programas/soma.mem")) memoria ( ... );
//   O arquivo deve ter um valor binário de 8 bits por linha.
//   Sem o parâmetro, a memória começa zerada.
//
//   O Icarus avisa "Not enough words in the file" quando o programa tem
//   menos de 256 linhas. É esperado e pode ser ignorado: as posições
//   restantes ficam em zero.
// ============================================================

module RAM #(
    parameter PROGRAMA = ""  // arquivo com o conteúdo inicial da memória
)(
    input  wire [7:0] address,
    input  wire [7:0] data_in,
    input  wire       write_enable,
    input  wire       read_enable,
    input  wire       clk,

    output reg  [7:0] data_out
);

    reg [7:0] memory [0:255]; // 256 bytes de memória

    // --------------------------------------------------------
    // Conteúdo inicial
    // --------------------------------------------------------
    integer i;
    initial begin
        // Zera a memória para não começar com valores indefinidos
        for (i = 0; i < 256; i = i + 1)
            memory[i] = 8'h00;

        // Carrega o programa, se algum tiver sido informado
        if (PROGRAMA != "")
            $readmemb(PROGRAMA, memory);
    end

    // --------------------------------------------------------
    // Escrita: síncrona, na borda de subida do clock.
    // No estado t7 o REM e o RDM já estão estáveis, então o valor
    // gravado é o correto.
    //
    // A memória não é apagada no reset: isso destruiria o programa.
    // --------------------------------------------------------
    always @(posedge clk) begin
        if (write_enable)
            memory[address] <= data_in;
    end

    // --------------------------------------------------------
    // Leitura: combinacional.
    // Fora da leitura devolve zero, e não alta impedância: esta saída
    // vai direto para uma entrada do MUX do RDM, não é barramento
    // compartilhado. Alta impedância aqui se propagaria para dentro
    // do RDM.
    // --------------------------------------------------------
    always @(*) begin

        // Leitura habilitada: entrega o conteúdo da posição endereçada
        if (read_enable) begin
            data_out = memory[address];
        end

        // Fora da leitura: saída em zero
        else begin
            data_out = 8'h00;
        end

    end

endmodule
