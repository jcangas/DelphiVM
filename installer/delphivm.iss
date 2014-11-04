# define VERSION "3.1.1"
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
Source: "installer\gem.build_complete"; DestDir: "{app}\lib\ruby\gems\2.1.0\extensions\x86-mingw32\2.1.0\psych-2.0.6"; Flags: ignoreversion

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
#include "installer\modpath.iss"
