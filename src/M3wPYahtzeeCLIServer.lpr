program M3wPYahtzeeCLIServer;

{$mode objfpc}{$H+}

{$DEFINE UseCThreads}

uses
	{$IFDEF UNIX}{$IFDEF UseCThreads}
	cthreads,
	{$ENDIF}{$ENDIF}
	Classes, SysUtils, CustApp, DModCLIServerMain, YahtzeeClasses,
	YahtzeeServer;

type

{ TYahtzeeServer }

	TYahtzeeServer = class(TCustomApplication)
	protected
		procedure DoRun; override;
	public
		constructor Create(TheOwner: TComponent); override;
		destructor Destroy; override;
		procedure WriteHelp; virtual;
	end;

{ TYahtzeeServer }

procedure TYahtzeeServer.DoRun;
	var
	ErrorMsg: String;
//	f: Boolean;
	z: TZone;
	i: Integer;
	s: string;

	begin
	// quick check parameters
	ErrorMsg:=CheckOptions('h', 'help');
	if ErrorMsg<>'' then begin
		ShowException(Exception.Create(ErrorMsg));
		Terminate;
		Exit;
	end;

	// parse parameters
	if HasOption('h', 'help') then begin
		WriteHelp;
		Terminate;
		Exit;
	end;

    CLIServerMainDMod:= TCLIServerMainDMod.Create(nil);
    CLIServerMainDMod.IdTCPServer1.Active:= True;

	while not Terminated do
    	begin
		Sleep(100);

//	    f:= DebugMsgs.QueueSize > 0;

//		Update debug message display to offload queue (could potentially block ourselves
//      	if any more are added here, queue does not grow - has maximum).
//    	while DebugMsgs.QueueSize > 0 do
//			Memo1.Lines.Add(string(DebugMsgs.PopItem));
//    		DebugMsgs.PopItem;

        with DebugMsgs.LockList do
			try
			while Count > 0 do
				begin
				s:= Items[0];
				Delete(0);
				Writeln(s);
				Flush(Output);
				end;
			finally
			DebugMsgs.UnlockList;
			end;


//    	if  f then
//		Memo1.ScrollBy(0, MaxInt);
//    		;

//		DebugMsgs.PushItem('- Heart beat.');

//    	while ExpireZones.QueueSize > 0 do
//    		begin
//    		z:= ExpireZones.PopItem;
//    		if  z.PlayerCount = 0 then
//    			z.Free;
//    		end;

		with ExpireZones.LockList do
			try
            while Count > 0 do
				begin
				z:= Items[0];
				Delete(0);
				if  z.PlayerCount = 0 then
					z.Free;
				end;
			finally
            ExpireZones.UnlockList;
			end;

    	with ListMessages.LockList do
    		try
    		for i:= Count - 1 downto 0 do
    			begin
    			if  Items[i].Process then
    				Items[i].ProcessList
    			else
    				Items[i].Elapsed;

    			if  Items[i].Complete then
    				begin
    				Items[i].Free;
    				Delete(i);
    				end;
    			end;

    		finally
    		ListMessages.UnlockList;
    		end;

    	LimboZone.BumpCounter;
    	LimboZone.ExpirePlayers;
		end;

	CLIServerMainDMod.Free;

//	stop program loop
	Terminate;
	end;

constructor TYahtzeeServer.Create(TheOwner: TComponent);
begin
	inherited Create(TheOwner);
	StopOnException:=True;
end;

destructor TYahtzeeServer.Destroy;
begin
	inherited Destroy;
end;

procedure TYahtzeeServer.WriteHelp;
begin
	{ add your help code here }
	writeln('Usage: ', ExeName, ' -h');
end;

var
	Application: TYahtzeeServer;
begin
	Application:=TYahtzeeServer.Create(nil);
	Application.Title:='M3wP Yahtzee! Server';
	Application.Run;
	Application.Free;
end.

