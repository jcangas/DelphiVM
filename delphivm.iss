[Setup]
AppName=DelphiVM
AppVersion=0.1
DefaultDirName={pf}\DelphiVM
DefaultGroupName=DelphiVM
OutputBaseFilename=DelphiVMInstaller

[Icons]
Name: "{group}\DelphiVM"; Filename: "{app}\DelphiVM.exe"
Name: "{group}\Uninstall DelphiVM"; Filename: "{uninstallexe}"

[Files]
Source: "Z:\Projects\github\DelphiVM\dvm.bat"; DestDir: "{app}"; Flags: ignoreversion
