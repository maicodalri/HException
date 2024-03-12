unit EH.Generic;

interface

uses
  System.SysUtils, System.IOUtils, System.DateUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.DBCtrls,
  Tlhelp32, System.Types, Winapi.Windows, System.Win.Registry, Vcl.Imaging.jpeg,
  FastMMMemLeakMonitor;

type

  TMyOnExceptionHandler = class
  private
    class var FLogProcess: boolean;
    class var FMyOnExceptionHandler: TMyOnExceptionHandler;
    function GetFileLogName: string;
  public
    procedure OnException(Sender: TObject; E: Exception);
    constructor Create(const ALogPocess: Boolean = True);
    class property LogProcess: boolean read FLogProcess write FLogProcess;
    class function GetInstance: TMyOnExceptionHandler;
    class destructor ClassDestructor;
  end;

implementation

{ TMyOnExceptionHandler }

class destructor TMyOnExceptionHandler.ClassDestructor;
begin
  if Assigned(FMyOnExceptionHandler) then
    FMyOnExceptionHandler.Free;
end;

constructor TMyOnExceptionHandler.Create(const ALogPocess: Boolean);
begin
  TMyOnExceptionHandler.LogProcess:= ALogPocess;
end;

function TMyOnExceptionHandler.GetFileLogName: string;
var
  lLocalPath, lFileName: string;
begin
  lFileName:= 'Day_' + DayOf(Now).ToString + '_' + ExtractFileName(ParamStr(0));
  lFileName:= ChangeFileExt(ExtractFileName(lFileName), '.log');
  lLocalPath:= TPath.Combine(ExtractFilePath(ParamStr(0)), 'LocalLog');
  lLocalPath:= TPath.Combine(lLocalPath, 'Year_' + YearOf(Now).ToString);
  lLocalPath:= TPath.Combine(lLocalPath, 'Month_' + MonthOf(Now).ToString);
  ForceDirectories(lLocalPath);
  Result:= TPath.Combine(lLocalPath, lFileName);
end;

class function TMyOnExceptionHandler.GetInstance: TMyOnExceptionHandler;
begin
  if not Assigned(FMyOnExceptionHandler) then
    FMyOnExceptionHandler:= TMyOnExceptionHandler.Create;
  Result:= FMyOnExceptionHandler;
end;

procedure TMyOnExceptionHandler.OnException(Sender: TObject; E: Exception);
var
  lFile: TStringList;
  lFileName: string;

  function WindowsUpTime: string;
  var
    count,days,min,hours,seconds: Longint;
  begin
    Count := GetTickCount();
    Count := Count div 1000;
    Days  := Count div (24 * 3600);
    if Days > 0 then Count := Count - (24 * 3600 * Days);
      Hours := Count div 3600;
    If Hours > 0 Then Count := Count - (3600 * Hours);
      Min := Count div 60;
    Seconds := Count Mod 60;
    Result := IntToStr(Days) + ' dias '    + IntToStr(Hours  ) + ' horas ' +
              IntToStr(Min ) + ' minutos ' + IntToStr(seconds) +' segundos ';
  end;

  procedure LocalLog(const AMsg: string);
  begin
    lFile.Add(AMsg);
  end;

  function LogProgramasAtivos: string;
  const
    PROCESS_TERMINATE = $0001;
  var
    LCount: Integer;
    lListaProcessos: TStringList;
    ContinueLoop: Boolean;
    FSnapshotHandle: THandle;
    FProcessEntry32: TProcessEntry32;
  begin
    lListaProcessos:= TStringList.Create;
    try
      FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
      FProcessEntry32.dwSize := sizeof(FProcessEntry32);
      ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);
      while Integer(ContinueLoop) <> 0 do
      begin
        lListaProcessos.Add(FProcessEntry32.szExeFile);
        ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
      end;
      CloseHandle(FSnapshotHandle);

      for LCount := 0 to Pred(lListaProcessos.Count) do
      begin
        Result:= Result + ' ' + '[' + lListaProcessos.Strings[lCount] + ']';
        if (lCount mod 10) = 0 then
          Result:= Result + sLineBreak;
      end;


    finally
      lListaProcessos.Free;
    end;
  end;

  function ObterNomeUsuario: string;
  var
    Size: DWord;
  begin
    Size := 1024;
    SetLength(result, Size);
    GetUserName(PChar(result), Size);
    SetLength(result, Size - 1);
  end;

  function ObterVersaoWindows: string;
  var
    vNome,
    vVersao,
    vCurrentBuild: String;
    Reg: TRegistry;
  begin
    Reg         := TRegistry.Create; //Criando um Registro na Memória
    try
      Reg.Access  := KEY_READ; //Colocando nosso Registro em modo Leitura
      Reg.RootKey := HKEY_LOCAL_MACHINE; //Definindo a Raiz

      //Abrindo a chave desejada
      Reg.OpenKey('\SOFTWARE\Microsoft\Windows NT\CurrentVersion\', true);

      //Obtendo os Parâmetros desejados
      vNome         := Reg.ReadString('ProductName');
      vVersao       := Reg.ReadString('CurrentVersion');
      vCurrentBuild := Reg.ReadString('CurrentBuild');

      //Montando uma String com a Versão e alguns detalhes
      Result := vNome + ' - ' + vVersao + ' - ' + vCurrentBuild;
    finally
      Reg.Free;
    end;
  end;

  function PrintFormAtivo: string;
  var
    lImage: TJPEGImage;
  begin
    Result:= ExtractFilePath(GetFileLogName);
    Result:= TPath.Combine(Result, FormatDateTime('hhmmssnn', Now) + '.jpg');
    lImage:= TJPEGImage.Create;
    try
      lImage.Assign(Screen.ActiveForm.GetFormImage);
      lImage.SaveToFile(Result);
    finally
      lImage.Free;
    end;
  end;

  function MemoriaUtilizada: string;
  var
    Estado: TMemoryManagerState;
    Bytes: Integer;
    I: Integer;
  begin
    Bytes := 0;
    {$WARN SYMBOL_PLATFORM OFF}
    GetMemoryManagerState(Estado);

    for I := 0 to High(Estado.SmallBlockTypeStates) do
      Inc(Bytes, Estado.SmallBlockTypeStates[I].AllocatedBlockCount * Estado.SmallBlockTypeStates[I].UseableBlockSize);

    Inc(Bytes, Estado.TotalAllocatedMediumBlockSize);
    Inc(Bytes, Estado.TotalAllocatedLargeBlockSize);
    Result:= FormatFloat('0.00', (Bytes / 1024)/1024) + ' MB';
  end;

begin
  lFileName:= GetFileLogName;
  lFile:= TStringList.Create;
  try
    if FileExists(lFileName) then
      lFile.LoadFromFile(lFileName);

    LocalLog('+----------------------------------------------------------+');
    LocalLog('    Exceção no sistema encontrada   ' + DateTimeToStr(Now));
    LocalLog('    ===================================================');
    LocalLog('Classe Exceção...........: ' + E.ClassName);
    LocalLog('Formulário...............: ' + Screen.ActiveForm.Name);
    LocalLog('Título do Formulário.....: ' + Screen.ActiveForm.Caption);
    LocalLog('Unit.....................: ' + Sender.UnitName);
    LocalLog('Controle Visual..........: ' + Screen.ActiveControl.Name);
    LocalLog('Mensagem.................: ' + E.Message);
    LocalLog('Aplicativo...............: ' + ParamStr(0));
    LocalLog('Data/Hora do Aplicativo..: ' + DateTimeToStr(FileDateToDateTime(FileAge(ParamStr(0)))));
    LocalLog('Memória Utilizada........: ' + MemoriaUtilizada);
    LocalLog('Usuário do Windows.......: ' + ObterNomeUsuario);
    LocalLog('Versão Windows...........: ' + ObterVersaoWindows);
    LocalLog('Print do Form Ativo......: ' + PrintFormAtivo);
    LocalLog('Tempo do Windows Ativo...: ' + WindowsUpTime);
    if TMyOnExceptionHandler.LogProcess then
      LocalLog('Processos Rodando........: ' + LogProgramasAtivos);
    LocalLog('+----------------------------------------------------------+');

    lFile.SaveToFile(lFileName);

    Application.MessageBox(PWideChar(E.Message), 'Exceção Encontrada No Sistema', MB_OK + MB_ICONSTOP);

  finally
    lFile.Free;
  end;

end;

initialization
  Application.OnException:= TMyOnExceptionHandler.GetInstance.OnException;

end.
