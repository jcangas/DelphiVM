program <%=name%>;

uses
  Vcl.Forms,
  <%=name%>.MainFrm in '..\<%=name%>\<%=name%>.MainFrm.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
