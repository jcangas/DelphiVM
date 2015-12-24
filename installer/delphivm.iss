# define VERSION "3.6.2"
[Setup]
AppName=DelphiVM
AppVersion={#VERSION}
DefaultDirName={pf}\DelphiVM
DefaultGroupName=DelphiVM
OutputBaseFilename={# 'DelphiVMInstaller-' + VERSION}

ChangesEnvironment=true
OutputDir=out

[Icons]
Name: "{group}\DelphiVM"; Filename: "{app}\DelphiVM.exe"
Name: "{group}\Uninstall DelphiVM"; Filename: "{uninstallexe}"

[Files]
Source: "installer\dvm.bat"; DestDir: "{app}"; Flags: ignoreversion

[Tasks]
Name: modifypath; Description: &Add application directory to your system path;

[Code]
const
	ModPathName = 'modifypath';
	ModPathType = 'user';

function ModPathDir(): TArrayOfString;
begin
	setArrayLength(Result, 2)
	Result[0] := ExpandConstant('{app}');
end;
#include "installer\modpath.iss"
