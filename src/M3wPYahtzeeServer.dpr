program M3wPYahtzeeServer;

uses
  System.StartUpCopy,
  FMX.Forms,
  FormServerMain in 'FormServerMain.pas' {ServerMainForm},
  YahtzeeServer in 'YahtzeeServer.pas',
  YahtzeeClasses in 'YahtzeeClasses.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TServerMainForm, ServerMainForm);
  Application.Run;
end.
