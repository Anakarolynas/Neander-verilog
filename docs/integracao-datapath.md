# Integração do Datapath — o que falta ajustar

> **Status: resolvido.** Os quatro itens deste documento foram implementados, e o
> `src/cpu.v` amarrando datapath, memória e unidade de controle já existe. O
> processador executa programas de ponta a ponta, com os desvios condicionais
> funcionando — veja `tb/cpu/cpu_tb.v`.
>
> O documento continua aqui como registro do que foi encontrado e por quê. As
> mudanças no `datapath.v` estão descritas em cada item.

Testei o `datapath.v` ligado à unidade de controle e à memória, rodando programas
reais em Neander. Este documento resume o que já funciona e o que ainda precisa
ser ajustado.

**Resumo em uma linha:** o datapath está fundamentalmente certo — falta uma peça
para o processador rodar (o registrador das flags N e Z), e três alinhamentos com
o diagrama.

---

## Como foi testado

Montei um CPU completo num arquivo temporário, ligando `datapath` + `RAM` +
`Unit_Control`, e executei programas de verdade carregados na memória. Os
resultados abaixo vêm dessas simulações, não só de leitura de código.

---

## ✅ O que já funciona

Rodei este programa:

```
LDA 20 (=5) ; ADD 21 (=3) ; STA 22 ; JMP 10 ; NOT ; HLT
```

Resultado:

```
AC final    = 247      (NOT de 8)
memoria[22] = 8        (5+3 gravado corretamente)
PC final    = 12       (parou no HLT certo)
```

**`LDA`, `ADD`, `STA`, `JMP`, `NOT` e `HLT` funcionam.** Os caminhos de dados, a
ULA, o PC, o REM e o RI estão todos corretos.

---

## 🔴 1. Falta o registrador das flags N e Z

Este é o único problema que **impede o processador de funcionar**.

### O sintoma

```
LDA 6      // mem[6] = 0, então AC = 0 e Z deveria ficar em 1
JZ  10     // se Z, desvia para 10
HLT        // (endereço 4) não deveria ser alcançado
...
HLT        // (endereço 10) destino do desvio
```

```
AC final  = 0          <- o LDA funcionou
PC final  = 5
RESULTADO: NAO desviou (parou no HLT do endereço 4)
```

### A causa

No `datapath.v`, o `N` e o `Z` saem **direto da ULA**:

```verilog
ula ula_inst (
    ...
    .N (N),      // vai direto para a saída do datapath
    .Z (Z)
);
```

A ULA é combinacional: o `N` e o `Z` refletem sempre a operação que ela está
calculando **naquele instante**. Mas a unidade de controle precisa das flags
**guardadas** da última operação: um `JZ` que vem depois de um `ADD` tem que
enxergar o `Z` daquele `ADD`.

No ciclo em que o `JZ` avalia a condição (t5), o `sel_ula` está no valor padrão
(ADD) e a ULA está somando outra coisa — então o `Z` que chega à UC não tem
relação nenhuma com o `LDA` anterior.

No diagrama do professor isso aparece como a caixinha `N Z` **separada** da ULA,
com o sinal `cargaNZ` entrando nela.

### A correção

O sinal `carga_nz` já existe e já é gerado corretamente pela unidade de controle —
hoje ele simplesmente não está ligado em nada. Bastam dois flip-flops:

```verilog
// Flags N e Z registradas
reg n_flag, z_flag;

always @(posedge clk) begin
    if (rst) begin
        n_flag <= 1'b0;
        z_flag <= 1'b0;
    end
    else if (carga_nz) begin
        n_flag <= n_ula;   // vindo da ULA
        z_flag <= z_ula;
    end
end

assign N = n_flag;   // saídas do datapath para a unidade de controle
assign Z = z_flag;
```

Isso exige adicionar `carga_nz` à lista de portas do `datapath`, e renomear os
fios que hoje vêm da ULA (para não colidir com as saídas `N` e `Z`).

**Testei exatamente essa correção**, sem alterar o `datapath.v`: o `JZ` passou a
desviar corretamente (`PC final = 11`).

---

## 🟡 2. Falta o MUX do RDM

Hoje o RDM está ligado direto na memória:

```verilog
register8 rdm_inst (
    .din (mem_din),   // só a memória
    ...
);
```

Pelo diagrama, o RDM tem um MUX na entrada, escolhendo entre a memória e o AC:

- `sel_rdm = 0` → dado vindo da memória (leitura)
- `sel_rdm = 1` → dado vindo do AC (usado pelo `STA`)

Sem esse MUX, o passo `RDM ← AC` do `STA` não existe, e o sinal `sel_rdm` da
unidade de controle fica sem onde ser ligado.

```verilog
mux mux_rdm (
    .data_a (mem_din),   // sel_rdm = 0 -> memória
    .data_b (ac_out),    // sel_rdm = 1 -> AC
    .sel    (sel_rdm),
    .dout   (rdm_din)
);
```

---

## 🟡 3. O dado enviado à memória deveria vir do RDM

```verilog
assign mem_dout = ac_out;   // hoje
```

É por isso que o `STA` funciona apesar do item 2 — o valor chega à memória por um
atalho, direto do AC. Funciona, mas diverge da tabela de transferências, onde o
`STA` faz `RDM ← AC` (t6) e só depois `MEM ← RDM` (t7).

Junto com o item 2, viraria:

```verilog
assign mem_dout = rdm_out;
```

---

## 🟡 4. O MUX do AC está sobrando

O `mux_ac`, com o sinal `ac_sel`, não corresponde a nenhum sinal da unidade de
controle. No projeto da UC o AC carrega **sempre** da ULA — o `LDA` usa a operação
ID da ULA (`sel_ula = 100`, que devolve o Y = RDM) para passar o valor adiante.

Nos meus testes amarrei `ac_sel = 1'b0` e tudo funcionou. O MUX pode ser removido,
com o `ac_inst.din` ligado direto em `ula_resultado`.

---

## Mapeamento dos sinais

Os nomes divergem entre os dois módulos. Não é problema — o `cpu.v` faz a ponte —
mas vale conferir na hora de ligar:

| Unidade de Controle | Datapath | Situação |
|---|---|---|
| `carga_pc`, `incrementa_pc` | `pc_carga`, `pc_inc` | só renomear |
| `carga_rem`, `sel_rem` | `rem_carga`, `rem_sel` | só renomear |
| `carga_rdm` | `rdm_carga` | só renomear |
| `carga_ri`, `carga_ac` | `ri_carga`, `ac_carga` | só renomear |
| `sel_ula` | `op_ula` | só renomear |
| `sel_rdm` | — | **falta** (item 2) |
| `carga_nz` | — | **falta** (item 1) |
| `read`, `write` | — | vão direto na RAM |
| `goto0` | — | não usado, pode ficar solto |
| — | `ac_sel` | **sobrando** (item 4) |

---

## Outros pontos

### Falta o `cpu.v`

Ainda não existe o módulo que junta `datapath` + `RAM` + `Unit_Control`. É a peça
que falta para o processador existir como unidade — o README já prevê "CPU" na
arquitetura.

### O testbench do datapath não se autoverifica

O `datapath_tb.v` tem 84 `$display` e nenhuma comparação automática: ele imprime
`Esperado: AC = 30` como texto, mas nada confere se o valor bateu. Conferi
manualmente e **os 10 testes estão corretos** — mas se alguém quebrar algo depois,
a simulação vai continuar "passando".

Os testbenches da FSM e da unidade de controle (`tb/fsm/`, `tb/unit_control/`)
contam os erros e imprimem um resultado final; dá para seguir o mesmo formato:

```verilog
if (ac_out !== 8'd30) begin
    erros = erros + 1;
    $display("ERRO: AC = %0d, esperado 30", ac_out);
end
```

Um detalhe: o teste 5 (`RDM → AC`) usa `ac_sel = 1`, exercitando justamente o
caminho do MUX que a unidade de controle nunca aciona (item 4).

### O testbench mudou de lugar

O `datapath_tb.v` foi movido de `src/` para **`tb/datapath/`**, seguindo a
organização do README (uma subpasta por módulo). Já tem um `datapath_tb.bat` lá
para rodar a simulação, e ele foi incluído no `tb/simular_tudo.bat`.

Para rodar: duplo clique em `tb\datapath\datapath_tb.bat`, ou
`tb\simular_tudo.bat` para rodar todos.

---

## Ordem sugerida

1. **Registrador das flags N/Z** — sem isso `JZ` e `JN` não funcionam (item 1)
2. MUX do RDM e `mem_dout = rdm_out` (itens 2 e 3, são o mesmo assunto)
3. Remover o `mux_ac` (item 4)
4. Escrever o `cpu.v` amarrando tudo

Depois do passo 1 o processador já roda programas com desvios condicionais.

---

## O que foi implementado

Os quatro passos acima foram aplicados. Resumo das mudanças:

### `src/datapath.v`

| Mudança | Item |
|---|---|
| Nova porta `nz_carga` e registrador das flags N e Z | 1 |
| Nova porta `rdm_sel` e `mux_rdm` na entrada do RDM | 2 |
| `mem_dout` passou a vir do `rdm_out` | 3 |
| `mux_ac` e a porta `ac_sel` removidos; o AC recebe direto da ULA | 4 |

A nomenclatura seguiu o padrão do módulo (`<bloco>_<sinal>`), por isso `rdm_sel` e
`nz_carga`, e não `sel_rdm`/`carga_nz` como na unidade de controle. A ligação entre
os dois nomes é feita no `cpu.v`.

### `src/cpu.v` (novo)

Módulo de topo, instanciando `datapath` + `RAM` + `Unit_Control` e fazendo a ponte
entre os nomes de sinais dos dois lados. Tem um parâmetro `PROGRAMA` para carregar
o programa na memória e saídas de observação (`pc`, `ac`, `ri`, `n`, `z`) para o
testbench e para as formas de onda.

### `tb/datapath/datapath_tb.v`

Ajustado para a nova interface. Os 10 testes continuam passando:

- O teste 5 (`RDM → AC`) agora usa a operação ID da ULA, em vez do `mux_ac`.
- O teste 9 (`AC → memória`) faz `RDM ← AC` antes, já que o dado escrito sai do RDM.
- O teste 10 (flags) carrega `nz_carga`, já que as flags agora são registradas.

### `tb/cpu/cpu_tb.v` e `programas/` (novos)

Testbench da CPU instanciando uma CPU por programa, cada uma com a sua própria
memória, executando todas em paralelo. Confere automaticamente o AC, a memória, as
flags e onde cada processador parou.

Os seis programas de demonstração exigidos pelo projeto estão em `programas/`:
`soma1`, `soma2`, `logica1`, `logica2`, `condicional1` e `condicional2`, mais o
`integracao` usado para validar a ligação entre os módulos.

## O que ainda falta para a entrega

- **Diagrama da arquitetura e da FSM**, com a descrição dos estados e os sinais de
  controle associados a cada um. A descrição textual já está no README; falta o
  desenho.
