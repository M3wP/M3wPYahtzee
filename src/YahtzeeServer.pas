unit YahtzeeServer;

{$IFDEF FPC}
	{$MODE DELPHI}
{$ENDIF}

interface

uses
	SyncObjs, Generics.Collections, Classes, TCPServer, YahtzeeClasses;

type

	{ TServerDispatcher }
	TServerDispatcher = class(TThread)
	protected
		procedure Execute; override;

	public
		ReadMessages: TIdentMessages;

		constructor Create;
		destructor  Destroy; override;
	end;

	TPlayer = class;
	TPlayersList = TThreadList<TPlayer>;

	TMessageTemplate = record
		Category: TMsgCategory;
		Method: Byte;
	end;

	TMessageList = class(TObject)
		Player: TPlayer;
		Name: AnsiString;
		Template: TMessageTemplate;
		Data: TQueue<AnsiString>;
		Process: Boolean;
		Complete: Boolean;
		Counter: Cardinal;

		constructor Create(APlayer: TPlayer);
		destructor  Destroy; override;

		procedure ProcessList;
		procedure Elapsed;
	end;

	TMessageLists = TThreadList<TMessageList>;

	TZone = class(TObject)
	protected
		FPlayers: TPlayersList;

		function  GetCount: Integer;
		function  GetPlayers(AIndex: Integer): TPlayer;

	public
		Desc: AnsiString;

		constructor Create; virtual;
		destructor  Destroy; override;

		class function  Name: AnsiString; virtual; abstract;

		procedure Remove(APlayer: TPlayer); virtual;
		procedure Add(APlayer: TPlayer); virtual;

		function  PlayerByIdent(const AIdent: TGUID): TPlayer;

		procedure ProcessPlayerMessage(APlayer: TPlayer; AMessage: TBaseMessage;
				var AHandled: Boolean); virtual; abstract;

		property PlayerCount: Integer read GetCount;
		property Players[AIndex: Integer]: TPlayer read GetPlayers; default;
	end;

	TSystemZone = class(TZone)
	public
		destructor  Destroy; override;

		class function  Name: AnsiString; override;

		procedure Remove(APlayer: TPlayer); override;
		procedure Add(APlayer: TPlayer); override;

		function  PlayerByName(AName: AnsiString): TPlayer;

		procedure ProcessPlayerMessage(APlayer: TPlayer; AMessage: TBaseMessage;
				var AHandled: Boolean); override;

		procedure PlayersKeepAliveDecrement(Ams: Integer);
		procedure PlayersKeepAliveExpire;
	end;

	TLimboZone = class(TZone)
	public
		class function  Name: AnsiString; override;

		procedure Remove(APlayer: TPlayer); override;
		procedure Add(APlayer: TPlayer); override;

		procedure BumpCounter;
		procedure ExpirePlayers;

		procedure ProcessPlayerMessage(APlayer: TPlayer; AMessage: TBaseMessage;
				var AHandled: Boolean); override;
	end;

	TLobbyZone = class;

	TLobbyRoom = class(TZone)
	public
		Lobby: TLobbyZone;
		Password: AnsiString;

		destructor  Destroy; override;

		class function  Name: AnsiString; override;

		procedure Remove(APlayer: TPlayer); override;
		procedure Add(APlayer: TPlayer); override;

		procedure ProcessPlayerMessage(APlayer: TPlayer; AMessage: TBaseMessage;
				var AHandled: Boolean); override;
	end;

	TLobbyRooms = TThreadList<TLobbyRoom>;

	TLobbyZone = class(TZone)
	private
		FRooms: TLobbyRooms;

	public
		constructor Create; override;
		destructor  Destroy; override;

		class function  Name: AnsiString; override;

		function  RoomByName(ADesc: AnsiString): TLobbyRoom;

		procedure RemoveRoom(ADesc: AnsiString);
		function  AddRoom(ADesc, APassword: AnsiString): TLobbyRoom;

		procedure Remove(APlayer: TPlayer); override;
		procedure Add(APlayer: TPlayer); override;

		procedure ProcessPlayerMessage(APlayer: TPlayer; AMessage: TBaseMessage;
				var AHandled: Boolean); override;
	end;

	TPlayZone = class;

	TPlaySlot = record
		Player: TPlayer;
		Name: AnsiString;
		State: TPlayerState;
		Score: Word;
		ScoreSheet: TScoreSheet;
		RollNo: Integer;
		Dice: TDice;
		Keepers: TDieSet;
		First: Boolean;
		FirstRoll: Integer;
	end;

	TPlayGame = class(TZone)
	public
		Play: TPlayZone;
		Password: AnsiString;
		Lock: TCriticalSection;
		State: TGameState;
		Round: Word;
		Turn: Integer;
		Slots: array[0..5] of TPlaySlot;
		SlotCount: Integer;
		ReadyCount: Integer;

		constructor Create; override;
		destructor  Destroy; override;

		class function  Name: AnsiString; override;

		procedure Remove(APlayer: TPlayer); override;
		procedure Add(APlayer: TPlayer); override;

		procedure ProcessPlayerMessage(APlayer: TPlayer; AMessage: TBaseMessage;
				var AHandled: Boolean); override;

		procedure SendGameStatus(APlayer: TPlayer);
		procedure SendSlotStatus(APlayer: TPlayer; ASlot: Integer);
	end;

	TPlayGames = TThreadList<TPlayGame>;

	TPlayZone = class(TZone)
	private
		FGames: TPlayGames;

	public
		constructor Create; override;
		destructor  Destroy; override;

		class function  Name: AnsiString; override;

		function  GameByName(ADesc: AnsiString): TPlayGame;

		procedure RemoveGame(ADesc: AnsiString);
		function  AddGame(ADesc, APassword: AnsiString): TPlayGame;

		procedure Remove(APlayer: TPlayer); override;
		procedure Add(APlayer: TPlayer); override;

		procedure ProcessPlayerMessage(APlayer: TPlayer; AMessage: TBaseMessage;
				var AHandled: Boolean); override;
	end;

	TZoneClass = class of TZone;

	TZones = TThreadList<TZone>;

	TExpireZones = TThreadList<TZone>;
    TExpirePlayers = TThreadList<TPlayer>;

	{ TPlayer }

    TPlayer = class(TObject)
	public
		Ident: TGUID;
		Ticket: string;
//		Connection: TTCPConnection;

		Zones: TZones;

        Lock: TCriticalSection;
		Name: AnsiString;
		Client: TNamedHost;

		Counter: Integer;
		KeepAliveCntr: Integer;
		NeedKeepAlive: Integer;
		SendKeepAlive: Boolean;

//		Messages: TMessages;

		InputBuffer: TMsgData;

		constructor Create(AIdent: TGUID);
		destructor  Destroy; override;

		procedure AddZone(AZone: TZone);
		procedure RemoveZone(AZone: TZone);
		procedure RemoveZoneByClass(AZoneClass: TZoneClass);
		procedure ClearZones;

		function  FindZoneByClass(AZoneClass: TZoneClass): TZone;
		function  FindZoneByNameDesc(AName, ADesc: AnsiString): TZone;

		procedure SendServerError(AMessage: AnsiString);

		procedure AddSendMessage(var AMessage: TBaseMessage);

		procedure KeepAliveReset;
		procedure KeepAliveDecrement(Ams: Integer);
	end;

var
	SystemZone: TSystemZone;
	LimboZone: TLimboZone;
	LobbyZone: TLobbyZone;
	PlayZone: TPlayZone;

	ServerDisp: TServerDispatcher;

	ListMessages: TMessageLists;

	ExpireZones: TExpireZones;
    ExpirePlayers: TExpirePlayers;


const
	LIT_SYS_VERNAME: AnsiString = 'alpha';
{$IFDEF ANDROID}
	LIT_SYS_PLATFRM: AnsiString = 'android';
{$ELSE}
	{$IFDEF UNIX}
		{$IFDEF LINUX}
   	LIT_SYS_PLATFRM: AnsiString = 'linux';
		{$ELSE}
   	LIT_SYS_PLATFRM: AnsiString = 'unix';
		{$ENDIF}
	{$ELSE}
	LIT_SYS_PLATFRM: AnsiString = 'mswindows';
	{$ENDIF}
{$ENDIF}
	LIT_SYS_VERSION: AnsiString = '0.00.82A';


implementation

uses
	SysUtils;

const
	ARR_LIT_SYS_INFO: array[0..4] of AnsiString = (
			'Yahtzee development system',
			'--------------------------',
			'Early alpha stage',
			'By Daniel England',
			'For Ecclestial Solutions');

	LIT_ERR_CLIENTID: AnsiString = 'Invalid client ident';
	LIT_ERR_CONNCTID: AnsiString = 'Invalid connect ident';
	LIT_ERR_SERVERUN: AnsiString = 'Unrecognised command';
	LIT_ERR_LBBYJINV: AnsiString = 'Invalid lobby join';
	LIT_ERR_LBBYPINV: AnsiString = 'Invalid lobby part';
	LIT_ERR_LBBYLINV: AnsiString = 'Invalid lobby list';
	LIT_ERR_TEXTPINV: AnsiString = 'Invalid text peer';
	LIT_ERR_PLAYJINV: AnsiString = 'Invalid play join';
	LIT_ERR_PLAYPINV: AnsiString = 'Invalid play part';
	LIT_ERR_PLAYLINV: AnsiString = 'Invalid play list';
	LIT_ERR_PLAYPWDR: AnsiString = 'Play password mismatch';
	LIT_ERR_PLAYGMST: AnsiString = 'Play in progress or full';
	LIT_ERR_PLAYNORL: AnsiString = 'Play rolls complete';


procedure DoDestroyListMessages;
	var
	i: Integer;

	begin
	with ListMessages.LockList do
		try
		for i:= Count - 1 downto 0 do
			Items[i].Free;

        Clear;

		finally
		ListMessages.UnlockList;
		end;

	ListMessages.Free;
	end;


{ TZone }

procedure TZone.Add(APlayer: TPlayer);
	begin
	FPlayers.Add(APlayer);
	APlayer.Zones.Add(Self);

	AddLogMessage(slkInfo, '"' + APlayer.Ticket + '" added to zone ' +
            Name + ' (' + Desc + ').');
	end;

constructor TZone.Create;
	begin
	inherited Create;

	FPlayers:= TPlayersList.Create;
	end;

destructor TZone.Destroy;
	var
	i: Integer;

	begin
	AddLogMessage(slkInfo, 'Destroying zone ' + Name + ' (' + Desc + ')');

	with FPlayers.LockList do
		try
		for i:= Count - 1 downto 0 do
			Remove(Items[i]);

		finally
		FPlayers.UnlockList;
		end;

	FPlayers.Free;

	inherited;
	end;

function TZone.GetCount: Integer;
	begin
	with FPlayers.LockList do
		try
		Result:= Count;

		finally
		FPlayers.UnlockList;
		end;
	end;

function TZone.GetPlayers(AIndex: Integer): TPlayer;
	begin
	with FPlayers.LockList do
		try
		Result:= Items[AIndex];

		finally
		FPlayers.UnlockList;
		end;
	end;

function TZone.PlayerByIdent(const AIdent: TGUID): TPlayer;
	var
	i: Integer;

	begin
	Result:= nil;

	with FPlayers.LockList do
		try
		for i:= 0 to Count - 1 do
			if  CompareMem(@Items[i].Ident, @AIdent, SizeOf(TGUID)) then
				begin
				Result:= Items[i];
				Exit;
				end;

		finally
		FPlayers.UnlockList;
		end;

	end;

procedure TZone.Remove(APlayer: TPlayer);
	begin
	FPlayers.Remove(APlayer);
	APlayer.Zones.Remove(Self);

	AddLogMessage(slkInfo, '"' + APlayer.Ticket + '" removed from zone ' +
            Name + '(' + Desc + ').');
	end;

{ TSystemZone }

procedure TSystemZone.Add(APlayer: TPlayer);
	begin
	inherited;

	LimboZone.Add(APlayer);
	end;

destructor TSystemZone.Destroy;
	begin

	inherited;
	end;

class function TSystemZone.Name: AnsiString;
	begin
	Result:= 'system';
	end;

function TSystemZone.PlayerByName(AName: AnsiString): TPlayer;
	var
	i: Integer;

	begin
	Result:= nil;

	with FPlayers.LockList do
		try
		for i:= 0 to Count - 1 do
			if  CompareText(string(Items[i].Name), string(AName)) = 0 then
				begin
				Result:= Items[i];
				Exit;
				end;

		finally
		FPlayers.UnlockList;
		end;
	end;

procedure TSystemZone.PlayersKeepAliveDecrement(Ams: Integer);
	var
	i: Integer;

	begin
	with FPlayers.LockList do
		try
		for i:= 0 to Count - 1 do
			if  not Assigned(LimboZone.PlayerByIdent(Items[i].Ident)) then
				Items[i].KeepAliveDecrement(Ams);

		finally
		FPlayers.UnlockList;
		end;
	end;

procedure TSystemZone.PlayersKeepAliveExpire;
	var
	i: Integer;

	begin
	with FPlayers.LockList do
		try
		for i:= Count - 1 downto 0 do
			if  Items[i].NeedKeepAlive <= 0 then
				Self.Remove(Items[i]);

		finally
		FPlayers.UnlockList;
		end;
	end;

procedure TSystemZone.ProcessPlayerMessage(APlayer: TPlayer;
        AMessage: TBaseMessage; var AHandled: Boolean);
	var
	i: Integer;
	a: TPlayer;
	m: TBaseMessage;
	n: AnsiString;
	ml: TMessageList;

	begin
	if  (AMessage.Category = mcText)
	and (AMessage.Method = 0) then
		begin
		ml:= TMessageList.Create(APlayer);

		for i:= 0 to High(ARR_LIT_SYS_INFO) do
			ml.Data.Enqueue(ARR_LIT_SYS_INFO[i]);

		m:= TBaseMessage.Create;
		m.Category:= mcText;
		m.Method:= $01;
		m.Params.Add(ml.Name);
		m.Params.Add(AnsiString(ARR_LIT_NAM_CATEGORY[mcSystem]));
		m.DataFromParams;

		APlayer.AddSendMessage(m);

		ListMessages.Add(ml);

		AHandled:= True;
		end
	else if (AMessage.Category = mcSystem) then
		begin
		TCPServer.TCPServer.DisconnectByIdent(APlayer.Ident);

		AHandled:= True;
		end
	else if  (AMessage.Category = mcText)
	and (AMessage.Method = $02) then
		begin
		AHandled:= True;
		AMessage.ExtractParams;

		if  AMessage.Params.Count > 0 then
			begin
			n:= Copy(AMessage.Params[0], 1, 8);

			with ListMessages.LockList do
				try
				for i:= 0 to Count - 1 do
					begin
					ml:= Items[i];

					if  CompareText(string(ml.Name), string(n)) = 0 then
						begin
						if  not ml.Complete then
							ml.Process:= True;

						Break;
						end;
					end;

				finally
				ListMessages.UnlockList;
				end;
			end;
		end
	else if  (AMessage.Category = mcText)
	and (AMessage.Method = $04) then
		begin
		AMessage.ExtractParams;

		if  AMessage.Params.Count > 0 then
			begin
			n:= Copy(AMessage.Params[0], 1, 8);
			a:= PlayerByName(n);

			if  Assigned(a) then
				begin
				m:= TBaseMessage.Create;
				m.Assign(AMessage);
				m.Params[0]:= APlayer.Name;
				m.DataFromParams;

				a.AddSendMessage(m);
				end;
			end
		else
			APlayer.SendServerError(LIT_ERR_TEXTPINV);

		AHandled:= True;
		end
	else if (AMessage.Category = mcConnect)
	and (AMessage.Method = 1) then
		begin
		AMessage.ExtractParams;
		if  (AMessage.Params.Count = 1)
		and (Length(AMessage.Params[0]) > 1) then
			begin
			n:= Copy(AMessage.Params[0], 1, 8);

			with FPlayers.LockList do
				try
					a:= PlayerByName(n);

					if  not Assigned(a) then
						begin
						m:= TBaseMessage.Create;
						m.Assign(AMessage);
						m.Params.Add(APlayer.Name);
						m.DataFromParams;

						APlayer.AddSendMessage(m);

						APlayer.Name:= n;
						end
					else
						APlayer.SendServerError(LIT_ERR_CONNCTID);
				finally
                FPlayers.UnlockList;
				end;
			end
		else
			APlayer.SendServerError(LIT_ERR_CONNCTID);

		AHandled:= True;
		end
	else if (AMessage.Category = mcClient)
	and (AMessage.Method = 2) then
		begin
		APlayer.KeepAliveReset;
		AHandled:= True;
		end;
	end;

procedure TSystemZone.Remove(APlayer: TPlayer);
	begin
	inherited;

	APlayer.ClearZones;

	ExpirePlayers.Add(APlayer);
	end;

{ TLimboZone }

procedure TLimboZone.Add(APlayer: TPlayer);
	begin
	inherited;

	APlayer.Counter:= 0;
	end;

procedure TLimboZone.BumpCounter;
	var
	i: Integer;
	p: TPlayer;

	begin
	with FPlayers.LockList do
		try
		for i:= 0 to Count - 1 do
			begin
			p:= Items[i];
            p.Lock.Acquire;
            try
			    p.Counter:= p.Counter + 1;

                if  p.Counter mod 100 = 0 then
				    AddLogMessage(slkInfo, '"' + p.Ticket +
							'" bumping auth wait count: ' + IntToStr(p.Counter));

                finally
                p.Lock.Release;
                end;
            end;

		finally
		FPlayers.UnlockList;
		end;
	end;

procedure TLimboZone.ExpirePlayers;
	var
	i: Integer;
	p: TPlayer;

	begin
	with FPlayers.LockList do
		try
		for i:= Count - 1 downto 0 do
			begin
			p:= Items[i];

            p.Lock.Acquire;
            try
			    if  Assigned(p.Client)
			    and (Length(p.Name) > 0) then
				    begin
				    AddLogMessage(slkInfo, '"' + p.Ticket +
							'" authenticated, move to lobby/play.');

                    LimboZone.Remove(p);

				    LobbyZone.Add(p);
				    PlayZone.Add(p);
				    end
			    else if p.Counter >= 600 then
				    begin
                    AddLogMessage(slkInfo, '"' + p.Ticket + '" auth failure.');

                    SystemZone.Remove(p);
				    end;

                finally
                p.Lock.Release;
                end;
            end;

		finally
		FPlayers.UnlockList;
		end;
	end;

class function TLimboZone.Name: AnsiString;
	begin
	Result:= 'limbo';
	end;

procedure TLimboZone.ProcessPlayerMessage(APlayer: TPlayer;
        AMessage: TBaseMessage; var AHandled: Boolean);
	var
	c: TNamedHost;

	begin
	if  (AMessage.Category = mcClient)
	and (AMessage.Method = 1) then
		begin
        APlayer.Lock.Acquire;
        try
		if not Assigned(APlayer.Client) then
			begin
			AMessage.ExtractParams;

			if  AMessage.Params.Count = 3 then
				begin
				c:= TNamedHost.Create;

				c.Name:= AMessage.Params[0];
				c.Host:= AMessage.Params[1];
				c.Version:= AMessage.Params[2];

				APlayer.Client:= c;
				end
			else
				APlayer.SendServerError(LIT_ERR_CLIENTID);
			end
		else
			APlayer.SendServerError(LIT_ERR_CLIENTID);


        finally
        APlayer.Lock.Release;
        end;

        AHandled:= True;
		end;
	end;

procedure TLimboZone.Remove(APlayer: TPlayer);
	begin
	inherited;

	end;

{ TLobbyRoom }

procedure TLobbyRoom.Add(APlayer: TPlayer);
	var
	i: Integer;

	procedure JoinMessageFromPeer(APeer: TPlayer; AName: AnsiString);
		var
		m: TBaseMessage;

		begin
		m:= TBaseMessage.Create;

		m.Category:= mcLobby;
		m.Method:= $01;

		m.Params.Add(Desc);
		m.Params.Add(AName);

		m.DataFromParams;

        APeer.AddSendMessage(m);
		end;

	begin
	inherited;

	with FPlayers.LockList do
		try
		for i:= 0 to Count - 1 do
			JoinMessageFromPeer(Items[i], APlayer.Name);

		finally
		FPlayers.UnlockList;
		end;
	end;

destructor TLobbyRoom.Destroy;
	begin
//	FDisposing:= True;

	if  Assigned(Lobby) then
		Lobby.RemoveRoom(Desc);

	inherited;
	end;

class function TLobbyRoom.Name: AnsiString;
	begin
	Result:= 'room';
	end;

procedure TLobbyRoom.ProcessPlayerMessage(APlayer: TPlayer;
        AMessage: TBaseMessage; var AHandled: Boolean);
	var
	i: Integer;

	procedure PeerMessageFromPlayer(APeer: TPlayer; AMessage: TBaseMessage);
		var
		m: TBaseMessage;

		begin
		m:= TBaseMessage.Create;

		m.Assign(AMessage);

		m.Category:= mcLobby;
		m.Method:= $04;

        APeer.AddSendMessage(m);
		end;

	begin
	if  AMessage.Category = mcLobby then
		if  AMessage.Method = 4 then
			begin
			AMessage.ExtractParams;
			if  (AMessage.Params.Count > 2)
			and (CompareText(string(Desc), string(AMessage.Params[0])) = 0) then
				begin
				AMessage.Params[1]:= Copy(AMessage.Params[1], Low(AnsiString), 8);

				AMessage.DataFromParams;

				with FPlayers.LockList do
					try
					for i:= 0 to Count - 1 do
						PeerMessageFromPlayer(Items[i], AMessage);

					finally
					FPlayers.UnlockList;
					end;

				AHandled:= True;
				end;
		end;
	end;

procedure TLobbyRoom.Remove(APlayer: TPlayer);
	var
	i: Integer;

	procedure PartMessageFromPeer(APeer: TPlayer; AName: AnsiString);
		var
		m: TBaseMessage;

		begin
		m:= TBaseMessage.Create;
		m.Category:= mcLobby;
		m.Method:= $02;

		m.Params.Add(Desc);
		m.Params.Add(AName);

		m.DataFromParams;

        APeer.AddSendMessage(m);
		end;

	begin
	with FPlayers.LockList do
		try
		for i:= 0 to Count - 1 do
			PartMessageFromPeer(Items[i], APlayer.Name);

		finally
		FPlayers.UnlockList;
		end;

	inherited;

	if  PlayerCount = 0 then
		ExpireZones.Add(Self);
	end;

{ TPlayer }

procedure TPlayer.AddZone(AZone: TZone);
	begin
	Zones.Add(AZone);
	end;

procedure TPlayer.ClearZones;
	var
	i: Integer;
	z: TZone;

	begin
	with Zones.LockList do
		try
		for i:= Count - 1 downto 0 do
			begin
			z:= Items[i];
			z.Remove(Self);
			end;
		finally
		Zones.UnlockList;
		end;
	end;

constructor TPlayer.Create(AIdent: TGUID);
	begin
	inherited Create;

    Lock:= TCriticalSection.Create;

	Zones:= TZones.Create;
	Zones.Duplicates:= dupError;

	Ident:= AIdent;

	Name:= '';
	Client:= nil;

	KeepAliveReset;
	end;

destructor TPlayer.Destroy;
	begin
    Lock.Acquire;
    try
        if  Assigned(Client) then
            Client.Free;

        finally
        Lock.Release;
        end;

    Zones.Free;

    Lock.Free;

	inherited;
	end;

function TPlayer.FindZoneByClass(AZoneClass: TZoneClass): TZone;
	var
	i: Integer;

	begin
	Result:= nil;

	with Zones.LockList do
		try
		for i:= 0 to Count - 1 do
			if  Items[i] is AZoneClass then
				begin
				Result:= Items[i];
				Exit;
				end;
		finally
		Zones.UnlockList;
		end;
	end;

function TPlayer.FindZoneByNameDesc(AName, ADesc: AnsiString): TZone;
	var
	i: Integer;

	begin
	Result:= nil;

	with Zones.LockList do
		try
		for i:= 0 to Count - 1 do
			if  (CompareText(string(Items[i].Name), string(AName)) = 0)
			and (CompareText(string(Items[i].Desc), string(ADesc)) = 0) then
				begin
				Result:= Items[i];
				Exit;
				end;
		finally
		Zones.UnlockList;
		end;
	end;

procedure TPlayer.KeepAliveDecrement(Ams: Integer);
	var
	m: TBaseMessage;

	begin
	if  KeepAliveCntr > 0 then
		Dec(KeepAliveCntr, Ams)
	else
		begin
		if  SendKeepAlive then
			begin
			SendKeepAlive:= False;

			m:= TBaseMessage.Create;

			m.Category:= mcServer;
			m.Method:= 2;

			AddSendMessage(m);
			end;

		Dec(NeedKeepAlive, Ams);
		end;
	end;

procedure TPlayer.KeepAliveReset;
	begin
	KeepAliveCntr:= 10000;
	NeedKeepAlive:= 5000;
	SendKeepAlive:= True;
	end;

procedure TPlayer.RemoveZone(AZone: TZone);
	begin
	AZone.Remove(Self);
	end;

procedure TPlayer.RemoveZoneByClass(AZoneClass: TZoneClass);
	var
	z: TZone;

	begin
	repeat
		z:= FindZoneByClass(AZoneClass);
		if  Assigned(z) then
			z.Remove(Self);

		until not Assigned(z);
	end;

procedure TPlayer.SendServerError(AMessage: AnsiString);
	var
	m: TBaseMessage;

	begin
	m:= TBaseMessage.Create;

	m.Category:= mcServer;
	m.Method:= 0;
	m.Params.Add(AMessage);
	m.DataFromParams;

	AddSendMessage(m);
	end;

procedure TPlayer.AddSendMessage(var AMessage: TBaseMessage);
	begin
    AMessage.Ident:= Ident;
	TCPServer.TCPServer.AddSendMessage(Ident, AMessage);
	end;

{ TLobbyZone }

procedure TLobbyZone.Add(APlayer: TPlayer);
	begin
	inherited;

	end;

function TLobbyZone.AddRoom(ADesc, APassword: AnsiString): TLobbyRoom;
	begin
	with  FRooms.LockList do
		try
			Result:= RoomByName(ADesc);
			if  not Assigned(Result) then
				begin
				Result:= TLobbyRoom.Create;

				Result.Desc:= ADesc;
				Result.Lobby:= Self;
				Result.Password:= APassword;

				FRooms.Add(Result);
				end;

			finally
            FRooms.UnlockList;
			end;
	end;

constructor TLobbyZone.Create;
	begin
	inherited;

	FRooms:= TLobbyRooms.Create;
	end;

destructor TLobbyZone.Destroy;
	var
	i: Integer;

	begin
	with FRooms.LockList do
		try
		for i:= Count - 1 downto 0 do
			begin
			Items[i].Lobby:= nil;
			Items[i].Free;
			end;

		finally
		FRooms.UnlockList;
		end;

	FRooms.Free;

	inherited;
	end;

class function TLobbyZone.Name: AnsiString;
	begin
	Result:= 'lobby';
	end;

procedure TLobbyZone.ProcessPlayerMessage(APlayer: TPlayer;
        AMessage: TBaseMessage; var AHandled: Boolean);
	var
	r: TLobbyRoom;
	s: AnsiString;
	m: TBaseMessage;
	ml: TMessageList;
	i: Integer;
	p: AnsiString;

	begin
	if  AMessage.Category = mcLobby then
		if  AMessage.Method = 1 then
			begin
			AMessage.ExtractParams;

			if  (AMessage.Params.Count > 0)
			and (AMessage.Params.Count < 3) then
				begin
				s:= Copy(AMessage.Params[0], Low(AnsiString), 8);
				r:= RoomByName(AMessage.Params[0]);

				if  AMessage.Params.Count = 2 then
					p:= AMessage.Params[1]
				else
					p:= '';

				if  not Assigned(r) then
					r:= AddRoom(s, p);

				if  CompareText(string(p), string(r.Password)) = 0 then
					with APlayer.Zones.LockList do
						try
						if  not Contains(r) then
							r.Add(APlayer);

						finally
						APlayer.Zones.UnlockList;
						end
				else
					begin
					m:= TBaseMessage.Create;
					m.Category:= mcLobby;
					m.Method:= $00;

					APlayer.AddSendMessage(m);
					end;
				end
			else
				APlayer.SendServerError(LIT_ERR_LBBYJINV);

			AHandled:= True;
			end
		else if AMessage.Method = 2 then
			begin
			AMessage.ExtractParams;

			r:= RoomByName(AMessage.Params[0]);

			if  Assigned(r) then
				r.Remove(APlayer)
			else
				APlayer.SendServerError(LIT_ERR_LBBYPINV);

			AHandled:= True;
			end
		else if AMessage.Method = $03 then
			begin
			AHandled:= True;

			AMessage.ExtractParams;

			r:= nil;

			if  AMessage.Params.Count > 0 then
				begin
				r:= RoomByName(AMessage.Params[0]);
				if  not Assigned(r) then
					begin
					APlayer.SendServerError(LIT_ERR_LBBYLINV);
					Exit;
					end;
				end;

			ml:= TMessageList.Create(APlayer);

			if  AMessage.Params.Count > 0 then
				with r.FPlayers.LockList do
					try
					if  (Length(r.Password) = 0)
					or  Contains(APlayer) then
						for i:= 0 to Count - 1 do
							ml.Data.Enqueue(Items[i].Name);

					finally
					r.FPlayers.UnlockList;
					end
			else
				with FRooms.LockList do
					try
					for i:= 0 to Count - 1 do
						if  Length(Items[i].Password) = 0 then
							ml.Data.Enqueue(Items[i].Desc);

					finally
					FRooms.UnlockList;
					end;

			m:= TBaseMessage.Create;
			m.Category:= mcText;
			m.Method:= $01;
			m.Params.Add(ml.Name);
			m.Params.Add(AnsiString(ARR_LIT_NAM_CATEGORY[mcLobby]));

			if  AMessage.Params.Count > 0 then
				m.Params.Add(r.Desc);

			m.DataFromParams;

			APlayer.AddSendMessage(m);

			ListMessages.Add(ml);
			end
	end;

procedure TLobbyZone.Remove(APlayer: TPlayer);
	begin
	inherited;

	APlayer.RemoveZoneByClass(TLobbyRoom);
	end;

procedure TLobbyZone.RemoveRoom(ADesc: AnsiString);
	var
	r: TLobbyRoom;

	begin
	r:= RoomByName(ADesc);
	if  Assigned(r) then
		FRooms.Remove(r);
	end;

function TLobbyZone.RoomByName(ADesc: AnsiString): TLobbyRoom;
	var
	i: Integer;

	begin
	Result:= nil;
	with FRooms.LockList do
		try
		for i:= 0 to Count - 1 do
			if  CompareText(string(Items[i].Desc), string(ADesc)) = 0 then
				begin
				Result:= Items[i];
				Exit;
				end;
		finally
		FRooms.UnlockList;
		end;
	end;


{ TServerDispatcher }

procedure TServerDispatcher.Execute;
	var
//	cm: TConnectMessage;
	im: TBaseIdentMessage;
	p: TPlayer;
	handled: Boolean;
	z: TZone;
	i: Integer;

	begin
	while not Terminated do
		try
		Sleep(100);

		im:= nil;
		try
			with ReadMessages.LockList do
				try
				if  Count > 0 then
					begin
					im:= Items[0];
					Delete(0);
					end;
				finally
				ReadMessages.UnlockList;
				end;

			except
			AddLogMessage(slkError, 'Dispatcher cannot read messages!');
			end;

		if  Assigned(im) then
			try
				p:= SystemZone.PlayerByIdent(im.Ident);

                if  not Assigned(p) then
					Continue;

				try
					handled:= False;
					z:= nil;

					with p.Zones.LockList do
						try
						for i:= 0 to Count - 1 do
							begin
							z:= Items[i];

							z.ProcessPlayerMessage(p, TBaseMessage(im), handled);
							if  handled then
								Break;

							z:= nil;
							end;

						finally
						p.Zones.UnlockList;
						end;

					if  handled then
						begin
						p.KeepAliveReset;
						AddLogMessage(slkDebug, '"' + p.Ticket +
								'" handled in ' + z.Name + ' zone.');
						end
					else
						begin
						p.SendServerError(LIT_ERR_SERVERUN);

						AddLogMessage(slkDebug, '"' + p.Ticket +
								'" unhandled message.');
						end;

					except
					AddLogMessage(slkError, '"' + p.Ticket +
								'" error processing player message!');
					end;

				finally
				im.Free;
				end;
        except
		AddLogMessage(slkError, 'Unknown dispatcher error!');
		end;
	end;

constructor TServerDispatcher.Create;
	begin
	ReadMessages:= TIdentMessages.Create;

	inherited Create(False);
	end;

destructor TServerDispatcher.Destroy;
	begin
    with ReadMessages.LockList do
		try
        	while Count > 0 do
				begin
				Items[Count - 1].Free;
				Delete(Count - 1);
				end;

			finally
            ReadMessages.UnlockList;
			end;

    ReadMessages.Free;

	inherited Destroy;
	end;

{ TMessageList }

constructor TMessageList.Create(APlayer: TPlayer);
	var
	s: AnsiString;
	i,
	u,
	p: Integer;
	f: Boolean;

	begin
	inherited Create;

	Player:= APlayer;

	s:= APlayer.Name;
	p:= Length(s) + 1;
	if  p > 8 then
		p:= 8;

	if  Length(s) < p then
		SetLength(s, p);

	Dec(p);

	u:= 0;
	repeat
		s[p + Low(AnsiString)]:= AnsiChar(u + Ord(AnsiChar('0')));

		f:= False;
		with ListMessages.LockList do
			try
			for i:= 0 to Count - 1 do
				if  CompareText(string(Items[i].Name), string(s)) = 0 then
					begin
					f:= True;
					Break;
					end;
			finally
			ListMessages.UnlockList;
			end;

		if  not f then
			begin
			Name:= s;
			end
		else
			Inc(u);

		until (not f) or (u > 9);

	if  u > 9 then
        begin
		AddLogMessage(slkInfo, '"' + APlayer.Ticket +
				'" out of room for new Message List!');
        Exit;
        end;

	Data:= TQueue<AnsiString>.Create;

	Template.Category:= mcText;
	Template.Method:= $03;

	Process:= True;
	Complete:= False;
	end;

destructor TMessageList.Destroy;
	begin
	Data.Free;

	inherited;
	end;

procedure TMessageList.Elapsed;
	begin
	Inc(Counter);

	if  Counter >= 6000 then
		Complete:= True;
	end;

procedure TMessageList.ProcessList;
	var
	c: Integer;
	m: TBaseMessage;

	begin
	c:= 0;
	while (Data.Count > 0) and (c < 15) do
		begin
		m:= TBaseMessage.Create;

		m.Category:= Template.Category;
		m.Method:= Template.Method;

		m.Params.Add(Name);
		m.Params.Add(Data.Dequeue);

		m.DataFromParams;

        Player.AddSendMessage(m);

		Inc(c);
		end;

	m:= TBaseMessage.Create;

	m.Category:= mcText;
	m.Method:= $02;

	m.Params.Add(Name);
	m.Params.Add(AnsiString(IntToStr(Data.Count)));

	m.DataFromParams;

	Player.AddSendMessage(m);

	Process:= False;
	Complete:= Data.Count = 0;
    Counter:= 0;
	end;

{ TPlayGame }

procedure TPlayGame.Add(APlayer: TPlayer);
	var
	i: Integer;
	s: Integer;
//	m: TMessage;

	procedure JoinMessageFromPeer(APeer: TPlayer; AName: AnsiString; ASlot: Integer);
		var
		m: TBaseMessage;

		begin
		m:= TBaseMessage.Create;

		m.Category:= mcPlay;
		m.Method:= $01;

		m.Params.Add(Desc);
		m.Params.Add(AName);
		m.Params.Add(AnsiChar(ASlot + $30));
//		m.Params.Add(AnsiChar(Ord(State)));

		m.DataFromParams;

		APeer.AddSendMessage(m);
		end;

	begin
	Lock.Acquire;
		try
		if  SlotCount < 6 then
			begin
			Inc(SlotCount);

			inherited;

			s:= -1;
			for i:= 0 to 5 do
				if  not Assigned(Slots[i].Player) then
					begin
					s:= i;

					FillChar(Slots[i], SizeOf(TPlaySlot), 0);
					FillChar(Slots[i].ScoreSheet, SizeOf(TScoreSheet), $FF);

					Slots[i].Player:= APlayer;
					Slots[i].Name:= APlayer.Name;

					Slots[i].State:= psIdle;

					Break;
					end;

			Assert(s > -1, 'Failure in Play Game Add Player');

			for i:= 0 to 5 do
				if  Assigned(Slots[i].Player) then
					JoinMessageFromPeer(Slots[i].Player, APlayer.Name, s);


			SendGameStatus(APlayer);
			end;

		finally
		Lock.Release;
		end;
	end;

constructor TPlayGame.Create;
	var
	i: Integer;

	begin
	inherited;

	Lock:= TCriticalSection.Create;

	for i:= 0 to 5 do
		FillChar(Slots[i].ScoreSheet, SizeOf(TScoreSheet), $FF);
	end;

destructor TPlayGame.Destroy;
	begin
	if  Assigned(Play) then
		Play.RemoveGame(Desc);

	Lock.Free;

	inherited;
	end;

class function TPlayGame.Name: AnsiString;
	begin
	Result:= 'game';
	end;

procedure TPlayGame.ProcessPlayerMessage(APlayer: TPlayer;
        AMessage: TBaseMessage; var AHandled: Boolean);
	var
	s,
	i,
	j: Integer;
	p: TPlayerState;
	m: TBaseMessage;
	f: Boolean;
	d: TDieSet;
	n: TScoreLocation;
	r: Word;
	u: TDieSet;
	o: TScoreLocation;

	procedure PeerMessageFromPlayer(APeer: TPlayer; AMessage: TBaseMessage);
		var
		m: TBaseMessage;

		begin
		m:= TBaseMessage.Create;

		m.Assign(AMessage);

		m.Category:= mcPlay;
		m.Method:= $04;

		APeer.AddSendMessage(m);
		end;

	begin
	if  AMessage.Category = mcPlay then
		if  AMessage.Method = 4 then
			begin
			AMessage.ExtractParams;
			if  (AMessage.Params.Count > 2)
			and (CompareText(string(Desc), string(AMessage.Params[0])) = 0) then
				begin
				AMessage.Params[1]:= Copy(AMessage.Params[1], Low(AnsiString), 8);

				AMessage.DataFromParams;

				with FPlayers.LockList do
					try
					for i:= 0 to Count - 1 do
						PeerMessageFromPlayer(Items[i], AMessage);

					finally
					FPlayers.UnlockList;
					end;

				AHandled:= True;
				end;
			end
		else if AMessage.Method = $07 then
			begin
//			AMessage.ExtractParams;
			AHandled:= True;

//			if  AMessage.Params.Count = 2 then
			if  Length(AMessage.Data) = 2 then
				begin
				Lock.Acquire;
					try
//					s:= Ord(AMessage.Params[0][Low(AnsiString)]);
					s:= AMessage.Data[0];

					if  (s > 5)
					or  (s < 0) then
						Exit;

//					p:= TPlayerState(Ord(AMessage.Params[1][Low(AnsiString)]));
					p:= TPlayerState(AMessage.Data[1]);

					if  (State >= gsPreparing)
					or  (p = psNone) then
						Exit
					else if (p = psIdle)
					and (Slots[s].State = psReady) then
						Dec(ReadyCount)
					else if (p = psReady)
					and (Slots[s].State = psIdle) then
						Inc(ReadyCount);

					f:= False;

					if  (State = gsWaiting)
					and (SlotCount > 1)
					and (ReadyCount = SlotCount) then
						begin
						f:= True;
						State:= gsPreparing;
						p:= psPreparing;
						ReadyCount:= 0;
						for i:= 0 to 5 do
							if  Slots[i].State = psReady then
								Slots[i].State:= p;
						end;

					Slots[s].State:= p;

					if  not f then
						for i:= 0 to 5 do
							if  Assigned(Slots[i].Player) then
								SendSlotStatus(Slots[i].Player, s);

					if  f then
						begin
						for i:= 0 to 5 do
							if  Assigned(Slots[i].Player) then
								for j:= 0 to 5 do
									SendSlotStatus(Slots[i].Player, j);

						for i:= 0 to 5 do
							if  Assigned(Slots[i].Player) then
								SendGameStatus(Slots[i].Player);
						end;

					finally
					Lock.Release;
					end;
				end;
			end
		else if AMessage.Method = $08 then
			begin
//			AMessage.ExtractParams;
			AHandled:= True;

//			if  AMessage.Params.Count = 2 then
			if  Length(AMessage.Data) = 2 then
				begin
				Lock.Acquire;
					try
//					s:= Ord(AMessage.Params[0][Low(AnsiString)]);
//					d:= ByteToDieSet(Ord(AMessage.Params[1][Low(AnsiString)]));
					s:= AMessage.Data[0];
					d:= ByteToDieSet(AMessage.Data[1]);

					if  Slots[s].State = psPreparing then
						begin
						RollDice(VAL_SET_DICEALL, Slots[s].Dice);

						Slots[s].FirstRoll:= 0;
						for i:= 0 to 4 do
							Slots[s].FirstRoll:= Slots[s].FirstRoll + Slots[s].Dice[i];

						Inc(ReadyCount);
						end
					else
						begin
						if  Slots[s].RollNo = 3 then
							begin
							m:= TBaseMessage.Create;
							m.Category:= mcPlay;
							m.Method:= $00;

							m.Params.Add(LIT_ERR_PLAYNORL);
							m.DataFromParams;

                            APlayer.AddSendMessage(m);

							Exit;
							end;

						if  Slots[s].RollNo = 0 then
							d:= VAL_SET_DICEALL;

						RollDice(d, Slots[s].Dice);
						Slots[s].RollNo:= Slots[s].RollNo + 1;

//						YAHTZEE BONANZA!
//						for i:= 1 to 4 do
//							Slots[s].Dice[i]:= Slots[s].Dice[0];
						end;

					for i:= 0 to 5 do
						if  Assigned(Slots[i].Player) then
							begin
							m:= TBaseMessage.Create;
							m.Category:= mcPlay;
							m.Method:= $08;

							SetLength(m.Data, 6);

//							m.Params.Add(AnsiChar(Ord(s)));
							m.Data[0]:= s;

							for j:= 0 to 4 do
//								m.Params.Add(AnsiChar(Slots[s].Dice[j]));
								m.Data[1 + j]:= Slots[s].Dice[j];

//							m.DataFromParams;

							Slots[i].Player.AddSendMessage(m);
							end;

					if  Slots[s].State = psPreparing then
						begin
						Slots[s].State:= psWaiting;

						for i:= 0 to 5 do
							if  Assigned(Slots[i].Player) then
								SendSlotStatus(Slots[i].Player, s);
						end;

					if  (State = gsPreparing)
					and (ReadyCount = SlotCount) then
						begin
						s:= 0;
						j:= Slots[0].FirstRoll;

						for i:= 1 to 5 do
							if  Slots[i].FirstRoll > j then
								begin
								s:= i;
								j:= Slots[i].FirstRoll;
								end;

						Slots[s].First:= True;
						Slots[s].State:= psPlaying;
						Slots[s].RollNo:= 0;
						Round:= 1;
						Turn:= s;

						for i:= 0 to 4 do
							Slots[s].Dice[i]:= 0;

						State:= gsPlaying;

						for i:= 0 to 5 do
							if  Assigned(Slots[i].Player) then
								SendGameStatus(Slots[i].Player);

						for i:= 0 to 5 do
							if  Assigned(Slots[i].Player) then
								begin
								SendSlotStatus(Slots[i].Player, s);

								m:= TBaseMessage.Create;
								m.Category:= mcPlay;
								m.Method:= $08;

								SetLength(m.Data, 6);

								m.Data[0]:= s;

								for j:= 0 to 4 do
									m.Data[1 + j]:= Slots[s].Dice[j];

								Slots[i].Player.AddSendMessage(m);
								end;
						end;

					finally
					Lock.Release;
					end;
				end;
			end
		else if AMessage.Method = $09 then
			begin
			AHandled:= True;

			if  Length(AMessage.Data) = 3 then
				begin
				Lock.Acquire;
					try
					s:= AMessage.Data[0];
//					d:= AMessage.Data[1];
					f:= Boolean(AMessage.Data[2]);

					if  (Turn = s)
					and (Slots[s].RollNo > 0) then
						begin
						if  f then
							Include(Slots[s].Keepers, AMessage.Data[1])
						else
							Exclude(Slots[s].Keepers, AMessage.Data[1]);

						for i:= 0 to 5 do
							if  Assigned(Slots[i].Player) then
								begin
								m:= TBaseMessage.Create;
								m.Assign(AMessage);

								Slots[i].Player.AddSendMessage(m);
								end;
						end;

					finally
					Lock.Release;
					end;
				end;
			end
		else if AMessage.Method = $0A then
			begin
			AHandled:= True;

			if  Length(AMessage.Data) = 2 then
				begin
				Lock.Acquire;
					try
					s:= AMessage.Data[0];
					n:= TScoreLocation(AMessage.Data[1]);

					u:= [];
					r:= VAL_KND_SCOREINVALID;
					o:= slAces;

					if  (Turn = s)
					and (Slots[s].RollNo > 0) then
						if  IsYahtzee(Slots[s].Dice) then
							begin
							if  IsYahtzeeBonus(Slots[s].ScoreSheet, o) then
								begin
								if  n in YahtzeeBonusStealLocs(Slots[s].ScoreSheet,
										Slots[s].Dice) then
									r:= YahtzeeBonusStealScore(n, Slots[s].Dice);
								end
							else if (n = slYahtzee)
							and (Slots[s].ScoreSheet[slYahtzee] = VAL_KND_SCOREINVALID) then
								r:= 50;
							end
						else if Slots[s].ScoreSheet[n] = VAL_KND_SCOREINVALID then
							r:= MakeScoreForLocation(n, Slots[s].Dice, u);

					m:= TBaseMessage.Create;
					m.Assign(AMessage);
					SetLength(m.Data, Length(m.Data) + 2);

					m.Data[2]:= Hi(r);
					m.Data[3]:= Lo(r);

					APlayer.AddSendMessage(m);

					if  o > slAces then
						begin
						m:= TBaseMessage.Create;
						m.Assign(AMessage);
						SetLength(m.Data, Length(m.Data) + 2);

						m.Data[1]:= Ord(o);
						m.Data[2]:= Hi(100);
						m.Data[3]:= Lo(100);

                        APlayer.AddSendMessage(m);
						end;

					finally
					Lock.Release;
					end;
				end;
			end
		else if AMessage.Method = $0B then
			begin
			AHandled:= True;

			if  Length(AMessage.Data) = 2 then
				begin
				Lock.Acquire;
					try
					s:= AMessage.Data[0];
					n:= TScoreLocation(AMessage.Data[1]);

					u:= [];
					r:= VAL_KND_SCOREINVALID;
					o:= slAces;

					if  (Turn = s)
					and (Slots[s].RollNo > 0) then
						if  IsYahtzee(Slots[s].Dice) then
							begin
							if  IsYahtzeeBonus(Slots[s].ScoreSheet, o) then
								begin
								if  n in YahtzeeBonusStealLocs(Slots[s].ScoreSheet,
										Slots[s].Dice) then
									r:= YahtzeeBonusStealScore(n, Slots[s].Dice);
								end
							else if (n = slYahtzee)
							and (Slots[s].ScoreSheet[slYahtzee] = VAL_KND_SCOREINVALID) then
								r:= 50;
							end
						else if Slots[s].ScoreSheet[n] = VAL_KND_SCOREINVALID then
							r:= MakeScoreForLocation(n, Slots[s].Dice, u);

					if  r <> VAL_KND_SCOREINVALID then
						begin
						Slots[s].ScoreSheet[n]:= r;
						Slots[s].Score:= Slots[s].Score + r;

						for i:= 0 to 5 do
							if  Assigned(Slots[i].Player) then
								begin
								m:= TBaseMessage.Create;
								m.Assign(AMessage);
								SetLength(m.Data, Length(m.Data) + 2);

								m.Data[2]:= Hi(r);
								m.Data[3]:= Lo(r);

								Slots[i].Player.AddSendMessage(m);
								end;

						if  (n in [slAces..slSixes])
						and (Slots[s].ScoreSheet[slUpperBonus] = VAL_KND_SCOREINVALID) then
							begin
							r:= 0;

							for i:= Ord(slAces) to Ord(slSixes) do
								if  Slots[s].ScoreSheet[TScoreLocation(i)] =
										VAL_KND_SCOREINVALID then
									begin
									r:= VAL_KND_SCOREINVALID;
									Break;
									end
								else
									Inc(r, Slots[s].ScoreSheet[TScoreLocation(i)]);

							if  r <> VAL_KND_SCOREINVALID then
								begin
								if  r > 63 then
									r:= 35
								else
									r:= 0;

								Slots[s].ScoreSheet[slUpperBonus]:= r;
								Slots[s].Score:= Slots[s].Score + r;

								for i:= 0 to 5 do
									if  Assigned(Slots[i].Player) then
										begin
										m:= TBaseMessage.Create;
										m.Assign(AMessage);
										SetLength(m.Data, Length(m.Data) + 2);

										m.Data[1]:= Ord(slUpperBonus);
										m.Data[2]:= Hi(r);
										m.Data[3]:= Lo(r);

										Slots[i].Player.AddSendMessage(m);
										end;
								end;
							end;

						if  o > slAces then
							begin
							Slots[s].ScoreSheet[o]:= 100;
							Slots[s].Score:= Slots[s].Score + 100;

							for i:= 0 to 5 do
								if  Assigned(Slots[i].Player) then
									begin
									m:= TBaseMessage.Create;
									m.Assign(AMessage);
									SetLength(m.Data, Length(m.Data) + 2);

									m.Data[1]:= Ord(o);
									m.Data[2]:= Hi(100);
									m.Data[3]:= Lo(100);

                                    Slots[i].Player.AddSendMessage(m);
									end;
							end;

						if  Turn = s then
							begin
							Slots[s].State:= psWaiting;
							Slots[s].RollNo:= 0;

							f:= False;

							while True do
								begin
								Inc(Turn);
								if  Turn > 5 then
									Turn:= 0;

								if  Slots[Turn].First then
									begin
									f:= True;
									Inc(Round);
									if  Round > 13 then
										begin
										State:= gsFinished;
										Turn:= -1;

										r:= 0;
										for i:= 0 to 5 do
											if  Slots[i].Score > r then
												r:= Slots[i].Score;

										for i:= 0 to 5 do
											if  Slots[i].State > psIdle then
												if  Slots[i].Score = r then
													Slots[i].State:= psWinner
												else
													Slots[i].State:= psFinished;

										Break;
										end;
									end;

								if  Assigned(Slots[Turn].Player)
								and (Slots[Turn].State = psWaiting) then
									Break;
								end;

							if  Turn > -1 then
								begin
								Slots[Turn].State:= psPlaying;

								Slots[Turn].Keepers:= [];
								for i:= 0 to 4 do
									Slots[Turn].Dice[i]:= 0;
								Slots[Turn].RollNo:= 0;
								end;

							if  f
							and (State = gsFinished) then
								begin
								for i:= 0 to 5 do
									for j:= 0 to 5 do
										if  Assigned(Slots[i].Player) then
											SendSlotStatus(Slots[i].Player, j);
								end
							else
								begin
								for i:= 0 to 5 do
									if  Assigned(Slots[i].Player) then
										SendSlotStatus(Slots[i].Player, s);

								for i:= 0 to 5 do
									if  Assigned(Slots[i].Player) then
										SendSlotStatus(Slots[i].Player, Turn);

								for i:= 0 to 5 do
									if  Assigned(Slots[i].Player) then
										begin
										m:= TBaseMessage.Create;
										m.Category:= mcPlay;
										m.Method:= $08;

										SetLength(m.Data, 6);

										m.Data[0]:= Turn;

										for j:= 0 to 4 do
											m.Data[1 + j]:= Slots[Turn].Dice[j];

										Slots[i].Player.AddSendMessage(m);

										for j:= 1 to 5 do
											begin
											m:= TBaseMessage.Create;
											m.Category:= mcPlay;
											m.Method:= $09;

											SetLength(m.Data, 3);

											m.Data[0]:= Turn;
											m.Data[1]:= j;
											m.Data[2]:= 0;

											Slots[i].Player.AddSendMessage(m);
											end;
										end;
								end;

							if  f then
								begin
								for i:= 0 to 5 do
									if  Assigned(Slots[i].Player) then
										SendGameStatus(Slots[i].Player);
								end;
							end;
						end;

					finally
					Lock.Release;
					end;
				end;
			end;
	end;

procedure TPlayGame.Remove(APlayer: TPlayer);
	var
	i,
	j: Integer;
	s: Integer;
	r: Integer;
	m: TBaseMessage;
	f: Boolean;

	procedure PartMessageFromPeer(APeer: TPlayer; AName: AnsiString; ASlot: Integer);
		var
		m: TBaseMessage;

		begin
		m:= TBaseMessage.Create;
		m.Category:= mcPlay;
		m.Method:= $02;

		m.Params.Add(Desc);
		m.Params.Add(AName);
		m.Params.Add(AnsiString(IntToStr(ASlot)));

		m.DataFromParams;

		APeer.AddSendMessage(m);
		end;

	begin
	Lock.Acquire;
		try
		s:= -1;
		for i:= 0 to 5 do
			if  Slots[i].Player = APlayer then
				begin
				s:= i;
				Break;
				end;

		if  s = -1 then
			Exit;

		Dec(SlotCount);

		for i:= 0 to 5 do
			if  Assigned(Slots[i].Player) then
				PartMessageFromPeer(Slots[i].Player, APlayer.Name, s);

		Slots[s].Player:= nil;

		f:= False;

		if  State = gsFinished then
//          Do nothing - dummy message will be sent
		else if  State = gsPreparing then
			begin
			Slots[s].State:= psNone;

			if  SlotCount = 1 then
				begin
				ReadyCount:= 0;
				f:= True;
				State:= gsWaiting;
				for i:= 0 to 5 do
					if  Assigned(Slots[i].Player) then
						Slots[i].State:= psIdle;
				end;
			end
		else if  State > gsPreparing then
			begin
			if  Slots[s].State = psPlaying then
				begin
//dengland      Optimise this with handling in message $0B, above

				while True do
					begin
					Inc(Turn);
					if  Turn > 5 then
						Turn:= 0;

					if  Slots[Turn].First then
						begin
						f:= True;
						Inc(Round);
						if  Round > 13 then
							begin
							State:= gsFinished;
							Turn:= -1;

							r:= 0;
							for i:= 0 to 5 do
								if  Slots[i].Score > r then
									r:= Slots[i].Score;

							for i:= 0 to 5 do
								if  Slots[i].State > psIdle then
									if  Slots[i].Score = r then
										Slots[i].State:= psWinner
									else
										Slots[i].State:= psFinished;

							Break;
							end;
						end;

					if  Assigned(Slots[Turn].Player)
					and (Slots[Turn].State = psWaiting) then
						Break;
					end;

				if  Turn > -1 then
					begin
					Slots[Turn].State:= psPlaying;

					Slots[Turn].Keepers:= [];
					for i:= 0 to 4 do
						Slots[Turn].Dice[i]:= 0;
					Slots[Turn].RollNo:= 0;
					end;

				if  f
				and (State = gsFinished) then
					begin
					for i:= 0 to 5 do
						for j:= 0 to 5 do
							if  Assigned(Slots[i].Player) then
								SendSlotStatus(Slots[i].Player, j);
					end
				else
					begin
					for i:= 0 to 5 do
						if  Assigned(Slots[i].Player) then
							SendSlotStatus(Slots[i].Player, s);

					for i:= 0 to 5 do
						if  Assigned(Slots[i].Player) then
							SendSlotStatus(Slots[i].Player, Turn);

					for i:= 0 to 5 do
						if  Assigned(Slots[i].Player) then
							begin
							m:= TBaseMessage.Create;
							m.Category:= mcPlay;
							m.Method:= $08;

							SetLength(m.Data, 6);

							m.Data[0]:= Turn;

							for j:= 0 to 4 do
								m.Data[1 + j]:= Slots[Turn].Dice[j];

							Slots[i].Player.AddSendMessage(m);

							for j:= 1 to 5 do
								begin
								m:= TBaseMessage.Create;
								m.Category:= mcPlay;
								m.Method:= $09;

								SetLength(m.Data, 3);

								m.Data[0]:= Turn;
								m.Data[1]:= j;
								m.Data[2]:= 0;

								Slots[i].Player.AddSendMessage(m);
								end;
							end;
					end;

				if  f then
					begin
					for i:= 0 to 5 do
						if  Assigned(Slots[i].Player) then
							SendGameStatus(Slots[i].Player);
					end;
				end;

			if  State <> gsFinished then
				begin
				Slots[s].State:= psFinished;

				if  SlotCount = 1 then
					begin
					f:= True;
					State:= gsFinished;
					for i:= 0 to 5 do
						if  Assigned(Slots[i].Player) then
							Slots[i].State:= psWinner;
					end;
				end;
			end
		else
			Slots[s].State:= psNone;

//dengland  This is really nasty when the game has ended or control otherwise changed
//      due to the currently playing player leaving
		if  not f then
			begin
			for i:= 0 to 5 do
				if  Assigned(Slots[i].Player) then
					SendSlotStatus(Slots[i].Player, s);
			end
		else
			begin
			for i:= 0 to 5 do
				if  Assigned(Slots[i].Player) then
					begin
					for j:= 0 to 5 do
						SendSlotStatus(Slots[i].Player, j);

					SendGameStatus(Slots[i].Player);
					end;
			end;

		finally
		Lock.Release;
		end;

	inherited;

	if  PlayerCount = 0 then
		ExpireZones.Add(Self);
	end;

procedure TPlayGame.SendGameStatus(APlayer: TPlayer);
	var
	m: TBaseMessage;

	begin
	m:= TBaseMessage.Create;
	m.Category:= mcPlay;
	m.Method:= $06;
//	m.Params.Add(AnsiChar(Ord(State)));
//	m.Params.Add(AnsiChar(Hi(Round)) + AnsiChar(Lo(Round)));
	SetLength(m.Data, 3);
	m.Data[0]:= Ord(State);
	m.Data[1]:= Hi(Round);
	m.Data[2]:= Lo(Round);

//	m.DataFromParams;

    APlayer.AddSendMessage(m);
	end;

procedure TPlayGame.SendSlotStatus(APlayer: TPlayer; ASlot: Integer);
	var
	m: TBaseMessage;

	begin
	m:= TBaseMessage.Create;
	m.Category:= mcPlay;
	m.Method:= $07;

//	m.Params.Add(AnsiChar(j));
//	m.Params.Add(AnsiChar(Slots[j].State));
//	m.Params.Add(AnsiChar(Hi(Slots[j].Score)) +
//			AnsiChar(Lo(Slots[j].Score)));
//
//	m.DataFromParams;
	SetLength(m.Data, 4);
	m.Data[0]:= ASlot;
	m.Data[1]:= Ord(Slots[ASlot].State);
	m.Data[2]:= Hi(Slots[ASlot].Score);
	m.Data[3]:= Lo(Slots[ASlot].Score);

    APlayer.AddSendMessage(m);
	end;

{ TPlayZone }

procedure TPlayZone.Add(APlayer: TPlayer);
	begin
	inherited;

	end;

function TPlayZone.AddGame(ADesc, APassword: AnsiString): TPlayGame;
	begin
	with FGames.LockList do
		try
			Result:= GameByName(ADesc);

			if  not Assigned(Result) then
				begin
				Result:= TPlayGame.Create;

				Result.Desc:= ADesc;
				Result.Play:= Self;
				Result.Password:= APassword;

				FGames.Add(Result);
				end;

			finally
            FGames.UnlockList;
			end;
	end;

constructor TPlayZone.Create;
	begin
	inherited;

	FGames:= TPlayGames.Create;
	end;

destructor TPlayZone.Destroy;
	var
	i: Integer;

	begin
	with FGames.LockList do
		try
		for i:= Count - 1 downto 0 do
			begin
			Items[i].Play:= nil;
			Items[i].Free;
			end;

		finally
		FGames.UnlockList;
		end;

	FGames.Free;

    inherited;
	end;

function TPlayZone.GameByName(ADesc: AnsiString): TPlayGame;
	var
	i: Integer;

	begin
	Result:= nil;
	with FGames.LockList do
		try
		for i:= 0 to Count - 1 do
			if  CompareText(string(Items[i].Desc), string(ADesc)) = 0 then
				begin
				Result:= Items[i];
				Exit;
				end;
		finally
		FGames.UnlockList;
		end;
	end;

class function TPlayZone.Name: AnsiString;
	begin
	result:= 'play';
	end;

procedure TPlayZone.ProcessPlayerMessage(APlayer: TPlayer;
        AMessage: TBaseMessage; var AHandled: Boolean);
	var
	g: TPlayGame;
	d: AnsiString;
	m: TBaseMessage;
	ml: TMessageList;
	i: Integer;
	p: AnsiString;
	f: Boolean;
	s: Integer;

	begin
	if  AMessage.Category = mcPlay then
		if  AMessage.Method = 1 then
			begin
			AHandled:= True;
			AMessage.ExtractParams;

			if  (AMessage.Params.Count > 0)
			and (AMessage.Params.Count < 3) then
				begin
				d:= Copy(AMessage.Params[0], Low(AnsiString), 8);
				g:= GameByName(AMessage.Params[0]);

				if  AMessage.Params.Count = 2 then
					p:= AMessage.Params[1]
				else
					p:= '';

				if  not Assigned(g) then
					g:= AddGame(d, p);

				if  CompareText(string(p), string(g.Password)) = 0 then
					begin
					g.Lock.Acquire;
						try
						if  (g.State < gsPreparing)
						and (g.SlotCount < 6) then
							begin
							g.Add(APlayer);

							s:= -1;
							for i:= 0 to 5 do
								begin
								if  (Assigned(g.Slots[i].Player))
								or  (g.Slots[i].State > psPlaying) then
									g.SendSlotStatus(APlayer, i);

								if  g.Slots[i].Player = APlayer then
									s:= i;
								end;

							Assert(s > -1, 'Failure in handling join in play zone.');

							for i:= 0 to 5 do
								if  (Assigned(g.Slots[i].Player))
								and (g.Slots[i].Player <> APlayer) then
									g.SendSlotStatus(g.Slots[i].Player, s);
							end
						else
							begin
							m:= TBaseMessage.Create;
							m.Category:= mcPlay;
							m.Method:= $00;

							m.Params.Add(LIT_ERR_PLAYGMST);
							m.DataFromParams;

                            APlayer.AddSendMessage(m);
							end;
						finally
						g.Lock.Release;
						end;
					end
				else
					begin
					m:= TBaseMessage.Create;
					m.Category:= mcPlay;
					m.Method:= $00;

					m.Params.Add(LIT_ERR_PLAYPWDR);
					m.DataFromParams;

                    APlayer.AddSendMessage(m);
					end;
				end
			else
				APlayer.SendServerError(LIT_ERR_PLAYJINV);
			end
		else if AMessage.Method = 2 then
			begin
			AMessage.ExtractParams;

			g:= GameByName(AMessage.Params[0]);

			if  Assigned(g) then
				begin
				g.Remove(APlayer);
				end
			else
				APlayer.SendServerError(LIT_ERR_PLAYPINV);

			AHandled:= True;
			end
		else if AMessage.Method = $03 then
			begin
			AHandled:= True;

			AMessage.ExtractParams;

			g:= nil;

			if  AMessage.Params.Count > 0 then
				begin
				g:= GameByName(AMessage.Params[0]);
				if  not Assigned(g) then
					begin
					APlayer.SendServerError(LIT_ERR_PLAYLINV);
					Exit;
					end;
				end;

			ml:= TMessageList.Create(APlayer);

			if  AMessage.Params.Count > 0 then
				begin
				g.Lock.Acquire;
					try
					f:= False;
					for i:= 0 to 5 do
						if  g.Slots[i].Player = APlayer then
							begin
							f:= True;
							Break;
							end;

					if  f
					or  (Length(g.Password) = 0) then
						for i:= 0 to 5 do
							if  Assigned(g.Slots[i].Player) then
								ml.Data.Enqueue(g.Slots[i].Name + ' ' +
										AnsiChar(i + $30));

					finally
					g.Lock.Release;
					end
				end
			else
				with FGames.LockList do
					try
					for i:= 0 to Count - 1 do
						if  Length(Items[i].Password) = 0 then
							ml.Data.Enqueue(Items[i].Desc);

					finally
					FGames.UnlockList;
					end;

			m:= TBaseMessage.Create;
			m.Category:= mcText;
			m.Method:= $01;
			m.Params.Add(ml.Name);
			m.Params.Add(AnsiString(ARR_LIT_NAM_CATEGORY[mcPlay]));

			if  AMessage.Params.Count > 0 then
				m.Params.Add(g.Desc);

			m.DataFromParams;

            APlayer.AddSendMessage(m);

            ListMessages.Add(ml);
			end
	end;

procedure TPlayZone.Remove(APlayer: TPlayer);
	begin
	APlayer.RemoveZoneByClass(TPlayGame);
	end;

procedure TPlayZone.RemoveGame(ADesc: AnsiString);
	var
	g: TPlayGame;

	begin
	g:= GameByName(ADesc);
	if  Assigned(g) then
		FGames.Remove(g);
	end;


initialization
    Randomize;

	ExpireZones:= TExpireZones.Create;
	ExpirePlayers:= TExpirePlayers.Create;

	ListMessages:= TMessageLists.Create;

	SystemZone:= TSystemZone.Create;
	LimboZone:= TLimboZone.Create;
	LobbyZone:= TLobbyZone.Create;
	PlayZone:= TPlayZone.Create;

finalization
	with ExpirePlayers.LockList do
		try
		while Count > 0 do
			begin
			Items[0].Free;
			Delete(0);
			end;
		finally
		ExpirePlayers.UnlockList;
		end;

	with ExpireZones.LockList do
		try
		while Count > 0 do
			begin
			Items[0].Free;
			Delete(0);
			end;
		finally
		ExpireZones.UnlockList;
		end;

	ServerDisp.Terminate;
	ServerDisp.WaitFor;
	ServerDisp.Free;

	DoDestroyListMessages;

	ExpireZones.Free;
    ExpirePlayers.Free;

	PlayZone.Free;
	LobbyZone.Free;
	LimboZone.Free;
	SystemZone.Free;

//	MessageLock.Free;

end.
