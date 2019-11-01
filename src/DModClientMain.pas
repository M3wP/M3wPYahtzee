unit DModClientMain;

{$IFDEF FPC}
	{$MODE DELPHI}
{$ENDIF}
{$H+}


interface

uses
	Classes, SysUtils, FileUtil, Controls, ActnList, ExtCtrls, YahtzeeClient;

type

	{ TClientMainDMod }
	TClientMainDMod = class(TDataModule)
		ActHostConnect: TAction;
		ActHostDisconnect: TAction;
		ActGameJoin: TAction;
		ActGamePart: TAction;
		ActGameList: TAction;
		ActGameControl: TAction;
		ActGameRoll: TAction;
		ActGameScore: TAction;
		ActGameFollow: TAction;
		ActNavReturn: TAction;
		ActNavStart: TAction;
		ActNavOverview: TAction;
		ActRoomMsg: TAction;
		ActRoomUsers: TAction;
		ActRoomList: TAction;
		ActRoomPart: TAction;
		ActRoomJoin: TAction;
		ActNavLobby: TAction;
		ActNavRoom: TAction;
		ActlstMain: TActionList;
		ActNavHost: TAction;
		ActNavDebug: TAction;
		ActNavConfigure: TAction;
		ActNavPlay: TAction;
		ActNavChat: TAction;
		ActNavConnect: TAction;
		ActlstNavigate: TActionList;
		ImageList1: TImageList;
		ImageList2: TImageList;
		ImageList3: TImageList;
		TimerMain: TTimer;
		procedure ActGameControlExecute(Sender: TObject);
		procedure ActGameFollowExecute(Sender: TObject);
  		procedure ActGameJoinExecute(Sender: TObject);
		procedure ActGameListExecute(Sender: TObject);
		procedure ActGamePartExecute(Sender: TObject);
		procedure ActGameRollExecute(Sender: TObject);
		procedure ActGameScoreExecute(Sender: TObject);
  		procedure ActHostConnectExecute(Sender: TObject);
		procedure ActHostDisconnectExecute(Sender: TObject);
  		procedure ActNavChatExecute(Sender: TObject);
		procedure ActNavConfigureExecute(Sender: TObject);
  		procedure ActNavConnectExecute(Sender: TObject);
  		procedure ActNavDebugExecute(Sender: TObject);
  		procedure ActNavHostExecute(Sender: TObject);
		procedure ActNavLobbyExecute(Sender: TObject);
		procedure ActNavOverviewExecute(Sender: TObject);
  		procedure ActNavPlayExecute(Sender: TObject);
		procedure ActNavReturnExecute(Sender: TObject);
		procedure ActNavRoomExecute(Sender: TObject);
		procedure ActNavStartExecute(Sender: TObject);
		procedure ActRoomJoinExecute(Sender: TObject);
		procedure ActRoomListExecute(Sender: TObject);
		procedure ActRoomMsgExecute(Sender: TObject);
		procedure ActRoomPartExecute(Sender: TObject);
		procedure ActRoomUsersExecute(Sender: TObject);
		procedure TimerMainTimer(Sender: TObject);
	private
		FConnection: TTCPConnection;
		FClient: TYahtzeeClient;

        procedure ConnectForwardBack(const AForward, ABack: TAction);

        procedure OnAfterConnect(ASender: TObject);
        procedure DoHandleDisconnected;

		procedure ProcessRoomLogMessages;
		procedure ProcessGameLogMessages;

	protected
		procedure DoConnect;
		procedure DoDisconnect;

	public
      	constructor Create(AOwner: TComponent); override;
		destructor  Destroy; override;

        property  Connection: TTCPConnection read FConnection;
		property  Client: TYahtzeeClient read FClient;
	end;

var
	ClientMainDMod: TClientMainDMod;

implementation

{$R *.lfm}

uses
	LMessages, LCLIntf, Forms, FormClientMain, YahtzeeClasses;


{ TClientMainDMod }

procedure TClientMainDMod.ActNavConnectExecute(Sender: TObject);
	begin
    if  ClientMainForm.PgctrlConnect.ActivePage = ClientMainForm.TbshtDebug then
		ConnectForwardBack(nil, ActNavHost)
	else
  		ConnectForwardBack(ActNavDebug, nil);

    ClientMainForm.PgctrlMain.ActivePage:= ClientMainForm.TbshtConnect;
	ActNavConnect.Checked:= True;
	end;

procedure TClientMainDMod.ActNavDebugExecute(Sender: TObject);
	begin
  	ConnectForwardBack(nil, ActNavHost);
    ClientMainForm.PgctrlConnect.ActivePage:= ClientMainForm.TbshtDebug;
	end;

procedure TClientMainDMod.ActNavHostExecute(Sender: TObject);
	begin
  	ConnectForwardBack(ActNavDebug, nil);
    ClientMainForm.PgctrlConnect.ActivePage:= ClientMainForm.TbshtHost;
	end;

procedure TClientMainDMod.ActNavLobbyExecute(Sender: TObject);
	begin
  	ConnectForwardBack(ActNavRoom, nil);
    ClientMainForm.PgctrlChat.ActivePage:= ClientMainForm.TbshtLobby;
	end;

procedure TClientMainDMod.ActNavOverviewExecute(Sender: TObject);
	begin
    ConnectForwardBack(nil, ActNavStart);
	ClientMainForm.PgctrlPlay.ActivePage:= ClientMainForm.TbshtOverview;
	end;

procedure TClientMainDMod.ActNavPlayExecute(Sender: TObject);
	begin
    if  ClientMainForm.PgctrlPlay.ActivePage = ClientMainForm.TbshtStart then
		ConnectForwardBack(ActNavOverview, nil)
	else if ClientMainForm.PgctrlPlay.ActivePage = ClientMainForm.TbshtOverview then
  		ConnectForwardBack(nil, ActNavStart)
	else
		ConnectForwardBack(nil, ActNavReturn);

    ClientMainForm.PgctrlMain.ActivePage:= ClientMainForm.TbshtPlay;
	ActNavPlay.Checked:= True;
	end;

procedure TClientMainDMod.ActNavReturnExecute(Sender: TObject);
	begin
    ConnectForwardBack(nil, ActNavStart);
	ClientMainForm.PgctrlPlay.ActivePage:= ClientMainForm.TbshtOverview;
	end;

procedure TClientMainDMod.ActNavRoomExecute(Sender: TObject);
	begin
  	ConnectForwardBack(nil, ActNavLobby);
    ClientMainForm.PgctrlChat.ActivePage:= ClientMainForm.TbshtRoom;
	end;

procedure TClientMainDMod.ActNavStartExecute(Sender: TObject);
	begin
    ConnectForwardBack(ActNavOverview, nil);
    ClientMainForm.PgctrlPlay.ActivePage:= ClientMainForm.TbshtStart;
	end;

procedure TClientMainDMod.ActRoomJoinExecute(Sender: TObject);
	begin
    if  Length(FClient.Room) = 0 then
		if  Length(ClientMainForm.EditRoom.Text) > 0 then
			FClient.SendRoomJoin(FConnection,
					AnsiString(ClientMainForm.EditRoom.Text),
					AnsiString(ClientMainForm.EditRoomPwd.Text))
		else
         	ClientMainForm.ActiveControl:= ClientMainForm.EditRoom;
	end;

procedure TClientMainDMod.ActRoomListExecute(Sender: TObject);
	begin
    FClient.SendRoomList(FConnection);
	end;

procedure TClientMainDMod.ActRoomMsgExecute(Sender: TObject);
	begin
    FClient.SendRoomMessage(FConnection,
			AnsiString(ClientMainForm.EditRoomText.Text));
	ClientMainForm.EditRoomText.Text:= '';
	end;

procedure TClientMainDMod.ActRoomPartExecute(Sender: TObject);
	begin
    if  Length(FClient.Room) > 0 then
		FClient.SendRoomPart(FConnection);
	end;

procedure TClientMainDMod.ActRoomUsersExecute(Sender: TObject);
	begin
    ClientMainForm.PanelRoomUsers.Visible:= not
			ClientMainForm.PanelRoomUsers.Visible;
	end;

procedure TClientMainDMod.TimerMainTimer(Sender: TObject);
	var
	i: Integer;

	begin
	with LogMessages.LockList do
		try
 			while Count > 0 do
				begin
				ClientMainForm.MemoDebug.Lines.Add(Items[0].Message);
                Items[0].Free;
				Delete(0)
				end;

			finally
            LogMessages.UnlockList;
			end;

    while  HostLogMessages.Count > 0 do
		begin
		ClientMainForm.MemoHost.Lines.Add(HostLogMessages[0]);
        HostLogMessages.Delete(0);
		end;

	ProcessRoomLogMessages;
	ProcessGameLogMessages;

	if  FConnection.Connected then
		begin
	    i:= FConnection.PrepareRead;

		if  i = -1 then
			DoDisconnect
		else
			begin
	        if  i > 0 then
				if  not FClient.ReadConnectionData(FConnection, i) then
					begin
					DoDisconnect;
					Exit;
					end;

	        FClient.ProcessReadMessages(FConnection);

            if  not FConnection.ProcessSendMessages then
				begin
				DoDisconnect;
				Exit;
				end;
			end;
		end;
	end;

procedure TClientMainDMod.ConnectForwardBack(const AForward, ABack: TAction);
    var
	i: Integer;

	begin
    for i:= 0 to ActlstNavigate.ActionCount - 1 do
		if  ActlstNavigate.Actions[i].Category = 'NavBrowse' then
			TAction(ActlstNavigate.Actions[i]).ShortCut:= 0;

	if  Assigned(AForward) then
		AForward.Shortcut:= 118;

	if  Assigned(ABack) then
		ABack.Shortcut:= 119;
	end;

procedure TClientMainDMod.OnAfterConnect(ASender: TObject);
	begin
    FConnection.Connected:= True;

	ClientMainForm.BtnHostCntrl.Action:= ActHostDisconnect;

	AddLogMessage(slkInfo, 'Client connected...');

	HostLogMessages.Add('! Connected to host.');
	HostLogMessages.Add('');
	end;

procedure TClientMainDMod.DoHandleDisconnected;
	begin
    FConnection.Connected:= False;
	FConnection.Purge;

	ClientMainForm.BtnHostCntrl.Action:= ActHostConnect;
	AddLogMessage(slkInfo, 'Client disconnected.');

	HostLogMessages.Add('');
	HostLogMessages.Add('! Disconnected from host.');
	HostLogMessages.Add('');

	if  Assigned(FClient.Server) then
		begin
		FClient.Server.Free;
        FClient.Server:= nil;
		end;

	ClientMainForm.EditHostInfo.Text:= '';
	end;

procedure TClientMainDMod.ProcessRoomLogMessages;
	var
	p: Integer;
	s,
	u,
	r: string;
	w: Boolean;

	begin
	while RoomLogMessages.Count > 0 do
		begin
		s:= RoomLogMessages.Items[0];
		RoomLogMessages.Delete(0);

		if  (s[Low(string)] = '<')
		or  (s[Low(string)] = '>') then
			begin
			if  not FClient.RoomHaveSpc then
				ClientMainForm.MemoRoom.Lines.Add('');

			ClientMainForm.MemoRoom.Lines.Add(s);
			ClientMainForm.MemoRoom.Lines.Add('');

			FClient.LastSpeak:= '';
			FClient.RoomHaveSpc:= True;
			end
		else
			begin
			w:= s[Low(string)] = '!';

			s:= Copy(s, Low(string) + 1, MaxInt);

			if  not w then
				begin
				p:= Pos(' ', s);
				r:= Copy(s, Low(string), p - Low(string));
				s:= Copy(s, p + 1, MaxInt);
				end;

			p:= Pos(' ', s);
			u:= Copy(s, Low(string), p - Low(string));
			s:= Copy(s, p + 1, MaxInt);

			if  w then
				u:= u + ' whispers';

			if  CompareText(u, Client.LastSpeak) <> 0 then
				begin
				FClient.LastSpeak:= u;

				ClientMainForm.MemoRoom.Lines.Add(u + ':');
				end;

			ClientMainForm.MemoRoom.Lines.Add(#9 + s);
			FClient.RoomHaveSpc:= False;
			end;
		end;
	end;

procedure TClientMainDMod.ProcessGameLogMessages;
	var
	p: Integer;
	s,
	u,
	r: string;
	w: Boolean;

	begin
	while GameLogMessages.Count > 0 do
		begin
		s:= GameLogMessages.Items[0];
		GameLogMessages.Delete(0);

		if  (s[Low(string)] = '<')
		or  (s[Low(string)] = '>') then
			begin
			if  not FClient.GameHaveSpc then
				ClientMainForm.MemoGame.Lines.Add('');

			ClientMainForm.MemoGame.Lines.Add(s);
			ClientMainForm.MemoGame.Lines.Add('');

			FClient.LastGameSpeak:= '';
			FClient.GameHaveSpc:= True;
			end
		else
			begin
			w:= s[Low(string)] = '!';

			s:= Copy(s, Low(string) + 1, MaxInt);

			if  not w then
				begin
				p:= Pos(' ', s);
				r:= Copy(s, Low(string), p - Low(string));
				s:= Copy(s, p + 1, MaxInt);
				end;

			p:= Pos(' ', s);
			u:= Copy(s, Low(string), p - Low(string));
			s:= Copy(s, p + 1, MaxInt);

			if  w then
				u:= u + ' whispers';

			if  CompareText(u, Client.LastSpeak) <> 0 then
				begin
				FClient.LastGameSpeak:= u;

				ClientMainForm.MemoGame.Lines.Add(u + ':');
				end;

			ClientMainForm.MemoGame.Lines.Add(#9 + s);
			FClient.GameHaveSpc:= False;
			end;
		end;
	end;

procedure TClientMainDMod.DoConnect;
    var
	cr: TCursor;

	begin
    cr:= Application.MainForm.Cursor;

	Application.MainForm.Cursor:= crHourGlass;
	try
	    FConnection.Connected:= False;
	    FConnection.Socket.ConnectionTimeout:= 5000;
	    FConnection.Socket.Connect(ClientMainForm.EditHost.Text, '7632');

		if  Assigned(FClient.Server) then
			begin
			FClient.Server.Free;
			FClient.Server:= nil;
			end;

		ClientMainForm.EditHostInfo.Text:= '';

		finally
        Application.MainForm.Cursor:= cr;
		end;
	end;

procedure TClientMainDMod.DoDisconnect;
	begin
	try
    	FConnection.Socket.CloseSocket;
		except
		end;

	DoHandleDisconnected;
	end;

constructor TClientMainDMod.Create(AOwner: TComponent);
	begin
	inherited Create(AOwner);

    FConnection:= TTCPConnection.Create;
	FClient:= TYahtzeeClient.Create;

	FConnection.Socket.OnAfterConnect:= OnAfterConnect;
	end;

destructor TClientMainDMod.Destroy;
	begin
    FClient.Free;
	FConnection.Free;

	inherited Destroy;
	end;

procedure TClientMainDMod.ActNavChatExecute(Sender: TObject);
	begin
    if  ClientMainForm.PgctrlChat.ActivePage = ClientMainForm.TbshtRoom then
		ConnectForwardBack(nil, ActNavLobby)
	else
  		ConnectForwardBack(ActNavRoom, nil);

    ClientMainForm.PgctrlMain.ActivePage:= ClientMainForm.TbshtChat;
	ActNavChat.Checked:= True;
	end;

procedure TClientMainDMod.ActHostConnectExecute(Sender: TObject);
	begin
    if  not FConnection.Connected then
		begin
        if  Length(ClientMainForm.EditUserName.Text) > 0 then
        	begin
            FClient.OurIdent:= ClientMainForm.EditUserName.Text;
			DoConnect;
			end
		else
			ClientMainForm.ActiveControl:= ClientMainForm.EditUserName;
		end;
	end;

procedure TClientMainDMod.ActGameJoinExecute(Sender: TObject);
	begin
    if  not Assigned(FClient.Game) then
		if  Length(ClientMainForm.EditGame.Text) > 0 then
			FClient.SendGameJoin(FConnection,
					AnsiString(ClientMainForm.EditGame.Text),
					AnsiString(ClientMainForm.EditGamePwd.Text))
		else
         	ClientMainForm.ActiveControl:= ClientMainForm.EditGame;
	end;

procedure TClientMainDMod.ActGameListExecute(Sender: TObject);
	begin
    FClient.SendGameList(FConnection);
	end;

procedure TClientMainDMod.ActGameControlExecute(Sender: TObject);
	begin
	if  Assigned(FClient.Game) then
		begin
		if  ActGameControl.Tag = 1 then
            FClient.SendGameSlotStatus(FConnection, FClient.Game.OurSlot,
					psReady)
		else if ActGameControl.Tag = 2 then
            FClient.SendGameSlotStatus(FConnection, FClient.Game.OurSlot,
					psIdle)
		else if ActGameControl.Tag = 3 then
        	FClient.SendGameRollDice(FConnection, FClient.Game.OurSlot,
					VAL_SET_DICEALL);
		end;
	end;

procedure TClientMainDMod.ActGameFollowExecute(Sender: TObject);
	begin
    if  Assigned(FClient.Game) then
		FClient.Game.FollowActive:= ActGameFollow.Checked;
	end;

procedure TClientMainDMod.ActGamePartExecute(Sender: TObject);
	begin
    if  Assigned(FClient.Game) then
		FClient.SendGamePart(FConnection);
	end;

procedure TClientMainDMod.ActGameRollExecute(Sender: TObject);
    var
	d: TDieSet;

	begin
    if  Assigned(FClient.Game)
	and (FClient.Game.VisibleSlot = FClient.Game.OurSlot)
	and (FClient.Game.RollNo < 3) then
		begin
        d:= [];

		if  ClientMainForm.BitBtn1.Parent = ClientMainForm.PanelRoll then
			Include(d, 1);
		if  ClientMainForm.BitBtn2.Parent = ClientMainForm.PanelRoll then
			Include(d, 2);
		if  ClientMainForm.BitBtn3.Parent = ClientMainForm.PanelRoll then
			Include(d, 3);
		if  ClientMainForm.BitBtn4.Parent = ClientMainForm.PanelRoll then
			Include(d, 4);
		if  ClientMainForm.BitBtn5.Parent = ClientMainForm.PanelRoll then
			Include(d, 5);

		FClient.SendGameRollDice(FConnection, FClient.Game.OurSlot, d);
		end;
	end;

procedure TClientMainDMod.ActGameScoreExecute(Sender: TObject);
	begin
    if  Assigned(FClient.Game)
	and (FClient.Game.VisibleSlot = FClient.Game.OurSlot)
	and FClient.Game.SelScore then
		begin
		FillChar(FClient.Game.Preview, SizeOf(TScoreSheet), $FF);
		FClient.Game.PreviewLoc:= [];

		FClient.SendGameScore(FConnection, FClient.Game.OurSlot,
				FClient.Game.SelScoreLoc);
		end;
	end;

procedure TClientMainDMod.ActHostDisconnectExecute(Sender: TObject);
	begin
    if  FConnection.Connected then
		DoDisconnect
	else
		DoHandleDisconnected;
	end;

procedure TClientMainDMod.ActNavConfigureExecute(Sender: TObject);
	begin
    ClientMainForm.PgctrlMain.ActivePage:= ClientMainForm.TbshtConfigure;
	ActNavConfigure.Checked:= True;
	end;

end.

