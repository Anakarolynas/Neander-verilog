# Processador Neander em Verilog

Projeto de implementação do processador Neander utilizando Verilog HDL.

## Estrutura

- `src/` - módulos do processador
- `tb/` - testbenches
- `docs/` - documentação e diagramas
- `sim/` - arquivos relacionados às simulações

## Ferramentas

- Verilog
- Icarus Verilog
- GTKWave
- Visual Studio Code

## Arquitetura

O projeto implementa a arquitetura didática Neander, incluindo:

- Registradores
- PC
- ULA
- Memória
- Datapath
- Unidade de Controle
- CPU
- ISA do Neander

## Unidade de Controle (`src/unit_control.v` + `src/fsm.v`)

A unidade de controle é composta por dois módulos. O `Unit_Control` é o módulo público:
ele instancia a `FSM` internamente, então **o datapath deve instanciar apenas o
`Unit_Control`** — a `FSM` não precisa ser ligada diretamente.

| Módulo | Arquivo | Papel |
|---|---|---|
| `FSM` | `src/fsm.v` | Sequenciador: decide qual é o passo atual do ciclo de instrução |
| `Unit_Control` | `src/unit_control.v` | Decodificador combinacional: gera os sinais de controle de cada passo |

### Estados

Os 8 estados ficam em `src/neander_states.vh`, incluído pelos dois módulos com
`` `include "neander_states.vh" ``. **Fonte única de verdade** — não redeclarar
esses valores dentro dos módulos, senão os dois lados podem discordar da codificação.

| Estado | Código | Passo | Transferência |
|---|---|---|---|
| `FETCH_STEP_1` | `000` | t0 | `REM ← PC` |
| `FETCH_STEP_2` | `001` | t1 | `RDM ← MEM(REM)`, `PC ← PC+1` |
| `FETCH_STEP_3` | `111` | t2 | `RI ← RDM` |
| `DECODE` | `010` | t3 | `REM ← PC` (só nas instruções com operando) |
| `FETCH_OPERAND_STEP_1` | `100` | t4 | `RDM ← MEM(REM)`, `PC ← PC+1` |
| `FETCH_OPERAND_STEP_2` | `011` | t5 | `REM ← RDM` ou `PC ← RDM` (desvios) |
| `EXECUTE_STEP_1` | `101` | t6 | primeiro ciclo de execução |
| `EXECUTE_STEP_2` | `110` | t7 | segundo ciclo de execução |

O `RI ← RDM` precisa de um estado próprio (t2): como o RDM também é um registrador,
carregar RI no mesmo ciclo faria o RI capturar o valor **anterior** do RDM.

### Interface do `Unit_Control`

```verilog
Unit_Control uc (
    .clk(clk), .rst(rst),
    .opcode(ri_out[7:4]),   // 4 bits mais significativos do RI
    .Z(z_flag), .N(n_flag), // flags vindas da ULA

    .carga_rem(...), .sel_rem(...),   // sel_rem: 0 = PC,      1 = RDM
    .carga_rdm(...), .sel_rdm(...),   // sel_rdm: 0 = memória, 1 = AC
    .carga_ri(...), .carga_ac(...), .carga_nz(...),
    .carga_pc(...), .incrementa_pc(...),
    .sel_ula(...),                    // 3 bits, mesma codificação do ula.v
    .read(...), .write(...),
    .goto0(...)                       // não utilizado (constante 0)
);
```

Operações da ULA (conforme `src/ula.v`): `ADD=000`, `AND=001`, `OR=010`, `NOT=011`, `ID=100`.

### Microcódigo por instrução

Todas as instruções compartilham t0–t3. A partir daí:

| Instrução | Opcode | Ciclos | t4 | t5 | t6 | t7 |
|---|---|---|---|---|---|---|
| `NOP` | `0000` | 4 | — | — | — | — |
| `STA` | `0001` | 8 | `RDM ← MEM` | `REM ← RDM` | `RDM ← AC` | `write` |
| `LDA` | `0010` | 8 | `RDM ← MEM` | `REM ← RDM` | `RDM ← MEM` | `AC ← RDM` |
| `ADD` | `0011` | 8 | `RDM ← MEM` | `REM ← RDM` | `RDM ← MEM` | `AC ← AC+RDM` |
| `OR`  | `0100` | 8 | `RDM ← MEM` | `REM ← RDM` | `RDM ← MEM` | `AC ← AC OR RDM` |
| `AND` | `0101` | 8 | `RDM ← MEM` | `REM ← RDM` | `RDM ← MEM` | `AC ← AC AND RDM` |
| `NOT` | `0110` | 5 | — | — | `AC ← NOT(AC)` | — |
| `JMP` | `1000` | 6 | `RDM ← MEM` | `PC ← RDM` | — | — |
| `JZ`  | `1001` | 6 | `RDM ← MEM` | `PC ← RDM` se `Z=1` | — | — |
| `JN`  | `1010` | 6 | `RDM ← MEM` | `PC ← RDM` se `N=1` | — | — |
| `HLT` | `1111` | ∞ | — | — | trava em t6 | — |

Instruções que alteram o AC (`LDA`, `ADD`, `OR`, `AND`, `NOT`) também ativam `carga_nz`.

Nos desvios condicionais, os caminhos "desvia" e "não desvia" gastam os mesmos ciclos:
o operando é lido de qualquer forma, e o `PC ← PC+1` do t4 já deixa o PC no lugar certo
caso o desvio não seja tomado. A condição afeta apenas o sinal `carga_pc` no t5 —
a FSM não consulta `Z`/`N`.

### Requisitos para a integração no datapath

- **A memória precisa ter leitura assíncrona (combinacional).** O `read` e o
  `carga_rdm` são ativados no mesmo ciclo (t1, t4, t6), com o endereço já estável no REM
  desde o ciclo anterior. Se a memória tiver leitura síncrona, o RDM captura lixo e será
  necessário um estado extra por leitura.
- A entrada `din` do PC deve vir do RDM (para o `carga_pc` dos desvios).
- A entrada Y da ULA deve vir do RDM; a entrada X vem do AC.
- O `opcode` vem dos 4 bits mais significativos do RI.

## Autores

- Ana Karolyna Silva Piauí
- Yuri Cirino
- Alfredo Muchanga