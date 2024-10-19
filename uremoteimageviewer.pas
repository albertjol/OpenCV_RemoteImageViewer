unit uRemoteImageViewer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, Spin, ComCtrls, blcksock, synsock;

type
  TJpegImageString = record
    Image: AnsiString;
  end;
  PJpegImageString = ^TJpegImageString;

  TTextRecord = record
    Text: String;
  end;
  PTextRecord = ^TTextRecord;

  { TServerThread }

  TServerThread = class(TThread)
    procedure Execute; override;
    constructor Create(CreateSuspended: Boolean; port: Integer);
    destructor Destroy; override;
  private
    FSocket: TTCPBlockSocket;
    FPort: Integer;
    procedure WriteAsyncQueue(Data: PtrInt);
    procedure UpdateStatusBar(Text: String);
    procedure UpdateStatusBarCall(Data: PtrInt);
  public

  end;

  { TFrm_RemoteImageViewer }

  TFrm_RemoteImageViewer = class(TForm)
    btn_StartServer: TButton;
    im_RemoteImage: TImage;
    lbl_Port: TLabel;
    ed_Port: TSpinEdit;
    sb_Status: TStatusBar;
    procedure btn_StartServerClick(Sender: TObject);
  private
    FThread: TServerThread;
  public

  end;

var
  Frm_RemoteImageViewer: TFrm_RemoteImageViewer;

implementation

{$R *.lfm}

{ TServerThread }

procedure TServerThread.Execute;
var
  clientSocket: TTCPBlockSocket;
  acceptedSocket: TSocket;
  jpeg: AnsiString;
  pJpeg: PJpegImageString;
begin
  FSocket.CreateSocket();
  FSocket.Bind('0.0.0.0', IntToStr(FPort));
  FSocket.Listen();
  while ( not Terminated ) do
  begin
    acceptedSocket := FSocket.Accept();
    if (FSocket.LastError = 0) then
    begin
      UpdateStatusBar('Connection established');
      clientSocket := TTCPBlockSocket.Create();
      clientSocket.Socket:=acceptedSocket;
      try
        while ( (clientSocket.LastError = 0) and not Terminated) do
        begin
          jpeg := clientSocket.RecvTerminated(60000, AnsiString(#$FF#$D9));
          if ( (clientSocket.LastError = 0)
               and jpeg.StartsWith(AnsiString(#$FF#$D8))
               (* and jpeg.EndsWith(AnsiString(#$FF#$D9)) *) ) then
          begin
            New(pJpeg);
            pJpeg^.Image := jpeg + AnsiString(#$FF#$D9); // RecvTerminated strippes the terminator
            Application.QueueAsyncCall(@WriteAsyncQueue, NativeUInt(pJpeg));
          end;
        end;
        clientSocket.CloseSocket();
        UpdateStatusBar('Connection Closed');
      finally
        FreeAndNil(clientSocket);
      end;
    end;
  end;
  FSocket.CloseSocket();
end;

procedure TServerThread.WriteAsyncQueue(Data: PtrInt);
var // called from main thread after all other messages have been processed to allow thread safe TMemo access
  jpeg: TJpegImageString;
  stream: TMemoryStream;
begin
  jpeg := PJpegImageString(Data)^;
  stream := TMemoryStream.Create();
  try
    if (Frm_RemoteImageViewer.im_RemoteImage <> nil) and (not Application.Terminated) then
    begin
      stream.WriteBuffer(PAnsiChar(jpeg.Image)^, Length(jpeg.Image));
      stream.Position := 0;

      Frm_RemoteImageViewer.im_RemoteImage.Picture.LoadFromStream(stream);
    end;
  finally
    FreeAndNil(stream);
    Dispose(PJpegImageString(Data));
  end;
end;

procedure TServerThread.UpdateStatusBar(Text: String);
var
  pStr: PTextRecord;
begin
  New(pStr);
  pStr^.Text := Text;
  Application.QueueAsyncCall(@UpdateStatusBarCall, NativeUInt(pStr));
end;

procedure TServerThread.UpdateStatusBarCall(Data: PtrInt);
var
  textToDisplay: String;
begin
  textToDisplay := PTextRecord(Data)^.Text;
  try
    if (not Application.Terminated
       and Assigned(Frm_RemoteImageViewer)
       and Assigned(Frm_RemoteImageViewer.sb_Status)
       and Assigned(Frm_RemoteImageViewer.sb_Status.Panels)
       and Assigned(Frm_RemoteImageViewer.sb_Status.Panels[0]))
     then
    begin
      Frm_RemoteImageViewer.sb_Status.Panels[0].Text := textToDisplay;
    end;
  finally
    Dispose(PTextRecord(Data));
  end;
end;

constructor TServerThread.Create(CreateSuspended: Boolean; port: Integer);
begin
  inherited Create(CreateSuspended);
  FPort := Port;
  FSocket := TTCPBlockSocket.Create();
end;

destructor TServerThread.Destroy;
begin
  FreeAndNil(FSocket);
  inherited Destroy;
end;

{ TFrm_RemoteImageViewer }


procedure TFrm_RemoteImageViewer.btn_StartServerClick(Sender: TObject);
begin
  if not Assigned(FThread) then
  begin
    sb_Status.Panels[0].Text := 'Waiting for connection';
    FThread := TServerThread.Create(True, ed_Port.Value);
    FThread.FreeOnTerminate := True;
    FThread.Start();
    btn_StartServer.Caption := 'Stop Server';
  end
  else
  begin
    sb_Status.Panels[0].Text := 'Stopping connection';
    FThread.Terminate();
    FThread := nil;
    btn_StartServer.Caption := 'Start Server';
  end;
end;


end.

