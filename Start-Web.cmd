@echo off
title CratAble Web Preview
set "CRATABLE_PYTHON="
for /d %%D in ("%ProgramFiles%\WindowsApps\OpenAI.CodexPrimaryRuntime*") do if exist "%%D\dependencies\python\python.exe" set "CRATABLE_PYTHON=%%D\dependencies\python\python.exe"
if defined CRATABLE_PYTHON (
  "%CRATABLE_PYTHON%" "%~dp0tools\serve_web.py"
) else (
  py -3 "%~dp0tools\serve_web.py"
)
pause
