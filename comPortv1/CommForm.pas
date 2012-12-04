unit CommForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, ComCtrls;

type
  TCommFrm = class(TForm)
    Button1: TButton;
    Button2: TButton;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Bevel1: TBevel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    ComboBox3: TComboBox;
    ComboBox4: TComboBox;
    ComboBox5: TComboBox;
    ComboBox6: TComboBox;
    Edit1: TEdit;
    UpDown1: TUpDown;
    UpDown2: TUpDown;
    Edit2: TEdit;
    UpDown3: TUpDown;
    Edit3: TEdit;
    UpDown4: TUpDown;
    Edit4: TEdit;
    UpDown5: TUpDown;
    Edit5: TEdit;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  CommFrm: TCommFrm;

implementation

{$R *.DFM}

end.
