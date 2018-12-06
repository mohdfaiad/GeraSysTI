unit USourceDBLayoutFB;

interface

uses
  UConexaoTargetDB,
  System.StrUtils,

  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, UPadraoSDI, Vcl.StdCtrls, Vcl.ExtCtrls, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.FB, FireDAC.Phys.FBDef,
  FireDAC.VCLUI.Wait, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt, Data.DB,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, FireDAC.Comp.UI, Vcl.Mask, JvExMask, JvToolEdit, Vcl.ComCtrls,
  Vcl.Menus, cxGraphics, cxLookAndFeels, cxLookAndFeelPainters, dxSkinsCore, dxSkinOffice2007Green,
  dxSkinOffice2010Blue, dxSkinOffice2016Colorful, dxSkinOffice2016Dark, cxButtons;

type
  TfrmSourceDBLayoutFB = class(TfrmPadraoSDI)
    lblSourceDB: TLabel;
    edSourceDB: TJvFilenameEdit;
    lblUsuario: TLabel;
    edUsuario: TEdit;
    edSenha: TEdit;
    lblSenha: TLabel;
    btnConectar: TButton;
    fdSourceDB: TFDConnection;
    fdTransSourceDB: TFDTransaction;
    fdGUIxWaitCursorSourceDB: TFDGUIxWaitCursor;
    qrySourceDB: TFDQuery;
    qrySourceDBDetails: TFDQuery;
    lblCompetencia: TLabel;
    cmCompetencia: TComboBox;
    chkTabelaCBO: TCheckBox;
    btnVisualizar: TButton;
    lblAndamento: TLabel;
    chkTodos: TCheckBox;
    prbAndamento: TProgressBar;
    chkTabelaEscolaridade: TCheckBox;
    chkTabelaCargoFuncao: TCheckBox;
    chkTabelaUnidadeGestora: TCheckBox;
    chkTabelaUnidadeOrcament: TCheckBox;
    chkTabelaUnidadeLotacao: TCheckBox;
    chkTabelaEstadoFuncional: TCheckBox;
    chkTabelaSituacao: TCheckBox;
    chkTabelaSetor: TCheckBox;
    chkTabelaEvento: TCheckBox;
    popParametrizacoes: TPopupMenu;
    BtnParametrizar: TcxButton;
    mniEvento: TMenuItem;
    mniEstadoFuncional: TMenuItem;
    chkTabelaBanco: TCheckBox;
    chkTabelaPFServidor: TCheckBox;
    procedure chkTodosClick(Sender: TObject);
    procedure btnConectarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure fdSourceDBAfterConnect(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnVisualizarClick(Sender: TObject);
    procedure chkTabelaCargoFuncaoClick(Sender: TObject);
    procedure mniEventoClick(Sender: TObject);
    procedure mniEstadoFuncionalClick(Sender: TObject);
  private
    { Private declarations }
    FBaseID : String;
    FCampoEventoRemunID ,
    FCampoEstadoFuncionalRemunID : String;

    procedure CriarTabelaDB;
    procedure GravarIni;
    procedure ListarCompetenciasLayoutFB;
    procedure CriarCampoEvento_Layout;
    procedure CriarCampoEstadoFuncional_Layout;
    procedure GerarUnidadeOrcamentariaPadrao(aUnidadeGestora : TUnidadeGestora);

    function ConectarSourceDB : Boolean;
    function RegistrarTabelaDB(aFileNameDB : String) : String;

    procedure ImportarCBO(Sender: TObject); virtual; abstract;
    procedure ImportarEscolaridade(Sender: TObject); virtual; abstract;
    procedure ImportarCargoFuncao(Sender: TObject);
    procedure ImportarUnidadeGestora(Sender: TObject);
    procedure ImportarUnidadeOrcamentaria(Sender: TObject);
    procedure ImportarUnidadeLotacao(Sender: TObject);
    procedure ImportarEstadoFuncional(Sender: TObject);
    procedure ImportarSituacao(Sender: TObject);
    procedure ImportarSetor(Sender: TObject); virtual; abstract;
    procedure ImportarEventos(Sender: TObject);
    procedure ImportarEntidadeFinanceira(Sender: TObject);
    procedure ImportarPessoaFisica(Sender: TObject);
  public
    { Public declarations }
    function ConfirmarProcesso : Boolean; override;
  end;

var
  frmSourceDBLayoutFB: TfrmSourceDBLayoutFB;

implementation

{$R *.dfm}

uses
  URecursos,
  USourceDBLayoutFBTabelas,
  USourceDBLayoutFBEvento,
  USourceDBLayoutFBEstadoFuncional;

{ TfrmSourceDBLayoutFB }

procedure TfrmSourceDBLayoutFB.btnConectarClick(Sender: TObject);
begin
  GravarIni;
  if ConectarSourceDB then
    MensagemInforme('Conex�o', 'Conex�o realizada com sucesso.');
end;

procedure TfrmSourceDBLayoutFB.btnVisualizarClick(Sender: TObject);
begin
  GravarIni;

  if not fdSourceDB.Connected then
    ConectarSourceDB;

  ShowTabelasFireBird(Self);
end;

procedure TfrmSourceDBLayoutFB.chkTabelaCargoFuncaoClick(Sender: TObject);
begin
//  if chkTabelaCargoFuncao.Checked then
//  begin
//    chkTabelaCBO.Checked          := True;
//    chkTabelaEscolaridade.Checked := True;
//  end;
end;

procedure TfrmSourceDBLayoutFB.chkTodosClick(Sender: TObject);
begin
  if chkTodos.Checked then
    chkMarcarTodos(Sender)
  else
    chkDesmarcarTodos(Sender)
end;

function TfrmSourceDBLayoutFB.ConectarSourceDB: Boolean;
begin
  try
    try
      with fdSourceDB do
      begin
        Connected := False;

        Params.Clear;
        Params.Add('DriverID=FB');
        Params.Add('Protocol=TCPIP');
        Params.Add('Server='    + gConfiguracao.ReadString('SourceDBLayoutFB', 'Server', 'localhost'));
        Params.Add('Port='      + gConfiguracao.ReadString('SourceDBLayoutFB', 'Port', '3050'));
        Params.Add('Database='  + gConfiguracao.ReadString('SourceDBLayoutFB', 'FileName', edSourceDB.Text));
        Params.Add('User_Name=' + gConfiguracao.ReadString('SourceDBLayoutFB', 'UserName', edUsuario.Text));
        Params.Add('Password='  + gConfiguracao.ReadString('SourceDBLayoutFB', 'Password', edSenha.Text));
        Params.Add('CharacterSet=WIN1252'); // WIN_PTBR

        Connected := True;
      end;
    except
      On E : Exception do
        MensagemErro('Erro', 'Erro ao tentar conectar com a base de origem dos dados.' + #13#13 + E.Message);
    end;
  finally
    Result := fdSourceDB.Connected;
  end;
end;

function TfrmSourceDBLayoutFB.ConfirmarProcesso: Boolean;
var
  aRetorno : Boolean;
begin
  aRetorno := False;
  try
    if MensagemConfirmar('Confirmar',
      'O processo de importa��o dos dados selecionados levar� alguns minutos.' + #13#13 +
      'Confirma o in�cio do processo?') then
    begin
      btnConectar.Enabled   := False;
      btnVisualizar.Enabled := False;
      btnConfirmar.Enabled  := False;
      btnCancelar.Enabled   := False;

      GravarIni;

      if dmConexaoTargetDB.ConectarTargetDB and ConectarSourceDB then
      begin
        if chkTabelaCBO.Checked             then ImportarCBO(chkTabelaCBO);
        if chkTabelaEscolaridade.Checked    then ImportarEscolaridade(chkTabelaEscolaridade);
        if chkTabelaCargoFuncao.Checked     then ImportarCargoFuncao(chkTabelaCargoFuncao);
        if chkTabelaUnidadeGestora.Checked  then ImportarUnidadeGestora(chkTabelaUnidadeGestora);
        if chkTabelaUnidadeOrcament.Checked then ImportarUnidadeOrcamentaria(chkTabelaUnidadeOrcament);
        if chkTabelaUnidadeLotacao.Checked  then ImportarUnidadeLotacao(chkTabelaUnidadeLotacao);
        if chkTabelaEstadoFuncional.Checked then ImportarEstadoFuncional(chkTabelaEstadoFuncional);
        if chkTabelaSituacao.Checked        then ImportarSituacao(chkTabelaSituacao);
        if chkTabelaSetor.Checked           then ImportarSetor(chkTabelaSetor);
        if chkTabelaEvento.Checked          then ImportarEventos(chkTabelaEvento);
        if chkTabelaBanco.Checked           then ImportarEntidadeFinanceira(chkTabelaBanco);
        if chkTabelaPFServidor.Checked      then ImportarPessoaFisica(chkTabelaPFServidor);
//        if chkTabelaDependente.Checked      then ImportarDependente(chkTabelaDependente);
//        if chkTabelaEventoFixo.Checked      then ImportarEventoFixoServidor(chkTabelaDependente);
//        if chkTabelaProgramacaoFerias.Checked then ImportarProgramacaoFeriais(chkTabelaProgramacaoFerias);
//        if chkLancamentoMesServidor.Checked   then ImportarFolhaMensalServidor(chkLancamentoMesServidor);

        aRetorno := True;
      end;
    end;
  finally
    if aRetorno then
      MensagemInforme('Importa��o', 'Importa��o de dados realizada com sucesso.');

    dmRecursos.ExibriLog;

    btnConectar.Enabled   := True;
    btnVisualizar.Enabled := True;
    btnConfirmar.Enabled  := True;
    btnCancelar.Enabled   := True;

    Result := aRetorno;
  end;
end;

procedure TfrmSourceDBLayoutFB.CriarCampoEstadoFuncional_Layout;
begin
  try
    fdSourceDB.ExecSQL('ALTER TABLE AFASTFOLHA ADD ' + FCampoEstadoFuncionalRemunID + ' INTEGER', True);
    fdSourceDB.CommitRetaining;
  except
  end;
end;

procedure TfrmSourceDBLayoutFB.CriarCampoEvento_Layout;
var
  I : Integer;
const
  MESES : Array[0..11] of String = ('JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV', 'DEZ');
begin
  for I := Low(MESES) to High(MESES) do
    try
      fdSourceDB.ExecSQL('ALTER TABLE SFP010' + MESES[I] + ' ADD ' + FCampoEventoRemunID + ' INTEGER', True);
      fdSourceDB.CommitRetaining;
    except
    end;
end;

procedure TfrmSourceDBLayoutFB.CriarTabelaDB;
var
  aSQL : TStringList;
begin
  aSQL := TStringList.Create;
  try
    if not dmConexaoTargetDB.fdTargetDB.Connected then
      dmConexaoTargetDB.ConectarTargetDB;

    aSQL.BeginUpdate;
    aSQL.Clear;
    aSQL.Add('CREATE TABLE ' + TBL_LAYOUT_IMPORT + ' (');
    aSQL.Add('    LAYOUT_ID "CHAR(2)"      NOT NULL');
    aSQL.Add('  , LAYOUT_DB "VARCHAR(240)" NOT NULL');
    aSQL.Add(')');
    aSQL.EndUpdate;

    dmConexaoTargetDB.CriarTabela('TMP_LAYOUT_IMPORT', 'LAYOUT_ID', aSQL);
  finally
    aSQL.Free;
  end;
end;

procedure TfrmSourceDBLayoutFB.fdSourceDBAfterConnect(Sender: TObject);
begin
  ListarCompetenciasLayoutFB;
  CriarTabelaDB;
  FBaseID := Trim(RegistrarTabelaDB(edSourceDB.Text));
end;

procedure TfrmSourceDBLayoutFB.FormCreate(Sender: TObject);
begin
  inherited;
  fdSourceDB.Connected := False;

  FBaseID := EmptyStr;
  FCampoEventoRemunID          := 'evento_remun_id';
  FCampoEstadoFuncionalRemunID := 'estado_funcional_remun_id';

  if not Assigned(gLogImportacao) then
    gLogImportacao := TStringList.Create;

  gLogImportacao.Clear;

  edSourceDB.Text       := gConfiguracao.ReadString('SourceDBLayoutFB', 'FileName',  EmptyStr);
  edSourceDB.InitialDir := gConfiguracao.ReadString('SourceDBLayoutFB', 'Directory', EmptyStr);
  edUsuario.Text        := gConfiguracao.ReadString('SourceDBLayoutFB', 'UserName',  edUsuario.Text);
  edSenha.Text          := gConfiguracao.ReadString('SourceDBLayoutFB', 'Password',  edSenha.Text);
  if Trim(edSourceDB.InitialDir) = EmptyStr then
  begin
    edSourceDB.InitialDir := ExtractFilePath(ParamStr(0)) + 'db\';
    if not DirectoryExists(edSourceDB.InitialDir) then
      ForceDirectories(edSourceDB.InitialDir);
  end;

  dmRecursos.ListarCompetencia(cmCompetencia, 1);
end;

procedure TfrmSourceDBLayoutFB.FormShow(Sender: TObject);
begin
  inherited;
  ConectarSourceDB;
end;

procedure TfrmSourceDBLayoutFB.GerarUnidadeOrcamentariaPadrao(aUnidadeGestora: TUnidadeGestora);
var
  aUnidadeOrca : TUnidadeOrcamentaria;
begin
  try
    aUnidadeOrca := TUnidadeOrcamentaria.Create;

    aUnidadeOrca.Descricao := 'MIGRA��O';
    aUnidadeOrca.Codigo    := Trim(aUnidadeGestora.Codigo);
    aUnidadeOrca.UnidadeGestora.ID := aUnidadeGestora.ID;

    if not dmConexaoTargetDB.InserirUnidadeOrcament(aUnidadeOrca) then
      gLogImportacao.Add('Unidade Or�ament�ria - ' +
        QuotedStr(aUnidadeOrca.Codigo + ' - ' + aUnidadeOrca.Descricao) + ' n�o importado');
  finally
    aUnidadeOrca.Destroy;
  end;
end;

procedure TfrmSourceDBLayoutFB.GravarIni;
begin
  gConfiguracao.WriteString('SourceDBLayoutFB', 'FileName',  edSourceDB.Text);
  gConfiguracao.WriteString('SourceDBLayoutFB', 'Directory', ExtractFilePath(edSourceDB.Text));
  gConfiguracao.WriteString('SourceDBLayoutFB', 'UserName',  edUsuario.Text);
  gConfiguracao.WriteString('SourceDBLayoutFB', 'Password',  edSenha.Text);
  gConfiguracao.UpdateFile;
end;


procedure TfrmSourceDBLayoutFB.ImportarCargoFuncao(Sender: TObject);
  procedure UpdateGenerators;
  begin
    dmConexaoTargetDB.UpdateGenerator('GEN_ID_CATEG_FUNCIONAL', 'CATEG_FUNCIONAL', 'ID');
    dmConexaoTargetDB.UpdateGenerator('GEN_ID_FATOR_PROG_SAL',  'FATOR_PROG_SAL',  'ID');
    dmConexaoTargetDB.UpdateGenerator('GEN_ID_CARGO_FUNCAO',    'CARGO_FUNCAO',    'ID');
  end;
var
  aCargoFuncao : TCargoFuncao;
  aCBO    ,
  aTipoTCM,
  aEscola ,
  aCompetencia : TGenerico;
begin
  try
    aCompetencia := TGenerico(cmCompetencia.Items.Objects[cmCompetencia.ItemIndex]);

    UpdateGenerators;

    if qrySourceDB.Active then
      qrySourceDB.Close;

    qrySourceDB.SQL.Clear;
    qrySourceDB.SQL.Add('Select ');
    qrySourceDB.SQL.Add('    c.*');
    qrySourceDB.SQL.Add('from SFP005' + aCompetencia.Sufixo + ' c');
    qrySourceDB.SQL.Add(' ');
    qrySourceDB.SQL.Add('union');
    qrySourceDB.SQL.Add(' ');
    qrySourceDB.SQL.Add('Select');
    qrySourceDB.SQL.Add('    ''999'' || x.codigo as codigo');
    qrySourceDB.SQL.Add('  , x.cargo2 as cargo');
    qrySourceDB.SQL.Add('  , null as cbo');
    qrySourceDB.SQL.Add('  , x.salario as salario');
    qrySourceDB.SQL.Add('  , null as horatrab');
    qrySourceDB.SQL.Add('  , null as horabase');
    qrySourceDB.SQL.Add('  , null as diaria');
    qrySourceDB.SQL.Add('  , x.obs');
    qrySourceDB.SQL.Add('  , null as valaula');
    qrySourceDB.SQL.Add('  , null as alterado');
    qrySourceDB.SQL.Add('  , null as status');
    qrySourceDB.SQL.Add('  , null as tipocargo');
    qrySourceDB.SQL.Add('  , null as numvagas');
    qrySourceDB.SQL.Add('  , null as nivelesc');
    qrySourceDB.SQL.Add('  , null as tipcria');
    qrySourceDB.SQL.Add('  , null as leicria');
    qrySourceDB.SQL.Add('  , null as datcria');
    qrySourceDB.SQL.Add('  , null as tipregjur');
    qrySourceDB.SQL.Add('  , null as leiregjur');
    qrySourceDB.SQL.Add('  , null as datregjur');
    qrySourceDB.SQL.Add('  , null as tipregprev');
    qrySourceDB.SQL.Add('  , null as leiregprev');
    qrySourceDB.SQL.Add('  , null as datregprev');
    qrySourceDB.SQL.Add('  , null as referencia');
    qrySourceDB.SQL.Add('  , null as codtcm');
    qrySourceDB.SQL.Add('  , null as codev1');
    qrySourceDB.SQL.Add('  , null as percev1');
    qrySourceDB.SQL.Add('  , null as valev1');
    qrySourceDB.SQL.Add('  , null as codev2');
    qrySourceDB.SQL.Add('  , null as percev2');
    qrySourceDB.SQL.Add('  , null as valev2');
    qrySourceDB.SQL.Add('  , null as codev3');
    qrySourceDB.SQL.Add('  , null as percev3');
    qrySourceDB.SQL.Add('  , null as valev3');
    qrySourceDB.SQL.Add('  , null as tcmdados');
    qrySourceDB.SQL.Add('  , null as obsreserva');
    qrySourceDB.SQL.Add('  , null as marcarel');
    qrySourceDB.SQL.Add('  , null as tmp_anu_masc');
    qrySourceDB.SQL.Add('  , null as tmp_anu_fem');
    qrySourceDB.SQL.Add('  , null as tmp_tri_masc');
    qrySourceDB.SQL.Add('  , null as tmp_tri_fem');
    qrySourceDB.SQL.Add('  , null as tmp_qui_masc');
    qrySourceDB.SQL.Add('  , null as tmp_qui_fem');
    qrySourceDB.SQL.Add('  , null as cbo_sim');
    qrySourceDB.SQL.Add('  , null as progauto');
    qrySourceDB.SQL.Add('  , null as cbogfip');
    qrySourceDB.SQL.Add('  , null as natureza_cargo');
    qrySourceDB.SQL.Add('  , null as dedicacao_exclussiva');
    qrySourceDB.SQL.Add('  , null as refhoras');
    qrySourceDB.SQL.Add('  , null as infodesc');
    qrySourceDB.SQL.Add('  , null as infodescricao');
    qrySourceDB.SQL.Add('  , null as horasref');
    qrySourceDB.SQL.Add('  , null as teto_max');
    qrySourceDB.SQL.Add('  , null as especialidade');
    qrySourceDB.SQL.Add('  , null as numvagasdef');
    qrySourceDB.SQL.Add('  , null as cotavagasdef');
    qrySourceDB.SQL.Add('  , null as tipo_normativo');
    qrySourceDB.SQL.Add('  , null as anolei');
    qrySourceDB.SQL.Add('  , null as data_pub_lei');
    qrySourceDB.SQL.Add('  , null as meio_pub_lei');
    qrySourceDB.SQL.Add('from SFPDXX25' + aCompetencia.Sufixo + ' x');
    qrySourceDB.SQL.Add('order by');
    qrySourceDB.SQL.Add('    2 ');
    qrySourceDB.Open;
    qrySourceDB.Last;

    prbAndamento.Position := 0;
    prbAndamento.Max      := qrySourceDB.RecordCount;

    qrySourceDB.First;
    while not qrySourceDB.Eof do
    begin
      aCargoFuncao := TCargoFuncao.Create;
      aCBO     := TGenerico.Create;
      aTipoTCM := TGenerico.Create;
      aEscola  := TGenerico.Create;

      aCargoFuncao.ID         := 0;
//      // Codigo = C�digo + CBO
//      aCargoFuncao.Codigo     := FormatFloat('##0000', StrToIntDef(Trim(qrySourceDB.FieldByName('codigo').AsString), 9999)) + FormatFloat('000000', StrToIntDef(Trim(qrySourceDB.FieldByName('cbo').AsString), 0));
      aCargoFuncao.Codigo     := FormatFloat('##0000', StrToIntDef(Trim(qrySourceDB.FieldByName('codigo').AsString), 9999));
      aCargoFuncao.Descricao  := AnsiUpperCase(Trim(qrySourceDB.FieldByName('cargo').AsString));
      aCargoFuncao.CBO.Codigo := FormatFloat('000000', StrToIntDef(Trim(qrySourceDB.FieldByName('cbo').AsString), 0));
      aCargoFuncao.NumeroAtoCriacao    := Trim(qrySourceDB.FieldByName('leicria').AsString);
      aCargoFuncao.DataAtoCriacao      := qrySourceDB.FieldByName('datcria').AsDateTime;
      aCargoFuncao.QuantidadeVaga      := qrySourceDB.FieldByName('numvagas').AsInteger;
      aCargoFuncao.CargaHorariaMensal  := StrToIntDef(Trim(qrySourceDB.FieldByName('horabase').AsString), 0);
      aCargoFuncao.BaseCalculoHoraAula := aCargoFuncao.CargaHorariaMensal;

      if (Trim(qrySourceDB.FieldByName('nivelesc').AsString) <> EmptyStr) then
        aCargoFuncao.Escolaridade.Codigo := FormatFloat('00', StrToInt(Trim(qrySourceDB.FieldByName('nivelesc').AsString)));

      if (Trim(qrySourceDB.FieldByName('codtcm').AsString) = EmptyStr) then
      begin
        aCargoFuncao.TipoTCM.Codigo    := '20';
        aCargoFuncao.TipoTCM.Descricao := 'EFETIVO CONCURSADO';
      end
      else
        aCargoFuncao.TipoTCM.Codigo    := Trim(qrySourceDB.FieldByName('codtcm').AsString);

//      Case qrySourceDB.FieldByName('vinculo').AsInteger of
//        40, 50, 55 :
//          begin
//            aCargoFuncao.TipoTCM.Codigo    := '40';
//            aCargoFuncao.TipoTCM.Descricao := 'TEMPORARIO';
//          end;
//        else
//          begin
//            aCargoFuncao.TipoTCM.Codigo    := '20';
//            aCargoFuncao.TipoTCM.Descricao := 'EFETIVO CONCURSADO';
//          end;
//      end;

      aCargoFuncao.Categoria.ID        := 1;
      aCargoFuncao.Categoria.Descricao := 'GERAL';
      aCargoFuncao.Categoria.Codigo    := 'G - 010';

      aCargoFuncao.FatorProgramaSalario.ID        := 1;
      aCargoFuncao.FatorProgramaSalario.Descricao := '0 REF. - 0 ANOS - 0.00%';
      aCargoFuncao.FatorProgramaSalario.Codigo    := '';
      aCargoFuncao.FatorProgramaSalario.QuantidadeReferencia := 1;
      aCargoFuncao.FatorProgramaSalario.ReferenciaInicial    := 1;
      aCargoFuncao.FatorProgramaSalario.QuantidadeAno        := 1;
      aCargoFuncao.FatorProgramaSalario.Percentual           := 0.0;
      aCargoFuncao.FatorProgramaSalario.Automatico           := True;
      aCargoFuncao.FatorProgramaSalario.IncorporaVenctoBase  := False;

      dmConexaoTargetDB.InserirCategoriaFuncional(aCargoFuncao.Categoria);
      dmConexaoTargetDB.InserirCargoTCM(aCargoFuncao.TipoTCM);
      dmConexaoTargetDB.InserirFatorProgramaSalario(aCargoFuncao.FatorProgramaSalario);

      dmConexaoTargetDB.GetID('CBO',            'ID', 'CODIGO = '   + QuotedStr(aCargoFuncao.CBO.Codigo), aCBO);
      dmConexaoTargetDB.GetID('TIPO_CARGO_TCM', 'ID', 'ID = '       + IfThen(Trim(aCargoFuncao.TipoTCM.Codigo) = EmptyStr, '0', Trim(aCargoFuncao.TipoTCM.Codigo)), aTipoTCM);
      dmConexaoTargetDB.GetID('ESCOLARIDADE',   'ID', 'COD_RAIS = ' + QuotedStr(aCargoFuncao.Escolaridade.Codigo), aEscola);

      aCargoFuncao.CBO.ID          := aCBO.ID;
      aCargoFuncao.TipoTCM.ID      := aTipoTCM.ID;
      aCargoFuncao.Escolaridade.ID := aEscola.ID;

      aCargoFuncao.VencimentoBase := qrySourceDB.FieldByName('salario').AsCurrency;
      aCargoFuncao.Observacao     := Trim(qrySourceDB.FieldByName('obs').AsString) + #13#13 + Trim(qrySourceDB.FieldByName('obsreserva').AsString);

      if not dmConexaoTargetDB.InserirCargoFuncao(aCargoFuncao) then
          gLogImportacao.Add(TCheckBox(Sender).Caption + ' - ' +
            QuotedStr(aCargoFuncao.Codigo + ' - ' + aCargoFuncao.Descricao) + ' n�o importado');

      lblAndamento.Caption  := Trim(qrySourceDB.FieldByName('cargo').AsString);
      prbAndamento.Position := prbAndamento.Position + 1;

      Application.ProcessMessages;
      qrySourceDB.Next;
    end;

    UpdateGenerators;
  finally
    dmRecursos.ExibriLog;

    if qrySourceDB.Active then
      qrySourceDB.Close;

    if (Sender is TCheckBox) then
      TCheckBox(Sender).Checked := False;
  end;
end;

procedure TfrmSourceDBLayoutFB.ImportarEntidadeFinanceira(Sender: TObject);
var
  aEntidadeFinanc : TEntidadeFinanceira;
begin
  try
    if qrySourceDB.Active then
      qrySourceDB.Close;

    qrySourceDB.SQL.Text := 'Select * from SFPD9911';
    qrySourceDB.Open;
    qrySourceDB.Last;

    prbAndamento.Position := 0;
    prbAndamento.Max      := qrySourceDB.RecordCount;

    qrySourceDB.First;
    while not qrySourceDB.Eof do
    begin
      aEntidadeFinanc := TEntidadeFinanceira.Create;

      aEntidadeFinanc.ID        := 0;
      aEntidadeFinanc.Codigo    := Trim(qrySourceDB.FieldByName('numbanco').AsString);
      aEntidadeFinanc.Descricao := AnsiUpperCase(Copy(Trim(qrySourceDB.FieldByName('nomebanco').AsString), 1, 40));
      aEntidadeFinanc.EBanco    := True;

      aEntidadeFinanc.Banco.Codigo    := aEntidadeFinanc.Codigo;
      aEntidadeFinanc.Banco.Descricao := aEntidadeFinanc.Descricao;

      // Inserir ENTIDADE FINANCEIRA
      if not dmConexaoTargetDB.InserirEntidadeFinanceira(aEntidadeFinanc) then
        gLogImportacao.Add(TCheckBox(Sender).Caption + ' - ' +
          QuotedStr(aEntidadeFinanc.Codigo + ' - ' + aEntidadeFinanc.Descricao) + ' n�o importado');

      lblAndamento.Caption  := Trim(qrySourceDB.FieldByName('nomebanco').AsString);
      prbAndamento.Position := prbAndamento.Position + 1;

      Application.ProcessMessages;
      qrySourceDB.Next;
    end;
  finally
    if qrySourceDB.Active then
      qrySourceDB.Close;
    if (Sender is TCheckBox) then
      TCheckBox(Sender).Checked := False;
  end;
end;

procedure TfrmSourceDBLayoutFB.ImportarEstadoFuncional(Sender: TObject);
var
  aEstadoFunc : TEstadoFuncional;
begin
  try
    CriarCampoEstadoFuncional_Layout;

    // Inserir Estado Funcional Padr�o
    aEstadoFunc := TEstadoFuncional.Create;
    aEstadoFunc.ID        := 1;
    aEstadoFunc.Codigo    := EmptyStr;
    aEstadoFunc.Descricao := 'ATIVO';
    dmConexaoTargetDB.InserirEstadoFuncional(aEstadoFunc);

    if qrySourceDB.Active then
      qrySourceDB.Close;

    qrySourceDB.SQL.Text := 'Select * from AFASTFOLHA';
    qrySourceDB.Open;
    qrySourceDB.Last;

    prbAndamento.Position := 0;
    prbAndamento.Max      := qrySourceDB.RecordCount;

    qrySourceDB.First;
    while not qrySourceDB.Eof do
    begin
      // Os estados funcionais possuem os mesmos c�digos em bases diferentes
      aEstadoFunc.ID        := qrySourceDB.FieldByName(FCampoEstadoFuncionalRemunID).AsInteger;
      aEstadoFunc.Codigo    := FormatFloat('000', StrToInt(Trim(qrySourceDB.FieldByName('codigo').AsString)));
      aEstadoFunc.Descricao := AnsiUpperCase(Trim(qrySourceDB.FieldByName('descricao').AsString));

      if not dmConexaoTargetDB.InserirEstadoFuncional(aEstadoFunc) then
        gLogImportacao.Add(TCheckBox(Sender).Caption + ' - ' +
          QuotedStr(aEstadoFunc.Codigo + ' - ' + aEstadoFunc.Descricao) + ' n�o importado');

      lblAndamento.Caption  := Trim(qrySourceDB.FieldByName('descricao').AsString);
      prbAndamento.Position := prbAndamento.Position + 1;

      Application.ProcessMessages;
      qrySourceDB.Next;
    end;

    dmConexaoTargetDB.UpdateGenerator('GEN_ID_ESTADO_FUNCIONAL', 'ESTADO_FUNCIONAL', 'ID');
  finally
    dmRecursos.ExibriLog;

    if qrySourceDB.Active then
      qrySourceDB.Close;
    if (Sender is TCheckBox) then
      TCheckBox(Sender).Checked := False;
  end;
end;

procedure TfrmSourceDBLayoutFB.ImportarEventos(Sender: TObject);
var
  aEvento : TEvento;
  aCompetencia : TGenerico;
begin
  try
    CriarCampoEvento_Layout;
    aCompetencia := TGenerico(cmCompetencia.Items.Objects[cmCompetencia.ItemIndex]);

    if qrySourceDB.Active then
      qrySourceDB.Close;

    qrySourceDB.SQL.Text := 'Select * from SFP010' + aCompetencia.Sufixo;
    qrySourceDB.Open;
    qrySourceDB.Last;

    prbAndamento.Position := 0;
    prbAndamento.Max      := qrySourceDB.RecordCount;

    qrySourceDB.First;
    while not qrySourceDB.Eof do
    begin
      aEvento := TEvento.Create;

      aEvento.ID        := qrySourceDB.FieldByName(FCampoEventoRemunID).AsInteger;
      aEvento.Codigo    := FBaseID + Trim(qrySourceDB.FieldByName('codigo').AsString);
      aEvento.Descricao := AnsiUpperCase(Trim(qrySourceDB.FieldByName('descricao').AsString));
      aEvento.CodigoRubrica := Trim(qrySourceDB.FieldByName('codigo').AsString);

//      Case StrToIntDef(Trim(dbfSourceDB.FieldByName('tipo').AsString), 0) of
//        1 : aEvento.Tipo := 'V';
//        2 : aEvento.Tipo := 'D';
//      end;
      if (Trim(qrySourceDB.FieldByName('natureza').AsString) = 'P') then
        aEvento.Tipo := 'V'
      else
      if (Trim(qrySourceDB.FieldByName('natureza').AsString) = 'D') then
        aEvento.Tipo := 'D'
      else
      if (Trim(qrySourceDB.FieldByName('natureza').AsString) = 'V') then
        aEvento.Tipo := 'D';

      aEvento.Categoria.ID          := 16;
      aEvento.Categoria.Descricao   := 'OUTRA';
      aEvento.CategoriaTCM.ID       := 0;
      aEvento.PercentualHoraExtra   := 0.0;
      aEvento.HRSobreHoraNormal     := EmptyStr;
      aEvento.TipoBaseCalculo       := baseCalculoUm;
      aEvento.IndiceSalarioFamilia  := False; // (Trim(qrySourceDB.FieldByName('salariofamilia').AsString) = 'S');
      aEvento.IndiceATS             := False; // (StrToIntDef(Trim(dbfSourceDB.FieldByName('INCATS').AsString), 0)    = 1);
      aEvento.IndiceFerias          := (Trim(qrySourceDB.FieldByName('incidefer').AsString) = 'S');
      aEvento.IndiceDecimoTerceiro  := (Trim(qrySourceDB.FieldByName('incide13').AsString) = 'S');
      aEvento.IndiceFalta           := True;
      aEvento.IndicePrevidencia     := (Trim(qrySourceDB.FieldByName('incideinss').AsString) = 'S');
      aEvento.IndiceIRRF            := (Trim(qrySourceDB.FieldByName('incideirrf').AsString) = 'S');
      aEvento.IndiceOutraBC1        := False;
      aEvento.IndiceOutraBC2        := False;
      aEvento.IndiceOutraBC3        := False;
      aEvento.GeraRAIS              := False; // (Trim(qrySourceDB.FieldByName('rais').AsString) = 'S');
      aEvento.CopiaMesAnterior      := False;
      aEvento.PermiteUsuarioAlterar := True;
      aEvento.SemUso                := False;
      aEvento.SubElementoDespesa := EmptyStr;
      aEvento.ContaCorrente      := EmptyStr;
      aEvento.BCMargemConsignada := True;;
      aEvento.ValorBCFixa        := 0.0;
      aEvento.Natureza           := naturezaEventoDois;
      aEvento.Remuneracao        := EmptyStr;

      (*
      0 - Null
      1 - (%) Acr�stimo na Hora x Quantidade
      2 - (%) da Hora x Quantidade
      3 - (%) do Valor x Quantidade
      4 - Quantidade x Valor
      5 - (%) x Valor
      *)
      if (Trim(qrySourceDB.FieldByName('tipo').AsString) = 'P') then
        aEvento.FormaCalculo := formaCalculoPorPercentual
      else
      if (Trim(qrySourceDB.FieldByName('tipo').AsString) = 'V') then
        aEvento.FormaCalculo := formaCalculoAutomatico;

      aEvento.ValorFixo  := qrySourceDB.FieldByName('valor').AsCurrency;
      aEvento.Divisor    := 0.0;
      aEvento.SubDivisor := 0.0;
      aEvento.Max_x_vencimentoBase  := 1;

      dmConexaoTargetDB.InserirCategoria(aEvento.Categoria);

      if not dmConexaoTargetDB.InserirEvento(aEvento) then
        gLogImportacao.Add(TCheckBox(Sender).Caption + ' - ' +
          QuotedStr(aEvento.Codigo + ' - ' + aEvento.Descricao) + ' n�o importado');

      lblAndamento.Caption  := Trim(qrySourceDB.FieldByName('descricao').AsString);
      prbAndamento.Position := prbAndamento.Position + 1;

      Application.ProcessMessages;
      qrySourceDB.Next;
    end;

    dmConexaoTargetDB.UpdateGenerator('GEN_ID_EVENTO', 'EVENTO', 'ID');
  finally
    dmRecursos.ExibriLog;

    if qrySourceDB.Active then
      qrySourceDB.Close;
    if (Sender is TCheckBox) then
      TCheckBox(Sender).Checked := False;
  end;
end;

procedure TfrmSourceDBLayoutFB.ImportarPessoaFisica(Sender: TObject);
  procedure UpdateGenerators;
  begin
    dmConexaoTargetDB.UpdateGenerator('GEN_ID_PESSOA_FISICA',        'PESSOA_FISICA',            'ID');
    dmConexaoTargetDB.UpdateGenerator('GEN_ID_PESSOA_FISICA_DEPEND', 'PESSOA_FISICA_DEPENDENTE', 'ID');
    dmConexaoTargetDB.UpdateGenerator('GEN_ID_SERVIDOR',      'SERVIDOR',      'CAST(substring(lpad(ID, 10, ''0'') from 1 for 9) as INTEGER)');
    dmConexaoTargetDB.UpdateGenerator('GEN_ID_ENTID_FINANC',  'ENTID_FINANC',  'ID');
    dmConexaoTargetDB.UpdateGenerator('GEN_ID_DEPTO',         'DEPTO',         'ID');
    dmConexaoTargetDB.UpdateGenerator('GEN_ID_SUB_UNID_ORCAMENT',   'SUB_UNID_ORCAMENT',   'ID');
    dmConexaoTargetDB.UpdateGenerator('GEN_ID_SERVIDOR_CONTA_BANC', 'SERVIDOR_CONTA_BANC', 'ID');
  end;
var
  aPessoa         ,
  aNacionalidade  ,
  aEstadoCivil    ,
  aDepartamento   : TGenerico;
  aServidor       : TServidor;
  aEntidadeFinanc : TContaBancoServidor;
  aSubUnidadeOrca : TSubUnidadeOrcamentaria;
  aEnderecoNumero ,
  aTituloEleitor  : String;
begin
  aPessoa         := TGenerico.Create;
  aNacionalidade  := TGenerico.Create;
  aEstadoCivil    := TGenerico.Create;
  aDepartamento   := TGenerico.Create;
  aSubUnidadeOrca := TSubUnidadeOrcamentaria.Create;
  try
    UpdateGenerators;

//    dmConexaoTargetDB.CriarCampoTabela('NACIONALIDADE', 'ID_SYS_ANTER', 'VARCHAR(11)');
//    dmConexaoTargetDB.CriarCampoTabela('ESTADO_CIVIL',  'ID_SYS_ANTER', 'VARCHAR(11)');
//    dmConexaoTargetDB.ExecutarStriptDB('Update ESTADO_CIVIL Set id_sys_anter =  ''1'' where id = 1');
//    dmConexaoTargetDB.ExecutarStriptDB('Update ESTADO_CIVIL Set id_sys_anter =  ''2'' where id = 2');
//    dmConexaoTargetDB.ExecutarStriptDB('Update ESTADO_CIVIL Set id_sys_anter =  ''3'' where id = 3');
//    dmConexaoTargetDB.ExecutarStriptDB('Update ESTADO_CIVIL Set id_sys_anter =  ''4'' where id = 4');
//    dmConexaoTargetDB.ExecutarStriptDB('Update ESTADO_CIVIL Set id_sys_anter =  ''5'' where id = 5');
//
    aDepartamento := TGenerico.Create;
    aDepartamento.ID        := 1;
    aDepartamento.Descricao := 'GERAL';
    aDepartamento.Codigo    := '000000';
    aDepartamento.Ativo     := True;

    // Inserir DEPARTAMENTO DEFAULT
    dmConexaoTargetDB.InserirDepartamento(aDepartamento);

//    aSubUnidadeOrca.ID        := 1;
//    aSubUnidadeOrca.Descricao := 'MIGRA��O';
//    aSubUnidadeOrca.Codigo    := '0000';
//    aSubUnidadeOrca.UnidadeOrcamentaria.ID := 1;
//    aSubUnidadeOrca.Setor.ID  := 1;
//
//    // Inserir SUBUNIDADE GESTORA DEFAULT
//    dmConexaoTargetDB.InserirSubUnidadeOrcament(aSubUnidadeOrca);
//
    if qrySourceDB.Active then
      qrySourceDB.Close;

    qrySourceDB.SQL.BeginUpdate;
    qrySourceDB.SQL.Clear;
    qrySourceDB.SQL.Add('Select');
    qrySourceDB.SQL.Add('    t.*');
    qrySourceDB.SQL.Add('  , coalesce(nullif(t.nacionalidade, ''0''), ''10'') as nacionalidade_codigo');
    qrySourceDB.SQL.Add('  , n.nome as nacionalidade_nome');
    qrySourceDB.SQL.Add('  , coalesce(t.estadocivil, ''9'') as estadocivil_codigo');
    qrySourceDB.SQL.Add('  , e.nome as estadocivil_nome');
    qrySourceDB.SQL.Add('  , c1.cbo as cbo_inicial');
    qrySourceDB.SQL.Add('  , c2.cbo as cbo_atual');
    qrySourceDB.SQL.Add('  , t.depdespesa  as depto');
    qrySourceDB.SQL.Add('  , u.nomeunidade as depto_nome');
//    qrySourceDB.SQL.Add('  , ss.nome as situacao_nome');
//    qrySourceDB.SQL.Add('  , sf.nome as situacao_nome_nome');
    qrySourceDB.SQL.Add('  , sl.valor as vencimento_base');
    qrySourceDB.SQL.Add('  , coalesce(''000000'', nullif(trim(t.divisao), '''')) as divisao_tmp');
    qrySourceDB.SQL.Add('from TRABALHADOR t');
    qrySourceDB.SQL.Add('  left join NACIONALIDADE n on (n.codigo = t.nacionalidade)');
    qrySourceDB.SQL.Add('  left join ESTADOCIVIL e on (e.codigo = t.estadocivil)');
    qrySourceDB.SQL.Add('  left join CARGOS c1 on (c1.empresa = t.empresa and c1.codigo = t.cargoinicial)');
    qrySourceDB.SQL.Add('  left join CARGOS c2 on (c2.empresa = t.empresa and c2.codigo = t.cargoatual)');
    qrySourceDB.SQL.Add('  left join UNIDADE u on (u.codigo = t.depdespesa)');
//    qrySourceDB.SQL.Add('  left join SITUACOES ss on (ss.codigo = t.situacao)');
    qrySourceDB.SQL.Add('  left join SITUACAO_FUNCIONAL sf on (sf.codigo = t.situacao_funcional)');
    qrySourceDB.SQL.Add('  left join SALARIOS sl on (sl.empresa = t.empresa and sl.codigo = t.refsalatual)');
    qrySourceDB.SQL.Add('order by');
    qrySourceDB.SQL.Add('    t.empresa');
    qrySourceDB.SQL.Add('  , t.nome');
    qrySourceDB.SQL.Add('  , t.matricula');
    qrySourceDB.SQL.Add('  , t.contrato');
    qrySourceDB.SQL.EndUpdate;

    qrySourceDB.Open;
    qrySourceDB.Last;

    prbAndamento.Position := 0;
    prbAndamento.Max      := qrySourceDB.RecordCount;

    qrySourceDB.First;
    while not qrySourceDB.Eof do
    begin
      if (Trim(qrySourceDB.FieldByName('cpf').AsString) <> EmptyStr) then
      begin
        if not Assigned(aServidor) then
          aServidor := TServidor.Create;

        if not Assigned(aEntidadeFinanc) then
          aEntidadeFinanc := TContaBancoServidor.Create;

//        aServidor.ID              := 0;
//        aServidor.Codigo          := Trim(qrySourceDB.FieldByName('empresa').AsString) + Trim(qrySourceDB.FieldByName('registro').AsString);
//        aServidor.Matricula       := Trim(qrySourceDB.FieldByName('matricula').AsString);
//        aServidor.Nome            := AnsiUpperCase(Trim(qrySourceDB.FieldByName('nome').AsString));
//        aServidor.SexoSigla       := AnsiUpperCase(Trim(qrySourceDB.FieldByName('sexo').AsString));
//        aServidor.DataNascimento  := qrySourceDB.FieldByName('dtnascimento').AsDateTime;
//        aServidor.Naturalidade.Cidade := AnsiUpperCase(Trim(qrySourceDB.FieldByName('cidade').AsString));
//        aServidor.Naturalidade.UF     := AnsiUpperCase(Trim(qrySourceDB.FieldByName('uf').AsString));
//        aServidor.RG.Numero           := Trim(qrySourceDB.FieldByName('rg').AsString);
//        aServidor.RG.OrgaoEmissor     := Trim(qrySourceDB.FieldByName('rgorgaoemissor').AsString);
//        aServidor.RG.UF               := Trim(qrySourceDB.FieldByName('ufrg').AsString);
//        aServidor.RG.DataEmissao      := qrySourceDB.FieldByName('dtrg').AsDateTime;
//        aServidor.CPF_CNPJ.Numero     := Trim(qrySourceDB.FieldByName('cpf').AsString);
//        aServidor.PisPasep.Numero     := Trim(qrySourceDB.FieldByName('pis').AsString);
//        aServidor.CNH.Categoria       := Trim(qrySourceDB.FieldByName('cnh_categoria').AsString);
//        aServidor.CNH.Numero          := Trim(qrySourceDB.FieldByName('cnh_numero').AsString);
//        aServidor.CNH.DataEmissao     := qrySourceDB.FieldByName('cnh_dtexpedida').AsDateTime;
//        aServidor.CNH.DataVencimento  := qrySourceDB.FieldByName('cnh_dtvalidade').AsDateTime;
//
//        aServidor.Titulo.Numero := Trim(qrySourceDB.FieldByName('eleitor').AsString);
//        aServidor.Titulo.Zona   := Trim(qrySourceDB.FieldByName('zonaeleitoral').AsString);
//        aServidor.Titulo.Secao  := Trim(qrySourceDB.FieldByName('secaoeleitoral').AsString);
//
//        aServidor.Reservista.Numero := Trim(qrySourceDB.FieldByName('reservista').AsString);
//        aServidor.Conjuge.Nome            := EmptyStr;
//        aServidor.Conjuge.CPF_CNPJ.Numero := EmptyStr;
//        aServidor.NomePai := Trim(qrySourceDB.FieldByName('nomepai').AsString);
//        aServidor.NomeMae := Trim(qrySourceDB.FieldByName('nomemae').AsString);
//
//        aServidor.Endereco.Logradouro  := Trim(qrySourceDB.FieldByName('endereco').AsString);
//        aServidor.Endereco.Numero      := StringReplace(Trim(qrySourceDB.FieldByName('numero').AsString), '''', '', [rfReplaceAll]);
//        aServidor.Endereco.Bairro      := Trim(qrySourceDB.FieldByName('bairro').AsString);
//        aServidor.Endereco.Cidade      := Trim(qrySourceDB.FieldByName('cidade').AsString);
//        aServidor.Endereco.Cep         := Trim(qrySourceDB.FieldByName('cep').AsString);
//        aServidor.Endereco.UF          := Trim(qrySourceDB.FieldByName('uf').AsString);
//        aServidor.Endereco.Complemento := Trim(qrySourceDB.FieldByName('compl').AsString);
//        aServidor.Email                := Trim(qrySourceDB.FieldByName('email').AsString);
//
//        aServidor.Nacionalidade.ID        := StrToIntDef(Trim(qrySourceDB.FieldByName('nacionalidade_codigo').AsString), 10);
//        aServidor.Nacionalidade.Descricao := Trim(qrySourceDB.FieldByName('nacionalidade_nome').AsString);
//        aServidor.Nacionalidade.Codigo    := Trim(qrySourceDB.FieldByName('nacionalidade_codigo').AsString);
//
//        aServidor.EstadoCivil.ID        := StrToIntDef(Trim(qrySourceDB.FieldByName('estadocivil_codigo').AsString), 9);
//        aServidor.EstadoCivil.Descricao := Trim(qrySourceDB.FieldByName('estadocivil_nome').AsString);
//        aServidor.EstadoCivil.Codigo    := Trim(qrySourceDB.FieldByName('estadocivil_codigo').AsString);
//
//        dmConexaoTargetDB.InserirNacionalidade(aServidor.Nacionalidade);
//        dmConexaoTargetDB.InserirEstadoCivil(aServidor.EstadoCivil);
//
//        dmConexaoTargetDB.GetID('NACIONALIDADE', 'ID', 'ID_SYS_ANTER = ' + QuotedStr(aServidor.Nacionalidade.Codigo), aNacionalidade);
//        dmConexaoTargetDB.GetID('ESTADO_CIVIL',  'ID', 'ID_SYS_ANTER = ' + QuotedStr(aServidor.EstadoCivil.Codigo),   aEstadoCivil);
//
//        aServidor.Nacionalidade.ID := aNacionalidade.ID;
//        aServidor.EstadoCivil.ID   := aEstadoCivil.ID;
//
//        // Inserir PESSOA FISICA
//        if not dmConexaoTargetDB.InserirPessoaFisica(TPessoaFisica(aServidor)) then
//          gLogImportacao.Add('Tabela Pessoa F�sica - ' +
//            QuotedStr(aServidor.Codigo + ' - ' + aServidor.Nome) + ' n�o importado');
//
//        dmConexaoTargetDB.GetID('PESSOA_FISICA', 'ID', 'CPF = ' + QuotedStr(aServidor.CPF_CNPJ.Numero), aPessoa);
//        aServidor.ID           := aPessoa.ID;
//        aServidor.IDServidor   := 0;
//        aServidor.Departamento := aDepartamento;
//        aServidor.DataAdmissao := qrySourceDB.FieldByName('dtadmissao').AsDateTime;
//        aServidor.SubUnidadeOrcamentaria := aSubUnidadeOrca;
//
//        aServidor.SubUnidadeOrcamentaria.Codigo  := Trim(qrySourceDB.FieldByName('empresa').AsString) + Trim(qrySourceDB.FieldByName('divisao_tmp').AsString);
//        aServidor.SubUnidadeOrcamentaria.ID      := dmConexaoTargetDB.GetValue('SUB_UNID_ORCAMENT', 'ID', 'ID_SYS_ANTER = ' + QuotedStr(aServidor.SubUnidadeOrcamentaria.Codigo));
//        if (aServidor.SubUnidadeOrcamentaria.ID = 0) then
//        begin
//          MensagemErro('Erro', 'Sub-Unidade Or�ament�ria ' + aServidor.SubUnidadeOrcamentaria.Codigo + ' n�o cadastrada/localizada!');
//          Abort;
//        end;
//
//        //aServidor.UnidadeLotacao.Codigo  := Trim(qrySourceDB.FieldByName('depdespesa').AsString);
//        aServidor.UnidadeLotacao.Codigo  := Trim(qrySourceDB.FieldByName('empresa').AsString) + Trim(qrySourceDB.FieldByName('subdivisao').AsString);
//        aServidor.UnidadeLotacao.ID      := dmConexaoTargetDB.GetValue('UNID_LOTACAO', 'ID', 'ID_SYS_ANTER = ' + QuotedStr(aServidor.UnidadeLotacao.Codigo));
//        if (aServidor.UnidadeLotacao.ID = 0) then
//        begin
//          MensagemErro('Erro', 'Unidade Lota��o ' + aServidor.UnidadeLotacao.Codigo + ' n�o cadastrada/localizada!');
//          Abort;
//        end;
//
//        aDepartamento.ID        := 0;
//        aDepartamento.Codigo    := Trim(qrySourceDB.FieldByName('depto').AsString);
//        aDepartamento.Descricao := AnsiUpperCase(Trim(qrySourceDB.FieldByName('depto_nome').AsString));
//        aDepartamento.CarregarDados;
//
//        if (aDepartamento.ID = 0) then
//        begin
//          aDepartamento.ID        := 1;
//          aDepartamento.Descricao := 'GERAL';
//          aDepartamento.Codigo    := '0000';
//          aDepartamento.Ativo     := True;
//        end;
//
//        aServidor.Departamento           := aDepartamento;
//        aServidor.CargoOrigem.Codigo     := FormatFloat('0000', StrToIntDef(Trim(qrySourceDB.FieldByName('cargoinicial').AsString), 9999)) + FormatFloat('000000', StrToIntDef(Trim(qrySourceDB.FieldByName('cbo_inicial').AsString), 0));
//        aServidor.CargoOrigem            := TCargoFuncao(dmConexaoTargetDB.ObjectID('CARGO_FUNCAO', 'ID', 'ID_SYS_ANTER', 'DESCRICAO', 'STATUS', 'ID_SYS_ANTER = ' + QuotedStr(aServidor.CargoOrigem.Codigo)));
//        aServidor.CargoAtual.Codigo      := FormatFloat('0000', StrToIntDef(Trim(qrySourceDB.FieldByName('cargoatual').AsString), 9999)) + FormatFloat('000000', StrToIntDef(Trim(qrySourceDB.FieldByName('cbo_atual').AsString), 0));
//        aServidor.CargoAtual             := TCargoFuncao(dmConexaoTargetDB.ObjectID('CARGO_FUNCAO', 'ID', 'ID_SYS_ANTER', 'DESCRICAO', 'STATUS', 'ID_SYS_ANTER = ' + QuotedStr(aServidor.CargoOrigem.Codigo)));
//        aServidor.ReferenciaSalario      := 0;
//        aServidor.VencimentoBase         := qrySourceDB.FieldByName('vencimento_base').AsCurrency;
//        aServidor.Escolaridade.Codigo    := FormatFloat('00', StrToIntDef(Trim(qrySourceDB.FieldByName('instrucao').AsString), 0));
//        aServidor.Escolaridade           := TCargoFuncao(dmConexaoTargetDB.ObjectID('ESCOLARIDADE', 'ID', 'COD_RAIS', 'DESCRICAO', EmptyStr, 'COD_RAIS = ' + QuotedStr(aServidor.Escolaridade.Codigo)));
//        aServidor.Formacao               := EmptyStr;
//        aServidor.ConselhoRegistro       := EmptyStr;
//        aServidor.CargaHorariaMensal     := 180;
//        aServidor.QuantidadeDependenteIRRF  := 0;
//        aServidor.CalculaVencimentoBase     := True;
//        aServidor.BloqueaLanctoEventoAuto   := False;
//        aServidor.CalculaPrevidencia        := True;
//        aServidor.CalculaIRRF               := True;
//        aServidor.NaoCalculaATS             := False;
////        aServidor.EstadoFuncional.Codigo    := FormatFloat('000', StrToIntDef(Trim(qrySourceDB.FieldByName('situacao').AsString), 0));
////        aServidor.EstadoFuncional := TEstadoFuncional(dmConexaoTargetDB.ObjectID('ESTADO_FUNCIONAL', 'ID', 'ID_SYS_ANTER', 'DESCRICAO', 'EM_ATIVIDADE', 'ID_SYS_ANTER = ' + QuotedStr(aServidor.EstadoFuncional.Codigo)));
//        aServidor.Status := statusServidorUm;
//
//        aServidor.EstadoFuncional.Codigo := FormatFloat('000', StrToIntDef(Trim(qrySourceDB.FieldByName('situacao').AsString), 0));
//        Case StrToIntDef(aServidor.EstadoFuncional.Codigo, 0) of
//          1 : aServidor.EstadoFuncional.ID := 1;
//          else
//            aServidor.EstadoFuncional := TEstadoFuncional(dmConexaoTargetDB.ObjectID('ESTADO_FUNCIONAL', 'ID', 'ID_SYS_ANTER', 'DESCRICAO', 'EM_ATIVIDADE', 'ID_SYS_ANTER = ' + QuotedStr(aServidor.EstadoFuncional.Codigo)));
//        end;
//
//        aServidor.SituacaoTCM.Codigo := Trim(qrySourceDB.FieldByName('situacao_funcional').AsString);
//        Case StrToIntDef(aServidor.SituacaoTCM.Codigo, 0) of
//          0    : aServidor.SituacaoTCM.ID := 20; // EFETIVO/CONCURSADO
//          1, 2 : aServidor.SituacaoTCM.ID := 10; // COMISSIONADO
//          3    : aServidor.SituacaoTCM.ID := 61; // TEMP S/ VINC NO PLANO DE CARGOS E SALARI
//          //6    : aSituacaoTCM.ID := 31; // PREFEITO
//          else
//            aServidor.SituacaoTCM.ID := 0;
//        end;
//
//        aServidor.Efetivo := (aServidor.SituacaoTCM.ID in [20, 21]); // EFETIVO/CONCURSADO e EFETIVO ART. 19 (ADCT) EST�VEIS
//
//        // Inserir SERVIDOR
//        if not dmConexaoTargetDB.InserirServidor(aServidor) then
//          gLogImportacao.Add('Tabela Servidor - ' +
//            QuotedStr(aServidor.Codigo + ' - ' + aServidor.Nome) + ' n�o importado')
//        else
//        begin
//          if qrySourceDBDetails.Active then
//            qrySourceDBDetails.Close;
//
//          qrySourceDBDetails.SQL.Clear;
//          qrySourceDBDetails.SQL.Add('Select');
//          qrySourceDBDetails.SQL.Add('    c.empresa');
//          qrySourceDBDetails.SQL.Add('  , c.registro');
//          qrySourceDBDetails.SQL.Add('  , c.banco');
//          qrySourceDBDetails.SQL.Add('  , b.nome');
//          qrySourceDBDetails.SQL.Add('  , c.agencia as nmagencia');
//          qrySourceDBDetails.SQL.Add('  , c.dvagencia');
//          qrySourceDBDetails.SQL.Add('  , c.agencia || coalesce(''-'' || nullif(c.dvagencia, ''''), '''') as agencia');
//          qrySourceDBDetails.SQL.Add('  , c.conta as nmconta');
//          qrySourceDBDetails.SQL.Add('  , c.dvconta');
//          qrySourceDBDetails.SQL.Add('  , c.conta || coalesce(''-'' || nullif(c.dvconta, ''''), '''') as conta');
//          qrySourceDBDetails.SQL.Add('  , c.padrao');
//          qrySourceDBDetails.SQL.Add('  , c.tipo');
//          qrySourceDBDetails.SQL.Add('from CONTASTRABALHADOR c');
//          qrySourceDBDetails.SQL.Add('  inner join BANCOS b on (b.codigo = c.banco)');
//          qrySourceDBDetails.SQL.Add('where c.empresa  = ' + QuotedStr( Trim(qrySourceDB.FieldByName('empresa').AsString) ));
//          qrySourceDBDetails.SQL.Add('  and c.registro = ' + QuotedStr( Trim(qrySourceDB.FieldByName('registro').AsString) ));
//          qrySourceDBDetails.Open;
//          qrySourceDBDetails.Last;
//
//          qrySourceDBDetails.First;
//          while not qrySourceDBDetails.Eof do
//          begin
//            aEntidadeFinanc.ID              := 0;
//            aEntidadeFinanc.IDConta         := 0;
//            aEntidadeFinanc.Servidor.Codigo := aServidor.Codigo;
//            aEntidadeFinanc.Servidor        := TServidor(dmConexaoTargetDB.ObjectID('SERVIDOR', 'ID', 'ID_SYS_ANTER', 'MATRICULA', EmptyStr, 'ID_SYS_ANTER = ' + QuotedStr(aEntidadeFinanc.Servidor.Codigo)));
//            aEntidadeFinanc.Banco.Codigo := Trim(qrySourceDBDetails.FieldByName('banco').AsString);
//            aEntidadeFinanc.Codigo       := aEntidadeFinanc.Banco.Codigo;
//            aEntidadeFinanc.Agencia      := Trim(qrySourceDBDetails.FieldByName('agencia').AsString);
//            aEntidadeFinanc.NumeroConta  := Trim(qrySourceDBDetails.FieldByName('conta').AsString);
//            aEntidadeFinanc.NumeroConta  := Copy(aEntidadeFinanc.NumeroConta, Length(aEntidadeFinanc.NumeroConta) - 10, 11);
//            aEntidadeFinanc.EBanco       := False;
//            aEntidadeFinanc.TipoConta    := tipoContaCorrente;
//
//            // Banco Caixa Econ�mica
//            if (aEntidadeFinanc.Banco.Codigo = '104') then
//              if StrToIntDef(Trim(qrySourceDBDetails.FieldByName('tipo').AsString), 0) = 37 then
//                aEntidadeFinanc.TipoConta := tipoContaSalario
//              else
//              if StrToIntDef(Trim(qrySourceDBDetails.FieldByName('tipo').AsString), 0) = 13 then
//                aEntidadeFinanc.TipoConta := tipoContaPoupanca;
//
//            aEntidadeFinanc.Descricao       := Trim(qrySourceDBDetails.FieldByName('nome').AsString);
//            aEntidadeFinanc.Banco.ID        := StrToIntDef(aEntidadeFinanc.Banco.Codigo, 0);
//            aEntidadeFinanc.Banco.Descricao := aEntidadeFinanc.Descricao;
//            aEntidadeFinanc.EBanco          := True;
//            aEntidadeFinanc.TipoConta       := tipoContaCorrente;
//
//            // Inserir ENTIDADE FINANCEIRA
//            if not dmConexaoTargetDB.InserirEntidadeFinanceira(aEntidadeFinanc) then
//              gLogImportacao.Add('Tabela Entidade Financeira - ' +
//                QuotedStr(aEntidadeFinanc.Codigo + ' - ' + aEntidadeFinanc.Descricao) + ' n�o importado');
//
//            if (aEntidadeFinanc.Agencia <> EmptyStr) and (aEntidadeFinanc.NumeroConta <> EmptyStr) then
//            begin
//              aEntidadeFinanc.ID := dmConexaoTargetDB.GetValue('ENTID_FINANC', 'ID', 'ID_SYS_ANTER = ' + QuotedStr(aEntidadeFinanc.Codigo));
//              if (aEntidadeFinanc.ID > 0) then
//              begin
//                if (Pos('-', aEntidadeFinanc.NumeroConta) = 0) then
//                  aEntidadeFinanc.NumeroConta :=
//                    Copy(aEntidadeFinanc.NumeroConta, 1, Length(aEntidadeFinanc.NumeroConta) - 1) + '-' +
//                    Copy(aEntidadeFinanc.NumeroConta, Length(aEntidadeFinanc.NumeroConta), 1);
//
//                aEntidadeFinanc.Ativo := (Trim(qrySourceDBDetails.FieldByName('padrao').AsString) = 'S');
//
//                // Inserir CONTA BANCO SERVIDOR
//                if not dmConexaoTargetDB.InserirContaBancoServidor(aEntidadeFinanc) then
//                  gLogImportacao.Add('Tabela Conta Corrente Servidor - ' +
//                    QuotedStr(aServidor.Codigo + ' - ' + aServidor.Nome) + ' n�o importado');
//              end;
//            end;
//
//            qrySourceDBDetails.Next;
//          end;
//        end;
      end;

      lblAndamento.Caption  := Trim(qrySourceDB.FieldByName('nome').AsString);
      prbAndamento.Position := prbAndamento.Position + 1;

      Application.ProcessMessages;
      qrySourceDB.Next;
    end;

    UpdateGenerators;
  finally
    dmRecursos.ExibriLog;

    aPessoa.Free;
    aNacionalidade.Free;
    aEstadoCivil.Free;
    aSubUnidadeOrca.Free;

    if qrySourceDB.Active then
      qrySourceDB.Close;
    if (Sender is TCheckBox) then
      TCheckBox(Sender).Checked := False;
  end;
end;

procedure TfrmSourceDBLayoutFB.ImportarSituacao(Sender: TObject);
var
  aSituacaoTCM : TGenerico;
  aCompetencia : TGenerico;
begin
  try
    aCompetencia := TGenerico(cmCompetencia.Items.Objects[cmCompetencia.ItemIndex]);

    if qrySourceDB.Active then
      qrySourceDB.Close;

    qrySourceDB.SQL.Text := 'Select * from CFG_VINC' + aCompetencia.Sufixo;
    qrySourceDB.Open;
    qrySourceDB.Last;

    prbAndamento.Position := 0;
    prbAndamento.Max      := qrySourceDB.RecordCount;

    qrySourceDB.First;
    while not qrySourceDB.Eof do
    begin
      aSituacaoTCM := TGenerico.Create;

      // Os v�nculos possuem c�digos diferentes em bases diferentes
      aSituacaoTCM.ID        := 0;
      aSituacaoTCM.Codigo    := FBaseID + Trim(qrySourceDB.FieldByName('id_vinculo').AsString);
      aSituacaoTCM.Descricao := AnsiUpperCase(Trim(qrySourceDB.FieldByName('nm_vinculo').AsString));

//      BLOCO DE REGRA ABAIXO NAO SE APLICA AO LAYOUT
//      Case StrToIntDef(aSituacaoTCM.Codigo, 0) of
//        1 : aSituacaoTCM.ID := 20; // EFETIVO/CONCURSADO
//        2 : aSituacaoTCM.ID := 21; // EFETIVO ART. 19 (ADCT) EST�VEIS
//        4 : aSituacaoTCM.ID := 10; // COMISSIONADO
//        6 : aSituacaoTCM.ID := 51; // PENSIONISTA DE MAIOR IDADE
//        9 : aSituacaoTCM.ID := 61; // TEMP S/ VINC NO PLANO DE CARGOS E SALARIO
//        else
//          aSituacaoTCM.ID := 0;
//      end;
//
      if not dmConexaoTargetDB.InserirSituacaoTCM(aSituacaoTCM) then
        gLogImportacao.Add(TCheckBox(Sender).Caption + ' - ' +
          QuotedStr(aSituacaoTCM.Codigo + ' - ' + aSituacaoTCM.Descricao) + ' n�o importado');

      lblAndamento.Caption  := Trim(qrySourceDB.FieldByName('nm_vinculo').AsString);
      prbAndamento.Position := prbAndamento.Position + 1;

      Application.ProcessMessages;
      qrySourceDB.Next;
    end;
  finally
    dmRecursos.ExibriLog;

    if qrySourceDB.Active then
      qrySourceDB.Close;
    if (Sender is TCheckBox) then
      TCheckBox(Sender).Checked := False;
  end;
end;

procedure TfrmSourceDBLayoutFB.ImportarUnidadeGestora(Sender: TObject);
  procedure UpdateGenerators;
  begin
    dmConexaoTargetDB.UpdateGenerator('GEN_ID_UNID_GESTORA',  'UNID_GESTORA',  'ID');
    dmConexaoTargetDB.UpdateGenerator('GEN_ID_UNID_ORCAMENT', 'UNID_ORCAMENT', 'ID');
  end;
var
  aTipoUnd : TGenerico;
  aUnidade : TUnidadeGestora;
  sCnpj          ,
  sCnpjPrincipal : String;
begin
  try
    UpdateGenerators;

    if qrySourceDB.Active then
      qrySourceDB.Close;

//    qrySourceDB.SQL.Text := 'Select * from SFP003';

    qrySourceDB.SQL.BeginUpdate;
    qrySourceDB.SQL.Clear;
    qrySourceDB.SQL.Add('Select');
    qrySourceDB.SQL.Add('    coalesce((Select first 1 a.ug from ECONTAS_010 a where a.codtcm = x.codtcm), x.codigo) as codigo');
    qrySourceDB.SQL.Add('  , x.codtcm');
    qrySourceDB.SQL.Add('  , x.descricao');
    qrySourceDB.SQL.Add('  , (Select first 1 a.tipo from ECONTAS_010 a where a.codtcm = x.codtcm) as tipo');
    qrySourceDB.SQL.Add('  , x.cgc ');
    qrySourceDB.SQL.Add('  , x.cgc as cgc_principal');
    qrySourceDB.SQL.Add('from SFP003 x');
    qrySourceDB.SQL.Add(' ');
    qrySourceDB.SQL.Add('union');
    qrySourceDB.SQL.Add(' ');
    qrySourceDB.SQL.Add('Select distinct   ');
    qrySourceDB.SQL.Add('    y.ug as codigo');
    qrySourceDB.SQL.Add('  , y.codtcm      ');
    qrySourceDB.SQL.Add('  , y.descricao   ');
    qrySourceDB.SQL.Add('  , y.tipo        ');
    qrySourceDB.SQL.Add('  , y.cnpj as cgc ');
    qrySourceDB.SQL.Add('  , (Select first 1 b.cgc from SFP003 b) as cgc_principal');
    qrySourceDB.SQL.Add('from ECONTAS_010 y');
    qrySourceDB.SQL.Add('where y.codtcm not in (');
    qrySourceDB.SQL.Add('    Select');
    qrySourceDB.SQL.Add('        x.codtcm');
    qrySourceDB.SQL.Add('    from SFP003 x');
    qrySourceDB.SQL.Add(')');
    qrySourceDB.SQL.EndUpdate;

    qrySourceDB.Open;
    qrySourceDB.Last;

    prbAndamento.Position := 0;
    prbAndamento.Max      := qrySourceDB.RecordCount;
    sCnpjPrincipal        := EmptyStr;

    qrySourceDB.First;
    while not qrySourceDB.Eof do
    begin
      sCnpj := Trim(qrySourceDB.FieldByName('cgc').AsString);
      sCnpj := StringReplace(StringReplace(StringReplace(sCnpj, '.', '', [rfReplaceAll]), '/', '', [rfReplaceAll]), '-', '', [rfReplaceAll]);

      sCnpjPrincipal := Trim(qrySourceDB.FieldByName('cgc_principal').AsString);
      sCnpjPrincipal := StringReplace(StringReplace(StringReplace(sCnpjPrincipal, '.', '', [rfReplaceAll]), '/', '', [rfReplaceAll]), '-', '', [rfReplaceAll]);

      if not Assigned(aTipoUnd) then
        aTipoUnd := TGenerico.Create;

      aUnidade := TUnidadeGestora.Create;
      aUnidade.ID             := StrToInt(Trim(qrySourceDB.FieldByName('codigo').AsString));
      aUnidade.Descricao      := AnsiUpperCase(Trim(qrySourceDB.FieldByName('descricao').AsString));
      aUnidade.RazaoSocial    := aUnidade.Descricao;
      aUnidade.Codigo         := Trim(qrySourceDB.FieldByName('codigo').AsString);
      aUnidade.CodigoTCM      := qrySourceDB.FieldByName('codtcm').AsInteger;
      aUnidade.CNPJ           := sCnpj;
      aUnidade.CNPJPrincipal  := sCnpjPrincipal; // aUnidade.CNPJ;

      aTipoUnd.ID     := 0;
      aTipoUnd.Codigo := Trim(qrySourceDB.FieldByName('tipo').AsString);
      dmConexaoTargetDB.GetID('TIPO_UNID_GESTORA', 'ID', 'ID = ' + aTipoUnd.Codigo, TGenerico(aTipoUnd));

      if (aTipoUnd.ID = 0) then
        aTipoUnd.ID := 1; // Prefeitura

      aUnidade.TipoUnidade := aTipoUnd;

      if not dmConexaoTargetDB.InserirUnidadeGestora(aUnidade) then
          gLogImportacao.Add(TCheckBox(Sender).Caption + ' - ' +
            QuotedStr(aUnidade.Codigo + ' - ' + aUnidade.Descricao) + ' n�o importado');

      lblAndamento.Caption  := Trim(qrySourceDB.FieldByName('descricao').AsString);
      prbAndamento.Position := prbAndamento.Position + 1;

      Application.ProcessMessages;
      qrySourceDB.Next;
    end;

    UpdateGenerators;
  finally
    dmRecursos.ExibriLog;

    if qrySourceDB.Active then
      qrySourceDB.Close;
    if (Sender is TCheckBox) then
      TCheckBox(Sender).Checked := False;
  end;
end;

procedure TfrmSourceDBLayoutFB.ImportarUnidadeLotacao(Sender: TObject);
  procedure UpdateGenerators;
  begin
    dmConexaoTargetDB.UpdateGenerator('GEN_ID_UNID_LOTACAO', 'UNID_LOTACAO', 'ID');
    dmConexaoTargetDB.UpdateGenerator('GEN_ID_DEPTO'       , 'DEPTO',        'ID');
  end;
var
  aLotacao : TUnidadeLotacao;
  aCompetencia  ,
  aDepartamento : TGenerico;
begin
  try
    UpdateGenerators;

    // Importar UNIDADES DE LOTA��O
    if qrySourceDB.Active then
      qrySourceDB.Close;

    qrySourceDB.SQL.Text := 'Select * from SFPD9924 order by escola';
    qrySourceDB.Open;
    qrySourceDB.Last;

    prbAndamento.Position := 0;
    prbAndamento.Max      := qrySourceDB.RecordCount;

    qrySourceDB.First;
    while not qrySourceDB.Eof do
    begin
      if not Assigned(aLotacao) then
        aLotacao := TUnidadeLotacao.Create;

      aLotacao.ID         := 0;
      aLotacao.Codigo     := Trim(qrySourceDB.FieldByName('codigo').AsString);
      aLotacao.Descricao  := AnsiUpperCase(Trim(qrySourceDB.FieldByName('escola').AsString));
      aLotacao.CodigoINEP := IfThen(Trim(qrySourceDB.FieldByName('codinep').AsString) = '99999999', EmptyStr, Trim(qrySourceDB.FieldByName('codinep').AsString));

     if (Pos('SMS', aLotacao.Descricao) > 0) then
       aLotacao.Tipo.ID := 3    // HOSPITAL / POSTO DE SA�DE
     else
     if (Pos('EMEF', aLotacao.Descricao) > 0) or (Pos('EMEI', aLotacao.Descricao) > 0) or (aLotacao.CodigoINEP <> EmptyStr) then
       aLotacao.Tipo.ID := 4    // ESCOLA
     else
       aLotacao.Tipo.ID := 99;  // OUTROS

      if not dmConexaoTargetDB.InserirUnidadeLotacao(aLotacao) then
        gLogImportacao.Add(TCheckBox(Sender).Caption + ' - ' +
          QuotedStr(aLotacao.Codigo + ' - ' + aLotacao.Descricao) + ' n�o importado');

      lblAndamento.Caption  := Trim(qrySourceDB.FieldByName('escola').AsString);
      prbAndamento.Position := prbAndamento.Position + 1;

      Application.ProcessMessages;
      qrySourceDB.Next;
    end;

    aCompetencia := TGenerico(cmCompetencia.Items.Objects[cmCompetencia.ItemIndex]);

    // Importar DEPTOS
    if qrySourceDB.Active then
      qrySourceDB.Close;

    qrySourceDB.SQL.BeginUpdate;
    qrySourceDB.SQL.Clear;
    qrySourceDB.SQL.Add('Select');
    qrySourceDB.SQL.Add('    d.cdsecreta || d.cdsetor as codigo ');
    qrySourceDB.SQL.Add('  , d.*');
    qrySourceDB.SQL.Add('  , d.codundgestor as ug_tcm');
    qrySourceDB.SQL.Add('  , d.codundorca   as uo_tcm');
    qrySourceDB.SQL.Add('from SFP006' + aCompetencia.Sufixo + ' d');
    qrySourceDB.SQL.Add('order by');
    qrySourceDB.SQL.Add('    d.descricao');
    qrySourceDB.SQL.EndUpdate;

    qrySourceDB.Open;
    qrySourceDB.Last;

    prbAndamento.Position := 0;
    prbAndamento.Max      := qrySourceDB.RecordCount;

    qrySourceDB.First;
    while not qrySourceDB.Eof do
    begin
      if not Assigned(aDepartamento) then
        aDepartamento := TGenerico.Create;

      aDepartamento.ID        := 0;
      aDepartamento.Codigo    := FormatFloat('###000000', qrySourceDB.FieldByName('codigo').AsInteger);
      aDepartamento.Descricao := AnsiUpperCase(Trim(qrySourceDB.FieldByName('descricao').AsString));
      aDepartamento.Ativo     := (Trim(qrySourceDB.FieldByName('status').AsString) = '1');

      if not dmConexaoTargetDB.InserirDepartamento(aDepartamento) then
        gLogImportacao.Add(TCheckBox(Sender).Caption + ' - Depto: ' +
          QuotedStr(aDepartamento.Codigo + ' - ' + aDepartamento.Descricao) + ' n�o importado');

      lblAndamento.Caption  := 'Depto: ' + Trim(qrySourceDB.FieldByName('descricao').AsString);
      prbAndamento.Position := prbAndamento.Position + 1;

      Application.ProcessMessages;
      qrySourceDB.Next;
    end;

    UpdateGenerators;
  finally
    dmRecursos.ExibriLog;
    aLotacao.Free;
    aDepartamento.Free;

    if qrySourceDB.Active then
      qrySourceDB.Close;
    if (Sender is TCheckBox) then
      TCheckBox(Sender).Checked := False;
  end;
end;

procedure TfrmSourceDBLayoutFB.ImportarUnidadeOrcamentaria(Sender: TObject);
  procedure UpdateGenerators;
  begin
    dmConexaoTargetDB.UpdateGenerator('GEN_ID_UNID_ORCAMENT',     'UNID_ORCAMENT',     'ID');
    dmConexaoTargetDB.UpdateGenerator('GEN_ID_SUB_UNID_ORCAMENT', 'SUB_UNID_ORCAMENT', 'ID');
  end;
var
  aCompetencia : TGenerico;
  aUnidadeGest : TUnidadeGestora;
  aUnidadeOrca : TUnidadeOrcamentaria;
  aSubUnidadeOrca : TSubUnidadeOrcamentaria;
  aPadraoGravado  : Boolean;
begin
  try
    aCompetencia := TGenerico(cmCompetencia.Items.Objects[cmCompetencia.ItemIndex]);

    UpdateGenerators;
    aPadraoGravado := False;

    // Unidade Or�ament�ria
    if qrySourceDB.Active then
      qrySourceDB.Close;

    qrySourceDB.SQL.BeginUpdate;
    qrySourceDB.SQL.Clear;
    qrySourceDB.SQL.Add('Select distinct');
    qrySourceDB.SQL.Add('    uo.uo as codigo');
    qrySourceDB.SQL.Add('  , uo.codtcm   ');
    qrySourceDB.SQL.Add('  , uo.descricao');
    qrySourceDB.SQL.Add('  , uo.cnpj     ');
    qrySourceDB.SQL.Add('  , uo.tipo     ');
    qrySourceDB.SQL.Add('  , uo.ug       ');
    qrySourceDB.SQL.Add('  , ug.codtcm as ug_tcm');
    qrySourceDB.SQL.Add('from ECONTAS_020 uo');
    qrySourceDB.SQL.Add('  left join (');
    qrySourceDB.SQL.Add('    Select distinct');
    qrySourceDB.SQL.Add('        x.ug');
    qrySourceDB.SQL.Add('      , x.descricao');
    qrySourceDB.SQL.Add('      , x.codtcm');
    qrySourceDB.SQL.Add('    from ECONTAS_010 x');
    qrySourceDB.SQL.Add('  ) ug on (ug.ug = uo.ug)');
    qrySourceDB.SQL.EndUpdate;

    qrySourceDB.Open;
    qrySourceDB.Last;

    prbAndamento.Position := 0;
    prbAndamento.Max      := qrySourceDB.RecordCount;

    qrySourceDB.First;
    while not qrySourceDB.Eof do
    begin
      if not Assigned(aUnidadeGest) then
        aUnidadeGest := TUnidadeGestora.Create;

      aUnidadeGest.ID        := 0;
      aUnidadeGest.Codigo    := Trim(qrySourceDB.FieldByName('ug').AsString);
      aUnidadeGest.CodigoTCM := StrToIntDef(Trim(qrySourceDB.FieldByName('ug_tcm').AsString), 0);
      dmConexaoTargetDB.GetID('UNID_GESTORA', 'ID', 'COD_ORGAO_TCM = ' + IntToStr(aUnidadeGest.CodigoTCM), TGenerico(aUnidadeGest));

      if (aUnidadeGest.ID = 0) then
        dmConexaoTargetDB.GetID('UNID_GESTORA', 'min(ID)', ID_SYS_ANTER + ' is not null', TGenerico(aUnidadeGest));

//      // Gravar Unidade Gestora com Unidade Or�ament�ria
//      if (not aPadraoGravado) then
//      begin
//        GerarUnidadeOrcamentariaPadrao(aUnidadeGest);
//        aPadraoGravado := True;
//      end;
//
      aUnidadeOrca := TUnidadeOrcamentaria.Create;

      aUnidadeOrca.Descricao := AnsiUpperCase(Trim(qrySourceDB.FieldByName('descricao').AsString));
      aUnidadeOrca.Codigo    := Trim(qrySourceDB.FieldByName('codigo').AsString);
      aUnidadeOrca.CodigoTCM := qrySourceDB.FieldByName('codtcm').AsInteger;
      aUnidadeOrca.UnidadeGestora.ID := aUnidadeGest.ID;

      if not dmConexaoTargetDB.InserirUnidadeOrcament(aUnidadeOrca) then
        gLogImportacao.Add(TCheckBox(Sender).Caption + ' - ' +
          QuotedStr(aUnidadeGest.Codigo + ' - ' + aUnidadeGest.Descricao) + ' n�o importado');


      lblAndamento.Caption  := Trim(qrySourceDB.FieldByName('descricao').AsString);
      prbAndamento.Position := prbAndamento.Position + 1;

      Application.ProcessMessages;
      qrySourceDB.Next;
    end;

    // Unidade Sub Or�ament�ria
    if qrySourceDB.Active then
      qrySourceDB.Close;

    qrySourceDB.SQL.BeginUpdate;
    qrySourceDB.SQL.Clear;
    qrySourceDB.SQL.Add('Select distinct');
    qrySourceDB.SQL.Add('    dp.cdsecreta as codigo');
    qrySourceDB.SQL.Add('  , ' + QuotedStr('MIGRA��O - SUBUNIDADE ') +' || dp.cdsecreta as descricao');
    qrySourceDB.SQL.Add('  , coalesce(nullif(trim(dp.codundgestor), ''''), ug.codtcm) as ug_tcm');
    qrySourceDB.SQL.Add('  , nullif(trim(dp.codundorca), ' + QuotedStr('0000000') + ') as uo_tcm');
    qrySourceDB.SQL.Add('  , uo.ug');
    qrySourceDB.SQL.Add('  , uo.uo');
    qrySourceDB.SQL.Add('  , ug.descricao as unidade_gestora');
    qrySourceDB.SQL.Add('  , uo.descricao as unidade_orcamentaria');
    qrySourceDB.SQL.Add('from SFP006' + aCompetencia.Sufixo + ' dp');
    qrySourceDB.SQL.Add('  left join (');
    qrySourceDB.SQL.Add('    Select distinct');
    qrySourceDB.SQL.Add('        x.ug');
    qrySourceDB.SQL.Add('      , x.uo');
    qrySourceDB.SQL.Add('      , x.codtcm');
    qrySourceDB.SQL.Add('      , x.descricao');
    qrySourceDB.SQL.Add('    from ECONTAS_020 x');
    qrySourceDB.SQL.Add('  ) uo on (uo.codtcm = dp.codundorca)');
    qrySourceDB.SQL.Add('  left join (');
    qrySourceDB.SQL.Add('    Select distinct');
    qrySourceDB.SQL.Add('        y.ug');
    qrySourceDB.SQL.Add('      , y.codtcm');
    qrySourceDB.SQL.Add('      , y.descricao');
    qrySourceDB.SQL.Add('    from ECONTAS_010 y');
    qrySourceDB.SQL.Add('  ) ug on (ug.ug = uo.ug)');
    qrySourceDB.SQL.EndUpdate;

    qrySourceDB.Open;
    qrySourceDB.Last;

    prbAndamento.Position := 0;
    prbAndamento.Max      := qrySourceDB.RecordCount;

    aSubUnidadeOrca := TSubUnidadeOrcamentaria.Create;

    qrySourceDB.First;
    while not qrySourceDB.Eof do
    begin
//      if not Assigned(aUnidadeGest) then
//        aUnidadeGest := TUnidadeGestora.Create;
//
//      aUnidadeGest.ID        := 0;
//      aUnidadeGest.Codigo    := Trim(qrySourceDB.FieldByName('ug').AsString);
//      aUnidadeGest.CodigoTCM := StrToIntDef(Trim(qrySourceDB.FieldByName('ug_tcm').AsString), 0);
//      dmConexaoTargetDB.GetID('UNID_GESTORA', 'ID', 'COD_ORGAO_TCM = ' + IntToStr(aUnidadeGest.CodigoTCM), TGenerico(aUnidadeGest));
//
//      if (aUnidadeGest.ID = 0) then
//        dmConexaoTargetDB.GetID('UNID_GESTORA', 'min(ID)', ID_SYS_ANTER + ' is not null', TGenerico(aUnidadeGest));
//
      if not Assigned(aUnidadeOrca) then
        aUnidadeOrca := TUnidadeOrcamentaria.Create;

      aUnidadeOrca.ID        := 0;
      aUnidadeOrca.Codigo    := Trim(qrySourceDB.FieldByName('uo').AsString);
      aUnidadeOrca.CodigoTCM := StrToIntDef(Trim(qrySourceDB.FieldByName('uo_tcm').AsString), 0);
      dmConexaoTargetDB.GetID('UNID_ORCAMENT', 'ID', 'COD_ORGAO_TCM = ' + IntToStr(aUnidadeOrca.CodigoTCM), TGenerico(aUnidadeOrca));

      if (aUnidadeOrca.ID = 0) then
        dmConexaoTargetDB.GetID('UNID_ORCAMENT', 'min(ID)', ID_SYS_ANTER + ' is not null', TGenerico(aUnidadeOrca));

      // Gravar sub-unidade padr�o para migra��o.
      if not aPadraoGravado then
      begin
        aSubUnidadeOrca.ID        := 0;
        aSubUnidadeOrca.Descricao := 'MIGRA��O';
        aSubUnidadeOrca.Codigo    := Trim(qrySourceDB.FieldByName('ug').AsString);
        aSubUnidadeOrca.Setor.ID  := 1;
        aSubUnidadeOrca.UnidadeOrcamentaria.ID := aUnidadeOrca.ID;

        dmConexaoTargetDB.InserirSubUnidadeOrcament(aSubUnidadeOrca);
        aPadraoGravado := True;
      end;

      aSubUnidadeOrca.ID        := 0;
      aSubUnidadeOrca.Descricao := AnsiUpperCase(Trim(qrySourceDB.FieldByName('descricao').AsString));
      aSubUnidadeOrca.Codigo    := Trim(qrySourceDB.FieldByName('codigo').AsString);
      aSubUnidadeOrca.Setor.ID  := 1;
      aSubUnidadeOrca.UnidadeOrcamentaria.ID := aUnidadeOrca.ID;

      if not dmConexaoTargetDB.InserirSubUnidadeOrcament(aSubUnidadeOrca) then
        gLogImportacao.Add(TCheckBox(Sender).Caption + ' - (SUB) ' +
          QuotedStr(aSubUnidadeOrca.Codigo + ' - ' + aSubUnidadeOrca.Descricao) + ' n�o importado');

      lblAndamento.Caption  := Trim(qrySourceDB.FieldByName('descricao').AsString);
      prbAndamento.Position := prbAndamento.Position + 1;

      Application.ProcessMessages;
      qrySourceDB.Next;
    end;

    UpdateGenerators;
  finally
    dmRecursos.ExibriLog;

    if qrySourceDB.Active then
      qrySourceDB.Close;
    if (Sender is TCheckBox) then
      TCheckBox(Sender).Checked := False;
  end;
end;

procedure TfrmSourceDBLayoutFB.ListarCompetenciasLayoutFB;
var
  I   ,
  idx ,
  mes ,
  ano : Integer;
  obj : TGenerico;
  aStr        ,
  aPrefixo    ,
  aTableName  : String;
  aTabelas    ,
  aListaMeses : TStringList;
begin
  aTabelas := TStringList.Create;
  aListaMeses := TStringList.Create;
  try
    try
      if not fdSourceDB.Connected then
        Abort;

      fdSourceDB.GetTableNames('', '', '', aTabelas);

      aPrefixo := 'SFP001'; // Servidor P�blico

      aListaMeses.BeginUpdate;
      aListaMeses.Clear;

      for I := 0 to aTabelas.Count - 1 do
      begin
        aTableName := aTabelas[I];

        if (Copy(aTableName, 1, 6) = aPrefixo) then
        begin
               if (aTableName = aPrefixo + 'JAN') then aListaMeses.Add('01-JAN-JANEIRO')
          else if (aTableName = aPrefixo + 'FEV') then aListaMeses.Add('02-FEV-FEVEREIRO')
          else if (aTableName = aPrefixo + 'MAR') then aListaMeses.Add('03-MAR-MAR�O')
          else if (aTableName = aPrefixo + 'ABR') then aListaMeses.Add('04-ABR-ABRIL')
          else if (aTableName = aPrefixo + 'MAI') then aListaMeses.Add('05-MAI-MAIO')
          else if (aTableName = aPrefixo + 'JUN') then aListaMeses.Add('06-JUN-JUNHO')
          else if (aTableName = aPrefixo + 'JUL') then aListaMeses.Add('07-JUL-JULHO')
          else if (aTableName = aPrefixo + 'AGO') then aListaMeses.Add('08-AGO-AGOSTO')
          else if (aTableName = aPrefixo + 'SET') then aListaMeses.Add('09-SET-SETEMBRO')
          else if (aTableName = aPrefixo + 'OUT') then aListaMeses.Add('10-OUT-OUTUBRO')
          else if (aTableName = aPrefixo + 'NOV') then aListaMeses.Add('11-NOV-NOVEMBRO')
          else if (aTableName = aPrefixo + 'DEZ') then aListaMeses.Add('12-DEZ-DEZEMBRO');
        end;
      end;

      aListaMeses.EndUpdate;
      aListaMeses.Sort();

      if qrySourceDB.Active then
        qrySourceDB.Close;

(*
Select distinct
    b.exercicio   as ano
  , b.competencia as mes
from BASES b
order by
    b.exercicio
  , b.competencia
*)
      qrySourceDB.SQL.Clear;
      qrySourceDB.SQL.Add('Select distinct     ');
      qrySourceDB.SQL.Add('  b.exercicio as ano');
      qrySourceDB.SQL.Add('from BASES b        ');
      qrySourceDB.SQL.Add('order by            ');
      qrySourceDB.SQL.Add('  b.exercicio       ');
      qrySourceDB.Open;
      qrySourceDB.Last;

      cmCompetencia.Clear;

      qrySourceDB.First;
      while not qrySourceDB.Eof do
      begin
        for I := 0 to aListaMeses.Count - 1 do
        begin
          aStr := Trim(aListaMeses.Strings[I]);

          if (aStr <> EmptyStr) then
          begin
            obj := TGenerico.Create;

            obj.ID        := StrToInt(Trim(qrySourceDB.FieldByName('ano').AsString) + Copy(aStr, 1, 2));
            obj.Codigo    := Copy(aStr, 1, 2) + Trim(qrySourceDB.FieldByName('ano').AsString);
            obj.Descricao := Copy(aStr, 1, 2) + '/' + Trim(qrySourceDB.FieldByName('ano').AsString);
            obj.Resumo    := Copy(aStr, 4, 3);

            cmCompetencia.AddItem(obj.Descricao, obj);
          end;
        end;

        qrySourceDB.Next;
      end;

      qrySourceDB.Close;

      cmCompetencia.ItemIndex := (cmCompetencia.Items.Count - 1);
    except
    end;
  finally
    aTabelas.Free;
    aListaMeses.Free;
  end;
end;

procedure TfrmSourceDBLayoutFB.mniEstadoFuncionalClick(Sender: TObject);
begin
  GravarIni;

  if not fdSourceDB.Connected then
    ConectarSourceDB;

  CriarCampoEstadoFuncional_Layout;
  ShowParametrizarEstadosFuncionais(Self,
    TGenerico(cmCompetencia.Items.Objects[cmCompetencia.ItemIndex]),
    'AFASTFOLHA',
    FCampoEstadoFuncionalRemunID,
    'Estados Funcionais');
end;

procedure TfrmSourceDBLayoutFB.mniEventoClick(Sender: TObject);
begin
  GravarIni;

  if not fdSourceDB.Connected then
    ConectarSourceDB;

  CriarCampoEvento_Layout;
  ShowParametrizarEventos(Self,
    TGenerico(cmCompetencia.Items.Objects[cmCompetencia.ItemIndex]),
    'SFP010',
    FCampoEventoRemunID,
    'Eventos');
end;

function TfrmSourceDBLayoutFB.RegistrarTabelaDB(aFileNameDB: String): String;
var
  vFileName,
  aReturno : String;
begin
  aReturno  := EmptyStr;
  vFileName := AnsiUpperCase(ExtractFileName(aFileNameDB));
  try
    with dmConexaoTargetDB, qryBusca do
    begin
      if not fdTargetDB.Connected then
        ConectarTargetDB;

      // Buscar registros
      Close;
      SQL.Clear;
      SQL.Add('SELECT ');
      SQL.Add('   x.LAYOUT_ID');
      SQL.Add('from ' + TBL_LAYOUT_IMPORT + ' x  ');
      SQL.Add('where upper(x.LAYOUT_DB) = upper(' + QuotedStr(vFileName) + ')' );
      OpenOrExecute;

      aReturno := Trim(FieldByName('LAYOUT_ID').AsString);

      // Inserir registro, caso ele n�o exista
      if (aReturno = EmptyStr) then
      begin
        try
          Close;
          SQL.Clear;
          SQL.Add('SELECT ');
          SQL.Add('   max(x.LAYOUT_ID) as ID');
          SQL.Add('from ' + TBL_LAYOUT_IMPORT + ' x ');
          OpenOrExecute;

          aReturno := FormatFloat('00', StrToIntDef(Trim(FieldByName('ID').AsString), 0) + 1);

          fdTargetDB.ExecSQL(
            'Insert Into ' + TBL_LAYOUT_IMPORT + ' (' +
            '    LAYOUT_ID ' +
            '  , LAYOUT_DB ' +
            ') values (' +
            '    ' + QuotedStr(aReturno) + ' ' +
            '  , ' + QuotedStr(vFileName) + ' ' +
            ')');

          fdTargetDB.CommitRetaining;
        except
        end;
      end;
      Close;
    end;
  finally
    dmConexaoTargetDB.qryBusca.Close;
    Result := aReturno;
  end;
end;

initialization
  gFormularios.RegisterForm('frmSourceDBLayoutFB', TfrmSourceDBLayoutFB);

end.
