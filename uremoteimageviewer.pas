unit uRemoteImageViewer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, Spin, blcksock, synsock;

type
  TJpegImageString = record
    image: AnsiString;
  end;
  PJpegImageString = ^TJpegImageString;

  { TServerThread }

  TServerThread = class(TThread)
    procedure Execute; override;
    constructor Create(CreateSuspended: Boolean; port: Integer);
    destructor Destroy; override;
  private
    FSocket: TTCPBlockSocket;
    FPort: Integer;
  public
    procedure WriteAsyncQueue(Data: PtrInt);

  end;

  { TFrm_RemoteImageViewer }

  TFrm_RemoteImageViewer = class(TForm)
    btn_StartServer: TButton;
    im_RemoteImage: TImage;
    lbl_Port: TLabel;
    ed_Port: TSpinEdit;
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
  pJpeg: PJpegImageString;
begin
  FSocket.CreateSocket();
  FSocket.Bind('0.0.0.0', IntToStr(FPort));
  FSocket.Listen();
  while ( not Terminated ) do
  begin
    acceptedSocket := FSocket.Accept();
    clientSocket := TTCPBlockSocket.Create();
    clientSocket.Socket:=acceptedSocket;
    try
      while ( (clientSocket.LastError = 0) and not Terminated) do
      begin
        New(pJpeg);
        pJpeg^.image := clientSocket.RecvTerminated(60000, AnsiString(#$FF#$D9));
        Application.QueueAsyncCall(@WriteAsyncQueue, NativeUInt(pJpeg));
      end;
      clientSocket.CloseSocket();
    finally
      FreeAndNil(clientSocket);
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
      stream.WriteBuffer(PAnsiChar(jpeg.image)^, Length(jpeg.image));
      stream.Position := 0;

      Frm_RemoteImageViewer.im_RemoteImage.Picture.LoadFromStream(stream);
    end;
  finally
    FreeAndNil(stream);
    Dispose(PJpegImageString(Data));
  end;
end;

constructor TServerThread.Create(CreateSuspended: Boolean; Port: Integer);
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
    FThread := TServerThread.Create(True, ed_Port.Value);
    FThread.FreeOnTerminate := True;
    FThread.Start();
    btn_StartServer.Caption := 'Stop Server';
  end
  else
  begin
    FThread.Terminate();
    FThread := nil;
    btn_StartServer.Caption := 'Start Server';
  end;
end;


end.

