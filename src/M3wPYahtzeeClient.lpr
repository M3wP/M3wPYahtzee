program M3wPYahtzeeClient;

{$mode objfpc}{$H+}

uses
	{$IFDEF UNIX}{$IFDEF UseCThreads}
	cthreads,
	{$ENDIF}{$ENDIF}
	Interfaces, // this includes the LCL widgetset
	Forms, FormClientMain, DModClientMain, YahtzeeClient
	{ you can add units after this };

{$R *.res}

begin
	RequireDerivedFormResource:=True;
	Application.Initialize;
	Application.CreateForm(TClientMainForm, ClientMainForm);
	Application.CreateForm(TClientMainDMod, ClientMainDMod);
	Application.Run;
end.

