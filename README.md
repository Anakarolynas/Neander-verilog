# Processador Neander em Verilog

Projeto de implementação do processador Neander utilizando Verilog HDL.

## Estrutura

- `src/` - módulos do processador
- `tb/` - testbenches, uma subpasta por módulo
- `docs/` - documentação e diagramas
- `sim/` - executáveis gerados pelas simulações (não versionado, veja o `.gitignore`)

## Ferramentas

- Verilog
- Icarus Verilog
- GTKWave
- Visual Studio Code

## Como rodar as simulações

Cada módulo tem sua própria pasta dentro de `tb/`, com o testbench e um script
que compila e executa a simulação:

```
tb/
├── simular_tudo.bat          roda todos os testbenches de uma vez
├── fsm/
│   ├── fsm_tb.v
│   └── fsm_tb.bat
├── mux/
│   ├── mux_tb.v
│   └── mux_tb.bat
├── pc/
├── ula/
└── unit_control/
```

### Rodando

Há três formas, todas equivalentes:

1. **Duplo clique** no `.bat` da pasta do módulo. A janela fica aberta no final
   para você ler o resultado.
2. **Pelo terminal**, de qualquer pasta do projeto:
   ```
   tb\fsm\fsm_tb.bat
   tb\unit_control\unit_control_tb.bat
   ```
3. **Todos de uma vez**, com `tb\simular_tudo.bat` (mostra um resumo no final e
   retorna código de erro diferente de zero se algum falhar).

Passando o argumento `nopause` (ex.: `tb\fsm\fsm_tb.bat nopause`) o script não
espera você apertar uma tecla no final — útil para encadear comandos.

Os executáveis gerados vão para `sim\sim_<módulo>`. Essa pasta é recriada
automaticamente e **não é versionada**: são arquivos binários gerados, que só
causariam conflito no Git.

### Pré-requisito

O **Icarus Verilog** precisa estar instalado e no PATH do Windows (a pasta `bin`
dele, por exemplo `C:\iverilog\bin`). Se não estiver, os scripts avisam com uma
mensagem explicando o que fazer, em vez de falhar com um erro confuso.

### Criando um testbench para um módulo novo

1. Crie a pasta `tb/<módulo>/` e escreva o `tb/<módulo>/<módulo>_tb.v`.
2. Copie qualquer `.bat` existente para `tb/<módulo>/<módulo>_tb.bat` e ajuste
   apenas as duas linhas do topo:
   ```bat
   set "NOME=<módulo>"
   set "FONTES=src\<módulo>.v"
   ```
   O `FONTES` lista todos os arquivos de `src/` que o testbench precisa. Se o
   módulo instanciar outros, some todos ali — por exemplo, o da unidade de
   controle usa `src\unit_control.v src\fsm.v`, porque a `Unit_Control`
   instancia a `FSM` por dentro.
3. Adicione uma linha `call :roda <módulo>` no `tb/simular_tudo.bat`.

O resto do script é igual em todos e não precisa ser alterado. Ele já cuida de
achar a raiz do projeto (funciona de qualquer pasta), de passar `-I src` para o
`iverilog` — necessário para o `` `include "neander_states.vh" `` ser encontrado —
e de reportar erro de compilação separado de erro de execução.

> **Atenção ao editar os `.bat`:** eles precisam ser salvos com quebra de linha
> **CRLF**. Com LF o `cmd` do Windows não encontra os rótulos (`:fim`, `:roda`) e
> o script falha com "não foi possível localizar o rótulo em lote". O
> `.gitattributes` do projeto já força isso no clone, mas vale conferir se o seu
> editor não estiver convertendo.

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