@echo off
REM ============================================================
REM  NEANDER - Executa os seis programas de demonstracao
REM
REM  Uso:
REM    - duplo clique neste arquivo, ou
REM    - tb\programas\programas_tb.bat            (de qualquer pasta)
REM    - tb\programas\programas_tb.bat nopause    (sem a pausa no final)
REM
REM  Roda cada programa em uma simulacao separada, para que cada um
REM  gere o seu proprio arquivo de ondas, apenas com a sua CPU. Assim
REM  as formas de onda ficam limpas para analisar e apresentar.
REM
REM  A verificacao completa dos seis programas de uma vez fica em
REM  tb\cpu\cpu_tb.bat.
REM
REM  Gera, para cada programa:
REM    sim\sim_<programa>     executavel da simulacao
REM    sim\<programa>.vcd     formas de onda, para abrir no GTKWave
REM ============================================================

setlocal enabledelayedexpansion

REM Programas de demonstracao. Ao criar um novo, adicione o nome aqui
REM e crie o tb\programas\<nome>_tb.v correspondente.
set "PROGRAMAS=soma1 soma2 logica1 logica2 condicional1 condicional2"

REM Fontes de src\ necessarios para montar a CPU inteira
set "FONTES=src\cpu.v src\datapath.v src\mem.v src\unit_control.v src\fsm.v src\ula.v src\mux.v src\pc.v src\register8.v"

set "PAUSA=1"
if /i "%~1"=="nopause" set "PAUSA=0"

REM Vai para a raiz do projeto (duas pastas acima desta)
set "RAIZ=%~dp0..\.."
pushd "%RAIZ%"
set /a FALHAS=0

where iverilog >nul 2>&1
if errorlevel 1 (
    echo [ERRO] iverilog nao encontrado no PATH.
    echo        Instale o Icarus Verilog e adicione a pasta bin dele ao PATH
    echo        do Windows. Exemplo: C:\iverilog\bin
    set /a FALHAS=1
    goto :fim
)

if not exist "sim" mkdir "sim"

echo ============================================================
echo  Programas de demonstracao
echo ============================================================
echo.

for %%P in (%PROGRAMAS%) do call :roda %%P

echo.
echo ============================================================
if !FALHAS! EQU 0 (
    echo  Os seis programas rodaram. Arquivos de ondas em sim\
) else (
    echo  !FALHAS! programa^(s^) com problema. Veja as mensagens acima.
)
echo ============================================================

:fim
popd
if "%PAUSA%"=="0" exit /b %FALHAS%
REM Pausa apenas quando o script foi aberto com duplo clique
echo %CMDCMDLINE% | find /i "%~nx0" >nul
if not errorlevel 1 pause
exit /b %FALHAS%


REM ------------------------------------------------------------
REM  :roda ^<programa^>
REM ------------------------------------------------------------
:roda
set "NOME=%~1"

REM -I src faz o iverilog encontrar o neander_states.vh dos includes
iverilog -I src -o "sim\sim_%NOME%" "tb\programas\%NOME%_tb.v" %FONTES%
if errorlevel 1 (
    echo [ERRO] Falha ao compilar o testbench de %NOME%
    set /a FALHAS+=1
    exit /b 1
)

vvp "sim\sim_%NOME%"
if errorlevel 1 set /a FALHAS+=1
echo.
exit /b 0
