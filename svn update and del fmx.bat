@echo off
cls
for /d %%g in (*) do svn update %~dp0%%g
for /R %%g in (*.fmx) do del "%%g"
for /R %%g in (*.err) do del "%%g"
pause
prompt $p$g
