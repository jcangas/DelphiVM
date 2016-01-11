@echo off
@echo --- DVM TEST ---
set DVMCATALOG=%~dp0imports
ruby %~dp0..\..\bin\delphivm test %*
