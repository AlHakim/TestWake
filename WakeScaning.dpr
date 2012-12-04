program WakeScaning;

uses
  Forms,
  Unit2 in 'Unit2.pas' {Form1};

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'ModBus Scaning';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
