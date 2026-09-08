#!/usr/bin/env bash
# ============================================================
#  NEANDER - Executa os seis programas de demonstracao
#
#  Uso:
#    ./tb/programas/programas_tb.sh        (de qualquer pasta do projeto)
#
#  Versao Linux/macOS do programas_tb.bat. Roda cada programa em uma
#  simulacao separada, para que cada um gere o seu proprio arquivo de
#  ondas, apenas com a sua CPU. Assim as formas de onda ficam limpas
#  para analisar e apresentar.
#
#  A verificacao completa dos seis programas de uma vez fica em
#  ./tb/cpu/cpu_tb.sh.
#
#  Gera, para cada programa:
#    sim/sim_<programa>     executavel da simulacao
#    sim/<programa>.vcd     formas de onda, para abrir no GTKWave
# ============================================================

set -u

# Programas de demonstracao. Ao criar um novo, adicione o nome aqui
# e crie o tb/programas/<nome>_tb.v correspondente.
PROGRAMAS="soma1 soma2 logica1 logica2 condicional1 condicional2"

# Fontes de src/ necessarios para montar a CPU inteira
FONTES="src/cpu.v src/datapath.v src/mem.v src/unit_control.v src/fsm.v src/ula.v src/mux.v src/pc.v src/register8.v"

# Vai para a raiz do projeto (duas pastas acima desta)
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$RAIZ" || exit 1

if ! command -v iverilog > /dev/null 2>&1; then
    echo "[ERRO] iverilog nao encontrado no PATH."
    echo "       Debian/Ubuntu:  sudo apt install iverilog gtkwave"
    echo "       Fedora:         sudo dnf install iverilog gtkwave"
    echo "       macOS:          brew install icarus-verilog"
    exit 1
fi

mkdir -p sim

echo "============================================================"
echo " Programas de demonstracao"
echo "============================================================"
echo

falhas=0

for nome in $PROGRAMAS; do

    # -I src faz o iverilog encontrar o neander_states.vh dos includes
    if ! iverilog -I src -o "sim/sim_$nome" "tb/programas/${nome}_tb.v" $FONTES; then
        echo "[ERRO] Falha ao compilar o testbench de $nome"
        falhas=$((falhas + 1))
        continue
    fi

    if ! vvp "sim/sim_$nome"; then
        falhas=$((falhas + 1))
    fi

    echo

done

echo "============================================================"
if [ "$falhas" -eq 0 ]; then
    echo " Os seis programas rodaram. Arquivos de ondas em sim/"
else
    echo " $falhas programa(s) com problema. Veja as mensagens acima."
fi
echo "============================================================"

exit "$falhas"
