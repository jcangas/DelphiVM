@echo off

setlocal

SET DVM_PRJDIR=%CD%
if exist %DVM_PRJDIR%\dvmsetup.bat (
   call %DVM_PRJDIR%\dvmsetup.bat
) 
DelphiVM.exe %*
