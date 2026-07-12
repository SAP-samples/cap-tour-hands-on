@echo off
rem Windows cmd equivalent of the Bash `showurls` script.
rem
rem The URLs contain characters (%%, $, parentheses) that native batch parsing
rem mangles, so this delegates to the PowerShell implementation alongside it to
rem guarantee identical, correct output. Pass the exercise number as the only
rem argument, e.g. `utils\showurls 1`.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0showurls.ps1" %*
