@echo off
@echo --- DVM TEST ---
set DVMCATALOG=%~dp0imports
ruby ..\..\bin\delphivm test %*
