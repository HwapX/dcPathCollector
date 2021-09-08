program PathCollector;

{$MODE Delphi}

uses
  Forms, Interfaces,
  uMain in 'uMain.pas' {frmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
