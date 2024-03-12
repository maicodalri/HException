program GerFrota;

uses
  Vcl.Forms,
  fMain in 'fMain.pas' {frmMain},
  EH.Generic in 'EH.Generic.pas',
  MemCheck in 'MemCheck.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
