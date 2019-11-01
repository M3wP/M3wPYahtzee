unit YahtzeeClient;

{$IFDEF FPC}
	{$MODE DELPHI}
{$ENDIF}
{$H+}

interface

uses
	Classes, SysUtils, Generics.Collections, YahtzeeClasses, LCLType, LMessages,
	LCLIntf, synsock, blcksock;

const
	YCM_BASE			=	LM_USER + $2000;
	YCM_UPDATEHOST		=   YCM_BASE;
 	YCM_UPDATEIDENT		=	YCM_BASE + 1;
	YCM_UPDATEROOMLIST	=	YCM_BASE + 2;
	YCM_UPDATEROOMUSERS = 	YCM_BASE + 3;
	YCM_UPDATEGAMELIST	=	YCM_BASE + 4;
	YCM_UPDATESLOTSTATE = 	YCM_BASE + 5;
	YCM_UPDATEROOM		= 	YCM_BASE + 6;
	YCM_UPDATEGAME		=	YCM_BASE + 7;
	YCM_UPDATEOURSTATE	=	YCM_BASE + 8;
	YCM_UPDATEGAMEDETAIL=	YCM_BASE + 9;
	YCM_UPDATEGAMESCORES=	YCM_BASE + 10;


type
	PString = ^string;

	TBaseMessages = TList<TBaseMessage>;

	{ TTCPConnection }
  	TTCPConnection = class
	private
		FHadData: Boolean;

	public
		Connected: Boolean;
		Socket: TTCPBlockSocket;

		ReadMessages: TBaseMessages;
		SendMessages: TBaseMessages;

		constructor Create; overload;
		destructor  Destroy; override;

		function  PrepareRead: Integer;
		function  ProcessSendMessages: Boolean;

		procedure Purge;
	end;

	TGameSlot = record
		Name: AnsiString;
		State: TPlayerState;
		Score: Word;
		Sheet: TScoreSheet;
		Dice: TDice;
		FirstRoll: Integer;
		Keepers: TDieSet;
	end;

	{ TYahtzeeGame }

	TYahtzeeGame = class
		Ident: AnsiString;
		Slots: array[0..5] of TGameSlot;
		OurSlot: Integer;
		VisibleSlot: Integer;
		State: TGameState;
		Round: Word;
		RollNo: Integer;
		Preview: TScoreSheet;
		PreviewLoc: TScoreLocations;
		SelScore: Boolean;
		SelScoreLoc: TScoreLocation;

		FollowActive: Boolean;

		constructor  Create;
	end;

	{ TYahtzeeClient }
	TYahtzeeClient = class
    private
    	procedure ProcessSystemMessage(AConnection: TTCPConnection;
				AMessage: TBaseMessage);
		procedure ProcessTextMessage(AConnection: TTCPConnection;
				AMessage: TBaseMessage);
		procedure ProcessLobbyMessage(AConnection: TTCPConnection;
				AMessage: TBaseMessage);
		procedure ProcessConnectMessage(AConnection: TTCPConnection;
				AMessage: TBaseMessage);
		procedure ProcessClientMessage(AConnection: TTCPConnection;
				AMessage: TBaseMessage);
		procedure ProcessServerMessage(AConnection: TTCPConnection;
				AMessage: TBaseMessage);
		procedure ProcessPlayMessage(AConnection: TTCPConnection;
				AMessage: TBaseMessage);

	protected
		FInputBuf: TMsgData;

		procedure SendClientIdent(AConnection: TTCPConnection);

	public
		Server: TNamedHost;
        OurIdent: AnsiString;

		Game: TYahtzeeGame;
        LastGameSpeak: AnsiString;
		GameHaveSpc: Boolean;

		Room: AnsiString;
        LastSpeak: AnsiString;
		RoomHaveSpc: Boolean;

		constructor Create;
		destructor  Destroy; override;

		procedure SendApplicationMessage(const AMessage: Cardinal;
				const AWParam: WParam; const ALParam: LParam);

		procedure SendConnctIdent(AConnection: TTCPConnection);
		procedure SendClientError(AConnection: TTCPConnection;
				const AMessage: string);

		procedure SendRoomJoin(AConnection: TTCPConnection;
				const ARoom, APassword: AnsiString);
		procedure SendRoomPart(AConnection: TTCPConnection);
		procedure SendRoomList(AConnection: TTCPConnection);
		procedure SendRoomMessage(AConnection: TTCPConnection;
				AText: AnsiString);

		procedure SendGameJoin(AConnection: TTCPConnection;
				const AGame, APassword: AnsiString);
		procedure SendGamePart(AConnection: TTCPConnection);
		procedure SendGameList(AConnection: TTCPConnection);
//TODO
//		procedure SendGameMessage(AConnection: TTCPConnection;
//				AText: AnsiString);
		procedure SendGameSlotStatus(AConnection: TTCPConnection;
				const ASlot: Integer; const AStatus: TPlayerState);
		procedure SendGameRollDice(AConnection: TTCPConnection;
				const ASlot: Integer; const ADice: TDieSet);
		procedure SendGameKeeper(AConnection: TTCPConnection;
				const ASlot: Integer; const ADie: TDie; const AKeep: Boolean);
		procedure SendGameScorePreview(AConnection: TTCPConnection;
				ASlot: Integer; AScoreLoc: TScoreLocation);
		procedure SendGameScore(AConnection: TTCPConnection;
				ASlot: Integer; AScoreLoc: TScoreLocation);

		function ReadConnectionData(AConnection: TTCPConnection;
				ASize: Integer): Boolean;
        procedure ProcessReadMessages(AConnection: TTCPConnection);
	end;

	TMessageList = class(TObject)
		Name,
		Desc,
		Locale: AnsiString;
	end;

	{ TMessageLists }

	TMessageLists = class(TObject)
	private
		procedure DoBeginMessageList(AMessageList: TMessageList);
		procedure DoDataMessageList(AMessageList: TMessageList;
				AData: AnsiString);

	public
		Lists: TList<TMessageList>;

		constructor Create;
		destructor  Destroy; override;

		function  MessageListByName(AName: AnsiString): TMessageList;

		procedure ReceiveTextMessage(AConnection: TTCPConnection;
				AMessage: TBaseMessage);

		procedure Clear;
	end;


	TTextMessages = TList<string>;


var
	HostLogMessages: TTextMessages;
	RoomLogMessages: TTextMessages;
	GameLogMessages: TTextMessages;

	ListMessages: TMessageLists;


implementation

uses
	Forms, DModClientMain;


const
	LIT_SYS_VERNAME = 'LCL_ref';
{$IFDEF LINUX}
	LIT_SYS_PLATFRM = 'linux';
{$ELSE}
	LIT_SYS_PLATFRM = 'mswindows';
{$ENDIF}
	LIT_SYS_VERSION = '0.00.80A';

	LIT_ERR_SERVERID = 'invalid server ident';
	LIT_ERR_SERVERCM = 'invalid server command';
	LIT_ERR_CONNCTCM = 'invalid connection command';
	LIT_ERR_CONNCTID = 'invalid connection ident';
	LIT_ERR_TEXTINVB = 'invalid text begin';
	LIT_ERR_TEXTINVM = 'invalid text more';
	LIT_ERR_TEXTINVD = 'invalid text data';

{ TYahtzeeGame }

constructor TYahtzeeGame.Create;
    var
	i: Integer;

	begin
	inherited;

    for i:= 0 to 5 do
		FillChar(Slots[i].Sheet, SizeOf(TScoreSheet), $FF);
	end;

{ TMessageLists }

procedure TMessageLists.DoBeginMessageList(AMessageList: TMessageList);
	begin
	if  CompareText(string(AMessageList.Desc), ARR_LIT_NAM_CATEGORY[mcLobby]) = 0 then
		begin
		if  Length(AMessageList.Locale) = 0 then
			ClientMainDMod.Client.SendApplicationMessage(YCM_UPDATEROOMLIST, 0, 0)
		else if  CompareText(string(AMessageList.Locale),
				string(ClientMainDMod.Client.Room)) = 0 then
   			ClientMainDMod.Client.SendApplicationMessage(YCM_UPDATEROOMUSERS, 0, 0)
		end
	else if CompareText(string(AMessageList.Desc), ARR_LIT_NAM_CATEGORY[mcPlay]) = 0 then
		if  Length(AMessageList.Locale) = 0 then
			ClientMainDMod.Client.SendApplicationMessage(YCM_UPDATEGAMELIST, 0, 0)
	end;

procedure TMessageLists.DoDataMessageList(AMessageList: TMessageList;
		AData: AnsiString);
	var
	p: Integer;
	u: AnsiString;
	s: Integer;
	d: AnsiString;

	begin
	if  CompareText(string(AMessageList.Desc), ARR_LIT_NAM_CATEGORY[mcSystem]) = 0 then
		begin
		HostLogMessages.Add('* ' + AData);
		end
	else if  CompareText(string(AMessageList.Desc), ARR_LIT_NAM_CATEGORY[mcLobby]) = 0 then
		if  Length(AMessageList.Locale) > 0 then
			begin
			if  CompareText(string(AMessageList.Locale),
					string(ClientMainDMod.Client.Room)) = 0 then
            	ClientMainDMod.Client.SendApplicationMessage(YCM_UPDATEROOMUSERS,
						WPARAM(@AData), 1);
			end
		else
			ClientMainDMod.Client.SendApplicationMessage(YCM_UPDATEROOMLIST,
					WPARAM(@AData), 1)
	else if  CompareText(string(AMessageList.Desc), ARR_LIT_NAM_CATEGORY[mcPlay]) = 0 then
		if  Length(AMessageList.Locale) > 0 then
			begin
			p:= Pos(' ', string(AData));
			u:= Copy(AData, Low(AData), p);
			d:= Copy(AData, p + 1, MaxInt);

			s:= Ord(d[Low(AnsiString)]) - $30;

			if  Assigned(ClientMainDMod.Client.Game) then
				begin
				ClientMainDMod.Client.Game.Slots[s].Name:= u;
				ClientMainDMod.Client.SendApplicationMessage(YCM_UPDATESLOTSTATE,
						WPARAM(ClientMainDMod.Client.Game.State), s);
				end;
			end
		else
			ClientMainDMod.Client.SendApplicationMessage(YCM_UPDATEGAMELIST,
					WPARAM(@AData), 1);
	end;

constructor TMessageLists.Create;
	begin
	inherited Create;

	Lists:= TList<TMessageList>.Create;
	end;

destructor TMessageLists.Destroy;
	var
	i: Integer;

	begin
	for i:= 0 to Lists.Count - 1 do
		Lists.Items[i].Free;

	Lists.Free;

	inherited Destroy;
	end;

function TMessageLists.MessageListByName(AName: AnsiString): TMessageList;
	var
	i: Integer;

	begin
	Result:= nil;

	for i:= 0 to Lists.Count - 1 do
		if  CompareText(string(Lists.Items[i].Name), string(AName)) = 0 then
			begin
			Result:= Lists.Items[i];
			Break;
			end;
	end;

procedure TMessageLists.ReceiveTextMessage(AConnection: TTCPConnection;
		AMessage: TBaseMessage);
	var
	ml: TMessageList;
	i: Integer;
	s: AnsiString;
	f: Boolean;
	m: TBaseMessage;

	begin
	if  AMessage.Category = mcText then
		if  AMessage.Method = $01 then
			begin
			AddLogMessage(slkDebug, 'Message text $01');

			AMessage.ExtractParams;

			f:= False;
			if  AMessage.Params.Count > 1 then
				begin
				ml:= MessageListByName(AMessage.Params[0]);

				if  not Assigned(ml) then
					begin
					ml:= TMessageList.Create;
					ml.Name:= AMessage.Params[0];
					ml.Desc:= AMessage.Params[1];

					if  AMessage.Params.Count > 2 then
						ml.Locale:= AMessage.Params[2];

					Lists.Add(ml);

					DoBeginMessageList(ml);

					f:= True;
					end;
				end;

			if  not f then
				ClientMainDMod.Client.SendClientError(AConnection, LIT_ERR_TEXTINVB);
			end
		else if AMessage.Method = $02 then
			begin
			AddLogMessage(slkDebug, 'Message text $02');

			AMessage.ExtractParams;

			f:= False;
			if  AMessage.Params.Count > 1 then
				begin
				ml:= MessageListByName(AMessage.Params[0]);

				if  Assigned(ml) then
					if  TryStrToInt(string(AMessage.Params[1]), i) then
						begin
						if  i = 0 then
							begin
							Lists.Remove(ml);
							ml.Free;

							f:= True;
							end
						else
							begin
							m:= TBaseMessage.Create;
							m.Assign(AMessage);

							AConnection.SendMessages.Add(m);
							end;
						end;
				end;

			if  not f then
				ClientMainDMod.Client.SendClientError(AConnection, LIT_ERR_TEXTINVM);
			end
		else if AMessage.Method = $03 then
			begin
			AddLogMessage(slkDebug, 'Message text $03');

			AMessage.ExtractParams;

			f:= False;
			if  AMessage.Params.Count > 0 then
				begin
				ml:= MessageListByName(AMessage.Params[0]);

				if  Assigned(ml) then
					begin
					s:= AnsiString('');

					for i:= 1 to AMessage.Params.Count - 1 do
						begin
						s:= s + AMessage.Params[i];
						if  i < (AMessage.Params.Count - 1) then
							s:= s + AnsiString(' ');
						end;

					DoDataMessageList(ml, s);

					f:= True;
					end;
				end;

			if  not f then
				ClientMainDMod.Client.SendClientError(AConnection, LIT_ERR_TEXTINVD);
			end;
	end;

procedure TMessageLists.Clear;
	var
	i: Integer;

	begin
	for i:= Lists.Count - 1 downto 0 do
		begin
		Lists.Items[i].Free;
		Lists.Delete(i);
		end;
	end;


{ TTCPConnection }

function TTCPConnection.PrepareRead: Integer;
    var
	i: Integer;
	TimeV: TTimeVal;
	FDSet: TFDSet;

	begin
	TimeV.tv_usec:= 1000;
	TimeV.tv_sec:= 0;
	FDSet:= Socket.FdSet;
	if  synsock.Select(Socket.Socket, nil, nil, @FDSet, @TimeV) > 0 then
		begin
		Result:= -1;
		AddLogMessage(slkInfo, 'Lost connection - error.');
		Exit;
		end;

	i:= Socket.WaitingData;

//	if  i = 0 then
//		begin
//		if  FHadData then
//		  	if  Socket.CanRead(1) then
//				begin
//				Result:= -1;
//				AddLogMessage(slkDebug, 'Lost connection - informed.');
//				Exit;
//				end;
//		end;

	if  not FHadData then
		FHadData:= i > 0;

    Result:= i;
	end;

function TTCPConnection.ProcessSendMessages: Boolean;
    var
	i: Integer;
	im: TBaseMessage;
	s2: string;
	buf: TMsgData;

	begin
    while SendMessages.Count > 0 do
		begin
		im:= SendMessages.Items[0];

        buf:= im.Encode;

        s2:= '<<' + IntToStr(buf[0]) + ' $' +
				IntToHex(buf[1], 2) + ': ';
		for i:= 2 to High(buf) do
			s2:= s2 + Char(buf[i]);

		AddLogMessage(slkDebug, s2);

		Socket.SendBuffer(TMemory(@(buf[0])), Length(buf));

		if  Socket.LastError <> 0 then
			begin
			Result:= False;
			AddLogMessage(slkInfo, 'Error while writing socket.');
			Exit;
			end;

        SendMessages.Delete(0);
		im.Free;
		end;

	Result:= True;
	end;

procedure TTCPConnection.Purge;
    var
	i: Integer;

	begin
	for i:= 0 to ReadMessages.Count - 1 do
		ReadMessages.Items[i].Free;

	ReadMessages.Clear;

	for i:= 0 to SendMessages.Count - 1 do
		SendMessages.Items[i].Free;

	SendMessages.Clear;

	FHadData:= False;
	end;

constructor TTCPConnection.Create;
	begin
    inherited;

	ReadMessages:= TBaseMessages.Create;
	SendMessages:= TBaseMessages.Create;

    Socket:= TTCPBlockSocket.Create;
	end;

destructor TTCPConnection.Destroy;
	begin
    Purge;

	ReadMessages.Free;
	SendMessages.Free;

    try
		Socket.CloseSocket;
		except
		end;

	Socket.Free;

	inherited Destroy;
	end;


{ TYahtzeeClient }

procedure TYahtzeeClient.ProcessSystemMessage(AConnection: TTCPConnection;
		AMessage: TBaseMessage);
	begin

	end;

procedure TYahtzeeClient.ProcessTextMessage(AConnection: TTCPConnection;
		AMessage: TBaseMessage);
	begin
	if  AMessage.Method = $04 then
		RoomLogMessages.Add('!' + string(AMessage.DataToString))
	else
		ListMessages.ReceiveTextMessage(AConnection, AMessage);
	end;

procedure TYahtzeeClient.ProcessLobbyMessage(AConnection: TTCPConnection;
		AMessage: TBaseMessage);
	var
	m: TBaseMessage;
	i: Integer;
	s: string;

	begin
	if  AMessage.Method = $01 then
		begin
		AMessage.ExtractParams;

		if  AMessage.Params.Count > 1 then
			begin
			if  (CompareText(string(AMessage.Params[1]), string(OurIdent)) = 0) then
				begin
				Room:= AMessage.Params[0];

				SendApplicationMessage(YCM_UPDATEROOM, 0, 1);
				end;

			if  (CompareText(string(AMessage.Params[0]), string(Room)) = 0) then
				begin
				s:= string(AMessage.Params[1]);
				SendApplicationMessage(YCM_UPDATEROOMUSERS, WPARAM(@s), 1);
				end;

			RoomLogMessages.Add('> ' + string(AMessage.Params[1]) + ' joins ' +
					string(AMessage.Params[0]));

			m:= TBaseMessage.Create;
			m.Category:= mcLobby;
			m.Method:= $03;
			m.Params.Add(Room);
			m.DataFromParams;

			AConnection.SendMessages.Add(m);
			end;
		end
	else if  AMessage.Method = $02 then
		begin
		AMessage.ExtractParams;

		if  AMessage.Params.Count > 1 then
			begin
			if  CompareText(string(AMessage.Params[1]), string(OurIdent)) = 0 then
				begin
				Room:= '';

				SendApplicationMessage(YCM_UPDATEROOM, 0, 0);
				end
			else if  (CompareText(string(AMessage.Params[0]), string(Room)) = 0) then
				begin
				s:= string(AMessage.Params[1]);
        		SendApplicationMessage(YCM_UPDATEROOMUSERS, WPARAM(@s), 2);
				end;

			RoomLogMessages.Add('< ' + string(AMessage.Params[1]) + ' parts ' +
					string(AMessage.Params[0]));
			end;
		end
	else if  AMessage.Method = $04 then
		RoomLogMessages.Add('-' + string(AMessage.DataToString));
	end;

procedure TYahtzeeClient.ProcessConnectMessage(AConnection: TTCPConnection;
		AMessage: TBaseMessage);
	begin
	if  AMessage.Method = $00 then
		begin
		HostLogMessages.Add('');
		HostLogMessages.Add('!!Connection Error:  ' + AMessage.DataToString);
		end
	else if  AMessage.Method = $01 then
		begin
		AMessage.ExtractParams;

		if  AMessage.Params.Count = 1 then
			begin
			OurIdent:= AMessage.Params[0];

			SendApplicationMessage(YCM_UPDATEIDENT, 0, 0);
			end
		else if AMessage.Params.Count = 2 then

		else
			SendClientError(AConnection, LIT_ERR_CONNCTID);
		end
	else
		SendClientError(AConnection, LIT_ERR_CONNCTCM);
	end;

procedure TYahtzeeClient.ProcessClientMessage(AConnection: TTCPConnection;
		AMessage: TBaseMessage);
	begin

	end;

procedure TYahtzeeClient.ProcessServerMessage(AConnection: TTCPConnection;
		AMessage: TBaseMessage);
    var
	m: TBaseMessage;

	begin
    case AMessage.Method of
		$00:
			begin
            HostLogMessages.Add('');
			HostLogMessages.Add('!!Server error: ' +
					string(AMessage.DataToString));
			end;
		$01:
			begin
			AMessage.ExtractParams;

			if  AMessage.Params.Count = 3 then
				begin
				if  not Assigned(Server) then
					Server:= TNamedHost.Create;

				Server.Name:= AMessage.Params[0];
				Server.Host:= AMessage.Params[1];
				Server.Version:= AMessage.Params[2];

				SendApplicationMessage(YCM_UPDATEHOST, 0, 0);

				SendClientIdent(AConnection);
				SendConnctIdent(AConnection);

				m:= TBaseMessage.Create;
				m.Category:= mcText;
				m.Method:= $00;

				AConnection.SendMessages.Add(m);
				end
			else
				SendClientError(AConnection, LIT_ERR_SERVERID);
			end;
		$02:
			begin
			m:= TBaseMessage.Create;
			m.Category:= mcClient;
			m.Method:= $02;

			AConnection.SendMessages.Add(m);
			end;
		end;
	end;

procedure TYahtzeeClient.ProcessPlayMessage(AConnection: TTCPConnection;
		AMessage: TBaseMessage);
	var
	m: TBaseMessage;
	i,
	j: Integer;
	n: TScoreLocation;
	r: Word;
	f: Boolean;

	begin
	if  AMessage.Method = $01 then
		begin
		AddLogMessage(slkDebug, 'Message play $01');

		AMessage.ExtractParams;

		if  AMessage.Params.Count > 2 then
			begin
			m:= nil;

			if  (CompareText(string(AMessage.Params[1]),
					string(ClientMainDMod.Client.OurIdent)) = 0) then
				begin
    			if  not Assigned(ClientMainDMod.Client.Game) then
                	ClientMainDMod.Client.Game:= TYahtzeeGame.Create;

				ClientMainDMod.Client.Game.Ident:= AMessage.Params[0];

				ClientMainDMod.Client.Game.State:= gsWaiting;
				ClientMainDMod.Client.Game.OurSlot:=
						Ord(AMessage.Params[2][Low(AnsiString)]) - $30;
				ClientMainDMod.Client.Game.VisibleSlot:= -1;

				for i:= 0 to 5 do
					FillChar(ClientMainDMod.Client.Game.Slots[i],
							SizeOf(TGameSlot), 0);

				for i:= 0 to 5 do
					for j:= Ord(Low(TScoreLocation)) to Ord(High(TScoreLocation)) do
						ClientMainDMod.Client.Game.Slots[i].Sheet[TScoreLocation(j)]:=
								VAL_KND_SCOREINVALID;

				ClientMainDMod.Client.SendApplicationMessage(YCM_UPDATEGAME,
						0, 1);

				m:= TBaseMessage.Create;
				m.Category:= mcPlay;
				m.Method:= $03;
				end;

			if  Assigned(ClientMainDMod.Client.Game) then
				if  (CompareText(string(AMessage.Params[0]),
						string(ClientMainDMod.Client.Game.Ident)) = 0) then
					begin
					i:= Ord(AMessage.Params[2][Low(AnsiString)]) - $30;
					ClientMainDMod.Client.Game.Slots[i].Name:= AMessage.Params[1];
					end;

			if  Assigned(m) then
				m.Params.Add(ClientMainDMod.Client.Game.Ident);
			end;

		if  Assigned(m) then
			begin
			m.DataFromParams;
			AConnection.SendMessages.Add(m);
			end;

		GameLogMessages.Add('> ' + string(AMessage.Params[1]) +
				' joins ' + string(AMessage.Params[0]));
		end
	else if  AMessage.Method = $02 then
		begin
		AddLogMessage(slkDebug, 'Message play $02');

		AMessage.ExtractParams;

		if  AMessage.Params.Count > 1 then
			begin
			if  Assigned(ClientMainDMod.Client.Game) then
				begin
				if  CompareText(string(AMessage.Params[1]),
						string(ClientMainDMod.Client.OurIdent)) = 0 then
					begin
					ClientMainDMod.Client.Game.Ident:= AnsiString('');

					ClientMainDMod.Client.SendApplicationMessage(YCM_UPDATEGAME,
							0, 0);

					ClientMainDMod.Client.Game.Free;
                    ClientMainDMod.Client.Game:= nil;
					end
				else if (CompareText(string(AMessage.Params[0]),
						string(ClientMainDMod.Client.Game.Ident)) = 0) then
					begin

					end;
				end;

			GameLogMessages.Add('< ' + string(AMessage.Params[1]) +
					' parts ' + string(AMessage.Params[0]));
			end;
		end
	else if  AMessage.Method = $04 then
		begin
		AddLogMessage(slkDebug, 'Message play $04');

		GameLogMessages.Add('-' + string(AMessage.DataToString));
		end
	else if AMessage.Method = $06 then
		begin
		AddLogMessage(slkDebug, 'Message play $06');

		if  Length(AMessage.Data) = 3 then
			begin
			if  Assigned(ClientMainDMod.Client.Game) then
				begin
				ClientMainDMod.Client.Game.State:=
						TGameState(AMessage.Data[0]);
				ClientMainDMod.Client.Game.Round:=
						(AMessage.Data[1] shl 8) or AMessage.Data[2];

				for i:= 0 to 5 do
					ClientMainDMod.Client.SendApplicationMessage(
							YCM_UPDATESLOTSTATE,
							Ord(ClientMainDMod.Client.Game.State), i);

				ClientMainDMod.Client.SendApplicationMessage(YCM_UPDATEOURSTATE,
						0, 0);
				end;
			end;
		end
	else if AMessage.Method = $07 then
		begin
		AddLogMessage(slkDebug, 'Message play $07');

		if  Length(AMessage.Data) = 4 then
			begin
			if  Assigned(ClientMainDMod.Client.Game) then
				begin
				i:= AMessage.Data[0];
				ClientMainDMod.Client.Game.Slots[i].State:= TPlayerState(
						AMessage.Data[1]);
				ClientMainDMod.Client.Game.Slots[i].Score:=
						(AMessage.Data[2] shl 8) or AMessage.Data[3];

                if  ClientMainDMod.Client.Game.Slots[i].State = psPlaying then
					ClientMainDMod.Client.Game.RollNo:= -1;

				ClientMainDMod.Client.SendApplicationMessage(
						YCM_UPDATESLOTSTATE,
						Ord(ClientMainDMod.Client.Game.State), i);

				if  i = ClientMainDMod.Client.Game.OurSlot then
    				ClientMainDMod.Client.SendApplicationMessage(
							YCM_UPDATEOURSTATE, 0, 0);

				if  ClientMainDMod.Client.Game.FollowActive
				and (ClientMainDMod.Client.Game.Slots[i].State = psPlaying) then
					ClientMainDMod.Client.Game.VisibleSlot:= i;

				if  ClientMainDMod.Client.Game.FollowActive
				or  ((ClientMainDMod.Client.Game.State > gsPreparing)
				and  (i = ClientMainDMod.Client.Game.VisibleSlot)) then
    				ClientMainDMod.Client.SendApplicationMessage(
							YCM_UPDATEGAMEDETAIL, 0, 0);
				end;
			end;
		end
	else if AMessage.Method = $08 then
		begin
		AddLogMessage(slkDebug, 'Message play $08');

//		ClientMainDMod.ActGameRoll.Tag:= 0;

		if  Length(AMessage.Data) = 6 then
			begin
			if  Assigned(ClientMainDMod.Client.Game) then
				begin
				i:= AMessage.Data[0];

				for j:= 0 to 4 do
					ClientMainDMod.Client.Game.Slots[i].Dice[j]:=
							AMessage.Data[j + 1];

				if  ClientMainDMod.Client.Game.Slots[i].State = psPreparing then
					begin
					ClientMainDMod.Client.Game.Slots[i].FirstRoll:= 0;
					for j:= 0 to 4 do
						ClientMainDMod.Client.Game.Slots[i].FirstRoll:=
								ClientMainDMod.Client.Game.Slots[i].FirstRoll +
								ClientMainDMod.Client.Game.Slots[i].Dice[j];
					end;

				ClientMainDMod.Client.Game.RollNo:=
						ClientMainDMod.Client.Game.RollNo + 1;

				if  (ClientMainDMod.Client.Game.State > gsPreparing)
				and (i = ClientMainDMod.Client.Game.VisibleSlot) then
    				ClientMainDMod.Client.SendApplicationMessage(
							YCM_UPDATEGAMEDETAIL, 0, 0);
				end;
			end;
		end
	else if AMessage.Method = $09 then
		begin
		AddLogMessage(slkDebug, 'Message play $09');

		if  Length(AMessage.Data) = 3 then
			begin
			if  Assigned(ClientMainDMod.Client.Game) then
				begin
				i:= AMessage.Data[0];

				if  AMessage.Data[2] = 0 then
					Exclude(ClientMainDMod.Client.Game.Slots[i].Keepers, AMessage.Data[1])
				else
					Include(ClientMainDMod.Client.Game.Slots[i].Keepers, AMessage.Data[1]);

				if  (ClientMainDMod.Client.Game.State > gsPreparing)
				and (i = ClientMainDMod.Client.Game.VisibleSlot) then
    				ClientMainDMod.Client.SendApplicationMessage(
							YCM_UPDATEGAMEDETAIL, 0, 0);
				end;
			end;
		end
	else if AMessage.Method = $0A then
		begin
		AddLogMessage(slkDebug, 'Message play $0A');

		f:= False;

		if  Length(AMessage.Data) = 4 then
			begin
			if  Assigned(ClientMainDMod.Client.Game) then
				begin
				i:= AMessage.Data[0];
				n:= TScoreLocation(AMessage.Data[1]);
				r:= (AMessage.Data[2] shl 8) or AMessage.Data[3];

				ClientMainDMod.Client.Game.Preview[n]:= r;
				Include(ClientMainDMod.Client.Game.PreviewLoc, n);

				f:= ClientMainDMod.Client.Game.VisibleSlot = i;
				end;

			if  f then
				ClientMainDMod.Client.SendApplicationMessage(
						YCM_UPDATEGAMESCORES, 0, 0);
			end;
		end
	else if AMessage.Method = $0B then
		begin
		AddLogMessage(slkDebug, 'Message play $0B');

		f:= False;
		if  Length(AMessage.Data) = 4 then
			begin
			if  Assigned(ClientMainDMod.Client.Game) then
				begin
				i:= AMessage.Data[0];
				n:= TScoreLocation(AMessage.Data[1]);
				r:= (AMessage.Data[2] shl 8) or AMessage.Data[3];

				ClientMainDMod.Client.Game.Slots[i].Sheet[n]:= r;

				ClientMainDMod.Client.Game.RollNo:= 0;
				ClientMainDMod.Client.Game.SelScore:= False;

				f:= ClientMainDMod.Client.Game.VisibleSlot = i;
				end;

			if  f then
				ClientMainDMod.Client.SendApplicationMessage(
						YCM_UPDATEGAMESCORES, 0, 0);
			end;
		end;
	end;

procedure TYahtzeeClient.SendApplicationMessage(const AMessage: Cardinal;
		const AWParam: WParam; const ALParam: LParam);
	begin
    SendMessage(Application.MainForm.Handle, AMessage, AWParam, ALParam);
	end;

procedure TYahtzeeClient.SendClientError(AConnection: TTCPConnection;
		const AMessage: string);
	var
	m: TBaseMessage;

	begin
	m:= TBaseMessage.Create;

	m.Category:= mcClient;
	m.Method:= 0;
	m.Params.Add(AnsiString(AMessage));
	m.DataFromParams;

	AConnection.SendMessages.Add(m);
	end;

procedure TYahtzeeClient.SendRoomJoin(AConnection: TTCPConnection; const ARoom,
		APassword: AnsiString);
	var
	m: TBaseMessage;

	begin
	m:= TBaseMessage.Create;

	m.Category:= mcLobby;
	m.Method:= 1;
	m.Params.Add(ARoom);

    if  Length(APassword) > 0 then
		m.Params.Add(APassword);

	m.DataFromParams;

	AConnection.SendMessages.Add(m);
	end;

procedure TYahtzeeClient.SendRoomPart(AConnection: TTCPConnection);
	var
	m: TBaseMessage;

	begin
	m:= TBaseMessage.Create;

	m.Category:= mcLobby;
	m.Method:= 2;
	m.Params.Add(Room);

	m.DataFromParams;

	AConnection.SendMessages.Add(m);
	end;

procedure TYahtzeeClient.SendRoomList(AConnection: TTCPConnection);
	var
	m: TBaseMessage;

	begin
	m:= TBaseMessage.Create;
	m.Category:= mcLobby;
	m.Method:= $03;

	AConnection.SendMessages.Add(m);
	end;

procedure TYahtzeeClient.SendRoomMessage(AConnection: TTCPConnection;
		AText: AnsiString);
    var
	m: TBaseMessage;

	begin
	m:= TBaseMessage.Create;

	m.Category:= mcLobby;
	m.Method:= 4;
	m.Params.Add(Room);
	m.Params.Add(OurIdent);
	m.Params.Add(AText);

	m.DataFromParams;

	AConnection.SendMessages.Add(m);
	end;

procedure TYahtzeeClient.SendGameJoin(AConnection: TTCPConnection; const AGame,
		APassword: AnsiString);
	var
	m: TBaseMessage;

	begin
	m:= TBaseMessage.Create;

	m.Category:= mcPlay;
	m.Method:= 1;
	m.Params.Add(AGame);

    if  Length(APassword) > 0 then
		m.Params.Add(APassword);

	m.DataFromParams;

	AConnection.SendMessages.Add(m);
	end;

procedure TYahtzeeClient.SendGamePart(AConnection: TTCPConnection);
	var
	m: TBaseMessage;

	begin
	m:= TBaseMessage.Create;

	m.Category:= mcPlay;
	m.Method:= 2;
	m.Params.Add(Game.Ident);

	m.DataFromParams;

	AConnection.SendMessages.Add(m);
	end;

procedure TYahtzeeClient.SendGameList(AConnection: TTCPConnection);
	var
	m: TBaseMessage;

	begin
	m:= TBaseMessage.Create;
	m.Category:= mcPlay;
	m.Method:= $03;

	AConnection.SendMessages.Add(m);
	end;

procedure TYahtzeeClient.SendGameSlotStatus(AConnection: TTCPConnection;
		const ASlot: Integer; const AStatus: TPlayerState);
	var
	m: TBaseMessage;

	begin
	m:= TBaseMessage.Create;

	m.Category:= mcPlay;
	m.Method:= $07;
	SetLength(m.Data, 2);
	m.Data[0]:= Byte(ASlot);
	m.Data[1]:= Ord(AStatus);

	AConnection.SendMessages.Add(m);
	end;

procedure TYahtzeeClient.SendGameRollDice(AConnection: TTCPConnection;
		const ASlot: Integer; const ADice: TDieSet);
    var
	m: TBaseMessage;

	begin
	m:= TBaseMessage.Create;
	m.Category:= mcPlay;
	m.Method:= $08;
	SetLength(m.Data, 2);
	m.Data[0]:= Byte(ASlot);
	m.Data[1]:= DieSetToByte(ADice);

	AConnection.SendMessages.Add(m);
	end;

procedure TYahtzeeClient.SendGameKeeper(AConnection: TTCPConnection;
		const ASlot: Integer; const ADie: TDie; const AKeep: Boolean);
    var
	m: TBaseMessage;

	begin
	m:= TBaseMessage.Create;
	m.Category:= mcPlay;
	m.Method:= $09;

	SetLength(m.Data, 3);

	m.Data[0]:= Byte(ASlot);
	m.Data[1]:= Byte(ADie);
	m.Data[2]:= Ord(AKeep);

	AConnection.SendMessages.Add(m);
	end;

procedure TYahtzeeClient.SendGameScorePreview(AConnection: TTCPConnection;
		ASlot: Integer; AScoreLoc: TScoreLocation);
	var
	m: TBaseMessage;

	begin
	m:= TBaseMessage.Create;
	m.Category:= mcPlay;
	m.Method:= $0A;
	SetLength(m.Data, 2);

	m.Data[0]:= Byte(ASlot);
	m.Data[1]:= Ord(AScoreLoc);

	AConnection.SendMessages.Add(m);
	end;

procedure TYahtzeeClient.SendGameScore(AConnection: TTCPConnection;
		ASlot: Integer; AScoreLoc: TScoreLocation);
	var
	m: TBaseMessage;

	begin
	m:= TBaseMessage.Create;
	m.Category:= mcPlay;
	m.Method:= $0B;
	SetLength(m.Data, 2);

	m.Data[0]:= Byte(ASlot);
	m.Data[1]:= Byte(Ord(AScoreLoc));

	AConnection.SendMessages.Add(m);
	end;

procedure TYahtzeeClient.SendClientIdent(AConnection: TTCPConnection);
	var
	m: TBaseMessage;

	begin
	m:= TBaseMessage.Create;

	m.Category:= mcClient;
	m.Method:= 1;
	m.Params.Add(AnsiString(LIT_SYS_VERNAME));
	m.Params.Add(AnsiString(LIT_SYS_PLATFRM));
	m.Params.Add(AnsiString(LIT_SYS_VERSION));
	m.DataFromParams;

	AConnection.SendMessages.Add(m);
	end;

procedure TYahtzeeClient.SendConnctIdent(AConnection: TTCPConnection);
	var
	m: TBaseMessage;

	begin
	m:= TBaseMessage.Create;

	m.Category:= mcConnect;
	m.Method:= 1;
	m.Params.Add(OurIdent);
	m.DataFromParams;

	AConnection.SendMessages.Add(m);
	end;

procedure TYahtzeeClient.ProcessReadMessages(AConnection: TTCPConnection);
    var
	i: Integer;
	m: TBaseMessage;

	begin
    for  i:= 0 to AConnection.ReadMessages.Count - 1 do
		try
        	m:= AConnection.ReadMessages.Items[i];
			case m.Category of
                mcSystem:
					ProcessSystemMessage(AConnection, m);
				mcText:
					ProcessTextMessage(AConnection, m);
				mcLobby:
					ProcessLobbyMessage(AConnection, m);
				mcConnect:
					ProcessConnectMessage(AConnection, m);
				mcClient:
					ProcessClientMessage(AConnection, m);
				mcServer:
					ProcessServerMessage(AConnection, m);
				mcPlay:
					ProcessPlayMessage(AConnection, m);
				end;

        	m.Free;

			except
			end;

	AConnection.ReadMessages.Clear;
	end;

constructor TYahtzeeClient.Create;
	begin
    inherited;

	GameHaveSpc:= True;
	RoomHaveSpc:= True;
	end;

destructor TYahtzeeClient.Destroy;
	begin
	if  Assigned(Game) then
		Game.Free;

	if  Assigned(Server) then
		Server.Free;

	inherited Destroy;
	end;

function TYahtzeeClient.ReadConnectionData(AConnection: TTCPConnection;
	ASize: Integer): Boolean;
    var
	i,
	j: Integer;
    buf: TMsgData;
	im: TBaseMessage;
	s: string;

	begin
	SetLength(buf, ASize);

    j:= AConnection.Socket.RecvBufferEx(TMemory(@(buf[0])), ASize, 100);

    Assert(ASize >= j, 'Buffer exceeded bounds!');

	if  AConnection.Socket.LastError = 0 then
		begin
		if  j > 0 then
			begin
        	if  j < ASize then
    	    	SetLength(buf, j);

    		i:= Length(FInputBuf);
        	SetLength(FInputBuf, i + Length(buf));

    		Move(buf[0], FInputBuf[i], Length(buf));

            while Length(FInputBuf) > 0 do
    			begin
                if  FInputBuf[0] > (Length(FInputBuf) - 1) then
    				Break;

    			im:= TBaseMessage.Create;

            	SetLength(buf, FInputBuf[0] + 1);
                Move(FInputBuf[0], buf[0], Length(buf));

                im.Decode(buf);

                if  Length(FInputBuf) > Length(buf) then
    				FInputBuf:= Copy(FInputBuf, Length(buf), MaxInt)
    			else
    				SetLength(FInputBuf, 0);

    			s:= '>>' + IntToStr(buf[0]) + ' $' +
    					IntToHex(buf[1], 2)+ ': ';

    			for i:= 2 to High(buf) do
                	s:= s + Char(buf[i]);

    			AddLogMessage(slkDebug, s);

    			AConnection.ReadMessages.Add(im);
            	end;

            Result:= True;
			end
		end
	else
		begin
		Result:= False;
		AddLogMessage(slkInfo, 'Error while reading socket.');
		Exit;
		end;
	end;

initialization
	HostLogMessages:= TTextMessages.Create;
	RoomLogMessages:= TTextMessages.Create;
	GameLogMessages:= TTextMessages.Create;

	ListMessages:= TMessageLists.Create;

finalization
	HostLogMessages.Clear;
	HostLogMessages.Free;

	RoomLogMessages.Clear;
	RoomLogMessages.Free;

	GameLogMessages.Clear;
	GameLogMessages.Free;

	ListMessages.Clear;
	ListMessages.Free;

end.

