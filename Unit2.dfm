object Form1: TForm1
  Left = 691
  Top = 47
  Width = 590
  Height = 551
  Caption = 'ModBus Scaning'
  Color = clBtnFace
  Constraints.MaxHeight = 750
  Constraints.MaxWidth = 590
  Constraints.MinHeight = 450
  Constraints.MinWidth = 590
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter3: TSplitter
    Left = 0
    Top = 169
    Width = 582
    Height = 3
    Cursor = crVSplit
    Align = alBottom
  end
  object Panel2: TPanel
    Left = 0
    Top = 172
    Width = 582
    Height = 333
    Align = alBottom
    TabOrder = 4
    object mWakeLog: TMemo
      Left = 1
      Top = 48
      Width = 580
      Height = 284
      Align = alBottom
      TabOrder = 0
    end
    object mWakeTxFrame: TMemo
      Left = 1
      Top = 1
      Width = 580
      Height = 47
      Align = alClient
      Color = clCaptionText
      ReadOnly = True
      TabOrder = 1
    end
  end
  object ModBusGrid: TStringGrid
    Left = 0
    Top = 20
    Width = 582
    Height = 149
    Align = alClient
    ColCount = 17
    DefaultColWidth = 32
    DefaultRowHeight = 15
    RowCount = 4096
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    PopupMenu = PopupMenu1
    TabOrder = 0
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 505
    Width = 582
    Height = 19
    Panels = <
      item
        Width = 120
      end
      item
        Width = 250
      end
      item
        Width = 100
      end
      item
        Width = 50
      end>
    SimplePanel = False
    OnClick = StatusBar1Click
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 582
    Height = 20
    Align = alTop
    Caption = 'Panel1'
    TabOrder = 1
  end
  object CollapsePanel1: TCollapsePanel
    Left = -1
    Top = 0
    Width = 583
    Height = 129
    BevelInner = bvLowered
    Caption = 'CollapsePanel1'
    FullRepaint = False
    TabOrder = 2
    AutoClose = True
    AutoCloseTime = 200
    StepCollaps = 15
    About = '(C) Lindsay DPenha (iamlinz@hotmail.com)'
    object GroupBox4: TGroupBox
      Left = 2
      Top = 18
      Width = 135
      Height = 109
      Align = alLeft
      Caption = 'Address Range'
      TabOrder = 1
      object mAdrRange: TMemo
        Left = 2
        Top = 15
        Width = 131
        Height = 92
        Align = alClient
        Lines.Strings = (
          '0+16'
          ';01F0+10')
        TabOrder = 0
      end
    end
    object GroupBox5: TGroupBox
      Left = 137
      Top = 18
      Width = 152
      Height = 109
      Align = alLeft
      Caption = 'Write Registers'
      TabOrder = 2
      object mWriteReg: TMemo
        Left = 2
        Top = 15
        Width = 127
        Height = 92
        Align = alLeft
        Lines.Strings = (
          '0021:0002')
        TabOrder = 0
      end
      object Button2: TButton
        Left = 131
        Top = 22
        Width = 17
        Height = 74
        Caption = 'Ok'
        TabOrder = 1
      end
    end
    object GroupBox7: TGroupBox
      Left = 289
      Top = 18
      Width = 248
      Height = 109
      Align = alLeft
      Caption = 'Upload File'
      TabOrder = 3
      object Label2: TLabel
        Left = 8
        Top = 35
        Width = 210
        Height = 13
        Caption = 'PtrLastRead:  Data/Time                     Offset'
      end
      object Label6: TLabel
        Left = 8
        Top = 71
        Width = 209
        Height = 13
        Caption = 'PtrLastWrite:  Data/Time                     Offset'
      end
      object cbWakeCmd: TComboBox
        Left = 7
        Top = 14
        Width = 217
        Height = 21
        ItemHeight = 13
        TabOrder = 0
        OnChange = cbWakeCmdChange
      end
      object meLastRdOffset: TMaskEdit
        Left = 151
        Top = 51
        Width = 73
        Height = 21
        EditMask = '!9999999999;1;_'
        MaxLength = 10
        TabOrder = 1
        Text = '0         '
      end
      object dtpLastRd2: TDateTimePicker
        Left = 87
        Top = 51
        Width = 66
        Height = 21
        CalAlignment = dtaLeft
        Date = 40193.2879861111
        Time = 40193.2879861111
        DateFormat = dfShort
        DateMode = dmComboBox
        Kind = dtkTime
        ParseInput = False
        TabOrder = 2
      end
      object dtpLastRd1: TDateTimePicker
        Left = 8
        Top = 51
        Width = 78
        Height = 21
        CalAlignment = dtaLeft
        Date = 43782.6709810764
        Time = 43782.6709810764
        DateFormat = dfShort
        DateMode = dmComboBox
        Kind = dtkDate
        ParseInput = False
        TabOrder = 3
      end
      object dtpLastWr1: TDateTimePicker
        Left = 8
        Top = 83
        Width = 77
        Height = 21
        CalAlignment = dtaLeft
        Date = 40193.6709810764
        Time = 40193.6709810764
        DateFormat = dfShort
        DateMode = dmComboBox
        Kind = dtkDate
        ParseInput = False
        TabOrder = 4
      end
      object dtpLastWr2: TDateTimePicker
        Left = 87
        Top = 83
        Width = 65
        Height = 21
        CalAlignment = dtaLeft
        Date = 40193.6709810764
        Time = 40193.6709810764
        DateFormat = dfShort
        DateMode = dmComboBox
        Kind = dtkTime
        ParseInput = False
        TabOrder = 5
      end
      object meLastWrOffset: TMaskEdit
        Left = 151
        Top = 83
        Width = 73
        Height = 21
        EditMask = '!9999999999;1;_'
        MaxLength = 10
        TabOrder = 6
        Text = '0         '
      end
      object btnWakeCmdTx: TButton
        Left = 227
        Top = 22
        Width = 17
        Height = 74
        Caption = 'Ok'
        TabOrder = 7
        OnClick = btnWakeCmdTxClick
      end
    end
    object GroupBox6: TGroupBox
      Left = 537
      Top = 18
      Width = 44
      Height = 109
      Align = alClient
      TabOrder = 4
      object Label3: TLabel
        Left = 9
        Top = 31
        Width = 21
        Height = 11
        Caption = 'RTU'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Lucida Console'
        Font.Style = []
        ParentFont = False
      end
      object cbStart: TCheckBox
        Left = 7
        Top = 10
        Width = 37
        Height = 17
        Caption = 'Go'
        TabOrder = 0
        OnClick = cbStartClick
      end
      object RtuString: TEdit
        Left = 7
        Top = 42
        Width = 29
        Height = 21
        TabOrder = 1
        Text = '1'
      end
    end
  end
  object ComPort1: TComPortV1
    RdIntervalTimeout = 100
    RdTotalTimeoutMultiplier = 0
    RdTotalTimeoutConstant = 1000
    WrTotalTimeoutMultiplier = 0
    WrTotalTimeoutConstant = 2000
    BaudRate = br38400
    Port = COM1
    Parity = prNone
    StopBits = sbOneStopBit
    FlowControl = fcNone
    DataBits = 8
    Events = [evRxChar, evTxEmpty, evRxFlag, evRing, evBreak, evCTS, evDSR, evError, evRLSD]
    EnableDTR = True
    WriteBufSize = 2048
    ReadBufSize = 2048
    Left = 16
    Top = 200
  end
  object PopupMenu1: TPopupMenu
    Left = 80
    Top = 200
    object N1: TMenuItem
      Caption = 'Очистить'
      OnClick = N1Click
    end
  end
  object OpenDialog1: TOpenDialog
    Left = 48
    Top = 200
  end
end
