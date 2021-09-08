unit uMain;

{$MODE Delphi}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls,
  ShellAPI, LCLType,
  Menus;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    ApplicationProperties1: TApplicationProperties;
    btnFileActions: TButton;
    btnTruncate: TMenuItem;
    btnShow: TMenuItem;
    btnOpenFile: TMenuItem;
    btnExit2: TMenuItem;
    MenuItem1: TMenuItem;
    chkSendTo: TMenuItem;
    chkClipboard: TMenuItem;
    btnGithub: TMenuItem;
    MenuItem2: TMenuItem;
    chkCollectAll: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    chkCollectFiles: TMenuItem;
    chkCollectDirectories: TMenuItem;
    pnlDrop: TPanel;
    edtOutputPath: TEdit;
    btnSelectOutput2: TButton;
    lbl1: TLabel;
    mm1: TMainMenu;
    File1: TMenuItem;
    btnExit: TMenuItem;
    btnSelectoutput: TMenuItem;
    N1: TMenuItem;
    pmFile: TPopupMenu;
    pmTray: TPopupMenu;
    SaveDialog1: TSaveDialog;
    Settings1: TMenuItem;
    chkSkipDuplicates: TMenuItem;
    chkAlwaysOnTop: TMenuItem;
    chkOutputAppend: TMenuItem;
    chkRecurseDirectories: TMenuItem;
    Help1: TMenuItem;
    btnAbout: TMenuItem;
    btnDonationCoder: TMenuItem;
    N2: TMenuItem;
    Output1: TMenuItem;
    chkOutputTruncate: TMenuItem;
    TrayIcon1: TTrayIcon;
    Window1: TMenuItem;
    chkMinimizeToTray: TMenuItem;
    lblLineCount: TLabel;
    procedure btnAboutClick(Sender: TObject);
    procedure ApplicationProperties1Deactivate(Sender: TObject);
    procedure btnDonationCoderClick(Sender: TObject);
    procedure btnFileActionsClick(Sender: TObject);
    procedure btnGithubClick(Sender: TObject);
    procedure btnOpenFileClick(Sender: TObject);
    procedure btnShowClick(Sender: TObject);
    procedure btnTruncateClick(Sender: TObject);
    procedure chkSendToClick(Sender: TObject);
    procedure edtOutputPathExit(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnSelectOutputClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure chkAlwaysOnTopClick(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    procedure FormWindowStateChange(Sender: TObject);
  private
    fFile: TextFile;
    fNextClipWnd: HWND;
    fClipDiscart: Boolean;
    fPathList: TStringList;
    fPnlDropPrevWndProc: LONG_PTR;
    fEdtOutputPrevWndProc: LONG_PTR;
    fUnqInstFile: HANDLE;
    fSendToLinkPath: string;
    fWorkingFile: string;

    function WMDropFiles(aDrop: WPARAM): LRESULT;// message WM_DROPFILES;
    function WMChangeCBChain(aRemoved: HWND; aNext: HWND): LRESULT;// message WM_CHANGECBCHAIN;
    function WMDrawClipboard: LRESULT;// message WM_DRAWCLIPBOARD;
    function WMCopyData(aCopyData: PCOPYDATASTRUCT): LRESULT;// message WM_COPYDATA;

    procedure ProcessFilesFromDrop(Drop: Cardinal);
    procedure ProcessFilesFromParams;
    //function GetFileList(const aDirPath: string): TStringDynArray;
    procedure UpdateForm;
    function RegisterUniqueInstance: Boolean;
    procedure HandleAlwaysOnTopOption;
    procedure CalculateSendToLinkPath;
  public
    procedure LoadSettings;
    procedure SaveSettings;
    procedure ProcessPaths(const aPaths: array of string);
    procedure AppendPaths(const aPathList: TStrings);
    procedure SetOutput(const aFilePath: string);
  end;

var
  frmMain: TfrmMain;

implementation

uses
  StrUtils, Types, ShlObj, ComObj, ActiveX,
  FileUtil,
  uAbout;

{$R *.lfm}

function pnlDropWndCallback(aHwnd: HWND; aMsg: UINT; aWParam: WParam;
  aLParam: LParam): LRESULT; stdcall;
begin
  case aMsg of
  WM_DROPFILES: Result:= frmMain.WMDropFiles(aWParam);
  WM_CHANGECBCHAIN: Result:= frmMain.WMChangeCBChain(aWParam, aLParam);
  WM_DRAWCLIPBOARD: Result:= frmMain.WMDrawClipboard;
  WM_COPYDATA: Result:= frmMain.WMCopyData(PCOPYDATASTRUCT(aLParam));
  else     
  Result := CallWindowProc(WNDPROC(frmMain.fPnlDropPrevWndProc), aHwnd, aMsg, aWParam, aLParam);
  end;
end;

function edtOutputWndCallback(aHwnd: HWND; aMsg: UINT; aWParam: WParam;
  aLParam: LParam): LRESULT; stdcall;
var
  PathLength: Cardinal;
  Path: string;
begin
  if aMsg <> WM_DROPFILES then
  begin
    Result := CallWindowProc(WNDPROC(frmMain.fEdtOutputPrevWndProc), aHwnd, aMsg, aWParam, aLParam);
    Exit;
  end;

  PathLength:= DragQueryFile(aWParam, 0, nil, 0);
  SetLength(Path, PathLength);
  DragQueryFile(aWParam, 0, @Path[1], PathLength + 1);
  frmMain.edtOutputPath.Text:= Path;

  Result:= 0;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  TrayIcon1.Icon:= Application.Icon;

  fPathList:= TStringList.Create;
  LoadSettings;

  fPnlDropPrevWndProc := SetWindowLongPtr(pnlDrop.Handle, GWL_WNDPROC, LONG_PTR(@pnlDropWndCallback));
  fEdtOutputPrevWndProc := SetWindowLongPtr(edtOutputPath.Handle, GWL_WNDPROC, LONG_PTR(@edtOutputWndCallback));
         
  if not RegisterUniqueInstance then
    Exit;
                                
  SetOutput(edtOutputPath.Text);

  ProcessFilesFromParams;

  fClipDiscart:= True;
  fNextClipWnd:= SetClipboardViewer(pnlDrop.Handle);

  DragAcceptFiles(pnlDrop.Handle, True);
  DragAcceptFiles(edtOutputPath.Handle, True);
end;   

procedure TfrmMain.btnFileActionsClick(Sender: TObject);
var
  P: TPoint;
begin
  P:= btnFileActions.ClientToScreen(Point(0, btnFileActions.Height));
  pmFile.PopUp(P.X, P.Y);
end;

procedure TfrmMain.btnGithubClick(Sender: TObject);
begin
  ShellExecute(0, 'open', 'https://github.com/HwapX/dcPathCollector/', '', '', SWP_NOACTIVATE);
end;

procedure TfrmMain.ApplicationProperties1Deactivate(Sender: TObject);
begin
  //For some reason Lazarus LCL devs decided to remove TOPMOST attribute when
  //the window lose focus, this is a hack to add it again.
  if chkAlwaysOnTop.Checked then
    SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE);
end;

procedure TfrmMain.btnDonationCoderClick(Sender: TObject);
begin
  ShellExecute(0, 'open', 'https://www.donationcoder.com/', '', '', SW_SHOWDEFAULT);
end;

procedure TfrmMain.btnAboutClick(Sender: TObject);
begin
  with TfrmAbout.Create(Self) do
  begin
    ShowModal;
    Free;
  end;
end;

procedure TfrmMain.btnOpenFileClick(Sender: TObject);
begin
  //Open output file in default editor
  if edtOutputPath.Text <> '' then
    ShellExecute(0, 'open', PChar(edtOutputPath.Text), '', '', SW_SHOWDEFAULT);
end;

procedure TfrmMain.btnShowClick(Sender: TObject);
begin
  ShowOnTop;
end;

procedure TfrmMain.btnTruncateClick(Sender: TObject);
begin
  if fWorkingFile = '' then
    Exit;

  fPathList.Clear;
  Rewrite(fFile);

  UpdateForm;
end;

procedure TfrmMain.chkSendToClick(Sender: TObject);
procedure CreateLink;
var
  ShellLink : IShellLink;
begin
  ShellLink := CreateComObject(CLSID_ShellLink) as IShellLink;

  ShellLink.SetPath(PChar(Application.ExeName));
  ShellLink.SetWorkingDirectory(PChar(ExtractFilePath(Application.ExeName)));

  (ShellLink as IPersistFile).Save(PWideChar(WideString(fSendToLinkPath)), False);
end;

begin
  if chkSendTo.Checked then
    CreateLink
  else
    DeleteFile(fSendToLinkPath);
end;

procedure TfrmMain.edtOutputPathExit(Sender: TObject);
begin
  SetOutput(edtOutputPath.Text);
end;

procedure TfrmMain.btnSelectOutputClick(Sender: TObject);
begin
  SaveDialog1.FileName:= edtOutputPath.Text;

  if chkOutputTruncate.Checked then
     SaveDialog1.Options:= SaveDialog1.Options + [ofOverwritePrompt]
  else
     SaveDialog1.Options:= SaveDialog1.Options - [ofOverwritePrompt];

  if not SaveDialog1.Execute then
    Exit;

  edtOutputPath.Text:= SaveDialog1.FileName;
  SetOutput(edtOutputPath.Text);
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  CloseHandle(fUnqInstFile);

  DragAcceptFiles(pnlDrop.Handle, False);
  DragAcceptFiles(edtOutputPath.Handle, False);

  ChangeClipboardChain(Handle, fNextClipWnd);

  SaveSettings;
                 
  fPathList.Free;

  if fWorkingFile <> '' then
    CloseFile(fFile);
end;

procedure TfrmMain.AppendPaths(const aPathList: TStrings);
var
  Path: string;
  UpperPath: string;
  I: Integer;
  PrevCount: Integer;
begin     
  if fWorkingFile = '' then
  begin
    TrayIcon1.BalloonFlags:= bfError;
    TrayIcon1.BalloonHint:= 'No output file selected.';
    TrayIcon1.ShowBalloonHint;
    Exit;
  end;

  PrevCount:= fPathList.Count;

  for I:= 0 to aPathList.Count - 1 do
  begin
    Path:= aPathList[I];
    UpperPath:= AnsiUpperCase(Path);

    if chkSkipDuplicates.Checked and (fPathList.IndexOf(UpperPath) <> -1) then
      continue;

    fPathList.Append(UpperPath);

    WriteLn(fFile, Path);
  end;

  Flush(fFile);

  UpdateForm;
                      
  TrayIcon1.BalloonFlags:= bfInfo;
  TrayIcon1.BalloonHint:= IntToStr(fPathList.Count - PrevCount) + ' paths collected.';
  TrayIcon1.ShowBalloonHint;
end;

procedure TfrmMain.SetOutput(const aFilePath: string);
begin
  if aFilePath = fWorkingFile then
    Exit;

  //if some file is already opened, close it
  if fWorkingFile <> '' then
  begin
    CloseFile(fFile);
    fPathList.Clear;

    fWorkingFile:= '';
  end;

  //if no file is informed then stop here
  if aFilePath = '' then
  begin
    UpdateForm;
    Exit;
  end;

  AssignFile(fFile, aFilePath);

  if chkOutputTruncate.Checked or not FileExists(aFilePath) then
  begin
    Rewrite(fFile);
  end
  else
  begin
    fPathList.LoadFromFile(aFilePath);
    fPathList.Text:= AnsiUpperCase(fPathList.Text);

    Append(fFile);
  end; 

  fWorkingFile:= aFilePath;

  UpdateForm;
end;

procedure TfrmMain.LoadSettings;
var
  Settings: TStringList;
  ConfigPath: string;
  CollectFiles: Boolean;
  CollectDirectories: Boolean;
begin
  CalculateSendToLinkPath;

  chkSendTo.Checked:= FileExists(fSendToLinkPath);

  ConfigPath:= ChangeFileExt(Application.ExeName, '.cfg');

  Settings:= TStringList.Create;
  try                              
    if FileExists(ConfigPath) then
      Settings.LoadFromFile(ConfigPath);

    edtOutputPath.Text:= Settings.Values['OUTPUT_PATH'];                           
    chkOutputTruncate.Checked:= StrToBoolDef(Settings.Values['OUTPUT_TRUNCATE'], False);
    chkOutputAppend.Checked:= not chkOutputTruncate.Checked;

    chkRecurseDirectories.Checked:= StrToBoolDef(Settings.Values['RECURSE_DIRECTORIES'], False);
    chkSkipDuplicates.Checked:= StrToBoolDef(Settings.Values['SKIP_DUPLICATES'], True);

    CollectFiles:= StrToBoolDef(Settings.Values['COLLECT_FILES'], True);
    CollectDirectories:= StrToBoolDef(Settings.Values['COLLECT_DIRECTORIES'], True);

    chkCollectAll.Checked:= CollectFiles = CollectDirectories;
    if not chkCollectAll.Checked then
    begin
      chkCollectFiles.Checked:= CollectFiles;
      chkCollectDirectories.Checked:= CollectDirectories;
    end;

    chkClipboard.Checked:= StrToBoolDef(Settings.Values['MONITOR_CLIPBOARD'], False);

    chkAlwaysOnTop.Checked:= StrToBoolDef(Settings.Values['ALWAYS_ON_TOP'], False);
    chkMinimizeToTray.Checked:= StrToBoolDef(Settings.Values['MINIMIZE_TO_TRAY'], False);

    Width:= StrToIntDef(Settings.Values['WINDOW_WIDTH'], Width);
    Height:= StrToIntDef(Settings.Values['WINDOW_HEIGHT'], Height);
    Top:= StrToIntDef(Settings.Values['WINDOW_TOP'], (Monitor.Height - Height) div 2);
    Left:= StrToIntDef(Settings.Values['WINDOW_LEFT'], (Monitor.Width - Width) div 2);
  finally
    Settings.Free;
  end;

  HandleAlwaysOnTopOption;
end;

procedure TfrmMain.SaveSettings;
var
  Settings: TStringList;
begin
  Settings:= TStringList.Create;
  try
    Settings.Values['OUTPUT_PATH']:= edtOutputPath.Text;                
    Settings.Values['OUTPUT_TRUNCATE']:= BoolToStr(chkOutputTruncate.Checked);

    Settings.Values['RECURSE_DIRECTORIES']:= BoolToStr(chkRecurseDirectories.Checked);
    Settings.Values['SKIP_DUPLICATES']:= BoolToStr(chkSkipDuplicates.Checked);

    Settings.Values['COLLECT_FILES']:= BoolToStr(chkCollectAll.Checked or chkCollectFiles.Checked);
    Settings.Values['COLLECT_DIRECTORIES']:= BoolToStr(chkCollectAll.Checked or chkCollectDirectories.Checked);

    Settings.Values['MONITOR_CLIPBOARD']:= BoolToStr(chkClipboard.Checked);

    Settings.Values['ALWAYS_ON_TOP']:= BoolToStr(chkAlwaysOnTop.Checked);
    Settings.Values['MINIMIZE_TO_TRAY']:= BoolToStr(chkMinimizeToTray.Checked);

    Settings.Values['WINDOW_WIDTH']:= IntToStr(Width);
    Settings.Values['WINDOW_HEIGHT']:= IntToStr(Height);  
    Settings.Values['WINDOW_TOP']:= IntToStr(Top);
    Settings.Values['WINDOW_LEFT']:= IntToStr(Left);

    Settings.SaveToFile(ChangeFileExt(Application.ExeName, '.cfg'));
  finally
    Settings.Free;
  end;
end;

//https://docs.microsoft.com/en-us/windows/win32/shell/wm-dropfiles
function TfrmMain.WMDropFiles(aDrop: WPARAM): LRESULT;
begin        
  Result:= 1;

  ProcessFilesFromDrop(aDrop);
end;

procedure TfrmMain.chkAlwaysOnTopClick(Sender: TObject);
begin
  HandleAlwaysOnTopOption;
end;

procedure TfrmMain.btnExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.FormWindowStateChange(Sender: TObject);
begin
  if chkMinimizeToTray.Checked and (WindowState = wsMinimized) then
    Hide;
end;

//https://docs.microsoft.com/en-us/windows/win32/dataxchg/wm-changecbchain
function TfrmMain.WMChangeCBChain(aRemoved: HWND; aNext: HWND): LRESULT;
begin
  Result:= 0;

  if aRemoved = fNextClipWnd then
    fNextClipWnd:= aNext
  else
    Result:= SendMessage(fNextClipWnd, WM_CHANGECBCHAIN, aRemoved, aNext);
end;

//https://docs.microsoft.com/en-us/windows/win32/dataxchg/wm-drawclipboard
function TfrmMain.WMDrawClipboard: LRESULT;
var
  ClipDrop: Cardinal;
begin
  Result:= 1;

  //SetClipboardViewer imediatly send one message with current clipboard contents
  //that content do not interest us, so that flag discart it.
  if fClipDiscart then
  begin
    fClipDiscart:= False;
    Exit;
  end;

  //If not monitoring stop here
  if not chkClipboard.Checked then
    Exit;

  OpenClipboard(Handle);

  ClipDrop:= GetClipboardData(CF_HDROP);

  //if clipboard has some valid data, process it
  if ClipDrop <> 0 then
    ProcessFilesFromDrop(ClipDrop);

  CloseClipboard;

  Result:= 1;
end;

//Handle paths sent from other instances
//https://docs.microsoft.com/en-us/windows/win32/dataxchg/wm-copydata
function TfrmMain.WMCopyData(aCopyData: PCOPYDATASTRUCT): LRESULT;
begin
  Result:= 1;

  //If msg is empty show app window
  if aCopyData^.lpData = nil then
  begin
    ShowOnTop;
    Exit;
  end;

  //Otherwise extract the paths from message
  ProcessPaths(SplitString(PChar(aCopyData^.lpData), '|'));
end;

procedure TfrmMain.ProcessFilesFromDrop(Drop: Cardinal);
var
  PathCount: Cardinal;
  Paths: TStringDynArray;
  PathLength: Cardinal;
  I: Cardinal;
begin
  //https://docs.microsoft.com/en-us/windows/win32/api/shellapi/nf-shellapi-dragqueryfilea
  PathCount:= DragQueryFile(Drop, $FFFFFFFF, nil, 0);

  SetLength(Paths, PathCount);

  for I:= 0 to PathCount - 1 do
  begin
    PathLength:= DragQueryFile(Drop, I, nil, 0);
    SetLength(Paths[I], PathLength);
    DragQueryFile(Drop, I, @Paths[I][1], PathLength + 1);
  end;

  ProcessPaths(Paths);
end;

procedure TfrmMain.ProcessFilesFromParams;
var
  I: Integer;
  Paths: TStringDynArray;
begin
  if ParamCount = 0 then
    Exit;

  SetLength(Paths, ParamCount);

  for I:= 1 to ParamCount do
    Paths[I - 1]:= ParamStr(I);

  ProcessPaths(Paths);
end;

procedure TfrmMain.UpdateForm;
begin
  if fWorkingFile = '' then
    lblLineCount.Caption:= 'No file selected'
  else if fPathList.Count = 1 then
    lblLineCount.Caption:= '1 line'
  else
    lblLineCount.Caption:= IntToStr(fPathList.Count) + ' lines';
end;

function TfrmMain.RegisterUniqueInstance: Boolean;
var
  WndPtr: PHANDLE;
  CopyData: COPYDATASTRUCT;
  Paths: string;
  I: Integer;
begin
  Result:= False;

  //Open app universal file mapping
  fUnqInstFile:= CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0, SizeOf(HWND), 'Local\HwapX.DC.PathCollector');

  WndPtr:= MapViewOfFile(fUnqInstFile, FILE_MAP_ALL_ACCESS, 0, 0, SizeOf(HWND));

  //Check if it contains any window handle, if not write this instance handle
  if WndPtr^ = 0 then
  begin
    WndPtr^:= pnlDrop.Handle;
    Exit(True);
  end;

  //Otherwise format params and send it to be processed by the other instance window
  for I:= 1 to ParamCount do
    if I = 1 then
      Paths:= ParamStr(I)
    else
      Paths:= Paths + '|' + ParamStr(I);

  CopyData.cbData:= Length(Paths) * SizeOf(Char);
  CopyData.lpData:= @Paths[1];

  SendMessage(WndPtr^, WM_COPYDATA, Handle, LPARAM(@CopyData));

  UnmapViewOfFile(WndPtr);

  Application.ShowMainForm:= False;
  Application.Terminate;
end;

procedure TfrmMain.HandleAlwaysOnTopOption;
begin
  if chkAlwaysOnTop.Checked then
    FormStyle:= fsStayOnTop
  else
    FormStyle:= fsNormal;
end;

procedure TfrmMain.CalculateSendToLinkPath;
var
  SendToPath: string;
  ItemIDList: PItemIDList;
begin
  SetLength(SendToPath, MAX_PATH);

  if (SHGetSpecialFolderLocation(0, CSIDL_SENDTO, ItemIDList) <> S_OK) or
    not SHGetPathFromIDList(ItemIdList, PChar(SendToPath)) then
  begin
    chkSendTo.Enabled:= False;

    //MessageDlg('Failed to get Send to directory, this function will be unavailable.', mtWarning, [mbOK], 0);
    Exit;
  end;

  ILFree(ItemIDList);

  SetLength(SendToPath, StrLen(PChar(SendToPath)));

  fSendToLinkPath:= SendToPath + '\Path Collector.lnk';
end;

procedure TfrmMain.ProcessPaths(const aPaths: array of string);
var
  PathList: TStringList;
  Path: string;
  IsDir: Boolean;
  CollectFiles: Boolean;
  CollectDirectories: Boolean;
begin
  SetOutput(edtOutputPath.Text);

  TrayIcon1.BalloonFlags:= bfWarning;
  TrayIcon1.BalloonHint:= 'Collecting...';
  TrayIcon1.ShowBalloonHint;

  CollectFiles:= chkCollectAll.Checked or chkCollectFiles.Checked;
  CollectDirectories:= chkCollectAll.Checked or chkCollectDirectories.Checked;

  PathList:= TStringList.Create;

  try
    for Path in aPaths do
    begin
      IsDir:= DirectoryExists(Path);

      if (IsDir and CollectDirectories) or (not IsDir and CollectFiles) then
        PathList.Add(Path);

      if IsDir and chkRecurseDirectories.Checked then
      begin
        if CollectDirectories then
          FindAllDirectories(PathList, Path);

        if CollectFiles then
          FindAllFiles(PathList, Path);
      end;
    end;

    AppendPaths(PathList);
  finally
    PathList.Free;
  end;
end;

end.
