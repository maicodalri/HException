unit fMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Mask, Vcl.ExtCtrls,
  Vcl.DBCtrls, Data.DB, Vcl.Imaging.jpeg, Vcl.Samples.Calendar, Vcl.Grids,
  Vcl.DBGrids, Vcl.AppEvnts;

type
  TfrmMain = class(TForm)
    btnGerar: TButton;
    Edit1: TEdit;
    DBEdit1: TDBEdit;
    DBGrid1: TDBGrid;
    Calendar1: TCalendar;
    Image1: TImage;
    procedure btnGerarClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.btnGerarClick(Sender: TObject);
begin
  raise Exception.Create('Error Message');
end;

end.
