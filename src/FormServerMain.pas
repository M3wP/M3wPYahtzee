unit FormServerMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.TabControl, FMX.StdCtrls, FMX.Controls.Presentation,
  FMX.Gestures, System.Actions, FMX.ActnList, IdContext, IdBaseComponent,
  IdComponent, IdCustomTCPServer, IdTCPServer, FMX.ScrollBox, FMX.Memo;

type
  TServerMainForm = class(TForm)
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
    ToolBar3: TToolBar;
    lblTitle3: TLabel;
    TabItem3: TTabItem;
    ToolBar4: TToolBar;
    lblTitle4: TLabel;
	TabItem4: TTabItem;
    ToolBar5: TToolBar;
    lblTitle5: TLabel;
    GestureManager1: TGestureManager;
    ActionList1: TActionList;
    NextTabAction1: TNextTabAction;
    PreviousTabAction1: TPreviousTabAction;
	IdTCPServer1: TIdTCPServer;
	Timer1: TTimer;
	Memo1: TMemo;
	procedure GestureDone(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean);
	procedure FormCreate(Sender: TObject);
	procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
	procedure IdTCPServer1Connect(AContext: TIdContext);
	procedure IdTCPServer1Disconnect(AContext: TIdContext);
	procedure IdTCPServer1Execute(AContext: TIdContext);
	procedure Timer1Timer(Sender: TObject);
  private
	{ Private declarations }
  public
	{ Public declarations }
  end;

var
  ServerMainForm: TServerMainForm;

implementation

{$R *.fmx}

uses
	IdGlobal, IdIOHandler, YahtzeeClasses, YahtzeeServer;


procedure TServerMainForm.FormCreate(Sender: TObject);
begin
  { This defines the default active tab at runtime }
  TabControl1.ActiveTab := TabItem1;
end;

procedure TServerMainForm.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkHardwareBack then
  begin
	if (TabControl1.ActiveTab = TabItem1) and (TabControl2.ActiveTab = TabItem6) then
	begin
	  TabControl2.Previous;
	  Key := 0;
	end;
  end;
end;

procedure TServerMainForm.GestureDone(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean);
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

procedure TServerMainForm.IdTCPServer1Connect(AContext: TIdContext);
	var
	p: TPlayer;
	m: TMessage;

	begin
	DebugMsgs.PushItem('Client connected.');

	p:= TPlayer.Create(AContext.Connection);
	SystemZone.Add(p);

	m:= TMessage.Create;
	m.Category:= mcServer;
	m.Method:= $01;
	m.Params.Add(LIT_SYS_VERNAME);
	m.Params.Add(LIT_SYS_PLATFRM);
	m.Params.Add(LIT_SYS_VERSION);

	m.DataFromParams;

	p.Messages.PushItem(m);
	end;

procedure TServerMainForm.IdTCPServer1Disconnect(AContext: TIdContext);
	var
	p: TPlayer;

	begin
	p:= SystemZone.PlayerByConnection(AContext.Connection);
	SystemZone.Remove(p);

	p.Free;

	DebugMsgs.PushItem('Client disconnected.');
	end;

procedure TServerMainForm.IdTCPServer1Execute(AContext: TIdContext);
	var
	p: TPlayer;
	m: TMessage;
	buffer: TIdBytes;
	io: TIdIOHandler;
	s: TConnectMessage;
	i: Integer;

	begin
	io:= AContext.Connection.IOHandler;

	p:= SystemZone.PlayerByConnection(AContext.Connection);

	while p.Messages.QueueSize > 0 do
		begin
		m:= p.Messages.PopItem;
		m.Encode(buffer);
		m.Free;

		io.Write(buffer);

		DebugMsgs.PushItem('Sent client message.');
		end;


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

		ServerMsgs.PushItem(s);

		DebugMsgs.PushItem('Received client message.');
		end;
	end;

procedure TServerMainForm.Timer1Timer(Sender: TObject);
	var
	f: Boolean;
	z: TZone;
	i: Integer;

	begin
	f:= DebugMsgs.QueueSize > 0;

//	Update debug message display to offload queue (could potentially block ourselves
//      if any more are added here, queue does not grow - has maximum).
	while DebugMsgs.QueueSize > 0 do
		Memo1.Lines.Add(string(DebugMsgs.PopItem));

	if  f then
		Memo1.ScrollBy(0, MaxInt);

//	DebugMsgs.PushItem('- Heart beat.');

	while ExpireZones.QueueSize > 0 do
		begin
		z:= ExpireZones.PopItem;
		if  z.PlayerCount = 0 then
			z.Free;
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

	SystemZone.PlayersKeepAliveDecrement(Timer1.Interval);
	SystemZone.PlayersKeepAliveExpire;

	LimboZone.BumpCounter;
	LimboZone.ExpirePlayers;
	end;

end.

