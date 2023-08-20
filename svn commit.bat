@echo off
cls
set commit_text=@ %date:~10,4%/%date:~4,2%%date:~6,3% %time%
for /d %%g in (*) do svn commit -m "%commit_text%" %~dp0%%g
for /R %%g in (*.fmx) do del "%%g"
for /R %%g in (*.err) do del "%%g"
pause
prompt $p$g


