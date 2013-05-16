program Sample;

uses
  Vcl.Forms,
  Sample.MainFrm in '..\Sample\Sample.MainFrm.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
