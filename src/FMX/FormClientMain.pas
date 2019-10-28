unit FormClientMain;

interface

uses
	System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
	FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.TabControl,
	FMX.StdCtrls, FMX.Controls.Presentation, FMX.Gestures, System.Actions,
	FMX.ActnList, FMX.ScrollBox, FMX.Memo, IdBaseComponent, IdComponent,
	IdTCPConnection, IdTCPClient, FMX.Edit, FMX.Layouts, FMX.ListBox, System.Rtti,
	FMX.Grid, System.ImageList, FMX.ImgList, YahtzeeClasses;

type
  TClientMainForm = class(TForm)
	TabControl1: TTabControl;
	TabItem1: TTabItem;
	TabControl2: TTabControl;
	TabItem5: TTabItem;
	ToolBar1: TToolBar;
	lblTitle1: TLabel;
	btnNext: TSpeedButton;
	TabItem6: TTabItem;
	ToolBar2: TToolBar;
	lblTitle2: TLabel;
	btnBack: TSpeedButton;
	TabItem2: TTabItem;
	TabItem3: TTabItem;
	TabItem4: TTabItem;
	ToolBar5: TToolBar;
	lblTitle5: TLabel;
	GestureManager1: TGestureManager;
	ActionList1: TActionList;
	NextTabAction1: TNextTabAction;
	PreviousTabAction1: TPreviousTabAction;
	Timer1: TTimer;
	Panel1: TPanel;
	Label1: TLabel;
	Edit1: TEdit;
	Label2: TLabel;
	Edit2: TEdit;
	Button1: TButton;
	Label3: TLabel;
	Edit3: TEdit;
	Memo2: TMemo;
	actConnectConnect: TAction;
	actConnectSetName: TAction;
    actUpdateName: TAction;
	actUpdateServer: TAction;
    Button2: TButton;
    TabControl3: TTabControl;
    TabItem7: TTabItem;
    ToolBar3: TToolBar;
    Label4: TLabel;
    SpeedButton1: TSpeedButton;
    Panel2: TPanel;
    TabItem8: TTabItem;
    ToolBar6: TToolBar;
	Label8: TLabel;
    SpeedButton2: TSpeedButton;
    NextTabAction2: TNextTabAction;
    PreviousTabAction2: TPreviousTabAction;
    Label5: TLabel;
    Edit4: TEdit;
    Button3: TButton;
	Button4: TButton;
	Memo3: TMemo;
	actRoomJoin: TAction;
	Panel3: TPanel;
	Memo4: TMemo;
	Edit5: TEdit;
	actRoomSend: TAction;
	actUpdateRoomLog: TAction;
    actUpdateRoomJoin: TAction;
    actUpdateRoomPart: TAction;
    actRoomList: TAction;
    SpeedButton3: TSpeedButton;
    Panel4: TPanel;
    ListBox1: TListBox;
    actRoomToggleMembers: TAction;
    TabControl4: TTabControl;
    TabItem9: TTabItem;
    ToolBar4: TToolBar;
    Label6: TLabel;
    Panel5: TPanel;
    Memo5: TMemo;
    TabItem10: TTabItem;
    ToolBar7: TToolBar;
	Label9: TLabel;
    SpeedButton5: TSpeedButton;
    Panel6: TPanel;
    Panel7: TPanel;
    ListBox2: TListBox;
	TabItem11: TTabItem;
	ToolBar8: TToolBar;
	Label10: TLabel;
    SpeedButton7: TSpeedButton;
    Panel8: TPanel;
    Panel9: TPanel;
    ListBox3: TListBox;
    Edit7: TEdit;
    Label11: TLabel;
	Panel10: TPanel;
	Memo1: TMemo;
	ListBox4: TListBox;
    Label13: TLabel;
    Memo6: TMemo;
    Label14: TLabel;
    Label15: TLabel;
    Edit9: TEdit;
    Label16: TLabel;
    Label17: TLabel;
    Button7: TButton;
    Label18: TLabel;
    GridPanelLayout1: TGridPanelLayout;
    SpeedButton6: TSpeedButton;
    Glyph1: TGlyph;
    SpeedButton8: TSpeedButton;
    Glyph2: TGlyph;
    SpeedButton9: TSpeedButton;
    Glyph3: TGlyph;
    SpeedButton10: TSpeedButton;
    Glyph4: TGlyph;
    SpeedButton11: TSpeedButton;
    Glyph5: TGlyph;
    Button8: TButton;
    imgLstDie: TImageList;
    StringGrid1: TStringGrid;
    StringColumn1: TStringColumn;
    StringColumn2: TStringColumn;
    StringColumn3: TStringColumn;
    StringColumn4: TStringColumn;
    Label19: TLabel;
    Label20: TLabel;
    GridPanelLayout2: TGridPanelLayout;
	Button9: TButton;
    Label21: TLabel;
    Label22: TLabel;
    ListBoxItem1: TListBoxItem;
    ListBoxItem2: TListBoxItem;
	ListBoxItem3: TListBoxItem;
	ListBoxItem4: TListBoxItem;
	ListBoxItem5: TListBoxItem;
    ListBoxItem6: TListBoxItem;
    imgLstGamePlayer: TImageList;
    imgListZones: TImageList;
    StyleBook1: TStyleBook;
    GridPanelLayout3: TGridPanelLayout;
    GridPanelLayout4: TGridPanelLayout;
    GridPanelLayout5: TGridPanelLayout;
    Label7: TLabel;
	Edit6: TEdit;
    Label12: TLabel;
    Edit8: TEdit;
    Button5: TButton;
    Button6: TButton;
    PreviousTabAction3: TPreviousTabAction;
    NextTabAction3: TNextTabAction;
    CheckBox1: TCheckBox;
    actGameJoin: TAction;
    actGameList: TAction;
    actUpdateGameJoin: TAction;
    actUpdateGamePart: TAction;
    actUpdateGameLog: TAction;
    actGameControl: TAction;
    actUpdateGameDetail: TAction;
    actGameRoll: TAction;
    actGameScore: TAction;
    SpeedButton4: TSpeedButton;
	procedure GestureDone(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean);
	procedure FormCreate(Sender: TObject);
	procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
	procedure Timer1Timer(Sender: TObject);
	procedure IdTCPClient1Connected(Sender: TObject);
	procedure IdTCPClient1Disconnected(Sender: TObject);
	procedure actConnectConnectExecute(Sender: TObject);
	procedure actConnectSetNameExecute(Sender: TObject);
	procedure actConnectSetNameUpdate(Sender: TObject);
	procedure actUpdateNameExecute(Sender: TObject);
	procedure actUpdateServerExecute(Sender: TObject);
	procedure actRoomJoinExecute(Sender: TObject);
	procedure actRoomJoinUpdate(Sender: TObject);
	procedure Edit5KeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
	  Shift: TShiftState);
	procedure actRoomSendExecute(Sender: TObject);
	procedure actUpdateRoomLogExecute(Sender: TObject);
	procedure Edit4KeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
	  Shift: TShiftState);
	procedure actUpdateRoomPartExecute(Sender: TObject);
	procedure actUpdateRoomJoinExecute(Sender: TObject);
	procedure FormDestroy(Sender: TObject);
	procedure actRoomListExecute(Sender: TObject);
	procedure actRoomListUpdate(Sender: TObject);
	procedure actRoomToggleMembersExecute(Sender: TObject);
	procedure ToolBar3KeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
	  Shift: TShiftState);
	procedure Edit7KeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
	  Shift: TShiftState);
    procedure SpeedButton10Click(Sender: TObject);
    procedure actGameJoinExecute(Sender: TObject);
    procedure actGameJoinUpdate(Sender: TObject);
    procedure actGameListExecute(Sender: TObject);
	procedure actGameListUpdate(Sender: TObject);
	procedure actUpdateGameJoinExecute(Sender: TObject);
	procedure actUpdateGamePartExecute(Sender: TObject);
	procedure actUpdateGameLogExecute(Sender: TObject);
    procedure actGameControlUpdate(Sender: TObject);
    procedure actGameControlExecute(Sender: TObject);
    procedure actUpdateGameDetailExecute(Sender: TObject);
	procedure actGameRollExecute(Sender: TObject);
	procedure ListBoxItem1Click(Sender: TObject);
	procedure StringGrid1SelectCell(Sender: TObject; const ACol, ARow: Integer;
	  var CanSelect: Boolean);
	procedure StringGrid1DrawColumnCell(Sender: TObject; const Canvas: TCanvas;
	  const Column: TColumn; const Bounds: TRectF; const Row: Integer;
	  const Value: TValue; const State: TGridDrawStates);
	procedure StringGrid1MouseUp(Sender: TObject; Button: TMouseButton;
	  Shift: TShiftState; X, Y: Single);
	procedure actGameScoreExecute(Sender: TObject);
	procedure actGameScoreUpdate(Sender: TObject);
	procedure actGameRollUpdate(Sender: TObject);
    procedure StringGrid1Tap(Sender: TObject; const Point: TPointF);
    procedure TabControl4Change(Sender: TObject);
  private

	procedure DoConnect;
	procedure DoDisconnect;

  public
	procedure UpdateGameSlotState(AGameState: TGameState; ASlot: Integer);
	procedure UpdateOurState;
  end;

var
  ClientMainForm: TClientMainForm;

implementation

{$R *.fmx}

uses
{$IFDEF ANDROID}
	ORawByteString,
{$ENDIF}
	YahtzeeClient;

procedure TClientMainForm.actConnectConnectExecute(Sender: TObject);
	begin
	PushDebugMsg(AnsiString('actConnectConnectExecute.'));

	Client.Game.Lock.Acquire;
	try
		if  not Client.Connection.Connected then
			DoConnect
		else
			DoDisconnect;

		finally
		Client.Game.Lock.Release;
		end;
	end;

procedure TClientMainForm.actConnectSetNameExecute(Sender: TObject);
	begin
	PushDebugMsg(AnsiString('actConnectSetNameExecute.'));

	Client.SendConnctIdent(AnsiString(Edit2.Text));
	end;

procedure TClientMainForm.actConnectSetNameUpdate(Sender: TObject);
	begin
	Client.Game.Lock.Acquire;
	try
		actConnectSetName.Enabled:= Client.Game.WasConnected;

		finally
		Client.Game.Lock.Release;
		end;
	end;

procedure TClientMainForm.actGameControlExecute(Sender: TObject);
	var
	m: TMessage;

	begin
	PushDebugMsg(AnsiString('actGameControlExecute.'));

	Client.Game.Lock.Acquire;
	try
		if  actGameControl.Tag = 1 then
			begin
			m:= TMessage.Create;
			m.Category:= mcPlay;
			m.Method:= $07;
//			m.Params.Add(AnsiChar(Client.Game.OurSlot));
//			m.Params.Add(AnsiChar(psReady));
			SetLength(m.Data, 2);
			m.Data[0]:= Client.Game.OurSlot;
			m.Data[1]:= Ord(psReady);

//			m.DataFromParams;

//			MessageLock.Acquire;
//			try
				SendMessages.PushItem(m)
//				finally
//				MessageLock.Release;
//				end;
			end
		else if actGameControl.Tag = 2 then
			begin
			m:= TMessage.Create;
			m.Category:= mcPlay;
			m.Method:= $07;
//			m.Params.Add(AnsiChar(Client.Game.OurSlot));
//			m.Params.Add(AnsiChar(psIdle));
			SetLength(m.Data, 2);
			m.Data[0]:= Client.Game.OurSlot;
			m.Data[1]:= Ord(psIdle);

//			m.DataFromParams;

//			MessageLock.Acquire;
//			try
				SendMessages.PushItem(m)
//				finally
//				MessageLock.Release;
//				end;
			end
		else if actGameControl.Tag = 3 then
			begin
			m:= TMessage.Create;
			m.Category:= mcPlay;
			m.Method:= $08;
//			m.Params.Add(AnsiChar(Client.Game.OurSlot));
//			m.Params.Add(AnsiChar(DieSetToByte(VAL_SET_DICEALL)));
			SetLength(m.Data, 2);
			m.Data[0]:= Client.Game.OurSlot;
			m.Data[1]:= DieSetToByte(VAL_SET_DICEALL);

//			m.DataFromParams;

//			MessageLock.Acquire;
//			try
				SendMessages.PushItem(m)
//				finally
//				MessageLock.Release;
//				end;
			end;

		finally
		Client.Game.Lock.Release;
		end;
	end;

procedure TClientMainForm.actGameControlUpdate(Sender: TObject);
	begin
	actGameControl.Enabled:= actGameControl.Tag > 0;
	end;

procedure TClientMainForm.actGameJoinExecute(Sender: TObject);
	var
	m: TMessage;
{$IFDEF ANDROID}
	i: Integer;
{$ENDIF}

	begin
	PushDebugMsg(AnsiString('actGameJoinExecute.'));

	if  actGameJoin.Tag = 0 then
		begin
		if  Length(Edit6.Text) > 0 then
			begin
			m:= TMessage.Create;
			m.Category:= mcPlay;
			m.Method:= $01;
			m.Params.Add(AnsiString(Copy(Edit6.Text, Low(string), 8)));

			if  Length(Edit8.Text) > 0 then
				m.Params.Add(AnsiString(Copy(Edit8.Text, Low(string), 8)));

			m.DataFromParams;

//			MessageLock.Acquire;
//			try
				SendMessages.PushItem(m);

//				finally
//				MessageLock.Release;
//				end;
			end;
		end
	else
		begin
{$IFDEF ANDROID}
		if  AnsiLength(Client.Game.Desc) > 0 then
{$ELSE}
		if  Length(Client.Game.Desc) > 0 then
{$ENDIF}
			begin
			m:= TMessage.Create;
			m.Category:= mcPlay;
			m.Method:= $02;
{$IFDEF ANDROID}
			i:= AnsiLength(Client.Game.Desc);
			if  AnsiLength(Client.Game.Desc) > 8 then
				i:= 8;

			m.Params.Add(AnsiString(AnsiCopy(Client.Game.Desc, 1, i)));
{$ELSE}
			m.Params.Add(AnsiString(Copy(Client.Game.Desc, Low(AnsiString), 8)));
{$ENDIF}
			m.DataFromParams;

//			MessageLock.Acquire;
//			try
				SendMessages.PushItem(m);

//				finally
//				MessageLock.Release;
//				end;
			end;
		end;
	end;

procedure TClientMainForm.actGameJoinUpdate(Sender: TObject);
	begin
	Client.Game.Lock.Acquire;
	try
		actGameJoin.Enabled:= Client.Game.WasConnected;

		finally
		Client.Game.Lock.Release;
		end;
	end;

procedure TClientMainForm.actGameListExecute(Sender: TObject);
	var
	m: TMessage;

	begin
	PushDebugMsg(AnsiString('actGameListExecute.'));

	m:= TMessage.Create;
	m.Category:= mcPlay;
	m.Method:= $03;

//	MessageLock.Acquire;
//	try
		SendMessages.PushItem(m);

//		finally
//		MessageLock.Release;
//		end;
	end;

procedure TClientMainForm.actGameListUpdate(Sender: TObject);
	begin
	Client.Game.Lock.Acquire;
	try
		actGameList.Enabled:= Client.Game.WasConnected;

		finally
		Client.Game.Lock.Release;
		end;
	end;

procedure TClientMainForm.actGameRollExecute(Sender: TObject);
	var
	m: TMessage;

	begin
	PushDebugMsg(AnsiString('actGameRollExecute.'));

	actGameRoll.Tag:= 1;

	Client.Game.Lock.Acquire;
	try
		Client.Game.RollNo:= Client.Game.RollNo + 1;
		Client.Game.PreviewLoc:= [];
		FillChar(Client.Game.Preview, SizeOf(TScoreSheet), $FF);

		m:= TMessage.Create;
		m.Category:= mcPlay;
		m.Method:= $08;

		SetLength(m.Data, 2);
		m.Data[0]:= Client.Game.OurSlot;
		m.Data[1]:= DieSetToByte(VAL_SET_DICEALL -
				Client.Game.Slots[Client.Game.OurSlot].Keepers);

		finally
		Client.Game.Lock.Release;
		end;

//	MessageLock.Acquire;
//	try
		SendMessages.PushItem(m);

//		finally
//		MessageLock.Release;
//		end;

	StringGrid1.Repaint;
	end;

procedure TClientMainForm.actGameRollUpdate(Sender: TObject);
	begin
	Client.Game.Lock.Acquire;
	try
		actGameRoll.Enabled:= Client.Game.WasConnected and
				(Client.Game.OurSlot = Client.Game.VisibleSlot) and
				(Client.Game.Slots[Client.Game.OurSlot].State = psPlaying) and
				(Client.Game.RollNo < 3) and
				(actGameRoll.Tag = 0);

		finally
		Client.Game.Lock.Release;
		end;
	end;

procedure TClientMainForm.actGameScoreExecute(Sender: TObject);
	var
	m: TMessage;

	begin
	PushDebugMsg(AnsiString('actGameScoreExecute.'));

	Client.Game.Lock.Acquire;
	try
		if  Client.Game.SelScore then
			begin
			FillChar(Client.Game.Preview, SizeOf(TScoreSheet), $FF);
			Client.Game.PreviewLoc:= [];

			m:= TMessage.Create;
			m.Category:= mcPlay;
			m.Method:= $0B;
			SetLength(m.Data, 2);

			m.Data[0]:= Client.Game.OurSlot;
			m.Data[1]:= Ord(Client.Game.SelScoreLoc);

//			MessageLock.Acquire;
//			try
				SendMessages.PushItem(m);

//				finally
//				MessageLock.Release;
//				end;
			end;

		finally
		Client.Game.Lock.Release;
		end;
	end;

procedure TClientMainForm.actGameScoreUpdate(Sender: TObject);
	begin
	Client.Game.Lock.Acquire;
	try
		actGameScore.Enabled:= Client.Game.WasConnected and
				(Client.Game.OurSlot = Client.Game.VisibleSlot) and
				(Client.Game.Slots[Client.Game.OurSlot].State = psPlaying) and
				Client.Game.SelScore;

		finally
		Client.Game.Lock.Release;
		end;
	end;

procedure TClientMainForm.actRoomJoinExecute(Sender: TObject);
	var
	m: TMessage;
{$IFDEF ANDROID}
	i: Integer;
{$ENDIF}

	begin
	PushDebugMsg(AnsiString('actRoomJoinExecute.'));

	if  actRoomJoin.Tag = 0 then
		begin
		if  Length(Edit4.Text) > 0 then
			begin
			m:= TMessage.Create;
			m.Category:= mcLobby;
			m.Method:= $01;
			m.Params.Add(AnsiString(Copy(Edit4.Text, Low(string), 8)));

			if  Length(Edit7.Text) > 0 then
				m.Params.Add(AnsiString(Copy(Edit7.Text, Low(string), 8)));

			m.DataFromParams;

//			MessageLock.Acquire;
//			try
				SendMessages.PushItem(m);

//				finally
//				MessageLock.Release;
//				end;
			end;
		end
	else
		begin
{$IFDEF ANDROID}
		if  AnsiLength(Client.Room) > 0 then
{$ELSE}
		if  Length(Client.Room) > 0 then
{$ENDIF}
			begin
			m:= TMessage.Create;
			m.Category:= mcLobby;
			m.Method:= $02;
{$IFDEF ANDROID}
			i:= AnsiLength(Client.Game.Desc);
			if  AnsiLength(Client.Game.Desc) > 8 then
				i:= 8;

			m.Params.Add(AnsiString(AnsiCopy(Client.Room, 1, i)));
{$ELSE}
			m.Params.Add(AnsiString(Copy(Client.Room, Low(string), 8)));
{$ENDIF}
			m.DataFromParams;

//			MessageLock.Acquire;
//			try
				SendMessages.PushItem(m);

//				finally
//				MessageLock.Release;
//				end;
			end;
		end;
	end;

procedure TClientMainForm.actRoomJoinUpdate(Sender: TObject);
	begin
	Client.Game.Lock.Acquire;
	try
		actRoomJoin.Enabled:= Client.Game.WasConnected;

		finally
		Client.Game.Lock.Release;
		end;
	end;

procedure TClientMainForm.actRoomListExecute(Sender: TObject);
	var
	m: TMessage;

	begin
	PushDebugMsg(AnsiString('actRoomListExecute.'));

	m:= TMessage.Create;
	m.Category:= mcLobby;
	m.Method:= $03;

//	MessageLock.Acquire;
// 	try
		SendMessages.PushItem(m);

//		finally
//		MessageLock.Release;
//		end;
	end;

procedure TClientMainForm.actRoomListUpdate(Sender: TObject);
	begin
	Client.Game.Lock.Acquire;
	try
		actRoomList.Enabled:= Client.Game.WasConnected;

		finally
		Client.Game.Lock.Release;
		end;
	end;

procedure TClientMainForm.actRoomSendExecute(Sender: TObject);
	var
	m: TMessage;
	c: TMsgCategory;
	s: string;
	n: AnsiString;
	p: Integer;

	begin
	PushDebugMsg(AnsiString('actRoomSendExecute.'));

	s:= Edit5.Text;

	if  CompareText(Copy(s, Low(string), 3), '/w ') = 0 then
		begin
		c:= mcText;

		s:= Copy(s, Low(string) + 3, MaxInt);
		p:= Pos(' ', s);
		if  p < 2 then
			Exit
		else
			begin
			n:= AnsiString(Copy(s, Low(string), p - Low(string)));
			s:= Copy(s, p + 1, MaxInt);
			end;
		end
	else
		begin
		c:= mcLobby;

		n:= Client.Name;
		end;

	if  Length(s) > 0 then
		begin
		m:= TMessage.Create;
		m.Category:= c;
		m.Method:= $04;

		if  c = mcLobby then
			m.Params.Add(Client.Room);

		m.Params.Add(n);

		m.Params.Add(AnsiString(Copy(s, Low(string), 40)));

		m.DataFromParams;

//		MessageLock.Acquire;
//		try
			SendMessages.PushItem(m);

//			finally
//			MessageLock.Release;
//			end;
		end;

	Edit5.Text:= '';
	end;

procedure TClientMainForm.actRoomToggleMembersExecute(Sender: TObject);
	begin
	Panel4.Visible:= not Panel4.Visible;
	end;

procedure TClientMainForm.actUpdateGameDetailExecute(Sender: TObject);
	var
	s: Integer;
	f: Boolean;
	i: Integer;

	begin
	PushDebugMsg(AnsiString('actUpdateGameDetailExecute.'));

	Client.Game.Lock.Acquire;
	try
		s:= Client.Game.VisibleSlot;

		if  s < 0 then
			Exit;

		f:= s = Client.Game.OurSlot;

		Label22.Text:= string(Client.Game.Slots[s].Name);

		Glyph1.ImageIndex:= Client.Game.Slots[s].Dice[0];
		Glyph2.ImageIndex:= Client.Game.Slots[s].Dice[1];
		Glyph3.ImageIndex:= Client.Game.Slots[s].Dice[2];
		Glyph4.ImageIndex:= Client.Game.Slots[s].Dice[3];
		Glyph5.ImageIndex:= Client.Game.Slots[s].Dice[4];

		for i:= 1 to 5 do
			if  i in Client.Game.Slots[s].Keepers then
				GridPanelLayout1.ControlCollection.Items[i - 1].Row:= 1
			else
				GridPanelLayout1.ControlCollection.Items[i - 1].Row:= 0;

		if  f then
			if  Client.Game.RollNo = 3 then
				actGameRoll.Text:= 'Can''t Roll'
			else
				actGameRoll.Text:= 'Roll ' + IntToStr(Client.Game.RollNo + 1) + '/3'
		else
			actGameRoll.Text:= 'Rolling';

		Label20.Text:= IntToStr(Client.Game.Slots[s].Score);

		GridPanelLayout1.Enabled:= f;
		StringGrid1.Enabled:= f;
		Button9.Enabled:= f;

		actGameRoll.Enabled:= f and not (Client.Game.RollNo = 3);

		finally
		Client.Game.Lock.Release;
		end;
	end;

procedure TClientMainForm.actUpdateGameJoinExecute(Sender: TObject);
	begin
	PushDebugMsg(AnsiString('actUpdateGameJoinExecute.'));

	actGameJoin.Text:= 'Part';
	actGameJoin.Tag:= 1;
	Edit6.Enabled:= False;
	Edit8.Enabled:= False;

	Memo6.Lines.Clear;

	Client.Game.Lock.Acquire;
	try
		Client.Game.GameHaveSpc:= True;

		finally
		Client.Game.Lock.Release;
		end;
	end;

procedure TClientMainForm.actUpdateGameLogExecute(Sender: TObject);
	var
	p: Integer;
	s,
	u,
	r: string;
	f: Boolean;
//	w: Boolean;

	begin
	f:= GameLog.QueueSize > 0;

	Client.Game.Lock.Acquire;
	try
		while  GameLog.QueueSize > 0 do
			begin
			s:= string(GameLog.PopItem);

			if  (s[Low(string)] = '<')
			or  (s[Low(string)] = '>') then
				begin
				if  not Client.Game.GameHaveSpc then
					Memo6.Lines.Add('');

				Memo6.Lines.Add(s);
				Memo6.Lines.Add('');

				Client.Game.GameLastSpeak:= '';
				Client.Game.GameHaveSpc:= True;
				end
			else
				begin
				s:= Copy(s, Low(string) + 1, MaxInt);

				p:= Pos(' ', s);
				r:= Copy(s, Low(string), p - Low(string));
				s:= Copy(s, p + 1, MaxInt);

				p:= Pos(' ', s);
				u:= Copy(s, Low(string), p - Low(string));
				s:= Copy(s, p + 1, MaxInt);

				if  CompareText(u, Client.Game.GameLastSpeak) <> 0 then
					begin
					Client.Game.GameLastSpeak:= u;

					Memo6.Lines.Add(u + ':');
					end;

				Memo6.Lines.Add(#9 + s);
				Client.Game.GameHaveSpc:= False;
				end;
			end;

		finally
		Client.Game.Lock.Release;
		end;

	if  f then
		Memo6.ScrollBy(0, MaxInt);
	end;

procedure TClientMainForm.actUpdateGamePartExecute(Sender: TObject);
	begin
	PushDebugMsg(AnsiString('actUpdateGamePartExecute.'));

	actGameJoin.Text:= 'Join';
	actGameJoin.Tag:= 0;
	Edit6.Enabled:= True;
	Edit8.Enabled:= True;
	Edit8.Text:= '';

	TabControl4.ActiveTab:= TabItem9;
	end;

procedure TClientMainForm.actUpdateNameExecute(Sender: TObject);
	begin
	Edit2.Text:= string(Client.Name);
	end;

procedure TClientMainForm.actUpdateRoomJoinExecute(Sender: TObject);
	begin
	PushDebugMsg(AnsiString('actUpdateRoomJoinExecute.'));

	actRoomJoin.Text:= 'Part';
	actRoomJoin.Tag:= 1;
	Edit4.Enabled:= False;
	Edit7.Enabled:= False;
	end;

procedure TClientMainForm.actUpdateRoomLogExecute(Sender: TObject);
	var
	p: Integer;
	s,
	u,
	r: string;
	f: Boolean;
	w: Boolean;

	begin
	f:= RoomLog.QueueSize > 0;

	Client.Game.Lock.Acquire;
	try
		while  RoomLog.QueueSize > 0 do
			begin
			s:= string(RoomLog.PopItem);

			if  (s[Low(string)] = '<')
			or  (s[Low(string)] = '>') then
				begin
				if  not Client.Game.RoomHaveSpc then
					Memo4.Lines.Add('');

				Memo4.Lines.Add(s);
				Memo4.Lines.Add('');

				Client.Game.LastSpeak:= '';
				Client.Game.RoomHaveSpc:= True;
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

				if  CompareText(u, Client.Game.LastSpeak) <> 0 then
					begin
					Client.Game.LastSpeak:= u;

					Memo4.Lines.Add(u + ':');
					end;

				Memo4.Lines.Add(#9 + s);
				Client.Game.RoomHaveSpc:= False;
				end;
			end;
		finally
		Client.Game.Lock.Release;
		end;

	if  f then
		Memo4.ScrollBy(0, MaxInt);
	end;

procedure TClientMainForm.actUpdateRoomPartExecute(Sender: TObject);
	begin
	PushDebugMsg(AnsiString('actUpdateRoomPartExecute.'));

	actRoomJoin.Text:= 'Join';
	actRoomJoin.Tag:= 0;
	Edit4.Enabled:= True;
	Edit7.Enabled:= True;
	Edit7.Text:= '';
	end;

procedure TClientMainForm.actUpdateServerExecute(Sender: TObject);
	begin
	PushDebugMsg(AnsiString('actUpdateServerExecute.'));

	Edit3.Text:= string(Client.Server.Name + AnsiString(' ') + Client.Server.Host +
			AnsiString(' ') + Client.Server.version);
	end;

procedure TClientMainForm.DoConnect;
	begin
{$IFNDEF ANDROID}
	DebugLock.Acquire;
	try
		if  Assigned(DebugFile) then
			DebugFile.Destroy;

		DebugFile:= TFileStream.Create(Edit2.Text + '.log', fmCreate);

		finally
		DebugLock.Release;
		end;
{$ENDIF}

	PushDebugMsg(AnsiString('DoConnect.'));

	Client.Connection.OnConnected:= IdTCPClient1Connected;
	Client.Connection.OnDisconnected:= IdTCPClient1Disconnected;

	Client.Connection.Host:= Edit1.Text;
	Client.Connection.Port:= 7632;

	actConnectConnect.Text:= 'Disconnect';

	Client.Connection.Connect;

	actUpdateRoomPartExecute(Self);
	actUpdateGamePartExecute(Self);
	end;

procedure TClientMainForm.DoDisconnect;
	begin
	PushDebugMsg(AnsiString('DoDisconnect.'));

	Client.Game.Lock.Acquire;
	try
//		Client.Connection:= nil;
		SetLength(Client.InputBuffer, 0);

		finally
		Client.Game.Lock.Release;
		end;

	Client.Connection.OnDisconnected:= nil;
	Client.Connection.Disconnect;

	PushDebugMsg(AnsiString('Discarding read message queue.'));

//	MessageLock.Acquire;
//	try
		while ReadMessages.QueueSize > 0 do
			ReadMessages.PopItem.Free;

//		finally
//		MessageLock.Release;
//		end;

	ListMessages.Clear;

	actConnectConnect.Text:= 'Connect';
	Edit3.Text:= '';

	Client.Game.Lock.Acquire;
	try
		Client.Game.WasConnected:= False;
		Client.Game.LostConnection:= False;

		finally
		Client.Game.Lock.Release;
		end;
	end;

procedure TClientMainForm.Edit4KeyDown(Sender: TObject; var Key: Word;
		var KeyChar: Char; Shift: TShiftState);
	begin
	if  key = vkReturn then
		begin
		Key:= 0;
		actRoomJoin.Execute;
		end;
	end;

procedure TClientMainForm.Edit5KeyDown(Sender: TObject; var Key: Word;
		var KeyChar: Char; Shift: TShiftState);

	begin
	if  Key = vkReturn then
		begin
		Key:= 0;

		actRoomSend.Execute;
		end;
	end;

procedure TClientMainForm.Edit7KeyDown(Sender: TObject; var Key: Word;
		var KeyChar: Char; Shift: TShiftState);
	begin
	if  key = vkReturn then
		begin
		Key:= 0;
		actRoomJoin.Execute;
		end;
	end;

procedure TClientMainForm.FormCreate(Sender: TObject);
	var
	i: TScoreLocation;

	procedure CorrectRowSize(AGridPanel: TGridPanelLayout; ASize: Integer);
		var
		i: Integer;

		begin
		for i:= 0 to AGridPanel.RowCollection.Count - 1 do
			AGridPanel.RowCollection[i].Value:= ASize;

		AGridPanel.Height:= AGridPanel.RowCollection.Count * ASize + 2;
		end;

	begin
	{ This defines the default active tab at runtime }
	TabControl1.ActiveTab := TabItem1;

//	Client.Connection:= IdTCPClient1;

	Client.Game.RoomHaveSpc:= True;
	Client.Game.GameHaveSpc:= True;
	Client.Game.ConnHaveSpc:= True;

	for i:= slAces to slSixes do
		StringGrid1.Cells[0, Ord(i)]:= ARR_LIT_NAME_SCORELOC[i] + ':';

	StringGrid1.Cells[0, 9]:= ARR_LIT_NAME_SCORELOC[slUpperBonus] + ':';

	for i:= slThreeKind to slChance do
		StringGrid1.Cells[2, Ord(i) - Ord(slThreeKind)]:= ARR_LIT_NAME_SCORELOC[i] + ':';

	StringGrid1.Cells[2, 8]:= ARR_LIT_NAME_SCORELOC[slYahtzeeBonus1] + ':';
	StringGrid1.Cells[2, 9]:= 'Bonus Score:';

	GridPanelLayout3.ControlCollection[1].ColumnSpan:= 3;
	GridPanelLayout3.ControlCollection[3].ColumnSpan:= 2;
	GridPanelLayout3.ControlCollection[7].ColumnSpan:= 3;

{$IFDEF ANDROID}
//	CorrectRowSize(GridPanelLayout1, 40);
	CorrectRowSize(GridPanelLayout2, 32);
	CorrectRowSize(GridPanelLayout3, 40);
	CorrectRowSize(GridPanelLayout4, 40);
	CorrectRowSize(GridPanelLayout5, 40);

	Button1.Height:= 32;
	Button2.Height:= 32;
	Button3.Height:= 32;
	Button4.Height:= 32;
	Button5.Height:= 32;
	Button6.Height:= 32;
	Button7.Height:= 32;
	Button8.Height:= 32;
	Button9.Height:= 32;

	Label1.Height:= 32;
	Label2.Height:= 32;
	Label3.Height:= 32;
	Label4.Height:= 32;
	Label5.Height:= 32;
	Label6.Height:= 32;
	Label7.Height:= 32;
	Label8.Height:= 32;
	Label9.Height:= 32;
	Label10.Height:= 32;
	Label11.Height:= 32;
	Label12.Height:= 32;
	Label13.Height:= 32;
	Label14.Height:= 32;
	Label15.Height:= 32;
	Label16.Height:= 32;
	Label17.Height:= 32;
	Label18.Height:= 32;
	Label19.Height:= 32;
	Label20.Height:= 32;
	Label21.Height:= 32;
	Label22.Height:= 32;

	StringGrid1.OnMouseUp:= nil;

	StringGrid1.RowHeight:= 32;
	StringGrid1.Height:= StringGrid1.RowCount * 32;

{$ELSE}
	TabItem1.StyleLookup:= 'TabItem1Style1';
	TabItem2.StyleLookup:= 'TabItem1Style1';
	TabItem3.StyleLookup:= 'TabItem1Style1';
	TabItem4.StyleLookup:= 'TabItem1Style1';
{$ENDIF}
	end;

procedure TClientMainForm.FormDestroy(Sender: TObject);
	begin
	Client.Game.Lock.Acquire;
	try
		if  Client.Game.WasConnected then
			Client.Connection.Disconnect;

		finally
		Client.Game.Lock.Release;
		end;
	end;

procedure TClientMainForm.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
	begin
	if Key = vkHardwareBack then
		begin
		if  (TabControl1.ActiveTab = TabItem1)
		and (TabControl2.ActiveTab = TabItem6) then
			begin
			TabControl2.Previous;
			Key := 0;
			end;
		end;
	end;

procedure TClientMainForm.GestureDone(Sender: TObject;
		const EventInfo: TGestureEventInfo; var Handled: Boolean);
	begin
	case EventInfo.GestureID of
		sgiLeft:
			begin
			if TabControl1.ActiveTab <> TabControl1.Tabs[TabControl1.TabCount - 1] then
				TabControl1.ActiveTab := TabControl1.Tabs[TabControl1.TabIndex + 1];
			Handled := True;
			end;

		sgiRight:
			begin
			if TabControl1.ActiveTab <> TabControl1.Tabs[0] then
				TabControl1.ActiveTab := TabControl1.Tabs[TabControl1.TabIndex - 1];
			Handled := True;
			end;
		end;
	end;

procedure TClientMainForm.IdTCPClient1Connected(Sender: TObject);
	begin
	PushDebugMsg(AnsiString('Connected to server.'));

	Client.Game.Lock.Acquire;
	try
		Client.Game.WasConnected:= Client.Connection.Connected;
        Client.Game.LostConnection:= False;

//	MessageLock.Acquire;
//	try
//		Client.Connection:= Client.Connection;
		Client.Name:= AnsiString(Edit2.Text);

//		finally
//		MessageLock.Release;
//		end;

		finally
		Client.Game.Lock.Release;
		end;
	end;

procedure TClientMainForm.IdTCPClient1Disconnected(Sender: TObject);
	begin
	PushDebugMsg(AnsiString('Disconnected from server.'));

	DoDisconnect;
	end;

procedure TClientMainForm.ListBoxItem1Click(Sender: TObject);
	var
	s: Integer;
	f: Boolean;

	begin
	PushDebugMsg(AnsiString('ListBoxItem1Click.'));

	f:= False;
	s:= (Sender as TListBoxItem).Tag;

	Client.Game.Lock.Acquire;
	try
		if  (Client.Game.State > gsPreparing)
		and (Client.Game.Slots[s].State > psPreparing) then
			begin
			f:= True;

			Client.Game.VisibleSlot:= s;
			end;

		finally
		Client.Game.Lock.Release;
		end;

	if f then
		begin
		actUpdateGameDetail.Execute;

		if  TabControl4.ActiveTab <> TabControl4.Tabs[TabControl4.TabCount - 1] then
			TabControl4.Next;
		end;
	end;

procedure TClientMainForm.SpeedButton10Click(Sender: TObject);
	var
	b: TSpeedButton;
	r: Integer;
	m: TMessage;
	d: TDieSet;

	begin
	PushDebugMsg(AnsiString('SpeedButton10Click.'));

//	if  WaitKeeper then
//		Exit;
//
//	WaitKeeper:= True;

	b:= Sender as TSpeedButton;

	r:= GridPanelLayout1.ControlCollection.Items[b.Tag].Row;
	r:= (r + 1) mod 2;
//	GridPanelLayout1.ControlCollection.Items[b.Tag].Row:= r;

	Client.Game.Lock.Acquire;
	try
		if  Client.Game.VisibleSlot = Client.Game.OurSlot then
			begin
			d:= Client.Game.Slots[Client.Game.OurSlot].Keepers;

			if  r = 0 then
				Exclude(d, b.Tag + 1)
			else
				Include(d, b.Tag + 1);

			m:= TMessage.Create;
			m.Category:= mcPlay;
			m.Method:= $09;

			SetLength(m.Data, 3);

			m.Data[0]:= Client.Game.OurSlot;
			m.Data[1]:= b.Tag + 1;
			m.Data[2]:= r;

//			MessageLock.Acquire;
//			try
				SendMessages.PushItem(m);

//				finally
//				MessageLock.Release;
//				end;
			end
		finally
		Client.Game.Lock.Release;
		end;
	end;

procedure TClientMainForm.StringGrid1DrawColumnCell(Sender: TObject;
		const Canvas: TCanvas; const Column: TColumn; const Bounds: TRectF;
		const Row: Integer; const Value: TValue; const State: TGridDrawStates);
	var
	r: Word;
	s: string;
	n: TScoreLocation;
	f: Boolean;
	p: Boolean;
	b: TRectF;

	begin
	if  (Column = StringColumn1)
	or  (Column = StringColumn3) then
		begin
		Canvas.Fill.Color:= TAlphaColorRec.MedGray;
		Canvas.Fill.Kind:= TBrushKind.Solid;
		Canvas.FillRect(Bounds, 0, 0, AllCorners, 1, TCornerType.Round);

		Canvas.Fill.Color:= TAlphaColorRec.White;
		Canvas.FillText(Bounds, StringGrid1.Cells[Column.Index, Row], False, 1,
				[], TTextAlign.Leading, TTextAlign.Center);
		end
	else
		begin
		b:= Bounds;

		if  State <> [] then
			Canvas.Fill.Color:= TAlphaColorRec.Lightblue
		else
			Canvas.Fill.Color:= TAlphaColorRec.White;

		Canvas.StrokeThickness:= 1;
		Canvas.Stroke.Thickness:= 1;
		Canvas.Stroke.Kind:= TBrushKind.Solid;
		Canvas.Stroke.Color:= TAlphaColorRec.Lightgray;

		Canvas.Fill.Kind:= TBrushKind.Solid;
		Canvas.FillRect(b, 0, 0, AllCorners, 1, TCornerType.Round);
		Canvas.DrawRect(b, 0, 0, AllCorners, 1, TCornerType.Round);

		b.Inflate(-1, -1);

		Canvas.StrokeThickness:= 0;
		Canvas.Stroke.Thickness:= 0;

		f:= False;
		n:= slAces;

		if  Column = StringColumn2 then
			begin
			if  Row = 9 then
				begin
				n:= slUpperBonus;
				f:= True;
				end
			else if  Row < 6 then
				begin
				n:= TScoreLocation(Row);
				f:= True;
				end;
			end;

		if  Column = StringColumn4 then
			if  Row < 7 then
				begin
				n:= TScoreLocation(Ord(slThreeKind) + Row);
				f:= True
				end
			else if  Row in [8, 9] then
				begin
				n:= slYahtzeeBonus1;
				f:= True;
				end;

		r:= VAL_KND_SCOREINVALID;
		p:= False;

		if  f then
			begin
			Client.Game.Lock.Acquire;
			try
				if  n = slYahtzeeBonus1 then
					begin
					r:= VAL_KND_SCOREINVALID;
					s:= '';

					if  Client.Game.Slots[Client.Game.VisibleSlot].Sheet[n] <>
							VAL_KND_SCOREINVALID then
						begin
						if  Row = 8 then
							s:= 'X '
						else
							r:= Client.Game.Slots[Client.Game.VisibleSlot].Sheet[n];

						if  Client.Game.Slots[Client.Game.VisibleSlot].Sheet[slYahtzeeBonus2] <>
								VAL_KND_SCOREINVALID then
							if  Row = 8 then
								s:= s + 'X '
							else
								r:= r + Client.Game.Slots[Client.Game.VisibleSlot].Sheet[n];

						if  Client.Game.Slots[Client.Game.VisibleSlot].Sheet[slYahtzeeBonus3] <>
								VAL_KND_SCOREINVALID then
							if  Row = 8 then
								s:= s + 'X '
							else
								r:= r + Client.Game.Slots[Client.Game.VisibleSlot].Sheet[n];
						end;

					if  [slYahtzeeBonus1..slYahtzeeBonus3] * Client.Game.PreviewLoc <> [] then
						begin
						p:= True;
						if  r = VAL_KND_SCOREINVALID then
							begin
							r:= 100;
							s:= s + 'X ';
							end
						else
							begin
							Inc(r, 100);
							s:= s + 'X ';
							end;
						end;

					if  Row = 9 then
						if  r = VAL_KND_SCOREINVALID then
							s:= ''
						else
							s:= IntToStr(r);
					end
				else
					begin
					r:= Client.Game.Slots[Client.Game.VisibleSlot].Sheet[n];

					if  Client.Game.VisibleSlot = Client.Game.OurSlot then
						if  n in Client.Game.PreviewLoc then
							begin
							r:= Client.Game.Preview[n];
							p:= True;
							end;
					end;

				finally
				Client.Game.Lock.Release;
				end;
			end;

		if  n <> slYahtzeeBonus1 then
			if  r = VAL_KND_SCOREINVALID then
				s:= ''
			else
				s:= IntToStr(r);

		if  p then
			Canvas.Fill.Color:= TAlphaColorRec.Red
		else
			Canvas.Fill.Color:= TAlphaColorRec.Black;

		Canvas.FillText(b, s, False, 1, [], TTextAlign.Trailing,
				TTextAlign.Center);
		end;
	end;

procedure TClientMainForm.StringGrid1MouseUp(Sender: TObject; Button: TMouseButton;
		Shift: TShiftState; X, Y: Single);
	var
	m: TMessage;

	begin
	PushDebugMsg(AnsiString('StringGrid1MouseUp.'));

	if  Button = TMouseButton.mbLeft then
		begin
		Client.Game.Lock.Acquire;
		try
			if  Client.Game.SelScore then
				begin
				FillChar(Client.Game.Preview, SizeOf(TScoreSheet), $FF);
				Client.Game.PreviewLoc:= [];

				m:= TMessage.Create;
				m.Category:= mcPlay;
				m.Method:= $0A;
				SetLength(m.Data, 2);

				m.Data[0]:= Client.Game.OurSlot;
				m.Data[1]:= Ord(Client.Game.SelScoreLoc);

//				MessageLock.Acquire;
//				try
					SendMessages.PushItem(m);

//					finally
//					MessageLock.Release;
//					end;
				end;

			finally
			Client.Game.Lock.Release;
			end;
		end;
	end;

procedure TClientMainForm.StringGrid1SelectCell(Sender: TObject; const ACol,
		ARow: Integer; var CanSelect: Boolean);
	begin
	PushDebugMsg(AnsiString('StringGrid1SelectCell.'));

	Client.Game.Lock.Acquire;
	try
		if  ACol in [0, 2] then
			CanSelect:= False
		else if ACol = 1 then
			begin
			CanSelect:= ARow < 6;
			if  CanSelect then
				Client.Game.SelScoreLoc:= TScoreLocation(ARow);
			end
		else
			begin
			CanSelect:= ARow < 7;
			if  CanSelect then
				Client.Game.SelScoreLoc:= TScoreLocation(Ord(slThreeKind) + ARow);
			end;

		Client.Game.SelScore:= CanSelect;

		finally
		Client.Game.Lock.Release;
		end;

{$IFDEF ANDROID}
	StringGrid1Tap(Sender, PointF(0, 0));
{$ENDIF}
	end;

procedure TClientMainForm.StringGrid1Tap(Sender: TObject; const Point: TPointF);
	var
	m: TMessage;

	begin
	Client.Game.Lock.Acquire;
	try
		if  Client.Game.SelScore then
			begin
			FillChar(Client.Game.Preview, SizeOf(TScoreSheet), $FF);
			Client.Game.PreviewLoc:= [];

			m:= TMessage.Create;
			m.Category:= mcPlay;
			m.Method:= $0A;
			SetLength(m.Data, 2);

			m.Data[0]:= Client.Game.OurSlot;
			m.Data[1]:= Ord(Client.Game.SelScoreLoc);

//			MessageLock.Acquire;
//			try
				SendMessages.PushItem(m);

//				finally
//				MessageLock.Release;
//				end;
			end;

		finally
		Client.Game.Lock.Release;
		end;
	end;

procedure TClientMainForm.TabControl4Change(Sender: TObject);
	begin
	if  TabControl4.ActiveTab <> TabItem11 then
		begin
		CheckBox1.IsChecked:= False;
		end;
	end;

procedure TClientMainForm.Timer1Timer(Sender: TObject);
	begin
	while DebugMsgs.QueueSize > 0 do
		Memo1.Lines.Add(string(DebugMsgs.PopItem));

	while ClientLog.QueueSize > 0 do
		Memo2.Lines.Add(string(ClientLog.PopItem));

	actUpdateRoomLog.Execute;
	actUpdateGameLog.Execute;

	Client.Game.Lock.Acquire;
	try
		finally
		Client.Game.Lock.Release;
		end;

	Client.Game.Lock.Acquire;
	try
		if  ReadMessages.QueueSize > 0 then
			if  Client.Game.WasConnected then
				Client.ExecuteMessages;
//			else
//				begin
//				PushDebugMsg(AnsiString('Discarding read message queue.'));
//
//				while ReadMessages.QueueSize > 0 do
//					ReadMessages.PopItem.Free;
//				end;
		finally
		Client.Game.Lock.Release;
		end;

	Client.Game.Lock.Acquire;
	try
		if  Client.Game.WasConnected
		and Client.Game.LostConnection then
			begin
			PushDebugMsg(AnsiString('Caught server disconnect.'));

			DoDisconnect;
			end;

		finally
		Client.Game.Lock.Release;
		end;
	end;

procedure TClientMainForm.ToolBar3KeyDown(Sender: TObject; var Key: Word;
		var KeyChar: Char; Shift: TShiftState);
	begin
	if  Key = vkRight then
		begin
		Key:= 0;
		TabControl3.Next;
		end
	else if Key = vkLeft then
		begin
		Key:= 0;
		TabControl3.Previous;
		end;
	end;

procedure TClientMainForm.UpdateGameSlotState(AGameState: TGameState;
		ASlot: Integer);
	var
	l: TListBoxItem;

	begin
	PushDebugMsg(AnsiString('UpdateGameSlotState.'));

	case  ASlot of
		0:
			l:= ListBoxItem1;
		1:
			l:= ListBoxItem2;
		2:
			l:= ListBoxItem3;
		3:
			l:= ListBoxItem4;
		4:
			l:= ListBoxItem5;
		5:
			l:= ListBoxItem6;
		else
			l:= nil;
		end;

	Assert(Assigned(l), 'Failure in Update Game Slot State logic');

	l.ImageIndex:= Ord(Client.Game.Slots[ASlot].State);
	if  Client.Game.Slots[ASlot].State > psNone then
		l.Text:= string(Client.Game.Slots[ASlot].Name)
	else
		l.Text:= '';

	case Client.Game.Slots[ASlot].State of
		psNone:
			if  AGameState >= gsPreparing then
				l.ItemData.Detail:= ''
			else
				l.ItemData.Detail:= 'Available for Player';
		psIdle:
			l.ItemData.Detail:= 'Not Yet Ready';
		psReady:
			l.ItemData.Detail:= 'Waiting for all Players';
		psPreparing:
				l.ItemData.Detail:= 'Waiting for First Roll';
		psWaiting..psWinner:
			if  (Client.Game.Slots[ASlot].State = psWaiting)
			and (Client.Game.Round = 0) then
				l.ItemData.Detail:= 'Rolled:  ' +
						IntToStr(Client.Game.Slots[ASlot].FirstRoll)
			else
				l.ItemData.Detail:= 'Score:  ' + IntToStr(Client.Game.Slots[ASlot].Score);
		else
			l.ItemData.Detail:= '';
		end;
	end;

procedure TClientMainForm.UpdateOurState;
	begin
	PushDebugMsg(AnsiString('UpdateOurState.'));

	if  Client.Game.State > gsPreparing then
		Label15.Text:= IntToSTr(Client.Game.Round)
	else
		Label15.Text:= 'Game Not Started';

	if  (Client.Game.OurSlot = -1)
	or  (Client.Game.Slots[Client.Game.OurSlot].State in [psNone, psWaiting]) then
		begin
		actGameControl.Tag:= 0;
		actGameControl.Text:= 'Waiting';
		end
	else if Client.Game.Slots[Client.Game.OurSlot].State = psIdle then
		begin
		actGameControl.Tag:= 1;
		actGameControl.Text:= 'Ready';
		end
	else if Client.Game.Slots[Client.Game.OurSlot].State = psReady then
		begin
		actGameControl.Tag:= 2;
		actGameControl.Text:= 'Not Ready';
		end
	else if Client.Game.Slots[Client.Game.OurSlot].State = psPreparing then
		begin
		actGameControl.Tag:= 3;
		actGameControl.Text:= 'Roll for First';
		end
	end;

end.

