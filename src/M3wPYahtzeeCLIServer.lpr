program M3wPYahtzeeCLIServer;

{$MODE DELPHI}
{$H+}

{.DEFINE DEBUG}

{$IFDEF UNIX}
	{$DEFINE UseCThreads}
{$ENDIF}

uses
{$IFDEF UNIX}
    {$IFNDEF DEBUG}
    cmem,
    {$ENDIF}
	{$IFDEF UseCThreads}
	cthreads,
    {$ENDIF}
{$ENDIF}
	Classes, SysUtils, CustApp, YahtzeeClasses, YahtzeeServer, TCPServer, blcksock,
    synsock;

type

{ TYahtzeeServer }

	TYahtzeeServer = class(TCustomApplication)
	protected
		procedure DoRun; override;

		procedure DoConnect(const AIdent: TGUID);
		procedure DoDisconnect(const AIdent: TGUID);
		procedure DoReject(const AConnection: TTCPConnection);
		procedure DoReadData(const AIdent: TGUID; const AData: TMsgData);

	public
		constructor Create(TheOwner: TComponent); override;
		destructor  Destroy; override;

		procedure WriteHelp; virtual;
	end;

{ TYahtzeeServer }

procedure TYahtzeeServer.DoRun;
	var
	ErrorMsg: String;
//	f: Boolean;
    p: TPlayer;
	z: TZone;
	i: Integer;
	lm: TLogMessage;
	silent: Boolean;
    s: string;

	begin
	// quick check parameters
	ErrorMsg:= CheckOptions('hm:s', 'help');
	if  ErrorMsg <> '' then
		begin
		ShowException(Exception.Create(ErrorMsg));
		Terminate;
		Exit;
		end;

	// parse parameters
	if  HasOption('h', 'help') then
		begin
		WriteHelp;
		Terminate;
		Exit;
		end;

    TCPServer.TCPServer:= TTCPServer.Create;
	TCPServer.TCPServer.OnConnect:= DoConnect;
	TCPServer.TCPServer.OnDisconnect:= DoDisconnect;
	TCPServer.TCPServer.OnReject:= DoReject;
	TCPServer.TCPServer.OnReadData:= DoReadData;

    if  HasOption('m', '') then
		begin
		s:= GetOptionValue('m', '');
		if  TryStrToInt(s, i) then
			TCPServer.TCPServer.MaxConnections:= i
		else
			begin
    		ShowException(Exception.Create('Invalid max connections value!'));
    		Terminate;
    		Exit;
			end;
		end;

    TCPListener:= TTCPListener.Create('7632');

	ServerDisp:= TServerDispatcher.Create(False);

	silent:= HasOption('s', '');

	while not Terminated do
    	begin
		Sleep(100);

//	    f:= DebugMsgs.QueueSize > 0;

//		Update debug message display to offload queue (could potentially block ourselves
//      	if any more are added here, queue does not grow - has maximum).
//    	while DebugMsgs.QueueSize > 0 do
//			Memo1.Lines.Add(string(DebugMsgs.PopItem));
//    		DebugMsgs.PopItem;

        with LogMessages.LockList do
			try
			while Count > 0 do
				begin
				lm:= Items[0];
				Delete(0);
				if  not silent then
					begin
					Writeln(lm.Message);
					Flush(Output);
					end;
                lm.Free;
				end;
			finally
			LogMessages.UnlockList;
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

        with ExpirePlayers.LockList do
        	try
            while Count > 0 do
        		begin
        		p:= Items[0];
        		Delete(0);

                TCPServer.TCPServer.DisconnectIdent(p.Ident);

                AddLogMessage(slkInfo, GUIDToString(p.Ident) + ' released.');

                p.Free;

{$IFDEF DEBUG}
                Terminate;
                Break;
{$ENDIF}
        		end;
        	finally
            ExpirePlayers.UnlockList;
        	end;

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

        SystemZone.PlayersKeepAliveDecrement(100);
		SystemZone.PlayersKeepAliveExpire;

    	LimboZone.BumpCounter;
    	LimboZone.ExpirePlayers;
		end;

	TCPListener.Terminate;
    TCPListener.WaitFor;

//	TCPServer.TCPServer.Free;

{$IFNDEF DEBUG}
//	stop program loop
	Terminate;
{$ENDIF}
    end;

procedure TYahtzeeServer.DoConnect(const AIdent: TGUID);
	var
	p: TPlayer;
	m: TBaseMessage;
	s: string;

	begin
	AddLogMessage(slkInfo, GUIDToString(AIdent) + ' connected.');

	p:= TPlayer.Create(AIdent);
	SystemZone.Add(p);

	m:= TBaseMessage.Create;
	m.Category:= mcServer;
	m.Method:= $01;
	m.Params.Add(LIT_SYS_VERNAME);
	m.Params.Add(LIT_SYS_PLATFRM);
	m.Params.Add(LIT_SYS_VERSION);

	m.DataFromParams;

    p.SendWorkerMessage(m);
	end;

procedure TYahtzeeServer.DoDisconnect(const AIdent: TGUID);
	var
	p: TPlayer;

	begin
	p:= SystemZone.PlayerByIdent(AIdent);

    if  Assigned(p) then
        SystemZone.Remove(p);

    AddLogMessage(slkInfo, GUIDToString(AIdent) + ' disconnected gracefully.');
	end;

procedure TYahtzeeServer.DoReject(const AConnection: TTCPConnection);
	begin

	end;

procedure TYahtzeeServer.DoReadData(const AIdent: TGUID; const AData: TMsgData);
	var
	p: TPlayer;
	i,
	j: Integer;
	im: TBaseMessage;
	s: string;
    buf: TMsgData;

	begin
	p:= SystemZone.PlayerByIdent(AIdent);

    if  Assigned(p) then
		begin
//        p.Lock.Acquire;
//        try
		i:= Length(p.InputBuffer);
    	SetLength(p.InputBuffer, i + Length(AData));

//		for j:= Low(AData) to High(AData) do
//			begin
//			p.InputBuffer[i]:= AData[j];
//			Inc(i);
//			end;

		Move(AData[0], p.InputBuffer[i], Length(AData));

        while Length(p.InputBuffer) > 0 do
			begin
            if  p.InputBuffer[0] > (Length(p.InputBuffer) - 1) then
				Break;

			im:= TBaseMessage.Create;
			im.Ident:= AIdent;

        	SetLength(buf, p.InputBuffer[0] + 1);
            Move(p.InputBuffer[0], buf[0], Length(buf));

            im.Decode(buf);

            if  Length(p.InputBuffer) > Length(buf) then
				p.InputBuffer:= Copy(p.InputBuffer, Length(buf), MaxInt)
			else
				SetLength(p.InputBuffer, 0);

			s:= '>>' + IntToStr(buf[0]) + ' $' +
					IntToHex(buf[1], 2)+ ': ';

			for i:= 2 to High(buf) do
            	s:= s + Char(buf[i]);

			AddLogMessage(slkDebug, GUIDToString(AIdent) + ' ' + s);

			TCPServer.TCPServer.ReadMessages.Add(im);
            end;
//        finally
//        p.Lock.Release;
//        end;
        end;
	end;

constructor TYahtzeeServer.Create(TheOwner: TComponent);
	begin
	inherited Create(TheOwner);
	StopOnException:= True;
	end;

destructor TYahtzeeServer.Destroy;
	begin
	inherited Destroy;
	end;

procedure TYahtzeeServer.WriteHelp;
	begin
	writeln('Usage: ', ExeName, ' [-h|--help]|[[-s] [-m <connections>]]');
	end;

var
	Application: TYahtzeeServer;

begin
{$IFDEF DEBUG}
    if  FileExists('heap.trc') then
        DeleteFile('heap.trc');

    SetHeapTraceOutput('heap.trc');
{$ENDIF}

	Application:= TYahtzeeServer.Create(nil);

{$IFDEF DEBUG}
    CustomApplication:= Application;
{$ENDIF}

	Application.Title:='M3wP Yahtzee! Server';
	Application.Run;
	Application.Free;
end.

