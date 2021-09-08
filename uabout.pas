unit uAbout;

{$mode delphi}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Menus;

type

  { TfrmAbout }

  TfrmAbout = class(TForm)
    Label1: TLabel;
    Label10: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    btnOpen: TMenuItem;
    btnCopyUrl: TMenuItem;
    pnlDrop: TPanel;
    pmUrl: TPopupMenu;
    pnlDrop1: TPanel;
    procedure btnCopyUrlClick(Sender: TObject);
    procedure LabelMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnOpenClick(Sender: TObject);
  private
    fPopupUrl: string;
  public

  end;

implementation

uses
  Windows, Clipbrd;

{$R *.lfm}

{ TfrmAbout }

procedure TfrmAbout.btnOpenClick(Sender: TObject);
begin
  ShellExecute(0, 'open', PChar(TLabel(Sender).Hint), '', '', SW_SHOWDEFAULT);
end;

procedure TfrmAbout.LabelMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Lbl: TLabel;
  P: TPoint;
begin
  if Button <> mbRight then
    Exit;

  Lbl:= TLabel(Sender);
  fPopupUrl:= Lbl.Hint;
  P:= Lbl.ClientToScreen(Classes.Point(X, Y));
  pmUrl.PopUp(P.X, P.Y);
end;

procedure TfrmAbout.btnCopyUrlClick(Sender: TObject);
begin
  Clipboard.AsText:= fPopupUrl;
end;

end.

