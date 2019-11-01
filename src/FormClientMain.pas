unit FormClientMain;

{$IFDEF FPC}
	{$MODE DELPHI}
{$ENDIF}
{$H+}


interface

uses
	Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
	ExtCtrls, StdCtrls, Buttons, LMessages, Grids, YahtzeeClient, Types;

type

	{ TClientMainForm }
	TClientMainForm = class(TForm)
		BitBtn1: TBitBtn;
		BitBtn2: TBitBtn;
		BitBtn3: TBitBtn;
		BitBtn4: TBitBtn;
		BitBtn5: TBitBtn;
		Button1: TButton;
		BtnHostCntrl: TButton;
		Button2: TButton;
		Button4: TButton;
		ButtonScore: TButton;
		ButtonRoll: TButton;
		ButtonRoomJoin: TButton;
		Button3: TButton;
		ButtonGameJoin: TButton;
		CheckBox1: TCheckBox;
		DrawGrid1: TDrawGrid;
		DrawGrid2: TDrawGrid;
		EditGame: TEdit;
		EditGamePwd: TEdit;
		EditRoomText: TEdit;
		EditRoomPwd: TEdit;
		EditHost: TEdit;
		EditRoom: TEdit;
		EditGameText: TEdit;
		EditUserName: TEdit;
		EditHostInfo: TEdit;
		Label1: TLabel;
		Label10: TLabel;
		Label11: TLabel;
		Label12: TLabel;
		Label13: TLabel;
		Label14: TLabel;
		Label15: TLabel;
		Label16: TLabel;
		Label17: TLabel;
		Label18: TLabel;
		Label19: TLabel;
		Label2: TLabel;
		Label20: TLabel;
		Label21: TLabel;
		Label23: TLabel;
		Label24: TLabel;
        Label25: TLabel;
        Label26: TLabel;
		LabelYour: TLabel;
		LabelTheir: TLabel;
		Label27: TLabel;
		LabelDetailName: TLabel;
		LabelGameRound: TLabel;
		Label22: TLabel;
		Label3: TLabel;
		Label4: TLabel;
		Label5: TLabel;
		Label6: TLabel;
		Label7: TLabel;
		Label8: TLabel;
		Label9: TLabel;
		LstbxRoomUsers: TListBox;
		MemoRoom: TMemo;
		MemoGame: TMemo;
		MemoRoomList: TMemo;
		MemoDebug: TMemo;
		MemoHost: TMemo;
		MemoGameList: TMemo;
		Panel10: TPanel;
		Panel11: TPanel;
		Panel12: TPanel;
		Panel13: TPanel;
		Panel14: TPanel;
		PanelKeep: TPanel;
		PanelRoll: TPanel;
		Panel4: TPanel;
		Panel5: TPanel;
		Panel6: TPanel;
		Panel7: TPanel;
		Panel8: TPanel;
		Panel9: TPanel;
		PanelRoomUsers: TPanel;
		PgctrlChat: TPageControl;
		PgctrlPlay: TPageControl;
		PgctrlMain: TPageControl;
		PgctrlConnect: TPageControl;
		Panel1: TPanel;
		Panel2: TPanel;
		Panel3: TPanel;
		TbshtDetail: TTabSheet;
		TbshtLobby: TTabSheet;
		TbshtStart: TTabSheet;
		TbshtRoom: TTabSheet;
		TbshtConnect: TTabSheet;
		TbshtChat: TTabSheet;
		TbshtPlay: TTabSheet;
		TbshtConfigure: TTabSheet;
		TbshtHost: TTabSheet;
		TbshtDebug: TTabSheet;
		TbshtOverview: TTabSheet;
		TlbrMain: TToolBar;
		ToolBar2: TToolBar;
		ToolBar3: TToolBar;
		ToolBar4: TToolBar;
		ToolBar5: TToolBar;
		ToolBar6: TToolBar;
		ToolBar7: TToolBar;
		ToolBar8: TToolBar;
		ToolButton1: TToolButton;
		ToolButton10: TToolButton;
		ToolButton11: TToolButton;
		ToolButton12: TToolButton;
		ToolButton13: TToolButton;
		ToolButton2: TToolButton;
		ToolButton3: TToolButton;
		ToolButton4: TToolButton;
		ToolButton5: TToolButton;
		ToolButton6: TToolButton;
		ToolButton7: TToolButton;
		ToolButton9: TToolButton;
		procedure BitBtn1Click(Sender: TObject);
  		procedure DrawGrid1DrawCell(Sender: TObject; aCol, aRow: Integer;
				aRect: TRect; aState: TGridDrawState);
		procedure DrawGrid1SelectCell(Sender: TObject; aCol, aRow: Integer;
			var CanSelect: Boolean);
		procedure DrawGrid2DrawCell(Sender: TObject; aCol, aRow: Integer;
			aRect: TRect; aState: TGridDrawState);
		procedure DrawGrid2MouseUp(Sender: TObject; Button: TMouseButton;
			Shift: TShiftState; X, Y: Integer);
		procedure DrawGrid2SelectCell(Sender: TObject; aCol, aRow: Integer;
			var CanSelect: Boolean);
  		procedure EditRoomTextKeyPress(Sender: TObject; var Key: char);
  		procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
	private

	protected
        procedure MsgUpdateHost(var AMessage: TLMessage); message YCM_UPDATEHOST;
        procedure MsgUpdateIdent(var AMessage: TLMessage); message YCM_UPDATEIDENT;
		procedure MsgUpdateRoomList(var AMessage: TLMessage); message YCM_UPDATEROOMLIST;
		procedure MsgUpdateRoom(var AMessage: TLMessage); message YCM_UPDATEROOM;
		procedure MsgUpdateRoomUsers(var AMessage: TLMessage); message YCM_UPDATEROOMUSERS;
		procedure MsgUpdateSlotState(var AMessage: TLMessage); message YCM_UPDATESLOTSTATE;
		procedure MsgUpdateGameList(var AMessage: TLMessage); message YCM_UPDATEGAMELIST;
		procedure MsgUpdateOurState(var AMessage: TLMessage); message YCM_UPDATEOURSTATE;
		procedure MsgUpdateGame(var AMessage: TLMessage); message YCM_UPDATEGAME;
		procedure MsgUpdateGameDetail(var AMessage: TLMessage); message YCM_UPDATEGAMEDETAIL;
		procedure MsgUpdateGameScores(var AMessage: TLMessage); message YCM_UPDATEGAMESCORES;

	public

	end;

var
	ClientMainForm: TClientMainForm;

implementation

{$R *.lfm}

uses
	LCLIntf, YahtzeeClasses, DModClientMain;


{ TClientMainForm }

procedure TClientMainForm.FormKeyDown(Sender: TObject; var Key: Word;
		Shift: TShiftState);
    var
	lmkey: TLMKey;

	begin
    lmkey.CharCode:= Key;
	lmkey.KeyData:= 0;

	ClientMainDMod.ActlstNavigate.IsShortCut(lmkey);
	end;

procedure TClientMainForm.EditRoomTextKeyPress(Sender: TObject; var Key: char);
	begin
    if  Key = #13 then
		begin
		ClientMainDMod.ActRoomMsg.Execute;
		Key:= #0;
		end;
	end;

procedure TClientMainForm.DrawGrid1DrawCell(Sender: TObject; aCol,
		aRow: Integer; aRect: TRect; aState: TGridDrawState);
    var
	s,
	i: Integer;
	n,
	v: string;

	begin
	if  Assigned(ClientMainDMod.Client.Game) then
		begin
        s:= ARow * 2 + ACol;

    	i:= Ord(ClientMainDMod.Client.Game.Slots[s].State);
    	if  ClientMainDMod.Client.Game.Slots[s].State > psNone then
    		n:= string(ClientMainDMod.Client.Game.Slots[s].Name)
    	else
    		n:= '';

    	case ClientMainDMod.Client.Game.Slots[s].State of
    		psNone:
    			if  ClientMainDMod.Client.Game.State >= gsPreparing then
    				v:= ''
    			else
    				v:= 'Available...';
    		psIdle:
    			v:= 'Not Ready...';
    		psReady:
    			v:= 'Waiting for all Ready';
    		psPreparing:
    			v:= 'Waiting for First Roll';
    		psWaiting..psWinner:
    			if  (ClientMainDMod.Client.Game.Slots[s].State = psWaiting)
    			and (ClientMainDMod.Client.Game.Round = 0) then
    				v:= 'Rolled:  ' +
    						IntToStr(ClientMainDMod.Client.Game.Slots[s].FirstRoll)
    			else
    				v:= 'Score:  ' +
							IntToStr(ClientMainDMod.Client.Game.Slots[s].Score);
    		else
    			v:= '';
    		end;
		end
	else
		begin
    	i:= 0;
        n:= 'No Game!';
		v:= 'Start a game.';
		end;

	DrawGrid1.Canvas.Changing;
	try
    	DrawGrid1.Canvas.Brush.Color:= clWindow;
        DrawGrid1.Canvas.Brush.Style:= bsSolid;
        DrawGrid1.Canvas.FillRect(ARect);

        ClientMainDMod.ImageList2.Draw(DrawGrid1.Canvas, ARect.Left + 8,
				ARect.Top + 2, i, True);

        DrawGrid1.Canvas.Font.Color:= clBlack;
        DrawGrid1.Canvas.TextOut(ARect.Left + 48, ARect.Top + 4, n);

        DrawGrid1.Canvas.Font.Color:= clGray;
        DrawGrid1.Canvas.TextOut(ARect.Left + 48, ARect.Top + 18, v);

		finally
        DrawGrid1.Canvas.Changed;
		end;
	end;

procedure TClientMainForm.BitBtn1Click(Sender: TObject);
    var
	b: TBitBtn;

	begin
    b:= Sender as TBitBtn;

    if  Assigned(ClientMainDMod.Client.Game)
	and (ClientMainDMod.Client.Game.VisibleSlot =
			ClientMainDMod.Client.Game.OurSlot) then
    	ClientMainDMod.Client.SendGameKeeper(ClientMainDMod.Connection,
				ClientMainDMod.Client.Game.OurSlot, b.Tag,
				b.Parent = PanelRoll);
	end;

procedure TClientMainForm.DrawGrid1SelectCell(Sender: TObject; aCol,
		aRow: Integer; var CanSelect: Boolean);
    var
	s: Integer;
    f: Boolean;

	begin
    CanSelect:= False;

	AddLogMessage(slkDebug, 'DrawGrid1SelectCell.');

	f:= False;
	s:= ARow * 2 + ACol;

	if  Assigned(ClientMainDMod)
	and Assigned(ClientMainDMod.Client.Game) then
		begin
		if  (ClientMainDMod.Client.Game.State > gsPreparing)
		and (ClientMainDMod.Client.Game.Slots[s].State > psPreparing) then
			begin
			f:= True;
 			ClientMainDMod.Client.Game.VisibleSlot:= s;
			end;
		end;

	if f then
		begin
		PgctrlPlay.ActivePage:= TbshtDetail;
		SendMessage(Handle, YCM_UPDATEGAMEDETAIL, 0, 0);
		end;
	end;

procedure TClientMainForm.DrawGrid2DrawCell(Sender: TObject; aCol,
		aRow: Integer; aRect: TRect; aState: TGridDrawState);
    var
	sl: Integer;
    b: TRect;
	r: Word;
	s: string;
	n: TScoreLocation;
	f: Boolean;
	p: Boolean;

	begin
	if  ACol in [0, 2] then
		begin
        sl:= ARow + (10 * ACol div 2);

		if  sl in [0..5] then
			s:= ARR_LIT_NAME_SCORELOC[TScoreLocation(sl)] + ':'
		else if sl = 9 then
			s:= ARR_LIT_NAME_SCORELOC[slUpperBonus] + ':'
		else if sl in [10..16] then
			s:= ARR_LIT_NAME_SCORELOC[TScoreLocation(sl - 10 + Ord(slThreeKind))] + ':'
		else if sl = 18 then
			s:= ARR_LIT_NAME_SCORELOC[slYahtzeeBonus1] + ':'
		else if sl = 19 then
			s:= 'Lower Bonus:'
		else
			s:= '';

		DrawGrid2.Canvas.Brush.Color:= clBtnFace;
		DrawGrid2.Canvas.Brush.Style:= bsSolid;
		DrawGrid2.Canvas.FillRect(ARect);

		DrawGrid2.Canvas.Font.Color:= clWindowText;
        DrawGrid2.Canvas.Font.Style:= [];
		DrawGrid2.Canvas.TextOut(ARect.Left + 8, ARect.Top + 4, s);
		end
	else
		begin
		b:= ARect;

		if  (AState <> [])
		and (ClientMainDMod.Client.Game.VisibleSlot =
				ClientMainDMod.Client.Game.OurSlot)
		and  ClientMainDMod.Client.Game.SelScore then
			begin
			DrawGrid2.Canvas.Brush.Color:= clSkyBlue;
            DrawGrid2.Canvas.Pen.Color:= clWindowText;
            DrawGrid2.Canvas.Pen.Style:= psDash;
			end
		else
			begin
			DrawGrid2.Canvas.Brush.Color:= clWhite;
            DrawGrid2.Canvas.Pen.Color:= clNone;
            DrawGrid2.Canvas.Pen.Style:= psClear;
			end;

		DrawGrid2.Canvas.Brush.Style:= bsSolid;
		DrawGrid2.Canvas.FillRect(b);

		if  (AState <> [])
		and (ClientMainDMod.Client.Game.VisibleSlot =
				ClientMainDMod.Client.Game.OurSlot)
		and  ClientMainDMod.Client.Game.SelScore then
			DrawGrid2.Canvas.DrawFocusRect(b);

		f:= False;
		n:= slAces;

		if  ACol = 1 then
			begin
			if  ARow = 9 then
				begin
				n:= slUpperBonus;
				f:= True;
				end
			else if  ARow < 6 then
				begin
				n:= TScoreLocation(ARow);
				f:= True;
				end;
			end;

		if  ACol = 3 then
			if  ARow < 7 then
				begin
				n:= TScoreLocation(Ord(slThreeKind) + ARow);
				f:= True
				end
			else if  ARow in [8, 9] then
				begin
				n:= slYahtzeeBonus1;
				f:= True;
				end;

		r:= VAL_KND_SCOREINVALID;
		p:= False;

		if  f then
			begin
			if  Assigned(ClientMainDMod)
			and Assigned(ClientMainDMod.Client.Game)
			and (ClientMainDMod.Client.Game.VisibleSlot > -1) then
				begin
				if  n = slYahtzeeBonus1 then
					begin
					r:= VAL_KND_SCOREINVALID;
					s:= '';

					if  ClientMainDMod.Client.Game.Slots[
							ClientMainDMod.Client.Game.VisibleSlot].Sheet[n] <>
							VAL_KND_SCOREINVALID then
						begin
						if  ARow = 8 then
							s:= 'X '
						else
							r:= ClientMainDMod.Client.Game.Slots[
									ClientMainDMod.Client.Game.VisibleSlot].Sheet[n];

						if  ClientMainDMod.Client.Game.Slots[
								ClientMainDMod.Client.Game.VisibleSlot].Sheet[slYahtzeeBonus2] <>
								VAL_KND_SCOREINVALID then
							if  ARow = 8 then
								s:= s + 'X '
							else
								r:= r +
										ClientMainDMod.Client.Game.Slots[
										ClientMainDMod.Client.Game.VisibleSlot].Sheet[n];

						if  ClientMainDMod.Client.Game.Slots[
								ClientMainDMod.Client.Game.VisibleSlot].Sheet[slYahtzeeBonus3] <>
								VAL_KND_SCOREINVALID then
							if  ARow = 8 then
								s:= s + 'X '
							else
								r:= r + ClientMainDMod.Client.Game.Slots[
										ClientMainDMod.Client.Game.VisibleSlot].Sheet[n];
						end;

					if  [slYahtzeeBonus1..slYahtzeeBonus3] *
							ClientMainDMod.Client.Game.PreviewLoc <> [] then
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

					if  ARow = 9 then
						if  r = VAL_KND_SCOREINVALID then
							s:= ''
						else
							s:= IntToStr(r);
					end
				else
					begin
					r:= ClientMainDMod.Client.Game.Slots[
							ClientMainDMod.Client.Game.VisibleSlot].Sheet[n];

					if  ClientMainDMod.Client.Game.VisibleSlot =
							ClientMainDMod.Client.Game.OurSlot then
						if  n in ClientMainDMod.Client.Game.PreviewLoc then
							begin
							r:= ClientMainDMod.Client.Game.Preview[n];
							p:= True;
							end;
					end;
				end;
			end;

		if  n <> slYahtzeeBonus1 then
			if  r = VAL_KND_SCOREINVALID then
				s:= ''
			else
				s:= IntToStr(r);

		if  p then
			begin
			DrawGrid2.Canvas.Font.Color:= clRed;
            DrawGrid2.Canvas.Font.Style:= [fsBold];
			end
		else
			begin
			DrawGrid2.Canvas.Font.Color:= clWindowText;
            DrawGrid2.Canvas.Font.Style:= [];
			end;

		DrawGrid2.Canvas.TextOut(b.Left + 8, b.Top + 4, s);
		end;
	end;

procedure TClientMainForm.DrawGrid2MouseUp(Sender: TObject;
		Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
	begin
	AddLogMessage(slkDebug, 'DrawGrid2MouseUp.');

	if  Button = mbLeft then
		begin
		if  Assigned(ClientMainDMod.Client.Game)
		and (ClientMainDMod.Client.Game.VisibleSlot =
				ClientMainDMod.Client.Game.OurSlot) then
			begin
			if  ClientMainDMod.Client.Game.SelScore then
				begin
				FillChar(ClientMainDMod.Client.Game.Preview,
						SizeOf(TScoreSheet), $FF);
				ClientMainDMod.Client.Game.PreviewLoc:= [];

				ClientMainDMod.Client.SendGameScorePreview(
						ClientMainDMod.Connection,
						ClientMainDMod.Client.Game.OurSlot,
						ClientMainDMod.Client.Game.SelScoreLoc);
				end;
			end;
		end;
	end;

procedure TClientMainForm.DrawGrid2SelectCell(Sender: TObject; aCol,
		aRow: Integer; var CanSelect: Boolean);
	begin
	AddLogMessage(slkDebug, 'DrawGrid2SelectCell.');

	if  Assigned(ClientMainDMod)
	and Assigned(ClientMainDMod.Client.Game)
	and (ClientMainDMod.Client.Game.VisibleSlot =
			ClientMainDMod.Client.Game.OurSlot) then
		begin
		if  ACol in [0, 2] then
			CanSelect:= False
		else if ACol = 1 then
			begin
			CanSelect:= ARow < 6;
			if  CanSelect then
				ClientMainDMod.Client.Game.SelScoreLoc:= TScoreLocation(ARow);
			end
		else
			begin
			CanSelect:= ARow < 7;
			if  CanSelect then
				ClientMainDMod.Client.Game.SelScoreLoc:=
						TScoreLocation(Ord(slThreeKind) + ARow);
			end;

		ClientMainDMod.Client.Game.SelScore:= CanSelect;
		end;
	end;

procedure TClientMainForm.MsgUpdateHost(var AMessage: TLMessage);
	begin
	if  Assigned(ClientMainDMod.Client.Server) then
		EditHostInfo.Text:= ClientMainDMod.Client.Server.Name + ' ' +
				ClientMainDMod.Client.Server.Host + ' ' +
				ClientMainDMod.Client.Server.Version
	else
		EditHostInfo.Text:= '';
	end;

procedure TClientMainForm.MsgUpdateIdent(var AMessage: TLMessage);
	begin
    EditUserName.Text:= ClientMainDMod.Client.OurIdent;
	end;

procedure TClientMainForm.MsgUpdateRoomList(var AMessage: TLMessage);
	begin
    if  AMessage.lParam = 0 then
		MemoRoomList.Clear
	else
		MemoRoomList.Lines.Add(PString(AMessage.WParam)^);
	end;

procedure TClientMainForm.MsgUpdateRoom(var AMessage: TLMessage);
	begin
    if  AMessage.lParam = 0 then
		begin
        EditRoom.Enabled:= True;
		EditRoomPwd.Enabled:= True;
		ButtonRoomJoin.Action:= ClientMainDMod.ActRoomJoin;

		LstbxRoomUsers.Clear;
		end
	else
		begin
        EditRoom.Text:= ClientMainDMod.Client.Room;

        EditRoom.Enabled:= False;
		EditRoomPwd.Enabled:= False;
		ButtonRoomJoin.Action:= ClientMainDMod.ActRoomPart;
		end;
	end;

procedure TClientMainForm.MsgUpdateRoomUsers(var AMessage: TLMessage);
    var
	i: Integer;
	s: string;

	begin
    if  AMessage.lParam = 0 then
		LstbxRoomUsers.Clear
	else if AMessage.lParam = 1 then
		begin
        s:= PString(AMessage.wParam)^;
		i:= LstbxRoomUsers.Items.IndexOf(s);
		if  i = -1 then
        	LstbxRoomUsers.Items.Add(s);
		end
	else
		begin
        s:= PString(AMessage.wParam)^;
		i:= LstbxRoomUsers.Items.IndexOf(s);
		if  i > -1 then
        	LstbxRoomUsers.Items.Delete(i);
		end;
	end;

procedure TClientMainForm.MsgUpdateSlotState(var AMessage: TLMessage);
	begin
    ClientMainDMod.Client.Game.SelScore:= False;

    DrawGrid1.Invalidate;

	DrawGrid2.ClearSelections;
	DrawGrid2.Invalidate;
	end;

procedure TClientMainForm.MsgUpdateGameList(var AMessage: TLMessage);
	begin
    if  AMessage.lParam = 0 then
		MemoGameList.Clear
	else
		MemoGameList.Lines.Add(PString(AMessage.WParam)^);
	end;

procedure TClientMainForm.MsgUpdateOurState(var AMessage: TLMessage);
	begin
	AddLogMessage(slkDebug, 'UpdateOurState.');

    if  Assigned(ClientMainDMod.Client.Game) then
		begin
		if  ClientMainDMod.Client.Game.State > gsPreparing then
			LabelGameRound.Caption:= IntToSTr(ClientMainDMod.Client.Game.Round)
		else if ClientMainDMod.Client.Game.State = gsWaiting then
			LabelGameRound.Caption:= 'Waiting for all Ready...'
		else
  			LabelGameRound.Caption:= 'Waiting for all Roll First...';

        if  ClientMainDMod.Client.Game.State = gsPlaying then
			begin
			ClientMainDMod.ActGameControl.Tag:= 4;
			ClientMainDMod.ActGameControl.Caption:= 'Playing';
			end
		else if  (ClientMainDMod.Client.Game.OurSlot = -1)
		or  (ClientMainDMod.Client.Game.Slots[
				ClientMainDMod.Client.Game.OurSlot].State in [psNone, psWaiting]) then
			begin
			ClientMainDMod.ActGameControl.Tag:= 0;
			ClientMainDMod.ActGameControl.Caption:= 'Waiting';
			end
		else if ClientMainDMod.Client.Game.Slots[
				ClientMainDMod.Client.Game.OurSlot].State = psIdle then
			begin
			ClientMainDMod.ActGameControl.Tag:= 1;
			ClientMainDMod.ActGameControl.Caption:= 'Ready';
			end
		else if ClientMainDMod.Client.Game.Slots[
				ClientMainDMod.Client.Game.OurSlot].State = psReady then
			begin
			ClientMainDMod.ActGameControl.Tag:= 2;
			ClientMainDMod.ActGameControl.Caption:= 'Not Ready';
			end
		else if ClientMainDMod.Client.Game.Slots[
				ClientMainDMod.Client.Game.OurSlot].State = psPreparing then
			begin
			ClientMainDMod.ActGameControl.Tag:= 3;
			ClientMainDMod.ActGameControl.Caption:= 'Roll for First';
			end
		end
	else
		begin
//TODO
        end;
	end;

procedure TClientMainForm.MsgUpdateGame(var AMessage: TLMessage);
	begin
    if  AMessage.lParam = 0 then
		begin
        EditGame.Enabled:= True;
		EditGamePwd.Enabled:= True;
		ButtonGameJoin.Action:= ClientMainDMod.ActGameJoin;

		if  PgctrlPlay.ActivePage = TbshtDetail then
			PgctrlPlay.ActivePage:= TbshtOverview;
		end
	else
		begin
        EditGame.Text:= ClientMainDMod.Client.Game.Ident;

        EditGame.Enabled:= False;
		EditGamePwd.Enabled:= False;
		ButtonGameJoin.Action:= ClientMainDMod.ActGamePart;
		end;
	end;

procedure TClientMainForm.MsgUpdateGameDetail(var AMessage: TLMessage);
    var
	s: Integer;

	begin
    AddLogMessage(slkDebug, 'MsgUpdateGameDetail.');

	if  ClientMainDMod.ActGameRoll.Enabled then
		ClientMainDMod.ActGameRoll.Enabled:= False;

    if  Assigned(ClientMainDMod.Client.Game)
	and (ClientMainDMod.Client.Game.VisibleSlot > -1)
	and (PgctrlPlay.ActivePage = TbshtDetail) then
		begin
		s:= ClientMainDMod.Client.Game.VisibleSlot;

		if  (ClientMainDMod.Client.Game.RollNo = -1)
		or  (ClientMainDMod.Client.Game.RollNo >= 3) then
			ClientMainDMod.ActGameRoll.Caption:= 'Can''t Roll'
        else
			begin
			ClientMainDMod.ActGameRoll.Caption:= 'Roll ' +
					IntToStr(ClientMainDMod.Client.Game.RollNo + 1) + ' / 3';
            ClientMainDMod.ActGameRoll.Enabled:=
					ClientMainDMod.Client.Game.VisibleSlot = ClientMainDMod.Client.Game.OurSlot;
			end;

        ClientMainForm.BitBtn1.Enabled:= ClientMainDMod.ActGameRoll.Enabled;
        ClientMainForm.BitBtn2.Enabled:= ClientMainDMod.ActGameRoll.Enabled;
        ClientMainForm.BitBtn3.Enabled:= ClientMainDMod.ActGameRoll.Enabled;
        ClientMainForm.BitBtn4.Enabled:= ClientMainDMod.ActGameRoll.Enabled;
        ClientMainForm.BitBtn5.Enabled:= ClientMainDMod.ActGameRoll.Enabled;

		LabelDetailName.Caption:= ClientMainDMod.Client.Game.Slots[s].Name;

		ClientMainDMod.ImageList3.GetBitmap(
				ClientMainDMod.Client.Game.Slots[s].Dice[0], BitBtn1.Glyph);
		ClientMainDMod.ImageList3.GetBitmap(
				ClientMainDMod.Client.Game.Slots[s].Dice[1], BitBtn2.Glyph);
		ClientMainDMod.ImageList3.GetBitmap(
				ClientMainDMod.Client.Game.Slots[s].Dice[2], BitBtn3.Glyph);
		ClientMainDMod.ImageList3.GetBitmap(
				ClientMainDMod.Client.Game.Slots[s].Dice[3], BitBtn4.Glyph);
		ClientMainDMod.ImageList3.GetBitmap(
				ClientMainDMod.Client.Game.Slots[s].Dice[4], BitBtn5.Glyph);

		if  1 in ClientMainDMod.Client.Game.Slots[s].Keepers then
			BitBtn1.Parent:= PanelKeep
		else
			BitBtn1.Parent:= PanelRoll;
		if  2 in ClientMainDMod.Client.Game.Slots[s].Keepers then
			BitBtn2.Parent:= PanelKeep
		else
			BitBtn2.Parent:= PanelRoll;
		if  3 in ClientMainDMod.Client.Game.Slots[s].Keepers then
			BitBtn3.Parent:= PanelKeep
		else
			BitBtn3.Parent:= PanelRoll;
		if  4 in ClientMainDMod.Client.Game.Slots[s].Keepers then
			BitBtn4.Parent:= PanelKeep
		else
			BitBtn4.Parent:= PanelRoll;
		if  5 in ClientMainDMod.Client.Game.Slots[s].Keepers then
			BitBtn5.Parent:= PanelKeep
		else
			BitBtn5.Parent:= PanelRoll;

        if  s <> ClientMainDMod.Client.Game.OurSlot then
			LabelTheir.Caption:= IntToStr(ClientMainDMod.Client.Game.Slots[s].Score)
		else
			LabelTheir.Caption:= '';

        LabelYour.Caption:= IntToStr(ClientMainDMod.Client.Game.Slots[
				ClientMainDMod.Client.Game.OurSlot].Score);
		end
	else
		ClientMainDMod.ActGameRoll.Caption:= 'No Game!';

	end;

procedure TClientMainForm.MsgUpdateGameScores(var AMessage: TLMessage);
	begin
    ClientMainDMod.ActGameScore.Enabled:=  Assigned(ClientMainDMod.Client.Game) and
            (ClientMainDMod.Client.Game.VisibleSlot = ClientMainDMod.Client.Game.OurSlot) and
//			(ClientMainDMod.Client.Game.RollNo > 0) and
			ClientMainDMod.Client.Game.SelScore;

	if  PgctrlPlay.ActivePage = TbshtDetail then
    	DrawGrid2.Invalidate;
	end;

end.

