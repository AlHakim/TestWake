unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, Grids, StdCtrls, Comms, Menus, MPHexEditor,
  Buttons, CollapsePanel, Math, SyncObjs, ExtCtrls, Mask;

Const
    cBaudRate :array [0..12]  of string = (  '110',   '300',   '600',  '1200',  '2400',  '4800', '9600',
                                           '14400', '19200', '38400', '56000', '57600', '115200');
    cPortType :array [0..3]  of string =  ('COM1', 'COM2', 'COM3', 'COM4');
    cParity   :array [0..4]  of string =  ('N', 'O', 'E', 'M', 'S');
    cStopBits :array [0..2]  of string =  ('1', '1.5', '2');
    ArrHex    :array [0..$f] of Char   =  ('0', '1', '2', '3', '4', '5', '6', '7',
                                           '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');
    cMaxPaketLength     = $7d; //7d;  //  максимальное число регистров за один раз

    cCmdRdReg           = $03;  //  команды по ModBus для записи файла
    cCmdWrReg           = $10;  //  команды по ModBus для записи файла
    cCmdUploadFile      = $42;  //  пользовательская команды по ModBus для записи файла
    cCmdReadArh         = $41;  //  пользовательская команды по ModBus для чтения архива

    cCmdClearArh        = $0080;
    cintSilentTimeout   = 10;

    // протокол Wake
    CRC_Init            = $DE;
    FEND                = $C0;  //Frame END
    FESC                = $DB;  //Frame ESCape
    TFEND               = $DC;  //Transposed Frame END
    TFESC               = $DD;  //Transposed Frame ESCape

    CmdWakeRdReg        = $64;

    const CmdText : array [$00..$0D] of String = (
            'Cmd_Nop',
            'Cmd_Err',
            'Cmd_Echo',
            'Cmd_Info',
            'Cmd_Repeat_Pac',
            'Cmd_Set_Addres',
            'Cmd_Get_Addres',
            'Cmd_SET_TIME',
            'Cmd_GET_TIME',

            'Cmd_CntToDay',
            'Cmd_CntToMonth',
            'Cmd_PtrLastRead',
            'Cmd_PtrLastWrite',

            'CMD_GET_STATUS'
    );

type
  PWakeTxRec = ^WakeTxRec;  //выделение отдельных ячеек
  WakeTxRec = record
    Ptr     : byte;                   //data pointer - указатель на текущий параметр стуртуры
    Addres  : byte;                   //address
    Cmd     : byte;                   //command
    NumByte : byte;                   //number of bytes
    DataBuffer: array of Byte;        //data
    CRC     : byte;                   //CRC
  end;

  PWakeRxRec = ^WakeRxRec;  //выделение отдельных ячеек
  WakeRxRec = record
    Ptr     : byte;                   //data pointer - указатель на текущий параметр стуртуры
    Addres  : byte;                   //address
    Cmd     : byte;                   //command
    NumByte : byte;                   //number of bytes
    DataBuffer: array of Byte;        //data
    CRC     : byte;                   //CRC
  end;


  PAdrRangeRec = ^AdrRangeRec;  //выделение отдельных ячеек
  AdrRangeRec = record
    AdrBegin: Word;
    AdrEnd  : Word;
  end;

  PWriteRegRec = ^WriteRegRec; //выделение отдельных ячеек
  WriteRegRec = record
    RegAdr  : Word;
    RegValue: Word;
  end;

  TForm1 = class(TForm)
    ModBusGrid: TStringGrid;
    StatusBar1: TStatusBar;
    Panel1: TPanel;
    ComPort1: TComPortv1;
    Splitter3: TSplitter;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    CollapsePanel1: TCollapsePanel;
    GroupBox4: TGroupBox;
    mAdrRange: TMemo;
    GroupBox5: TGroupBox;
    mWriteReg: TMemo;
    Button2: TButton;
    GroupBox7: TGroupBox;
    GroupBox6: TGroupBox;
    Label3: TLabel;
    cbStart: TCheckBox;
    RtuString: TEdit;
    OpenDialog1: TOpenDialog;
    Panel2: TPanel;
    mWakeLog: TMemo;
    cbWakeCmd: TComboBox;
    Label2: TLabel;
    meLastRdOffset: TMaskEdit;
    dtpLastRd2: TDateTimePicker;
    dtpLastRd1: TDateTimePicker;
    dtpLastWr1: TDateTimePicker;
    dtpLastWr2: TDateTimePicker;
    meLastWrOffset: TMaskEdit;
    Label6: TLabel;
    mWakeTxFrame: TMemo;
    btnWakeCmdTx: TButton;
    procedure FormCreate(Sender: TObject);
    procedure StatusBar1Click(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure cbStartClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnWakeCmdTxClick(Sender: TObject);
    procedure cbWakeCmdChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure ParserAddresRange;
    procedure ParserRegWrite;
  end;

  TRdThread = class(TThread)
    RdSuspended : Boolean;
  protected
    procedure Execute; override;
    property Terminated;
  end;

  TWrThread = class(TThread)
    WrSuspended : Boolean;
  protected
    procedure Execute; override;
    property Terminated;
  end;

var Form1: TForm1;
    i, FileCrc16, CntTry: Word;
    FIn, FOut       : TFileStream;
    FOutHandle      : Integer;
    TxData, TxData2, RxData  : array of Byte;

    TmpAdrRange     : PAdrRangeRec;
    TmpWriteReg     : PWriteRegRec;
    AdrRangeList    : TList;
    WriteRegList    : TList;
    CntPacketOk, CntPacketTx :Word;

    PaketLength, NumPacket: word;
    Offset, AdrRTU  : Byte;
    MusorStr        : String;

    CS              : TCriticalSection;   //    CS: TRTLCriticalSection;
    RdThread        : TRdThread;
    WrThread        : TWrThread;

function Wake_TxFrame(ADDR,CMD, N: byte; var TxData :array of byte):byte;
function Wake_RxFrame(CntRxByte: Word; PRxBuf: pointer; var RxFrame: PWakeRxRec):boolean;

implementation

{$R *.DFM}

{Конвертирует строку в OEM. Для использования необходимо сделать uses Windows}
function StrToOEM(str: String): String;
begin
    Result := str;
    CharToOEM(PChar(Result), PChar(Result));
end;

procedure SendLogToFile(InputStr: string);
var DumpBuffer: String;
    TmpStr : String;
begin
    SetLength(DumpBuffer, Length(InputStr) shl 1);
    BinToHex(@(InputStr[1]), PChar(DumpBuffer), Length(InputStr));

    TmpStr := '('+DumpBuffer+')'+InputStr+#13#10;
    FOut.Write(PChar(TmpStr)^, Length(TmpStr));
end;

function FileOpen(FileName:String): Boolean;
var BackupName: string;
    FileHandle:integer;
begin
    result := False;
    if FileExists(FileName) then begin
        BackupName := ChangeFileExt(FileName,'.BAK');
        if FileExists(BackupName) then DeleteFile(BackupName);
        if not RenameFile(FileName, BackupName) then
            raise Exception.Create('Unable to create backup file.');
    end;

    FileHandle:=FileCreate(FileName);
    FileClose(FileHandle);
    try
        FOut := TFileStream.Create(FileName,fmOpenWrite or fmShareDenyWrite);
        FOutHandle := FOut.Handle;
        result := True;
    except on Exception do ShowMessage('No enabled Open File');
    end;// end of except

end;

procedure FillCellReg(StartAdres, CntReg: word; var VarData);
var  Data: array[0..$FFFF] of byte absolute VarData;
    i: Cardinal;
begin
    for i:=0 to (CntReg shr 1)-1 do begin
        Form1.ModBusGrid.Cells[((StartAdres+i) and $0f)+1,
                                ((StartAdres+i) shr 4)+1] := format('%0.2x%0.2x',[Data[2*i],Data[2*i+1]]);
//        Form1.ModBusGrid.Refresh;
    end;
    Form1.ModBusGrid.Refresh;
end;

function WakeRdReg(RTU: byte; TxData :array of byte; fFillCells: boolean): integer;
var TmpByte : byte;
    TmpStr, DumpBuffer  : String;
begin                //sleep // KillTimer  QueryPerformanceCounter
//              TxData[0] := CmdWakeRdReg
//              TxData[1] := 2;               // кол-во передаваемых байт команды
//              TxData[2] := TmpInt;          // начальный адрес, считываемых регистров (0..255)
//              TxData[3] := RxCnt;           // кол-во регистров, которые надо считать (0..255)

    result := 0;  MusorStr := '';
    inc(CntPacketTx,1);
    //function Wake_TxFrame(ADDR,CMD, N: byte; var ^TxBuf :array of byte):byte;
    TmpByte := Wake_TxFrame(RTU, TxData[0], TxData[1], TxData[2]);

    //
    //  выводим в отладочное окно
    //
    //SetLength(DumpBuffer, TmpByte shl 1);
    //BinToHex(@(TxData[2]), PChar(DumpBuffer), TmpByte);
    TmpStr := 'Tx--> ' + DumpBuffer + '+ CRC';
    Form1.mWakeLog.Lines.Add(TmpStr);

    Form1.ComPort1.PurgeOut;    Form1.ComPort1.PurgeIn; // очищаем буфер
    //if (Form1.ComPort1.Write(TxData[2], TmpByte) = TmpByte) then result := TRUE;
    Form1.ComPort1.Write(TxData[2], TmpByte);
    if (TmpByte>0) then begin

      //
      //  ожидаем появление ответа от слайва
      //
      TmpByte := Form1.ComPort1.Read(RxData,255);       // читаем текущие данные из сом- порта
      if (TmpByte = 0) then begin
          DumpBuffer := '0 byte';
      end
      else
        begin
          inc(CntPacketOk,1);
          SetLength(DumpBuffer, TmpByte shl 1);
          BinToHex(@(RxData), PChar(DumpBuffer), TmpByte);
         // if (fFillCells) then FillCellReg(TxData[2], TxData[3], RxData[4]);
      end;

      TmpStr := 'Rx--> ' + DumpBuffer;// + ' CRC';
      Form1.mWakeLog.Lines.Add(TmpStr);
    end;
    DumpBuffer :='';
    //FreeMem(DumpBuffer);
    Form1.StatusBar1.Panels[1].Text := format('Статус обмена(Tx/ok/Error): %d/%d/%d',[CntPacketTx,CntPacketOk,CntPacketTx-CntPacketOk]);
end;

//==================================================================================
//==================================================================================
//==================================================================================
procedure TForm1.FormCreate(Sender: TObject);
//const   Data1: array[0..4] of byte = (0,1,2,3,4);
var i: Integer;
begin
    CS := TCriticalSection.Create;
    StatusBar1.Panels[0].Text := cPortType[integer(ComPort1.Port)] +' '+
                                       cBaudRate[integer(ComPort1.BaudRate)]+','+
                                       cParity[integer(ComPort1.Parity)]+','+
                                       IntToStr(ComPort1.DataBits)+','+
                                       cStopBits[integer(ComPort1.StopBits)];

    for i:=1 to 16 do ModBusGrid.Cells[i,0]:= format('%0.2x',[i-1]);
    for i:=1 to 4096 do ModBusGrid.Cells[0,i]:= format('%4.4x',[(i-1)*$10]);

    AdrRangeList := TList.Create;
    WriteRegList := TList.Create;
    FileOpen('MobBus.log');

    SetLength(TxData, 255);
    SetLength(TxData2, 255);
    SetLength(RxData, 255);

    RdThread := TRdThread.Create(True);       // create threads
    RdThread.FreeOnTerminate := true;
    WrThread := TWrThread.Create(True);       // create threads
    WrThread.FreeOnTerminate := true;

    for i := $0 to $0D do begin
        cbWakeCmd.Items.Add(CmdText[i]);
    end;
    meLastRdOffset.Enabled := False;  dtpLastRd1.Enabled := False;  dtpLastRd2.Enabled := False;
    meLastWrOffset.Enabled := False;  dtpLastWr1.Enabled := False;  dtpLastWr2.Enabled := False;
    cbWakeCmd.ItemIndex := 2;
end;

procedure TForm1.StatusBar1Click(Sender: TObject);
begin
//    ComPort1.Close;
    ShowPropForm(ComPort1);
    StatusBar1.Panels[0].Text := cPortType[integer(ComPort1.Port)] +' '+
                                       cBaudRate[integer(ComPort1.BaudRate)]+','+
                                       cParity[integer(ComPort1.Parity)]+','+
                                       IntToStr(ComPort1.DataBits)+','+
                                       cStopBits[integer(ComPort1.StopBits)];
end;

procedure TForm1.N1Click(Sender: TObject);
var i,j: Cardinal;
begin
    if (Sender is Tmemo) then
        TMemo(Sender).Lines.Clear
    else
        for i:=1 to ModBusGrid.RowCount-1 do
            for j:=1 to ModBusGrid.ColCount - 1 do
                ModBusGrid.Cells[j, i] :='';
end;

function StrToVal(InpuStr : String): word;
var  CodeError: Integer;
begin
    result := 0;                    // по умолчанию результат равен "0"
    InpuStr := Trim(InpuStr);
    if (InpuStr <> '') then begin
        {$R-}   //The values for out-of-range vary depending upon the data type of V
            val('$'+InpuStr,result,CodeError);

            if (CodeError <> 0) then
                raise Exception.Create('Error at position: ' + IntToStr(CodeError));
        {$R+}   //An out-of-range value always generates a run-time error.
      end
end;

procedure TForm1.ParserAddresRange;
var i: Cardinal;
    TmpStr,TmpStr2   : string;
    Val1, Val2  : Word;
    ComentPos   : Word;                 //позиция комментария
    PosPlus     : Word;                 //позиция '+'
    PosTire     : Word;                 //позиция '-'

begin
    //
    //  Удаляем объекты в Tlist
    //
    while(AdrRangeList.Count > 0) do begin
        TmpAdrRange := AdrRangeList.Items[0];
        Dispose(TmpAdrRange);
        AdrRangeList.Delete(0)
    end;
    AdrRangeList.Clear;

    //
    //  Парсер адресного диапазона
    //
    if (mAdrRange.Lines.Count = 0) then begin ShowMessage('Задайте адресный диапазон'); exit; end;

    for i:=0 to mAdrRange.Lines.Count-1 do begin
        TmpStr := mAdrRange.Lines.Strings[i];
        ComentPos := pos(';', TmpStr);
        delete(TmpStr,ComentPos,255);         // удаляем комментарии
        TmpStr :=Trim(TmpStr);
        if (TmpStr = '') then Continue;     // строка состоит из комментария

        //
        //  поиск символа диапазона "+ / -"
        //
        PosPlus := pos('+', TmpStr);
        PosTire := pos('-', TmpStr);

        if ((PosPlus <> 0) and (PosTire <> 0)) then
            raise Exception.Create('Неправильный формат диапазона адресов'+#13#10#13#10+
                                    'допустимые варианты 0000 или 0000+0100 или 0000-0100');

        TmpStr2 := copy(TmpStr,0, (PosPlus or PosTire)-1);  // выделили первую часть строки
        delete(TmpStr,1,PosPlus or PosTire);                // выделили вторую часть строки
        Val1 := StrToVal(TmpStr2);  Val2 := StrToVal(TmpStr);

        new(TmpAdrRange);       //PAdrRangeRec
        TmpAdrRange^.AdrBegin := Val1;

        if (PosTire <> 0) then
            TmpAdrRange^.AdrEnd := Val2-Val1
        else
            if (PosPlus <> 0) then
                TmpAdrRange^.AdrEnd := Val2
            else // одиночный регистр
                begin
                    TmpAdrRange^.AdrBegin := Val2;
                    TmpAdrRange^.AdrEnd := 1;
                end;

        AdrRangeList.Add(TmpAdrRange);
    end;
end;

procedure TForm1.ParserRegWrite;
var i: Cardinal;
    TmpStr,TmpStr2   : string;
    Val1, Val2  : Word;
    ComentPos   : Word;                 //позиция комментария
    PosColon    : Word;                 //позиция ':'

begin
    //
    //  Удаляем объекты в Tlist
    //
    while(WriteRegList.Count > 0) do begin
        TmpWriteReg := WriteRegList.Items[0];
        Dispose(TmpWriteReg);
        WriteRegList.Delete(0);
    end;
    WriteRegList.Clear;

    //
    //  Парсер адресного диапазона
    //
    if (mWriteReg.Lines.Count = 0) then exit; //Нет данных для записи

    for i:=0 to mWriteReg.Lines.Count-1 do begin
        TmpStr := mWriteReg.Lines.Strings[i];
        ComentPos := pos(';', TmpStr);
        delete(TmpStr,ComentPos,255);         // удаляем комментарии
        TmpStr :=Trim(TmpStr);
        if (TmpStr = '') then Continue;     // строка состоит из комментария

        //
        //  поиск разделительного символа " : "
        //
        PosColon := pos(':', TmpStr);

        if (PosColon = 0) then
            raise Exception.Create('Неправильный формат диапазона адресов'+#13#10#13#10+
                                    'допустимые варианты 0000 или 0000+0100 или 0000-0100');

        TmpStr2 := copy(TmpStr,0, PosColon-1);  // выделили первую часть строки
        delete(TmpStr,1,PosColon);              // выделили вторую часть строки
        Val1 := StrToVal(TmpStr2);  Val2 := StrToVal(TmpStr);

        new(TmpWriteReg);                       //PAdrRangeRec
        TmpWriteReg^.RegAdr   := Val1;
        TmpWriteReg^.RegValue := Val2;
        WriteRegList.Add(TmpWriteReg);
    end;
end;


procedure TForm1.cbStartClick(Sender: TObject);
var ErrCode: Integer;
begin
    if cbStart.Checked then begin
      {$R-}
         Val(Form1.RtuString.Text, AdrRTU, ErrCode);
      {$R+}
         { Error during conversion to integer? }
          if ErrCode <> 0 then begin
              MessageDlg('Error: Проверте правильность выставленного адреса', mtError, [mbOk], 0);
              halt;
          end;

          ParserAddresRange;
          CntPacketOk := 0;
          CntPacketTx := 0;
          RdThread.Priority  := tpHigher;
          if RdThread.Suspended then
            RdThread.Resume;
      end
    else
      begin
        RdThread.RdSuspended := True;
        WrThread.WrSuspended := True;
      end;
end;

//===========================================================
//===========================================================
//===========================================================
procedure TRdThread.Execute;
const AdrArhPtr   = 4;
      AdrZamerPtr = 5;
var i, TmpInt, TmpEnd : Integer;
    TmpCnt, RxCnt : Byte;
begin
  Form1.ComPort1.open;
  while not Terminated do begin
    CS.Enter;                             //EnterCriticalSection(CS); // CS begins here
    try
      TmpCnt := AdrRangeList.Count;
      i := 0;
      while (TmpCnt > 0) do begin
        with PAdrRangeRec(AdrRangeList.Items[i])^ do begin
            TmpInt := AdrBegin; TmpEnd := AdrEnd;
            while(TmpEnd > 0) do begin
              if (TmpEnd > cMaxPaketLength) then RxCnt := cMaxPaketLength else RxCnt := TmpEnd;

              TxData[0] := CmdWakeRdReg;
              TxData[1] := 2;               // кол-во передаваемых байт команды
              TxData[2] := TmpInt;          // начальный адрес, считываемых регистров (0..255)
              TxData[3] := RxCnt;           // кол-во регистров, которые надо считать (0..255)
              inc(TmpInt,RxCnt);
              dec(TmpEnd,RxCnt);

              WakeRdReg(AdrRTU, TxData, True); // зааполняем таблицу (вызываем ф-цию FillCells)
            end;
        end;
        if (RdSuspended ) then   break;
        inc(i,1);  dec(TmpCnt, 1);
      end;  // end of while (TmpCnt > 0)

    finally
      CS.Leave;                           //LeaveCriticalSection(CS); // CS ends here
      sleep(300);
      if (RdSuspended) then begin
        RdSuspended := False;
        Form1.ComPort1.Close;
        if (FOut.Handle = FOutHandle) then FOut.Free;

        Suspend;

        FileOpen('MobBus.log');           // возобновляем поток
        Form1.ComPort1.open;
      end;
    end;
  end;  //end of while not Terminated
end;

procedure TWrThread.Execute;
begin
  while not Terminated do begin
    CS.Enter;
    try
      //WakeRdReg(AdrRTU, TxData2, False); // зааполняем таблицу (вызываем ф-цию FillCells)
    finally
      CS.Leave;
    end;
    Suspend;
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
    if (RdThread <> nil) then begin
      if (not RdThread.Suspended) then
        RdThread.Suspend;
      RdThread.Terminate;
      //RdThread.WaitFor;
      RdThread.Free;
    end;
    if (WrThread <> nil) then begin
      if (not WrThread.Suspended) then WrThread.Suspend;
      WrThread.Terminate;
      WrThread.Free;
    end;
    if (FOut.Handle = FOutHandle) then FOut.Free;
    if ComPort1.Connected then begin
        ComPort1.Close;
    end;
    ComPort1.Destroy;
(*    i := 0;
    while(AdrRangeList.Count > 0) do begin
        TmpAdrRange := AdrRangeList.Items[i];
        Dispose(TmpAdrRange);
        AdrRangeList.Delete(i)
//        inc(i,1);
    end;
*)
    AdrRangeList.Free;
    WriteRegList.Free;
end;


procedure DowCRC(b:byte; var crc: byte);
var i: byte;
begin
   for i:= 0 to 7 do begin
       if (((b xor crc) and 1) <> 0) then
            crc := ((crc xor $18) shr 1) or $80
       else
            crc := (crc shr 1) and not($80);
    b := b shr 1;
   end;
end;

function Wake_TxFrame(ADDR,CMD, N: byte; var TxData :array of byte):byte;
var  Data: array[0..$FF] of byte absolute TxData;

     TxBuff: array[0..255] of byte;
     i, CRC, TmpByte : byte;
     TmpIndex: integer;
begin                //sleep // KillTimer  QueryPerformanceCounter
    //
    //  заполняем шапку пакета
    //
    FillChar(TxBuff,255,0); TmpIndex := 0;
    CRC := CRC_Init;

    for i:=0 to N+4 do begin
        if (i = 0)    then TmpByte := FEND else  //FEND
        if (i = 1)    then TmpByte := ADDR else  //address
        if (i = 2)    then TmpByte := CMD  else  //command
        if (i = 3)    then TmpByte := N    else  //N
        if (i = N+4)  then TmpByte := CRC  else  //CRC
           TmpByte := Data[i-4];            //data

        DowCRC(TmpByte, CRC);
        if (i = 1) then TmpByte := TmpByte or $80;
        if (i > 0) then
            if ((TmpByte = FEND) or (TmpByte = FESC)) then begin
                TxBuff[TmpIndex] := FESC;  inc(TmpIndex,1);
                if (TmpByte = FEND) then TmpByte := TFEND else TmpByte := TFESC;
            end;
            TxBuff[TmpIndex] := TmpByte;  inc(TmpIndex,1);
    end; // end of  for i:=0 to N+4

    move(TxBuff, Data, i);
    result := i;
    //
    // отсылаем данные в COM - порт
    //
    //Form1.ComPort1.PurgeOut;    Form1.ComPort1.PurgeIn; // очищаем буфер
    //result := False;
    //if (Form1.ComPort1.Write(TxData, TmpIndex) = TmpIndex) then result := TRUE;
end;

function Wake_RxFrame(CntRxByte: Word; PRxBuf: pointer; var RxFrame: PWakeRxRec):boolean;
var  j, TmpByte : byte;
     i: integer;
     RxBuf : PChar absolute PRxBuf; //Byte(RxBuf[i]
begin //sleep // KillTimer  QueryPerformanceCounter
    //
    //  заполняем шапку пакета
    //
    j:=0; i := 0; result := False;
    RxFrame.CRC := CRC_Init;
    while(i < CntRxByte) do begin
      TmpByte := Byte(RxBuf[i]);
      if ((TmpByte <> FEND) or ((i > 0) and (TmpByte = FEND))) then exit;

        if (i > 0) then begin
            if (TmpByte = FESC) then
              if (Byte(RxBuf[i+1]) = TFEND) then TmpByte := FEND else
                  if (TmpByte = TFESC)     then TmpByte := FESC else exit;
            i := i+1;
            inc(RxFrame.Ptr);
        end;

        // Адрес
        if (RxFrame.Ptr = 1) then
          if ((TmpByte and $80) > 0) then begin TmpByte := TmpByte and $7f; RxFrame.Addres := TmpByte end else exit;

        // команда  , 7-ой бит всегда = 0
        if (RxFrame.Ptr = 2) then
          if ((TmpByte and $80)>0) then exit else RxFrame.Cmd := TmpByte;

        // кол-во байт данных
        if (RxFrame.Ptr = 3) then  RxFrame.NumByte := TmpByte;

        if (RxFrame.Ptr > 3) then begin
            if (RxFrame.NumByte = j) then begin
                if (RxFrame.CRC = TmpByte) then result := True;
                exit;
            end
            else
                RxFrame.DataBuffer[j] := TmpByte;

            inc(j,1);
        end;

        DowCRC(TmpByte, RxFrame.CRC);
        inc(i,1);
    end // of for i:=0 to
end;

procedure TForm1.btnWakeCmdTxClick(Sender: TObject);
var i:byte;
    RTC : array[0..6] of Word;
    PortsPtr: Pointer;
begin
(*          'Cmd_CntToDay',
            'Cmd_CntToMonth',
            'Cmd_PtrLastRead',
            'Cmd_PtrLastWrite',

            'CMD_GET_STATUS'    *)

  if (cbWakeCmd.ItemIndex < 0) then exit;

  TxData2[0] := cbWakeCmd.ItemIndex;

  case cbWakeCmd.ItemIndex of
      $00..$01,
      $03     : begin exit; end;

      $02     : begin  // посылаем тестовую посылку
                  TxData2[1] := 20;               // кол-во передаваемых байт команды
                  for i:=0 to 20 do
                    TxData2[2+i] := i+1;          // данные
                end;
      $04     : begin  // Cmd_Repeat_Pac
                  TxData2[1] := 0;               // кол-во передаваемых байт команды
                end;
      $05     : begin  //Cmd_Set_Addres
                  TxData2[1] := 1;               // кол-во передаваемых байт команды
                  TxData2[2] := 2;               // данные
                end;
      $06     : begin  //Cmd_Get_Addres
                  TxData2[1] := 0;               // кол-во передаваемых байт команды
                end;
      $07     : begin  //Cmd_SET_TIME

                  DecodeDate(dtpLastRd1.DateTime, RTC[6], RTC[5], RTC[4]);
                  DecodeTime(dtpLastRd2.DateTime, RTC[3], RTC[2], RTC[1], RTC[0]);
                  RTC[6] := RTC[6] - 1980;
                  //sec  = 42; min  = 54; hour = 6; wday = 7; mday  = 13;   month= 11; year = 2019;

                  // Pack date and time into a DWORD variable
                  //return    ((DWORD)(rtc.year - 1980) << 25)        //(2010-1080)<<25 = 0x3C00 0000
                  //            | ((DWORD)rtc.month << 21)            //12 << 21 = 0x0180 0000
                  //            | ((DWORD)rtc.mday << 16)             //31 << 16 = 0x001f 0000
                  //            | ((DWORD)rtc.hour << 11)
                  //            | ((DWORD)rtc.min << 5)
                  //            | ((DWORD)rtc.sec >> 1);
                  //   = 0x4f6d36d5
                                                                                                       // unsigned long sec  : 6;
                  TxData2[1] := 4;               // кол-во передаваемых байт команды                    // unsigned long min  : 6;
                  PortsPtr := @TxData2[2];

                  Cardinal(PortsPtr^) := (RTC[6] shl 25) or (RTC[5] shl 21) or (RTC[4] shl 16) or
                                         (RTC[3] shl 11) or (RTC[2] shl 5)  or (RTC[1] shl 1);
                end;
      $08     : begin  //Cmd_GET_TIME
                  TxData2[1] := 0;               // кол-во передаваемых байт команды
                end;

  end;// end of case
  WrThread.Resume;
end;

procedure TForm1.cbWakeCmdChange(Sender: TObject);
begin
  if (cbWakeCmd.ItemIndex < 0) then exit;
  meLastRdOffset.Enabled := False;  dtpLastRd1.Enabled := False;  dtpLastRd2.Enabled := False;
  meLastWrOffset.Enabled := False;  dtpLastWr1.Enabled := False;  dtpLastWr2.Enabled := False;

  case cbWakeCmd.ItemIndex of
    0..6,8: begin
           end;
      $07: begin
              dtpLastRd1.Enabled := true;  dtpLastRd2.Enabled := true;
            end;
  end;// end of case
end;

end.
