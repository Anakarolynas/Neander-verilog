#!/usr/bin/env bash
# ============================================================
#  NEANDER - Roda todos os testbenches do projeto
#
#  Uso:
#    ./tb/simular_tudo.sh        (de qualquer pasta do projeto)
#
#  Versao Linux/macOS do simular_tudo.bat. Chama o script de cada
#  pasta de testbench, em ordem, e mostra um resumo no final.
#  Para rodar um testbench sozinho, use o script da pasta dele
#  (ex.: ./tb/fsm/fsm_tb.sh).
#
#  Ao criar um testbench novo, adicione o nome dele na lista abaixo.
# ============================================================

set -u

TB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TESTBENCHES="mux pc ula fsm unit_control datapath cpu"

falhas=0

for nome in $TESTBENCHES; do

    script="$TB/$nome/${nome}_tb.sh"

    if [ ! -f "$script" ]; then
        echo
        echo "[ERRO] Script nao encontrado: tb/$nome/${nome}_tb.sh"
        falhas=$((falhas + 1))
        continue
    fi

    if ! bash "$script"; then
        falhas=$((falhas + 1))
    fi

done

echo
echo "============================================================"
if [ "$falhas" -eq 0 ]; then
    echo " Todos os testbenches rodaram sem erro."
else
    echo " $falhas testbench(s) com problema. Veja as mensagens acima."
fi
echo "============================================================"

exit "$falhas"
