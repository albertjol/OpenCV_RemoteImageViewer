program RemoteImageViewer;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, uRemoteImageViewer
  { you can add units after this };

{$R *.res}

begin
  {$if declared(UseHeapTrace)}
       GlobalSkipIfNoLeaks := True; // supported as of debugger version 3.2.0
  {$endIf}

  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TFrm_RemoteImageViewer, Frm_RemoteImageViewer);
  Application.Run;
end.

