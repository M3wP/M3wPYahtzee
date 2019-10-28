unit YahtzeeClient;

interface

uses
{$IFDEF ANDROID}
	ORawByteString,
{$ENDIF}
	Generics.Collections, Classes, SyncObjs, YahtzeeClasses, IdGlobal, IdTCPClient;


type
	TClientDispatcher = class(TThread)
	protected
		procedure Execute; override;

	public

	end;

	TSlot = record
		Name: AnsiString;
		State: TPlayerState;
		Score: Word;
		Sheet: TScoreSheet;
		Dice: TDice;
		FirstRoll: Integer;
		Keepers: TDieSet;
	end;

	TGame = class(TObject)
		Lock: TCriticalSection;
		Desc: AnsiString;
		Slots: array[0..5] of TSlot;
		OurSlot: Integer;
		VisibleSlot: Integer;
		State: TGameState;
		Round: Word;
		RollNo: Integer;
		Preview: TScoreSheet;
		PreviewLoc: TScoreLocations;

		WasConnected: Boolean;
		LostConnection: Boolean;

		LastSpeak: string;
		RoomHaveSpc: Boolean;

		GameLastSpeak: string;
		GameHaveSpc: Boolean;

		LastWhisp: string;
		ConnHaveSpc: Boolean;
		SelScore: Boolean;
		SelScoreLoc: TScoreLocation;
		WaitKeeper: Boolean;

		constructor Create;
		destructor  Destroy; override;
	end;

	TPlayer = class(TObject)
	public
		Connection: TIdTCPClient;

		Room: AnsiString;
		Game: TGame;

		Name: AnsiString;
		Server: TNamedHost;

		InputBuffer: TIdBytes;

		constructor Create;
		destructor  Destroy; override;

		procedure SendConnctIdent(AName: AnsiString);

		procedure ExecuteMessages;

		procedure SendClientError(AMessage: AnsiString);
	end;

	TMessageList = class(TObject)
		Name,
		Desc,
		Locale: AnsiString;
	end;

	TMessageLists = class(TObject)
	private
		procedure DoBeginMessageList(AMessageList: TMessageList);
		procedure DoDataMessageList(AMessageList: TMessageList; AData: AnsiString);

	public
		Lists: TThreadList<TMessageList>;

		constructor Create;
		destructor  Destroy; override;

		function  MessageListByName(AName: AnsiString): TMessageList;

		procedure ReceiveTextMessage(AMessage: TMessage);

		procedure Clear;
	end;

	procedure PushDebugMsg(AMessage: AnsiString);

var
//	MessageLock: TCriticalSection;
	SendMessages: TMessages;
	ReadMessages: TMessages;

	ClientLog: TLogMessages;
	RoomLog: TLogMessages;
	GameLog: TLogMessages;

	ListMessages: TMessageLists;

	Client: TPlayer;

	ClientDisp: TClientDispatcher;

	DebugFile: TFileStream;
	DebugLock: TCriticalSection;

const
	LIT_SYS_VERNAME = 'alpha';
{$IFDEF ANDROID}
	LIT_SYS_PLATFRM = 'android';
{$ELSE}
	LIT_SYS_PLATFRM = 'mswindows';
{$ENDIF}
	LIT_SYS_VERSION = '0.00.80A';


implementation

uses
	SysUtils, IdIOHandler, FormClientMain;


const
	LIT_ERR_SERVERID = 'invalid server ident';
	LIT_ERR_SERVERCM = 'invalid server command';
	LIT_ERR_CONNCTCM = 'invalid connection command';
	LIT_ERR_CONNCTID = 'invalid connection ident';
	LIT_ERR_TEXTINVB = 'invalid text begin';
	LIT_ERR_TEXTINVM = 'invalid text more';
	LIT_ERR_TEXTINVD = 'invalid text data';


procedure PushDebugMsg(AMessage: AnsiString);
	var
	s: AnsiString;

	begin
{$IFNDEF ANDROID}
	DebugLock.Acquire;
		try
		if  Assigned(DebugFile) then
			begin
			s:= AMessage + AnsiString(#13#10);
			DebugFile.Write(s[Low(AnsiString)], Length(s));
			DebugFile.Seek(0, soFromEnd);
			end;

		finally
		DebugLock.Release;
		end;
{$ENDIF}

	DebugMsgs.PushItem(AMessage);
	end;


{ TClientDispatcher }

procedure TClientDispatcher.Execute;
	var
	m: TMessage;
	buffer: TIdBytes;
	s: AnsiString;
	i: Integer;

	begin
	while not Terminated do
		begin
		Client.Game.Lock.Acquire;
		try
			if  Client.Game.WasConnected
			and ((not Assigned(Client.Connection))
			or   (not Client.Connection.Connected)) then
				Client.Game.LostConnection:= True;

			finally
			Client.Game.Lock.Release;
			end;

		Client.Game.Lock.Acquire;
		try
			if  Assigned(Client.Connection)
			and Client.Connection.Connected then
				begin
				Client.Connection.ReadTimeout:= 1;
				Client.Connection.IOHandler.ReadBytes(Client.InputBuffer, -1, True);

				if  (Length(Client.InputBuffer) > 0)
				and (Length(Client.InputBuffer) > Client.InputBuffer[0]) then
					begin
					PushDebugMsg(AnsiString('Received message.'));

					SetLength(buffer, Client.InputBuffer[0] + 1);
					for i:= 0 to Client.InputBuffer[0] do
						buffer[i]:= Client.InputBuffer[i];

					Client.InputBuffer:= Copy(Client.InputBuffer,
							Client.InputBuffer[0] + 1, MaxInt);

					m:= TMessage.Create;
					m.Decode(buffer);

					m.ExtractParams;
					s:= AnsiString('>Receiving'#9) +
							AnsiString(ARR_LIT_NAM_CATEGORY[m.Category]) +
							AnsiString(#9) + AnsiString(IntToStr(m.Method)) +
							AnsiString(#9);
					for i:= 0 to m.Params.Count - 1 do
						s:= s + m.Params[i] + AnsiString(' ');

					PushDebugMsg(s);

					ReadMessages.PushItem(m);
					end;
				end;

			finally
			Client.Game.Lock.Release;
			end;

		Sleep(17);

		Client.Game.Lock.Acquire;
		try
			while  SendMessages.QueueSize > 0 do
				begin
				PushDebugMsg(AnsiString('Sending message.'));
				m:= SendMessages.PopItem;

				if  not Assigned(m) then
					Continue;

				if  Assigned(Client.Connection)
				and Client.Connection.Connected then
					begin
					m.Encode(buffer);

					Client.Connection.IOHandler.Write(buffer);

					m.ExtractParams;
					s:= AnsiString('<Sending'#9) +
							AnsiString(ARR_LIT_NAM_CATEGORY[m.Category]) +
							AnsiString(#9) + AnsiString(IntToStr(m.Method)) +
							AnsiString(#9);
					for i:= 0 to m.Params.Count - 1 do
						s:= s + m.Params[i] + AnsiString(' ');

					PushDebugMsg(s);
					end
				else
					PushDebugMsg(AnsiString('Discarding message.'));

				m.Free;
				end;

			finally
			Client.Game.Lock.Release;
			end;

		Sleep(17);
		end;
	end;

{ TPlayer }

constructor TPlayer.Create;
	begin
	inherited;

	Connection:= TIdTCPClient.Create(nil);
	end;

destructor TPlayer.Destroy;
	begin
	if  Assigned(Connection) then
		FreeAndNil(Connection);

	if  Assigned(Game) then
		Game.Free;

	if  Assigned(Server) then
		Server.Free;

	inherited;
	end;

procedure TPlayer.ExecuteMessages;
	var
	m: TMessage;

	procedure SendClientIdent;
		var
		m: TMessage;

		begin
		m:= TMessage.Create;

		m.Category:= mcClient;
		m.Method:= 1;
		m.Params.Add(AnsiString(LIT_SYS_VERNAME));
		m.Params.Add(AnsiString(LIT_SYS_PLATFRM));
		m.Params.Add(AnsiString(LIT_SYS_VERSION));
		m.DataFromParams;

//		MessageLock.Acquire;
//		try
			SendMessages.PushItem(m);

//			finally
//			MessageLock.Release;
//			end;
		end;


	procedure HandleServerMessage(AMessage: TMessage);
		var
		m: TMessage;

		begin
		Game.Lock.Acquire;
		try
			if  AMessage.Method = 0 then
				begin
				if  not Game.ConnHaveSpc then
					ClientLog.PushItem(AnsiString(''));

				ClientLog.PushItem(AnsiString('Server Error:'));
				ClientLog.PushItem(AnsiString(#9) + AMessage.DataToString);
				ClientLog.PushItem(AnsiString(''));

				Game.ConnHaveSpc:= True;
				end
			else if  AMessage.Method = 1 then
				begin
				AMessage.ExtractParams;

				if  AMessage.Params.Count = 3 then
					begin
					if  not Assigned(Server) then
						Server:= TNamedHost.Create;

					Server.Name:= AMessage.Params[0];
					Server.Host:= AMessage.Params[1];
					Server.Version:= AMessage.Params[2];

//					ClientMainForm.actUpdateServer.Execute;
					ClientMainForm.actUpdateServerExecute(nil);

					SendClientIdent;
					SendConnctIdent(Client.Name);

					m:= TMessage.Create;
					m.Category:= mcText;
					m.Method:= $00;

//					MessageLock.Acquire;
//					try
						SendMessages.PushItem(m);

//						finally
//						MessageLock.Release;
//						end;
					end
				else
					SendClientError(AnsiString(LIT_ERR_SERVERID));
				end
			else if AMessage.Method = 2 then
				begin
				m:= TMessage.Create;
				m.Category:= mcClient;
				m.Method:= $02;

				SendMessages.PushItem(m);
				end
			else
				SendClientError(AnsiString(LIT_ERR_SERVERCM));

			finally
			Game.Lock.Release;
			end;
		end;

	procedure HandleConnectMessage(AMessage: TMessage);
		begin
		Game.Lock.Acquire;
		try
			if  AMessage.Method = $00 then
				begin
				if  not Game.ConnHaveSpc then
					ClientLog.PushItem(AnsiString(''));

				ClientLog.PushItem(AnsiString('Connection Error:'));
				ClientLog.PushItem(AnsiString(#9) + AMessage.DataToString);
				ClientLog.PushItem(AnsiString(''));

				Game.ConnHaveSpc:= True;
				end
			else if  AMessage.Method = $01 then
				begin
				AMessage.ExtractParams;

				if  AMessage.Params.Count = 1 then
					begin
					Client.Name:= AMessage.Params[0];

//					ClientMainForm.actUpdateName.Execute;
					ClientMainForm.actUpdateNameExecute(nil);

					end
				else if AMessage.Params.Count = 2 then

				else
					SendClientError(AnsiString(LIT_ERR_CONNCTID));
				end
			else
				SendClientError(AnsiString(LIT_ERR_CONNCTCM));

			finally
			Game.Lock.Release;
			end;
		end;

	procedure HandleLobbyMessage(AMessage: TMessage);
		var
		m: TMessage;
		i: Integer;

		begin
		if  AMessage.Method = $01 then
			begin
			AMessage.ExtractParams;

			if  AMessage.Params.Count > 1 then
				begin
				if  (CompareText(string(AMessage.Params[1]), string(Client.Name)) = 0) then
					begin
					Client.Room:= AMessage.Params[0];

//					ClientMainForm.actUpdateRoomJoin.Execute;
					ClientMainForm.actUpdateRoomJoinExecute(nil);
					end;

				if  (CompareText(string(AMessage.Params[0]), string(Client.Room)) = 0) then
					begin
					i:= ClientMainForm.ListBox1.Items.IndexOf(string(AMessage.Params[1]));
					if  i = -1 then
						ClientMainForm.ListBox1.Items.Add(string(AMessage.Params[1]));
					end;

				RoomLog.PushItem(AnsiString('> ') + AMessage.Params[1] +
						AnsiString(' joins ') + AMessage.Params[0]);

				m:= TMessage.Create;
				m.Category:= mcLobby;
				m.Method:= $03;
				m.Params.Add(Client.Room);
				m.DataFromParams;

//				MessageLock.Acquire;
//				try
					SendMessages.PushItem(m);

//					finally
//					MessageLock.Release;
//					end;
				end;
			end
		else if  AMessage.Method = $02 then
			begin
			AMessage.ExtractParams;

			if  AMessage.Params.Count > 1 then
				begin
				if  CompareText(string(AMessage.Params[1]), string(Client.Name)) = 0 then
					begin
					Client.Room:= AnsiString('');

//					ClientMainForm.actUpdateRoomPart.Execute;
					ClientMainForm.actUpdateRoomPartExecute(nil);

					ClientMainForm.ListBox1.Clear;
					end
				else if  (CompareText(string(AMessage.Params[0]),
						string(Client.Room)) = 0) then
					for i:= ClientMainForm.ListBox1.Items.Count - 1 downto 0 do
						if  CompareText(string(AMessage.Params[1]),
								ClientMainForm.ListBox1.Items[i]) = 0 then
							ClientMainForm.ListBox1.Items.Delete(i);

				RoomLog.PushItem(AnsiString('< ') + AMessage.Params[1] +
						AnsiString(' parts ') + AMessage.Params[0]);
				end;
			end
		else if  AMessage.Method = $04 then
			begin
			RoomLog.PushItem(AnsiString('-') + AMessage.DataToString);
			end;
		end;

	procedure HandleTextMessage(AMessage: TMessage);
		begin
		if  AMessage.Method = $04 then
			begin
			RoomLog.PushItem(AnsiString('!') + AMessage.DataToString);
			end
		else
			ListMessages.ReceiveTextMessage(m);
		end;

	procedure HandlePlayMessage(AMessage: TMessage);
		var
		m: TMessage;
		i,
		j: Integer;
		n: TScoreLocation;
		r: Word;
		f: Boolean;

		begin
		if  AMessage.Method = $01 then
			begin
			PushDebugMsg(AnsiString('Message play $01'));

			AMessage.ExtractParams;

			if  AMessage.Params.Count > 2 then
				begin
				m:= nil;

				Client.Game.Lock.Acquire;
					try
					if  (CompareText(string(AMessage.Params[1]), string(Client.Name)) = 0) then
						begin
						Client.Game.Desc:= AMessage.Params[0];

						Client.Game.State:= gsWaiting;
{$IFDEF ANDROID}
						Client.Game.OurSlot:= Byte(AMessage.Params[2].Chars[0]) - $30;
{$ELSE}
						Client.Game.OurSlot:= Ord(AMessage.Params[2][Low(AnsiString)]) - $30;
{$ENDIF}
						Client.Game.VisibleSlot:= -1;

						for i:= 0 to 5 do
							FillChar(Client.Game.Slots[i], SizeOf(TSlot), 0);

						for i:= 0 to 5 do
							for j:= Ord(Low(TScoreLocation)) to Ord(High(TScoreLocation)) do
								Client.Game.Slots[i].Sheet[TScoreLocation(j)]:=
										VAL_KND_SCOREINVALID;

//						ClientMainForm.actUpdateGameJoin.Execute;
						ClientMainForm.actUpdateGameJoinExecute(nil);

						m:= TMessage.Create;
						m.Category:= mcPlay;
						m.Method:= $03;
						end;

					if  (CompareText(string(AMessage.Params[0]), string(Client.Game.Desc)) = 0) then
						begin
{$IFDEF ANDROID}
//						DebugMsgs.PushItem(AnsiString(AMessage.DataText));

						i:= Byte(AMessage.Params[2].Chars[0]) - $30;
{$ELSE}
						i:= Ord(AMessage.Params[2][Low(AnsiString)]) - $30;
{$ENDIF}
						Client.Game.Slots[i].Name:= AMessage.Params[1];
						end;

//					for i:= 0 to 5 do
//						ClientMainForm.UpdateGameSlotState(Client.Game.State, i);

					if  Assigned(m) then
						m.Params.Add(Client.Game.Desc);

					finally
					Client.Game.Lock.Release;
					end;

				if  Assigned(m) then
					begin
					m.DataFromParams;

//					MessageLock.Acquire;
//					try
						SendMessages.PushItem(m);

//						finally
//						MessageLock.Release;
//						end;
					end;

				GameLog.PushItem(AnsiString('> ') + AMessage.Params[1] +
						AnsiString(' joins ') + AMessage.Params[0]);
				end;
			end
		else if  AMessage.Method = $02 then
			begin
			PushDebugMsg(AnsiString('Message play $02'));

			AMessage.ExtractParams;

			if  AMessage.Params.Count > 1 then
				begin
				Client.Game.Lock.Acquire;
				try
					if  CompareText(string(AMessage.Params[1]), string(Client.Name)) = 0 then
						begin
						Client.Game.Desc:= AnsiString('');

//						ClientMainForm.actUpdateGamePart.Execute;
						ClientMainForm.actUpdateGamePartExecute(nil);
						end
					else if (CompareText(string(AMessage.Params[0]),
							string(Client.Game.Desc)) = 0) then
						begin

						end;
					finally
					Client.Game.Lock.Release;
					end;

				GameLog.PushItem(AnsiString('< ') + AMessage.Params[1] +
						AnsiString(' parts ') + AMessage.Params[0]);
				end;
			end
		else if  AMessage.Method = $04 then
			begin
			PushDebugMsg(AnsiString('Message play $04'));

			GameLog.PushItem(AnsiString('-') + AMessage.DataToString);
			end
		else if AMessage.Method = $06 then
			begin
			PushDebugMsg(AnsiString('Message play $06'));

//			AMessage.ExtractParams;

//			if  AMessage.Params.Count > 1 then
			if  Length(AMessage.Data) = 3 then
				begin
				Client.Game.Lock.Acquire;
					try
					Client.Game.State:=
//							TGameState(Ord(AMessage.Params[0][Low(AnsiString)]));
							TGameState(AMessage.Data[0]);
					Client.Game.Round:=
//							(Ord(AMessage.Params[1][Low(AnsiString)]) shl 8) or
//							Ord(AMessage.Params[1][Succ(Low(AnsiString))]);
							(AMessage.Data[1] shl 8) or AMessage.Data[2];

					for i:= 0 to 5 do
						ClientMainForm.UpdateGameSlotState(Client.Game.State, i);

					ClientMainForm.UpdateOurState;

					finally
					Client.Game.Lock.Release;
					end;
				end;
			end
		else if AMessage.Method = $07 then
			begin
			PushDebugMsg(AnsiString('Message play $07'));

//			AMessage.ExtractParams;

//			if  AMessage.Params.Count > 2 then
			if  Length(AMessage.Data) = 4 then
				begin
				Client.Game.Lock.Acquire;
					try
//					i:= Ord(AMessage.Params[0][Low(AnsiString)]);
					i:= AMessage.Data[0];

					Client.Game.Slots[i].State:= TPlayerState(
//							Ord(AMessage.Params[1][Low(AnsiString)]));
							AMessage.Data[1]);
					Client.Game.Slots[i].Score:=
//							(Ord(AMessage.Params[2][Low(AnsiString)]) shl 8) or
//							Ord(AMessage.Params[2][Succ(Low(AnsiString))]);
							(AMessage.Data[2] shl 8) or AMessage.Data[3];

					ClientMainForm.UpdateGameSlotState(Client.Game.State, i);

					if  i = Client.Game.OurSlot then
						ClientMainForm.UpdateOurState;

					if  ClientMainForm.CheckBox1.IsChecked
					and (Client.Game.Slots[i].State = psPlaying) then
						Client.Game.VisibleSlot:= i;

					if  ClientMainForm.CheckBox1.IsChecked
					or  ((Client.Game.State > gsPreparing)
					and  (i = Client.Game.VisibleSlot)) then
//						ClientMainForm.actUpdateGameDetail.Execute;
						ClientMainForm.actUpdateGameDetailExecute(nil);

					finally
					Client.Game.Lock.Release;
					end;
				end;
			end
		else if AMessage.Method = $08 then
			begin
			PushDebugMsg(AnsiString('Message play $08'));

			ClientMainForm.actGameRoll.Tag:= 0;

//			AMessage.ExtractParams;

//			if  AMessage.Params.Count = 6 then
			if  Length(AMessage.Data) = 6 then
				begin
				Client.Game.Lock.Acquire;
					try
//					i:= Ord(AMessage.Params[0][Low(AnsiString)]);
					i:= AMessage.Data[0];

					for j:= 0 to 4 do
						Client.Game.Slots[i].Dice[j]:=
//								Ord(AMessage.Params[j + 1][Low(AnsiString)]);
								AMessage.Data[j + 1];

					if  Client.Game.Slots[i].State = psPreparing then
						begin
						Client.Game.Slots[i].FirstRoll:= 0;
						for j:= 0 to 4 do
							Client.Game.Slots[i].FirstRoll:=
									Client.Game.Slots[i].FirstRoll +
									Client.Game.Slots[i].Dice[j];
						end;

					if  (Client.Game.State > gsPreparing)
					and (i = Client.Game.VisibleSlot) then
//						ClientMainForm.actUpdateGameDetail.Execute;
						ClientMainForm.actUpdateGameDetailExecute(nil);

					finally
					Client.Game.Lock.Release;
					end;
				end;
			end
		else if AMessage.Method = $09 then
			begin
			PushDebugMsg(AnsiString('Message play $09'));

//			ClientMainForm.WaitKeeper:= False;

			if  Length(AMessage.Data) = 3 then
				begin
				Client.Game.Lock.Acquire;
					try
					i:= AMessage.Data[0];

					if  AMessage.Data[2] = 0 then
						Exclude(Client.Game.Slots[i].Keepers, AMessage.Data[1])
					else
						Include(Client.Game.Slots[i].Keepers, AMessage.Data[1]);

					if  (Client.Game.State > gsPreparing)
					and (i = Client.Game.VisibleSlot) then
//						ClientMainForm.actUpdateGameDetail.Execute;
						ClientMainForm.actUpdateGameDetailExecute(nil);

					finally
					Client.Game.Lock.Release;
					end;
				end;
			end
		else if AMessage.Method = $0A then
			begin
			PushDebugMsg(AnsiString('Message play $0A'));

			if  Length(AMessage.Data) = 4 then
				begin
				Client.Game.Lock.Acquire;
					try
					i:= AMessage.Data[0];
					n:= TScoreLocation(AMessage.Data[1]);
					r:= (AMessage.Data[2] shl 8) or AMessage.Data[3];

					Client.Game.Preview[n]:= r;
					Include(Client.Game.PreviewLoc, n);

					f:= Client.Game.VisibleSlot = i;

					finally
					Client.Game.Lock.Release;
					end;

				if  f then
					ClientMainForm.StringGrid1.Repaint;
				end;
			end
		else if AMessage.Method = $0B then
			begin
			PushDebugMsg(AnsiString('Message play $0B'));

			if  Length(AMessage.Data) = 4 then
				begin
				Client.Game.Lock.Acquire;
					try
					i:= AMessage.Data[0];
					n:= TScoreLocation(AMessage.Data[1]);
					r:= (AMessage.Data[2] shl 8) or AMessage.Data[3];

					Client.Game.Slots[i].Sheet[n]:= r;

					Client.Game.RollNo:= 0;

					f:= Client.Game.VisibleSlot = i;

					finally
					Client.Game.Lock.Release;
					end;

				if  f then
					ClientMainForm.StringGrid1.Repaint;
				end;
			end;
		end;

	begin
//	MessageLock.Acquire;
//	try
		while ReadMessages.QueueSize > 0 do
//		if  ReadMessages.QueueSize > 0 then
			begin
			m:= ReadMessages.PopItem;

			if  not Assigned(m) then
				Continue;

			case m.Category of
				mcSystem:
					;
				mcText:
					HandleTextMessage(m);
				mcLobby:
					HandleLobbyMessage(m);
				mcConnect:
					HandleConnectMessage(m);
				mcClient:
					;
				mcServer:
					HandleServerMessage(m);
				mcPlay:
					HandlePlayMessage(m);
				end;

			m.Free;
			end;

//		finally
//		MessageLock.Release;
//		end;

	end;


procedure TPlayer.SendConnctIdent(AName: AnsiString);
	var
	m: TMessage;

	begin
	m:= TMessage.Create;

	m.Category:= mcConnect;
	m.Method:= 1;
	m.Params.Add(AName);
	m.DataFromParams;

//	MessageLock.Acquire;
//	try
		SendMessages.PushItem(m);

//		finally
//		MessageLock.Release;
//		end;
	end;

procedure TPlayer.SendClientError(AMessage: AnsiString);
	var
	m: TMessage;

	begin
	m:= TMessage.Create;

	m.Category:= mcClient;
	m.Method:= 0;
	m.Params.Add(AMessage);
	m.DataFromParams;

//	MessageLock.Acquire;
//	try
		SendMessages.PushItem(m);

//		finally
//		MessageLock.Release;
//		end;
	end;

{ TMessageLists }

procedure TMessageLists.Clear;
	var
	i: Integer;

	begin
	with Lists.LockList do
		try
		for i:= 0 to Count - 1 do
			begin
			Remove(Items[i]);
			Items[i].Free;
			end;

		finally
		Lists.UnlockList;
		end;
	end;

constructor TMessageLists.Create;
	begin
	inherited Create;

	Lists:= TThreadList<TMessageList>.Create;
	end;

destructor TMessageLists.Destroy;
	var
	i: Integer;

	begin
	with Lists.LockList do
		try
		for i:= 0 to Count - 1 do
			Items[i].Free;

		finally
		Lists.UnlockList;
		end;

	Lists.Free;

	inherited;
	end;

procedure TMessageLists.DoBeginMessageList(AMessageList: TMessageList);
	begin
	if  CompareText(string(AMessageList.Desc),
			string(ARR_LIT_NAM_CATEGORY[mcLobby])) = 0 then
		begin
{$IFDEF ANDROID}
		if  AnsiLength(AMessageList.Locale) = 0 then
{$ELSE}
		if  Length(AMessageList.Locale) = 0 then
{$ENDIF}
			ClientMainForm.Memo3.Lines.Clear
		else if  CompareText(string(AMessageList.Locale), string(Client.Room)) = 0 then
			ClientMainForm.ListBox1.Clear;
		end
	else if CompareText(string(AMessageList.Desc),
			string(ARR_LIT_NAM_CATEGORY[mcPlay])) = 0 then
{$IFDEF ANDROID}
		if  AnsiLength(AMessageList.Locale) = 0 then
{$ELSE}
		if  Length(AMessageList.Locale) = 0 then
{$ENDIF}
			ClientMainForm.Memo5.Lines.Clear;
	end;

procedure TMessageLists.DoDataMessageList(AMessageList: TMessageList;
		AData: AnsiString);
	var
	p: Integer;
	u: AnsiString;
	s: Integer;
	d: AnsiString;
//	t: string;

	begin
	if  CompareText(string(AMessageList.Desc),
			string(ARR_LIT_NAM_CATEGORY[mcSystem])) = 0 then
		begin
		Client.Game.Lock.Acquire;
			try
			Client.Game.ConnHaveSpc:= False;

			finally
            Client.Game.Lock.Release;
            end;

		ClientLog.PushItem(AnsiString('* ') + AData);
		end
	else if  CompareText(string(AMessageList.Desc),
			string(ARR_LIT_NAM_CATEGORY[mcLobby])) = 0 then
{$IFDEF ANDROID}
		if  AnsiLength(AMessageList.Locale) > 0 then
{$ELSE}
		if  Length(AMessageList.Locale) > 0 then
{$ENDIF}
			begin
			if  CompareText(string(AMessageList.Locale), string(Client.Room)) = 0 then
				ClientMainForm.ListBox1.Items.Add(string(AData));
			end
		else
			ClientMainForm.Memo3.Lines.Add(string(AData))
	else if  CompareText(string(AMessageList.Desc),
			string(ARR_LIT_NAM_CATEGORY[mcPlay])) = 0 then
{$IFDEF ANDROID}
		if  AnsiLength(AMessageList.Locale) > 0 then
{$ELSE}
		if  Length(AMessageList.Locale) > 0 then
{$ENDIF}
			begin
			p:= Pos(' ', string(AData));
{$IFDEF ANDROID}
//			t:= string(AData);

			u:= AnsiCopy(AData, 1, p - 1);
			d:= AnsiCopy(AData, p + 1, AData.Length - p);

//			t:= t + ' :"' + string(u) + '" "' + string(d) + '"';
//			DebugMsgs.PushItem(AnsiString(t));

{$ELSE}
			u:= Copy(AData, Low(AData), p);
			d:= Copy(AData, p + 1, MaxInt);
{$ENDIF}

{$IFDEF ANDROID}
			s:= Byte(d.Chars[0]) - $30;
{$ELSE}
			s:= Ord(d[Low(AnsiString)]) - $30;
{$ENDIF}
			Client.Game.Lock.Acquire;
				try
				Client.Game.Slots[s].Name:= u;

				ClientMainForm.UpdateGameSlotState(Client.Game.State, s);

				finally
				Client.Game.Lock.Release;
				end;
			end
		else
			ClientMainForm.Memo5.Lines.Add(string(AData));
	end;

function TMessageLists.MessageListByName(AName: AnsiString): TMessageList;
	var
	i: Integer;

	begin
	Result:= nil;

	with Lists.LockList do
		try
		for i:= 0 to Count - 1 do
			if  CompareText(string(Items[i].Name), string(AName)) = 0 then
				begin
				Result:= Items[i];
				Break;
				end;

		finally
		Lists.UnlockList;
		end;
	end;

procedure TMessageLists.ReceiveTextMessage(AMessage: TMessage);
	var
	ml: TMessageList;
	i: Integer;
	s: AnsiString;
	f: Boolean;
	m: TMessage;

	begin
	if  AMessage.Category = mcText then
		if  AMessage.Method = $01 then
			begin
			PushDebugMsg(AnsiString('Message text $01'));

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
				Client.SendClientError(AnsiString(LIT_ERR_TEXTINVB));
			end
		else if AMessage.Method = $02 then
			begin
			PushDebugMsg(AnsiString('Message text $02'));

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

							ClientLog.PushItem(AnsiString(''));

							Client.Game.Lock.Acquire;
								try
								Client.Game.ConnHaveSpc:= True;

								finally
								Client.Game.Lock.Release;
								end;

							f:= True;
							end
						else
							begin
							m:= TMessage.Create;
							m.Assign(AMessage);

//							MessageLock.Acquire;
//							try
								SendMessages.PushItem(m);

//								finally
//								MessageLock.Release;
//								end;
							end;
						end;
				end;

			if  not f then
				Client.SendClientError(AnsiString(LIT_ERR_TEXTINVM));
			end
		else if AMessage.Method = $03 then
			begin
			PushDebugMsg(AnsiString('Message text $03'));

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
				Client.SendClientError(AnsiString(LIT_ERR_TEXTINVD));
			end;
	end;


{ TGame }

constructor TGame.Create;
	begin
	inherited;

	Lock:= TCriticalSection.Create;
	end;

destructor TGame.Destroy;
	begin
	Lock.Free;

	inherited;
	end;

initialization
	DebugLock:= TCriticalSection.Create;
	DebugFile:= nil;

//	MessageLock:= TCriticalSection.Create;

	SendMessages:= TMessages.Create(64, 1000, 1);
	ReadMessages:= TMessages.Create(64, 1000, 1);

	ClientLog:= TLogMessages.Create(64, 10);
	RoomLog:= TLogMessages.Create(64, 10);
	GameLog:= TLogMessages.Create(64, 10);

	ListMessages:= TMessageLists.Create;

	Client:= TPlayer.Create;
	Client.Game:= TGame.Create;

	Client.Game.PreviewLoc:= [];
	FillChar(Client.Game.Preview, SizeOf(TScoreSheet), $FF);
	FillChar(Client.Game.Slots[0].Sheet, SizeOf(TScoreSheet), $FF);
	FillChar(Client.Game.Slots[1].Sheet, SizeOf(TScoreSheet), $FF);
	FillChar(Client.Game.Slots[2].Sheet, SizeOf(TScoreSheet), $FF);
	FillChar(Client.Game.Slots[3].Sheet, SizeOf(TScoreSheet), $FF);
	FillChar(Client.Game.Slots[4].Sheet, SizeOf(TScoreSheet), $FF);
	FillChar(Client.Game.Slots[5].Sheet, SizeOf(TScoreSheet), $FF);

	ClientDisp:= TClientDispatcher.Create(False);


finalization
	ClientDisp.Terminate;
	ClientDisp.WaitFor;
	ClientDisp.Free;

	Client.Free;

	ListMessages.Free;

	GameLog.Free;
	RoomLog.Free;
	ClientLog.Free;

	ReadMessages.Free;
	SendMessages.Free;

//	MessageLock.Free;

	if  Assigned(DebugFile) then
		DebugFile.Free;

	DebugFile:= nil;
	DebugLock.Free;

end.
