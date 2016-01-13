@echo off
@echo --- DVM TEST --- 1>&2
set DVMCATALOG=%~dp0imports
ruby %~dp0..\..\bin\delphivm test %*
