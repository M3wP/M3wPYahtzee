unit DModCLIServerMain;

{$mode objfpc}{$H+}

{.DEFINE DEBUG}

interface

uses
	Classes, SysUtils, IdTCPServer, IdContext;

type

	{ TCLIServerMainDMod }

	TCLIServerMainDMod = class(TDataModule)
		IdTCPServer1: TIdTCPServer;
		procedure IdTCPServer1Connect(AContext: TIdContext);
		procedure IdTCPServer1Disconnect(AContext: TIdContext);
  		procedure IdTCPServer1Execute(AContext: TIdContext);
	private

	public

	end;

var
	CLIServerMainDMod: TCLIServerMainDMod;

implementation

{$R *.lfm}

uses
	IdGlobal, IdIOHandler, YahtzeeClasses, YahtzeeServer
{$IFDEF DEBUG}
    , CustApp
{$ENDIF};

{ TCLIServerMainDMod }

procedure TCLIServerMainDMod.IdTCPServer1Execute(AContext: TIdContext);
	var
	p: TPlayer;
	m: TMessage;
	buffer: TIdBytes;
	io: TIdIOHandler;
	s: TConnectMessage;
	i: Integer;
{$IFDEF FPC}
	debugs: string;
{$ENDIF}

	begin
	io:= AContext.Connection.IOHandler;

	p:= SystemZone.PlayerByConnection(AContext.Connection);

{$IFNDEF FPC}
	while p.Messages.QueueSize > 0 do
		begin
		m:= p.Messages.PopItem;
		m.Encode(buffer);
		m.Free;

		io.Write(buffer);

		DebugMsgs.PushItem('Sent client message.');
		end;
{$ELSE}
	m:= nil;
	with p.Messages.LockList do
		try
        while Count > 0 do
			begin
			m:= Items[0];
			Delete(0);

			m.Encode(buffer);
			m.Free;

        	io.Write(buffer);

	        debugs:= 'Sent client message.';
			UniqueString(debugs);
			DebugMsgs.Add(debugs);
			end;
		finally
       	p.Messages.UnlockList;
   		end;
{$ENDIF}

	io.ReadTimeout:= 1;
	io.ReadBytes(p.InputBuffer, -1, True);

	if  (Length(p.InputBuffer) > 0)
	and (Length(p.InputBuffer) > p.InputBuffer[0]) then
		begin
		SetLength(buffer, p.InputBuffer[0] + 1);
		for i:= 0 to p.InputBuffer[0] do
			buffer[i]:= p.InputBuffer[i];

		p.InputBuffer:= Copy(p.InputBuffer, p.InputBuffer[0] + 1, MaxInt);

		m:= TMessage.Create;
		m.Decode(buffer);

		s:= TConnectMessage.Create;
		s.Connection:= AContext.Connection;
		s.Msg:= m;

{$IFNDEF FPC}
		ServerMsgs.PushItem(s);
		DebugMsgs.PushItem('Received client message.');
{$ElSE}
        ServerMsgs.Add(s);

        debugs:= 'Received client message.';
		UniqueString(debugs);
		DebugMsgs.Add(debugs);
{$ENDIF}
		end;
	end;

procedure TCLIServerMainDMod.IdTCPServer1Connect(AContext: TIdContext);
	var
	p: TPlayer;
	m: TMessage;
{$IFDEF FPC}
	s: string;
{$ENDIF}

	begin
{$IFNDEF FPC}
	DebugMsgs.PushItem('Client connected.');
{$ELSE}
	s:= 'Client connected.';
	UniqueString(s);
	DebugMsgs.Add(s);
{$ENDIF}

	p:= TPlayer.Create(AContext.Connection);
	SystemZone.Add(p);

	m:= TMessage.Create;
	m.Category:= mcServer;
	m.Method:= $01;
	m.Params.Add(LIT_SYS_VERNAME);
	m.Params.Add(LIT_SYS_PLATFRM);
	m.Params.Add(LIT_SYS_VERSION);

	m.DataFromParams;

{$IFNDEF FPC}
	p.Messages.PushItem(m);
{$ELSE}
	p.Messages.Add(m);
{$ENDIF}
	end;

procedure TCLIServerMainDMod.IdTCPServer1Disconnect(AContext: TIdContext);
	var
	p: TPlayer;
{$IFDEF FPC}
	s: string;
{$ENDIF}

	begin
	p:= SystemZone.PlayerByConnection(AContext.Connection);
	SystemZone.Remove(p);

	p.Free;

{$IFNDEF FPC}
	DebugMsgs.PushItem('Client disconnected.');
{$ELSE}
    s:= 'Client disconnected.';
	UniqueString(s);
    DebugMsgs.Add(s);
{$ENDIF}

{$IFDEF DEBUG}
    CustomApplication.Terminate;
{$ENDIF}
    end;

end.

