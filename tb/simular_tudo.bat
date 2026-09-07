@echo off
REM ============================================================
REM  NEANDER - Roda todos os testbenches do projeto
REM
REM  Uso:
REM    - duplo clique neste arquivo, ou
REM    - tb\simular_tudo.bat
REM
REM  Chama o script de cada pasta de testbench, em ordem, e mostra
REM  um resumo no final. Para rodar um testbench sozinho, use o
REM  script da pasta dele (ex.: tb\fsm\fsm_tb.bat).
REM
REM  Ao criar um testbench novo, adicione uma linha "call :roda"
REM  aqui embaixo.
REM ============================================================

setlocal enabledelayedexpansion

set "TB=%~dp0"
set /a FALHAS=0

call :roda mux
call :roda pc
call :roda ula
call :roda fsm
call :roda unit_control
call :roda datapath
call :roda cpu

echo.
echo ============================================================
if !FALHAS! EQU 0 (
    echo  Todos os testbenches rodaram sem erro.
) else (
    echo  !FALHAS! testbench^(s^) com problema. Veja as mensagens acima.
)
echo ============================================================

REM Pausa apenas quando o script foi aberto com duplo clique
echo %CMDCMDLINE% | find /i "%~nx0" >nul
if not errorlevel 1 pause
exit /b !FALHAS!


:roda
set "NOME=%~1"
if not exist "%TB%%NOME%\%NOME%_tb.bat" (
    echo.
    echo [ERRO] Script nao encontrado: tb\%NOME%\%NOME%_tb.bat
    set /a FALHAS+=1
    exit /b 1
)
call "%TB%%NOME%\%NOME%_tb.bat" nopause
if errorlevel 1 set /a FALHAS+=1
exit /b 0
