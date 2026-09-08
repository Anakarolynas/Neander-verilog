# Processador Neander em Verilog

Projeto de implementação do processador Neander utilizando Verilog HDL.

## Estrutura

- `src/` - módulos do processador
- `tb/` - testbenches, uma subpasta por módulo
- `programas/` - programas em linguagem de máquina para rodar na CPU
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

Cada pasta tem duas versões do script: `.bat` para Windows e `.sh` para
Linux/macOS. As duas fazem exatamente a mesma coisa.

```
tb/
├── simular_tudo.bat          roda todos os testbenches de uma vez
├── simular_tudo.sh
├── cpu/
│   ├── cpu_tb.v              testbench do processador completo
│   ├── cpu_tb.bat
│   └── cpu_tb.sh
├── datapath/
├── fsm/
│   ├── fsm_tb.v
│   ├── fsm_tb.bat
│   └── fsm_tb.sh
├── mux/
├── pc/
├── ula/
└── unit_control/
```

### Rodando

**No Windows**, há três formas equivalentes:

1. **Duplo clique** no `.bat` da pasta do módulo. A janela fica aberta no final
   para você ler o resultado.
2. **Pelo terminal**, de qualquer pasta do projeto:
   ```
   tb\fsm\fsm_tb.bat
   tb\unit_control\unit_control_tb.bat
   ```
3. **Todos de uma vez**, com `tb\simular_tudo.bat`.

Passando o argumento `nopause` (ex.: `tb\fsm\fsm_tb.bat nopause`) o script não
espera você apertar uma tecla no final — útil para encadear comandos.

**No Linux ou macOS**, use os `.sh`:

```
./tb/fsm/fsm_tb.sh
./tb/simular_tudo.sh
```

Os dois `simular_tudo` mostram um resumo no final e retornam código de erro
diferente de zero se algum testbench falhar.

### O que é gerado

Tudo vai para `sim/`, que é recriada automaticamente e **não é versionada**:

| Arquivo | O que é |
|---|---|
| `sim/sim_<módulo>` | Executável da simulação |
| `sim/<módulo>.vcd` | Formas de onda, para abrir no GTKWave |

Para ver as formas de onda:

```
gtkwave sim/cpu.vcd
```

O `$dumpvars` de cada testbench registra a hierarquia inteira, então o `.vcd`
traz também os sinais internos dos módulos instanciados — dá para acompanhar o
estado da FSM, os sinais de controle e o conteúdo dos registradores ciclo a
ciclo. No caso do `cpu.vcd` isso inclui as sete instâncias da CPU, uma por
programa.

### Pré-requisito

O **Icarus Verilog** precisa estar instalado e no PATH. Se não estiver, os
scripts avisam com uma mensagem explicando o que fazer, em vez de falhar com um
erro confuso.

- **Windows**: a pasta `bin` dele no PATH, por exemplo `C:\iverilog\bin`
- **Debian/Ubuntu**: `sudo apt install iverilog gtkwave`
- **Fedora**: `sudo dnf install iverilog gtkwave`
- **macOS**: `brew install icarus-verilog`

### Criando um testbench para um módulo novo

1. Crie a pasta `tb/<módulo>/` e escreva o `tb/<módulo>/<módulo>_tb.v`. Para
   gerar as formas de onda, inclua:
   ```verilog
   initial begin
       $dumpfile("sim/<módulo>.vcd");
       $dumpvars(0, <módulo>_tb);
   end
   ```
2. Copie um `.bat` e um `.sh` existentes para a pasta nova e ajuste apenas as
   duas linhas do topo de cada um:
   ```bat
   set "NOME=<módulo>"
   set "FONTES=src\<módulo>.v"
   ```
   ```bash
   NOME="<módulo>"
   FONTES="src/<módulo>.v"
   ```
   O `FONTES` lista todos os arquivos de `src/` que o testbench precisa. Se o
   módulo instanciar outros, some todos ali — por exemplo, o da unidade de
   controle usa `src/unit_control.v src/fsm.v`, porque a `Unit_Control`
   instancia a `FSM` por dentro.
3. Registre o módulo nos dois scripts que rodam tudo: uma linha
   `call :roda <módulo>` no `tb/simular_tudo.bat`, e o nome na lista
   `TESTBENCHES` do `tb/simular_tudo.sh`.

O resto dos scripts é igual em todos e não precisa ser alterado. Eles já cuidam
de achar a raiz do projeto (funcionam de qualquer pasta), de passar `-I src` para
o `iverilog` — necessário para o `` `include "neander_states.vh" `` ser
encontrado — e de reportar erro de compilação separado de erro de execução.

> **Atenção às quebras de linha ao editar os scripts.** Os `.bat` precisam de
> **CRLF**: com LF o `cmd` do Windows não encontra os rótulos (`:fim`, `:roda`) e
> falha com "não foi possível localizar o rótulo em lote". Os `.sh` precisam de
> **LF**: com CRLF o bash reclama de `$'\r': command not found`. O
> `.gitattributes` do projeto já força os dois casos no clone, mas vale conferir
> se o seu editor não está convertendo.

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

## CPU (`src/cpu.v`)

Módulo de topo do processador. Instancia e liga as três partes:

```
                    ┌──────────────────┐
     opcode (RI)    │                  │   sinais de controle
   ┌───────────────►│  Unit_Control    ├────────────────┐
   │    flags N,Z   │  (FSM + decod.)  │                │
   │  ┌────────────►│                  ├──────┐         │
   │  │             └──────────────────┘      │         │
   │  │                                  read │         │
   │  │                                 write │         ▼
   │  │             ┌──────────────────┐      │  ┌──────────────┐
   │  └─────────────┤                  │      └─►│              │
   └────────────────┤    datapath      │  addr   │     RAM      │
                    │  registradores   ├────────►│  256 x 8     │
                    │  MUXes, ULA      │  dado   │              │
                    │  flags N,Z       ├────────►│              │
                    │                  │◄────────┤              │
                    └──────────────────┘  lido   └──────────────┘
```

- Os sinais de controle vão da `Unit_Control` para o `datapath`.
- `read` e `write` vão da `Unit_Control` direto para a `RAM`.
- O endereço (REM) e o dado a escrever (RDM) saem do `datapath`; o dado lido volta.
- O `opcode` são os 4 bits mais significativos do RI, e as flags N e Z voltam do
  `datapath` para a `Unit_Control`.

### Usando

```verilog
cpu #(.PROGRAMA("programas/integracao.mem")) neander (
    .clk (clk),
    .rst (rst),
    .pc  (pc),   // saídas de observação, para o testbench
    .ac  (ac),   // e para as formas de onda; não fazem parte
    .ri  (ri),   // do funcionamento do processador
    .n   (n),
    .z   (z)
);
```

O `rst` precisa ficar ativo por pelo menos um ciclo completo de clock: os
registradores e o PC têm reset síncrono.

O caminho do programa é relativo à pasta de onde a simulação é executada — por
isso os scripts de simulação rodam a partir da raiz do projeto.

### Programas

Ficam em `programas/`, um valor binário de 8 bits por linha, começando do
endereço 0. O formato está detalhado na seção da memória. Cada arquivo traz no
cabeçalho a listagem comentada, instrução por instrução, e o resultado esperado.

| Programa | O que faz | Resultado |
|---|---|---|
| `soma1.mem` | Soma dois valores: `5 + 3` | `memoria[42] = 8` |
| `soma2.mem` | Soma três parcelas acumulando no AC: `10 + 20 + 7` | `memoria[43] = 37` |
| `logica1.mem` | Máscara de bits com AND: `11110000 AND 00111100` | `memoria[42] = 00110000` |
| `logica2.mem` | OR seguido de NOT: `(11110000 OR 00001111)` invertido | `memoria[42] = 0`, `Z = 1` |
| `condicional1.mem` | Se/senão decidido pela flag N (teste de sinal) | `memoria[43] = 2` |
| `condicional2.mem` | Laço decidido pela flag Z, somando 5 três vezes | `memoria[42] = 15` |
| `integracao.mem` | Caminho completo, com os dois desfechos de um desvio | `AC = 247` |

Os seis primeiros são os programas de demonstração exigidos pelo projeto: duas
somas, duas operações lógicas e duas estruturas condicionais.

Como o Neander não tem subtração, o decremento do contador em `condicional2.mem`
é feito somando `11111111`, que é -1 em complemento de dois.

### Testbench

`tb/cpu/cpu_tb.v` instancia uma CPU para cada programa — cada uma com a sua
própria memória — e as executa em paralelo, conferindo automaticamente o AC, as
posições de memória escritas, as flags e o endereço onde o processador parou.

Para rodar: duplo clique em `tb\cpu\cpu_tb.bat`.

## Unidade de Controle (`src/unit_control.v` + `src/fsm.v`)

A unidade de controle é composta por dois módulos. O `Unit_Control` é o módulo público:
ele instancia a `FSM` internamente, então **o datapath deve instanciar apenas o
`Unit_Control`** — a `FSM` não precisa ser ligada diretamente.

| Módulo | Arquivo | Papel |
|---|---|---|
| `FSM` | `src/fsm.v` | Sequenciador: decide qual é o passo atual do ciclo de instrução |
| `Unit_Control` | `src/unit_control.v` | Decodificador combinacional: gera os sinais de controle de cada passo |

### Estados

O diagrama de estados está em [`docs/fsm-estados.uml`](docs/fsm-estados.uml), em
formato PlantUML. Ele mostra os 8 estados com a codificação, as transferências e os
sinais de controle de cada um, além das condições de transição. Para gerar a imagem:

```
java -jar plantuml.jar -charset UTF-8 -tpng docs/fsm-estados.uml
```

Também dá para colar o conteúdo em qualquer editor PlantUML online.

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
  necessário um estado extra por leitura. A `RAM` de `src/mem.v` já atende a isso.
- A entrada `din` do PC deve vir do RDM (para o `carga_pc` dos desvios).
- A entrada Y da ULA deve vir do RDM; a entrada X vem do AC.
- O `opcode` vem dos 4 bits mais significativos do RI.
- **As flags N e Z precisam ser registradas.** A `ula.v` gera `N` e `Z` de forma
  combinacional, refletindo sempre o resultado atual. A unidade de controle precisa das
  flags *armazenadas*: um `JZ` que vem depois de um `ADD` tem que enxergar o `Z` daquele
  `ADD`, e nesse momento a ULA já está calculando outra coisa. São dois flip-flops
  carregados por `carga_nz` — no diagrama é a caixinha `N Z`, separada da ULA. Já
  implementados no `datapath.v`.

## Memória (`src/mem.v`)

Módulo `RAM`: 256 posições de 8 bits, endereçadas pelo REM.

```verilog
RAM memoria (
    .clk(clk),
    .address(rem_out),        // endereço vindo do REM
    .data_in(rdm_out),        // dado a gravar, vindo do RDM
    .write_enable(write),     // sinais da unidade de controle
    .read_enable(read),
    .data_out(mem_out)        // vai para a entrada 0 do MUX do RDM
);
```

### Leitura assíncrona, escrita síncrona

Esta é a característica mais importante do módulo, e ela **não é opcional**: o
timing de toda a unidade de controle depende dela.

| Operação | Quando acontece |
|---|---|
| Leitura | Combinacional — o dado sai no mesmo ciclo em que o endereço está no REM |
| Escrita | Na borda de subida do clock, quando `write_enable` está ativo |

A unidade de controle ativa `read` e `carga_rdm` **no mesmo ciclo** (t1, t4 e t6). Se a
leitura fosse registrada (`data_out <= memory[address]` dentro de um `always @(posedge
clk)`), o dado só apareceria no ciclo seguinte e o RDM capturaria o valor anterior — o
mesmo problema que motivou a criação do estado `FETCH_STEP_3` para o `RI ← RDM`.

Fora da leitura a saída fica em `8'h00`, e não em alta impedância: ela vai direto para
uma entrada do MUX do RDM, não é um barramento compartilhado, e o `z` se propagaria para
dentro do RDM.

A memória **não é apagada no reset** — isso destruiria o programa carregado. Por isso o
módulo não tem porta `rst`.

### Carregando um programa

O conteúdo inicial vem de um arquivo, informado pelo parâmetro `PROGRAMA`:

```verilog
RAM #(.PROGRAMA("programas/soma.mem")) memoria ( ... );
```

O arquivo tem um valor binário de 8 bits por linha, uma posição de memória por linha,
começando do endereço 0. Exemplo de um programa que soma duas posições e guarda o
resultado:

```
00100000   // LDA
00000100   //   endereco 4
00110000   // ADD
00000101   //   endereco 5
00010000   // STA
00000110   //   endereco 6
11110000   // HLT
```

Comentários usam `//`, como em Verilog. **Não use `;`** — o `$readmemb` não reconhece
esse caractere e passa a ler o arquivo errado a partir dali, silenciosamente.

Sem o parâmetro, a memória começa zerada. Quando o programa tem menos de 256 linhas, o
Icarus imprime `Not enough words in the file` — é esperado, as posições restantes ficam
em zero.

## Autores

- Ana Karolyna Silva Piauí
- Yuri Cirino
- Alfredo Muchanga