program EscalaGeraSys;

uses
  MidasLib,
  Vcl.Forms,
  UMain in 'UMain.pas' {frmMain},
  UDados in 'UDados.pas' {dmDados: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'EscalaGeraSys - Lan�amento de Carga Hor�ria (Portable)';
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TdmDados, dmDados);
  Application.Run;
end.
