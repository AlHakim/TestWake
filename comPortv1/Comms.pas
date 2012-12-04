// ------- this is a freeware --------
// TComPort component, version 1.0
//   for Delphi 2.0, 3.0, 4.0
// written by Dejan Crnila
//   email: emilija.crnila@guest.arnes.si
// ------- this is a freeware --------

unit Comms;

interface

uses
  Windows, Classes, SysUtils;

type
  TBaudRate = (br110, br300, br600, br1200, br2400, br4800, br9600,
               br14400, br19200, br38400, br56000, br57600, br115200);
  TPortType = (COM1, COM2, COM3, COM4);
  TStopBits = (sbOneStopBit, sbOne5StopBits, sbTwoStopBits);
  TParity = (prNone, prOdd, prEven, prMark, prSpace);
  TFlowControl = (fcNone, fcRtsCts, fcXonXoff);
  TEvent = (evRxChar, evTxEmpty, evRxFlag, evRing, evBreak, evCTS,
            evDSR, evError, evRLSD);
  TEvents = set of TEvent;

  TRxCharEvent = procedure(Sender: TObject; InQue: Integer) of object;

  TComPortV1 = class;

  TComThread = class(TThread)
  private
    Owner: TComPortV1;
    Mask: DWORD;
    StopEvent: THandle;
  protected
    procedure Execute; override;
    procedure DoEvents;
    procedure Stop;
  public
    constructor Create(AOwner: TComPortV1);
    destructor Destroy; override;
  end;

  TComPortV1 = class(TComponent)
  private
     fRdIntervalTimeout        : DWORD;
    fRdTotalTimeoutMultiplier : DWORD;
    fRdTotalTimeoutConstant   : DWORD;
    fWrTotalTimeoutMultiplier : DWORD;
    fWrTotalTimeoutConstant   : DWORD;

    ComHandle: THandle;
    EventThread: TComThread;
    FConnected: Boolean;
    FBaudRate: TBaudRate;
    FPortType: TPortType;
    FParity: TParity;
    FStopBits: TStopBits;
    FFlowControl: TFlowControl;
    FDataBits: Byte;
    FEvents: TEvents;
    FEnableDTR: Boolean;
    FWriteBufSize: Integer;
    FReadBufSize: Integer;
    FOnRxChar: TRxCharEvent;
    FOnTxEmpty: TNotifyEvent;
    FOnBreak: TNotifyEvent;
    FOnRing: TNotifyEvent;
    FOnCTS: TNotifyEvent;
    FOnDSR: TNotifyEvent;
    FOnRLSD: TNotifyEvent;
    FOnError: TNotifyEvent;
    FOnRxFlag: TNotifyEvent;
    FOnOpen: TNotifyEvent;
    FOnClose: TNotifyEvent;
    procedure SetDataBits(Value: Byte);
    procedure DoOnRxChar;
    procedure DoOnTxEmpty;
    procedure DoOnBreak;
    procedure DoOnRing;
    procedure DoOnRxFlag;
    procedure DoOnCTS;
    procedure DoOnDSR;
    procedure DoOnError;
    procedure DoOnRLSD;
  protected
    procedure CreateHandle;
    procedure DestroyHandle;
    procedure SetupState;
  public
    function ComString: String;
    property Connected: Boolean read FConnected;
    function ValidHandle: Boolean;
    procedure Open;
    procedure Close;
    function InQue: Integer;
    function OutQue: Integer;
    function ActiveCTS: Boolean;
    function Write(var Buffer; Count: Integer): Integer;
    function WriteString(Str: String): Integer;
    function Read(var Buffer; Count: Integer): Integer;
    function ReadString(var Str: String; Count: Integer): Integer;
    procedure PurgeIn;
    procedure PurgeOut;
    function GetComHandle: THandle;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property RdIntervalTimeout       : DWORD read fRdIntervalTimeout        write fRdIntervalTimeout;
    property RdTotalTimeoutMultiplier: DWORD read fRdTotalTimeoutMultiplier write fRdTotalTimeoutMultiplier;
    property RdTotalTimeoutConstant  : DWORD read fRdTotalTimeoutConstant   write fRdTotalTimeoutConstant;
    property WrTotalTimeoutMultiplier: DWORD read fWrTotalTimeoutMultiplier write fWrTotalTimeoutMultiplier;
    property WrTotalTimeoutConstant  : DWORD read fWrTotalTimeoutConstant   write fWrTotalTimeoutConstant;

    property BaudRate: TBaudRate read FBaudRate write FBaudRate;
    property Port: TPortType read FPortType write FPortType;
    property Parity: TParity read FParity write FParity;
    property StopBits: TStopBits read FStopBits write FStopBits;
    property FlowControl: TFlowControl read FFlowControl write FFlowControl;
    property DataBits: Byte read FDataBits write SetDataBits;
    property Events: TEvents read FEvents write FEvents;
    property EnableDTR: Boolean read FEnableDTR write FEnableDTR;
    property WriteBufSize: Integer read FWriteBufSize write FWriteBufSize;
    property ReadBufSize: Integer read FReadBufSize write FReadBufSize;
    property OnRxChar: TRxCharEvent read FOnRxChar write FOnRxChar;
    property OnTxEmpty: TNotifyEvent read FOnTxEmpty write FOnTxEmpty;
    property OnBreak: TNotifyEvent read FOnBreak write FOnBreak;
    property OnRing: TNotifyEvent read FOnRing write FOnRing;
    property OnCTS: TNotifyEvent read FOnCTS write FOnCTS;
    property OnDSR: TNotifyEvent read FOnDSR write FOnDSR;
    property OnRLSD: TNotifyEvent read FOnRLSD write FOnRLSD;
    property OnRxFlag: TNotifyEvent read FOnRxFlag write FOnRxFlag;
    property OnError: TNotifyEvent read FOnError write FOnError;
    property OnOpen: TNotifyEvent read FOnOpen write FOnOpen;
    property OnClose: TNotifyEvent read FOnClose write FOnClose;
  end;

  EComHandle = class(Exception);
  EComState  = class(Exception);
  EComWrite  = class(Exception);
  EComRead   = class(Exception);

const
  dcb_Binary           = $00000001;
  dcb_Parity           = $00000002;
  dcb_OutxCtsFlow      = $00000004;
  dcb_OutxDsrFlow      = $00000008;
  dcb_DtrControl       = $00000030;
  dcb_DsrSensivity     = $00000040;
  dcb_TXContinueOnXOff = $00000080;
  dcb_OutX             = $00000100;
  dcb_InX              = $00000200;
  dcb_ErrorChar        = $00000400;
  dcb_Null             = $00000800;
  dcb_RtsControl       = $00003000;
  dcb_AbortOnError     = $00004000;

function ShowPropForm(ComPort: TComPortV1): Boolean;
procedure Register;

implementation

uses DsgnIntf, CommForm, Controls;

type
  TComPortV1Editor = class(TComponentEditor)
  private
    procedure ExecuteVerb(Index: Integer); override;
    function GetVerb(Index: Integer): string; override;
    function GetVerbCount: Integer; override;
  end;

// Component code

function LastErr: String;
begin
  Result := IntToStr(GetLastError);
end;

constructor TComThread.Create(AOwner: TComPortV1);
var AMask: Integer;
begin
  inherited Create(True);
  StopEvent := CreateEvent(nil, True, False, nil);
  Owner := AOwner;
  AMask := 0;
  if evRxChar in Owner.FEvents then AMask := AMask or EV_RXCHAR;
  if evRxFlag in Owner.FEvents then AMask := AMask or EV_RXFLAG;
  if evTxEmpty in Owner.FEvents then AMask := AMask or EV_TXEMPTY;
  if evRing in Owner.FEvents then AMask := AMask or EV_RING;
  if evCTS in Owner.FEvents then AMask := AMask or EV_CTS;
  if evDSR in Owner.FEvents then AMask := AMask or EV_DSR;
  if evRLSD in Owner.FEvents then AMask := AMask or EV_RLSD;
  if evError in Owner.FEvents then AMask := AMask or EV_ERR;
  if evBreak in Owner.FEvents then AMask := AMask or EV_BREAK;
  SetCommMask(Owner.ComHandle, AMask);
  Resume;
end;

procedure TComThread.Execute;
var EventHandles: Array[0..1] of THandle;
    Overlapped: TOverlapped;
    dwSignaled, BytesTrans: DWORD;
begin
  FillChar(Overlapped, SizeOf(Overlapped), 0);
  Overlapped.hEvent := CreateEvent(nil, True, True, nil);
  EventHandles[0] := StopEvent;
  EventHandles[1] := Overlapped.hEvent;
  repeat
    WaitCommEvent(Owner.ComHandle, Mask, @Overlapped);
    dwSignaled := WaitForMultipleObjects(2, @EventHandles, False, INFINITE);
    case dwSignaled of
      WAIT_OBJECT_0:Break;
      WAIT_OBJECT_0 + 1: if GetOverlappedResult(Owner.ComHandle, Overlapped,
                              BytesTrans, False) then Synchronize(DoEvents);
      else Break;
    end;
  until False;
  PurgeComm(Owner.ComHandle, PURGE_RXCLEAR or PURGE_RXABORT);
  CloseHandle(Overlapped.hEvent);
  CloseHandle(StopEvent);
end;

procedure TComThread.Stop;
begin
  SetEvent(StopEvent);
end;

destructor TComThread.Destroy;
begin
  Stop;
  inherited Destroy;
end;

procedure TComThread.DoEvents;
begin
  if (EV_RXCHAR and Mask) > 0 then Owner.DoOnRxChar;
  if (EV_TXEMPTY and Mask) > 0 then Owner.DoOnTxEmpty;
  if (EV_BREAK and Mask) > 0 then Owner.DoOnBreak;
  if (EV_RING and Mask) > 0 then Owner.DoOnRing;
  if (EV_CTS and Mask) > 0 then Owner.DoOnCTS;
  if (EV_DSR and Mask) > 0 then Owner.DoOnDSR;
  if (EV_RXFLAG and Mask) > 0 then Owner.DoOnRxFlag;
  if (EV_RLSD and Mask) > 0 then Owner.DoOnRLSD;
  if (EV_ERR and Mask) > 0 then Owner.DoOnError;
end;

constructor TComPortV1.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FConnected := false;
  FBaudRate := br115200;
  FParity := prNone;
  FPortType := COM1;
  FStopBits := sbOneStopBit;
  FDataBits := 8;
  FEvents := [evRxChar, evTxEmpty, evRxFlag, evRing, evBreak,
             evCTS, evDSR, evError, evRLSD];
  FEnableDTR := True;
  FWriteBufSize := 2048;
  FReadBufSize := 2048;
  ComHandle := INVALID_HANDLE_VALUE;

  fRdIntervalTimeout        := 100;   //макс. врем€ между 2-м€ байтами
  fRdTotalTimeoutMultiplier := 0; //задает множитель, в миллисекундах, используемый дл€ вычислени€ общего тайм-аута операции чтени€. ƒл€
                                    //каждой операции чтени€ данное значение умножаетс€ на количество запрошеных дл€ чтени€ символов
  fRdTotalTimeoutConstant   := 1000;//«адает константу, в миллисекундах, используемую дл€ вычислени€ общего тайм-аута операции чтени€.
                                    //ƒл€ каждой операции чтени€ данное значение прибавл€етс€ к результату умножени€ ReadTotalTimeoutMultiplier
                                    //на количество запрошеных дл€ чтени€ символов. Ќулевое значение полей ReadTotalTimeoutMultiplier и
                                    //ReadTotalTimeoutConstant означает, что общий тайм-аут дл€ операции чтени€ не используетс€.
  fWrTotalTimeoutMultiplier:= 200;  //«адает множитель, в миллисекундах, используемый дл€ вычислени€ общего тайм-аута операции записи. ƒл€
                                    //каждой операции записи данное значение умножаетс€ на количество записываемых символов.
  fWrTotalTimeoutConstant  := 2000; //«адает константу, в миллисекундах, используемую дл€ вычислени€ общего тайм-аута операции записи. ƒл€
                                    //каждой операции записи данное значение прибавл€етс€ к результату умножени€ WriteTotalTimeoutMultiplier
                                    //на количество записываемых символов. Ќулевое значение полей WriteTotalTimeoutMultiplier и
                                    //WriteTotalTimeoutConstant означает, что общий тайм-аут дл€ операции записи не используетс€.
end;

destructor TComPortV1.Destroy;
begin
  Close;
  inherited Destroy;
end;

procedure TComPortV1.CreateHandle;
begin
  ComHandle := CreateFile(
    PChar(ComString),
    GENERIC_READ or GENERIC_WRITE,
    0,
    nil,
    OPEN_EXISTING,
    FILE_FLAG_OVERLAPPED,
    0);

  if not ValidHandle then
    raise EComHandle.Create('Unable to open com port: ' + LastErr);
end;

procedure TComPortV1.DestroyHandle;
begin
  if ValidHandle then
    CloseHandle(ComHandle);
end;

function TComPortV1.ValidHandle: Boolean;
begin
  if ComHandle = INVALID_HANDLE_VALUE then
    Result := False
  else
    Result := True;
end;

procedure TComPortV1.Open;
begin
  Close;
  CreateHandle;
  SetupState;
  EventThread := TComThread.Create(Self);
  FConnected := True;
  if Assigned(FOnOpen) then FOnOpen(Self);
end;

procedure TComPortV1.Close;
begin
  if FConnected then begin
    EventThread.Free;
    DestroyHandle;
    FConnected := False;
    if Assigned(FOnClose) then FOnClose(Self);
  end;
end;

procedure TComPortV1.SetupState;
var DCB: TDCB;
    Timeouts: TCommTimeouts;
begin
  FillChar(DCB, SizeOf(DCB), 0);
 // TCommFrm.
 // property Port: TPortType read FPortType write FPortType;
  DCB.DCBlength := SizeOf(DCB);
  DCB.XonChar := #17;
  DCB.XoffChar := #19;
  DCB.XonLim := FWriteBufSize div 4;
  DCB.XoffLim := 1;

  DCB.Flags := DCB.Flags or dcb_Binary;
  if FEnableDTR then
    DCB.Flags := DCB.Flags or (dcb_DtrControl and (DTR_CONTROL_ENABLE shl 4));

  case FFlowControl of
    fcRtsCts: begin
      DCB.Flags := DCB.Flags or dcb_OutxCtsFlow or
        (dcb_RtsControl and (RTS_CONTROL_HANDSHAKE shl 12));
    end;
    fcXonXoff: DCB.Flags := DCB.Flags or dcb_OutX or dcb_InX;
  end;

  case FParity of
    prNone:    DCB.Parity := NOPARITY;
    prOdd:   DCB.Parity := ODDPARITY;
    prEven:  DCB.Parity := EVENPARITY;
    prMark:  DCB.Parity := MARKPARITY;
    prSpace: DCB.Parity := SPACEPARITY;
  end;

  case FStopBits of
    sbOneStopBit:   DCB.StopBits := ONESTOPBIT;
    sbOne5StopBits: DCB.StopBits := ONE5STOPBITS;
    sbTwoStopBits:  DCB.StopBits := TWOSTOPBITS;
  end;

  case FBaudRate of
    br110:    DCB.BaudRate := CBR_110;
    br300:    DCB.BaudRate := CBR_300;
    br600:    DCB.BaudRate := CBR_600;
    br1200:   DCB.BaudRate := CBR_1200;
    br2400:   DCB.BaudRate := CBR_2400;
    br4800:   DCB.BaudRate := CBR_4800;
    br9600:   DCB.BaudRate := CBR_9600;
    br14400:  DCB.BaudRate := CBR_14400;
    br19200:  DCB.BaudRate := CBR_19200;
    br38400:  DCB.BaudRate := CBR_38400;
    br56000:  DCB.BaudRate := CBR_56000;
    br57600:  DCB.BaudRate := CBR_57600;
    br115200: DCB.BaudRate := CBR_115200;
  end;

  DCB.ByteSize := FDataBits;

  if not SetCommState(ComHandle, DCB) then
    raise EComState.Create('Unable to set com state: ' + LastErr);

  if not GetCommTimeouts(ComHandle, Timeouts) then
    raise EComState.Create('Unable to set com state: ' + LastErr);

//  Timeouts.ReadIntervalTimeout := MAXDWORD;
//  Timeouts.ReadTotalTimeoutMultiplier := 100;
//  Timeouts.ReadTotalTimeoutConstant := 0;
//  Timeouts.WriteTotalTimeoutMultiplier := 200;
//  Timeouts.WriteTotalTimeoutConstant := 1500;

    Timeouts.ReadIntervalTimeout        := fRdIntervalTimeout;
    Timeouts.ReadTotalTimeoutMultiplier := fRdTotalTimeoutMultiplier;
    Timeouts.ReadTotalTimeoutConstant   := fRdTotalTimeoutConstant;
    Timeouts.WriteTotalTimeoutMultiplier:= fWrTotalTimeoutMultiplier;
    Timeouts.WriteTotalTimeoutConstant  := fWrTotalTimeoutConstant;

  if not SetCommTimeouts(ComHandle, Timeouts) then
    raise EComState.Create('Unable to set com state: ' + LastErr);

  if not SetupComm(ComHandle, FReadBufSize, FWriteBufSize) then
    raise EComState.Create('Unable to set com state: ' + LastErr);
end;

function TComPortV1.InQue: Integer;
var Errors: DWORD;
    ComStat: TComStat;
begin
  ClearCommError(ComHandle, Errors, @ComStat);
  Result := ComStat.cbInQue;
end;

function TComPortV1.OutQue: Integer;
var Errors: DWORD;
    ComStat: TComStat;
begin
  ClearCommError(ComHandle, Errors, @ComStat);
  Result := ComStat.cbOutQue;
end;

function TComPortV1.ActiveCTS: Boolean;
var Errors: DWORD;
    ComStat: TComStat;
begin
  ClearCommError(ComHandle, Errors, @ComStat);
  Result := not (fCtlHold in ComStat.Flags);
end;

function TComPortV1.Write(var Buffer; Count: Integer): Integer;
var Overlapped: TOverlapped;
    BytesWritten: DWORD;
begin
  FillChar(Overlapped, SizeOf(Overlapped), 0);
  Overlapped.hEvent := CreateEvent(nil, True, True, nil);
  WriteFile(ComHandle, Buffer, Count, BytesWritten, @Overlapped);

  WaitForSingleObject(Overlapped.hEvent, INFINITE);
  if not GetOverlappedResult(ComHandle, Overlapped, BytesWritten, False) then
    raise EWriteError('Unable to write to port: ' + LastErr);
  CloseHandle(Overlapped.hEvent);
  Result := BytesWritten;
end;

function TComPortV1.WriteString(Str: String): Integer;
var Overlapped: TOverlapped;
    BytesWritten: DWORD;
begin
  FillChar(Overlapped, SizeOf(Overlapped), 0);
  Overlapped.hEvent := CreateEvent(nil, True, True, nil);
  WriteFile(ComHandle, Str[1], Length(Str), BytesWritten, @Overlapped);

  WaitForSingleObject(Overlapped.hEvent, INFINITE);
  if not GetOverlappedResult(ComHandle, Overlapped, BytesWritten, False) then
    raise EWriteError('Unable to write to port: ' + LastErr);
  CloseHandle(Overlapped.hEvent);
  Result := BytesWritten;
end;

function TComPortV1.Read(var Buffer; Count: Integer): Integer;
var Overlapped: TOverlapped;
    BytesRead: DWORD;
begin
  FillChar(Overlapped, SizeOf(Overlapped), 0);
  Overlapped.hEvent := CreateEvent(nil, True, True, nil);
  ReadFile(ComHandle, Buffer, Count, BytesRead, @Overlapped);
  WaitForSingleObject(Overlapped.hEvent, INFINITE);
  if not GetOverlappedResult(ComHandle, Overlapped, BytesRead, False) then
    raise EWriteError('Unable to write to port: ' + LastErr);
  CloseHandle(Overlapped.hEvent);
  Result := BytesRead;
end;

function TComPortV1.ReadString(var Str: String; Count: Integer): Integer;
var Overlapped: TOverlapped;
    BytesRead: DWORD;
begin
  SetLength(Str, Count);
  FillChar(Overlapped, SizeOf(Overlapped), 0);
  Overlapped.hEvent := CreateEvent(nil, True, True, nil);
  ReadFile(ComHandle, Str[1], Count, BytesRead, @Overlapped);
  WaitForSingleObject(Overlapped.hEvent, INFINITE);
  if not GetOverlappedResult(ComHandle, Overlapped, BytesRead, False) then
    raise EWriteError('Unable to write to port: ' + LastErr);
  CloseHandle(Overlapped.hEvent);
  SetLength(Str, BytesRead);
  Result := BytesRead;
end;

procedure TComPortV1.PurgeIn;
begin
  PurgeComm(ComHandle, PURGE_RXABORT or PURGE_RXCLEAR);
end;

procedure TComPortV1.PurgeOut;
begin
  PurgeComm(ComHandle, PURGE_TXABORT or PURGE_TXCLEAR);
end;

function TComPortV1.GetComHandle: THandle;
begin
  Result := ComHandle;
end;

procedure TComPortV1.SetDataBits(Value: Byte);
begin
  if Value <> FDataBits then
    if Value > 8 then FDataBits := 8 else
      if Value < 5 then FDataBits := 5 else
        FDataBits := Value;
end;

procedure TComPortV1.DoOnRxChar;
begin
  if Assigned(FOnRxChar) then FOnRxChar(Self, InQue);
end;

procedure TComPortV1.DoOnBreak;
begin
  if Assigned(FOnBreak) then FOnBreak(Self);
end;

procedure TComPortV1.DoOnRing;
begin
  if Assigned(FOnRing) then FOnRing(Self);
end;

procedure TComPortV1.DoOnTxEmpty;
begin
  if Assigned(FOnTxEmpty) then FOnTxEmpty(Self);
end;

procedure TComPortV1.DoOnCTS;
begin
  if Assigned(FOnCTS) then FOnCTS(Self);
end;

procedure TComPortV1.DoOnDSR;
begin
  if Assigned(FOnDSR) then FOnDSR(Self);
end;

procedure TComPortV1.DoOnRLSD;
begin
  if Assigned(FOnRLSD) then FOnRLSD(Self);
end;

procedure TComPortV1.DoOnError;
begin
  if Assigned(FOnError) then FOnError(Self);
end;

procedure TComPortV1.DoOnRxFlag;
begin
  if Assigned(FOnRxFlag) then FOnRxFlag(Self);
end;

function TComPortV1.ComString: String;
begin
  case FPortType of
    COM1: Result := 'COM1';
    COM2: Result := 'COM2';
    COM3: Result := 'COM3';
    COM4: Result := 'COM4';
  end;
end;

function ShowPropForm(ComPort: TComPortV1): Boolean;
begin
  with TCommFrm.Create(nil) do begin
    ComboBox1.ItemIndex := Integer(ComPort.Port);
    ComboBox2.ItemIndex := Integer(ComPort.BaudRate);
    ComboBox3.ItemIndex := Integer(ComPort.StopBits);
    ComboBox4.ItemIndex := ComPort.DataBits - 5;
    ComboBox5.ItemIndex := Integer(ComPort.Parity);
    ComboBox6.ItemIndex := Integer(ComPort.FlowControl);

    UpDown1.position := ComPort.RdIntervalTimeout;
    UpDown2.position := ComPort.RdTotalTimeoutMultiplier;
    UpDown3.position := ComPort.RdTotalTimeoutConstant;
    UpDown4.position := ComPort.WrTotalTimeoutMultiplier;
    UpDown5.position := ComPort.WrTotalTimeoutConstant;

    if ShowModal = mrOK then begin
        ComPort.Port := TPortType(ComboBox1.ItemIndex);
        ComPort.BaudRate := TBaudRate(ComboBox2.ItemIndex);
        ComPort.StopBits := TStopBits(ComboBox3.ItemIndex);
        ComPort.DataBits := ComboBox4.ItemIndex + 5;
        ComPort.Parity := TParity(ComboBox5.ItemIndex);
        ComPort.FlowControl := TFlowControl(ComboBox6.ItemIndex);

        ComPort.RdIntervalTimeout       := UpDown1.position;
        ComPort.RdTotalTimeoutMultiplier:= UpDown2.position;
        ComPort.RdTotalTimeoutConstant  := UpDown3.position;
        ComPort.WrTotalTimeoutMultiplier:= UpDown4.position;
        ComPort.WrTotalTimeoutConstant  := UpDown5.position;
        Result := True;
    end
    else
      Result := False;
    Free;
  end;
end;

procedure TComPortV1Editor.ExecuteVerb(Index: Integer);
begin
  if Index = 0 then
    if ShowPropForm(TComPortV1(Component)) then
      Designer.Modified;
end;

function TComPortV1Editor.GetVerb(Index: Integer): string;
begin
  case Index of
    0: Result := 'Edit Properties';
  end;
end;

function TComPortV1Editor.GetVerbCount: Integer;
begin
  Result := 1;
end;

procedure Register;
begin
  RegisterComponents('Custom', [TComPortV1]);
  RegisterComponentEditor(TComPortV1, TComPortV1Editor);
end;

end.
