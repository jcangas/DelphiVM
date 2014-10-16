[Setup]
AppName=DelphiVM
AppVersion=0.1
DefaultDirName={pf}\DelphiVM
DefaultGroupName=DelphiVM
OutputBaseFilename=DelphiVMInstaller
ChangesEnvironment=true

[Icons]
Name: "{group}\DelphiVM"; Filename: "{app}\DelphiVM.exe"
Name: "{group}\Uninstall DelphiVM"; Filename: "{uninstallexe}"

[Files]
Source: "Z:\Projects\github\DelphiVM\dvm.bat"; DestDir: "{app}"; Flags: ignoreversion

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
	Result[1] := ExpandConstant('{app}\bin');
end;
#include "modpath.iss"
