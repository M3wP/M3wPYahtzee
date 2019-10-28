program M3wPYahtzeeClient;

uses
  System.StartUpCopy,
  FMX.Forms,
  FormClientMain in 'FormClientMain.pas' {ClientMainForm},
  YahtzeeClasses in 'YahtzeeClasses.pas',
  YahtzeeClient in 'YahtzeeClient.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TClientMainForm, ClientMainForm);
  Application.Run;
end.
