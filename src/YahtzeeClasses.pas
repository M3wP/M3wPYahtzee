unit YahtzeeClasses;

{$IFDEF FPC}
	{$MODE DELPHI}
{$ENDIF}


interface

uses
{$IFDEF ANDROID}
	ORawByteString,
{$ENDIF}
	Generics.Collections, Classes, IdGlobal;

type
	TMsgCategory = (mcSystem, mcText, mcLobby, mcConnect, mcClient, mcServer, mcPlay);

	TMsgData = array of Byte;

	TMessage = class(TObject)
	public
		Category: TMsgCategory;
		Method: Byte;
		Data: TMsgData;
		Params: TList<AnsiString>;

{$IFDEF ANDROID}
//		DataText: string;
{$ENDIF}

		constructor Create;
		destructor  Destroy; override;

		procedure ExtractParams; virtual;
		procedure DataFromParams;

		function  DataToString: AnsiString;

		procedure Encode(var AComsData: TIdBytes); virtual;
		procedure Decode(AComsData: TIdBytes); virtual;

		procedure Assign(AMessage: TMessage);
	end;

{$IFNDEF FPC}
	TMessages = TThreadedQueue<TMessage>;
	TLogMessages = TThreadedQueue<AnsiString>;
{$ELSE}
	TMessages = TThreadList<TMessage>;
	TLogMessages = TThreadList<AnsiString>;
{$ENDIF}

	TNamedHost = class(TObject)
	public
		Name: AnsiString;
		Host: AnsiString;
		Version: AnsiString;
	end;

	TGameState = (gsWaiting, gsPreparing, gsPlaying, gsPaused, gsFinished);
	TPlayerState = (psNone, psIdle, psReady, psPreparing, psWaiting, psPlaying,
			psFinished, psWinner);

	TDie = 0..6;
	TDice = array[0..4] of TDie;
	TDieSet = set of 1..5;

	TScoreLocation = (slAces, slTwos, slThrees, slFours, slFives, slSixes,
			slUpperBonus, slThreeKind, slFourKind, slFullHouse, slSmlStraight,
			slLrgStraight, slYahtzee, slChance, slYahtzeeBonus1, slYahtzeeBonus2,
			slYahtzeeBonus3);
	TScoreLocations = set of TScoreLocation;

	TScoreSheet = array[TScoreLocation] of Word;

	function  DieSetToByte(ADieSet: TDieSet): Byte;
	function  ByteToDieSet(AByte: Byte): TDieSet;

	function  MakeScoreForLocation(ALocation: TScoreLocation; ADice: TDice;
			var AUsed: TDieSet): Word;

	function  IsYahtzee(ADice: TDice): Boolean;
	function  IsYahtzeeBonus(ASheet: TScoreSheet; var ALocation: TScoreLocation): Boolean;
	function  YahtzeeBonusStealLocs(ASheet: TScoreSheet; ADice: TDice): TScoreLocations;
	function  YahtzeeBonusStealScore(ALocation: TScoreLocation; ADice: TDice): Word;

const
	VAL_KND_SCOREINVALID = High(Word);

	ARR_LIT_NAM_CATEGORY: array[TMsgCategory] of string = (
			'system', 'text', 'lobby', 'connect', 'client', 'server', 'play');

	VAL_SET_DICEALL: TDieSet = [1..5];

	VAL_SET_SCOREUPPER: TScoreLocations = [slAces..slSixes];
	VAL_SET_SCORELOWER: TScoreLocations = [slThreeKind..High(TScoreLocation)];

	ARR_LIT_NAME_SCORELOC: array[TScoreLocation] of string = (
			'Aces (1''s)', 'Twos (2''s)', 'Threes (3''s)', 'Fours (4''s)',
			'Fives (5''s)', 'Sixes (6''s)', 'Upper Bonus', '3 of a Kind',
			'4 of a Kind', 'Full House', 'SM Straight', 'LG Straight', 'YAHTZEE',
			'Chance', 'YAHTZEE Bonus', 'YAHTZEE Bonus', 'YAHTZEE Bonus');


//  I think that 2 should be 5 but this is using RFC messages as a template.

//		0	-	System
//		00	- 	Hang up
//		0E	-	Invalid category
//		0F	-	Invalid empty
//
//		1	-	Text
//		10	-	Information
//		11	-	Begin
//		12	-	More
//		13	-	Data
//		14	-	Peer
//
//		2	-	Lobby
//		20 	- 	Error
//		21	-	Join
//		22	-	Part
//		23	-	List
//		24	-	Peer
//
//		3	-	Connection
//		30	-	Error
//		31	-	Identify
//
//		4	-	Client
//		40	-	Error
//		41	-	Identify
//
//		5	-	Server
//		50	-	Error
//		51	-	Identify
//
//		6	-	Play
//		60 	- 	Error
//		61	-	Join
//		62	-	Part
//		63	-	List
//		64	-	TextPeer
//		65	-	KickPeer
//		66	-	StatusGame
//		67	-	StatusPeer
//		68	-	RollPeer
//		69	-	KeepersPeer
//		6A	-	ScoreQuery
//		6B	-	ScorePeer

var
	DebugMsgs: TLogMessages;


implementation

{$IFDEF ANDROID}
//uses
//	SysUtils;
{$ENDIF}

function  DieSetToByte(ADieSet: TDieSet): Byte;
	var
	i: TDie;
	b: Byte;

	begin
	Result:= 0;
	b:= $01;

	for i:= 1 to 5 do
		begin
		if  i in ADieSet then
			Result:= Result or b;
		b:= b shl 1;
		end;
	end;

function  ByteToDieSet(AByte: Byte): TDieSet;
	var
	i: TDie;
	b: Byte;

	begin
	Result:= [];
	b:= $01;

	for i:= 1 to 5 do
		begin
		if  (b and AByte) <> 0 then
			Include(Result, i);
		b:= b shl 1;
		end;

	end;


function TallyDieScoreFor(ADie: Integer; ADice: TDice; var AUsed: TDieSet): Word;
	var
	i: Integer;

	begin
	Result:= 0;

	for i:= 0 to 4 do
		if  ADice[i] = ADie then
			begin
			Include(AUsed, i + 1);
			Inc(Result, ADie);
			end;
	end;

function TallyAllDieScore(ADice: TDice): Word;
	var
	i: Integer;

	begin
	Result:= 0;

	for i:= 0 to 4 do
		Inc(Result, ADice[i]);
	end;

function  MakeScoreForLocation(ALocation: TScoreLocation; ADice: TDice;
		var AUsed: TDieSet): Word;

	function HaveCountDie(ACount: Integer; ADice: TDice; var AUsed: TDieSet): Boolean;
		var
		i,
		j: Integer;
		d,
		c: Integer;
		u: TDieSet;

		begin
		Result:= False;

		for i:= 0 to 4 do
			if  not ((i + 1) in AUsed) then
				begin
				d:= ADice[i];
				u:= AUsed;
				c:= 0;

				for j:= 0 to 4 do
					if  not ((j + 1) in u) then
						if d = ADice[j] then
							begin
							Inc(c);
							Include(u, j + 1);
							if  c = ACount then
								Break;
							end;

				if  c = ACount then
					begin
					Result:= True;
					AUsed:= u;
					Break;
					end;
				end;
		end;

	function TallyDieScoreKind(ACount: Integer; ADice: TDice; var AUsed: TDieSet): Word;
		var
		i: Integer;
		f: Boolean;

		begin
		Result:= 0;

		if  ACount > 0 then
			begin
			f:= False;
			for i:= 0 to 4 do
				if  HaveCountDie(ACount, ADice, AUsed) then
					begin
					f:= True;
					Break;
					end;
			end
		else
			f:= True;

		if  f then
			Result:= TallyAllDieScore(ADice);
		end;

	function FindFullHouse(ADice: TDice; var AUsed: TDieSet): Word;
		begin
		Result:= 0;

		if  HaveCountDie(3, ADice, AUsed)
		and HaveCountDie(2, ADice, AUsed) then
			Result:= 25;
		end;

	function HaveSequence(AStart, ASize: Integer; ADice: TDice; var AUsed: TDieSet): Boolean;
		var
		u: TDieSet;
		c: Integer;
		i,
		j: Integer;
		d: Integer;
		f: Boolean;

		begin
		Result:= False;

		for i:= 0 to 4 do
			begin
			d:= AStart;
			u:= AUsed;
			c:= 0;

			if  not ((i + 1) in AUsed) then
				if  ADice[i] = d then
					begin
					f:= True;
					Inc(c);
					Include(u, i + 1);
					Dec(d);

					while f do
						begin
						f:= False;

						for j:= 0 to 4 do
							if  (not ((j + 1) in AUsed))
							and (ADice[j] = d) then
								begin
								Inc(c);
								f:= c < ASize;
								Dec(d);
								Include(u, j + 1);
								Break;
								end;

						end;

					if  c = ASize then
						begin
						Result:= True;
						AUsed:= u;
						Break;
						end;
					end;
			end;
		end;

	function FindStraight(ASize: Integer; ADice: TDice; var AUsed: TDieSet): Word;
		var
		i: Integer;
		n: Integer;

		begin
		Result:= 0;

		n:= 6 - (6 - ASize);

		for i:= 6 downto n do
			if  HaveSequence(i, ASize, ADice, AUsed) then
				begin
				if  ASize = 5 then
					Result:= 40
				else
					Result:= 30;
				Break;
				end;
		end;

	begin
//	Result:= 0;
	AUsed:= [];

	if  ALocation in VAL_SET_SCOREUPPER then
		Result:= TallyDieScoreFor(Ord(ALocation) + 1, ADice, AUsed)
	else
		case ALocation of
			slThreeKind:
				Result:= TallyDieScoreKind(3, ADice, AUsed);
			slFourKind:
				Result:= TallyDieScoreKind(4, ADice, AUsed);
			slFullHouse:
				Result:= FindFullHouse(ADice, AUsed);
			slSmlStraight:
				Result:= FindStraight(4, ADice, AUsed);
			slLrgStraight:
				Result:= FindStraight(5, ADice, AUsed);
			slYahtzee:
				if  HaveCountDie(5, ADice, AUsed) then
					Result:= 50
				else
					Result:= 0;
			slChance:
				begin
				Result:= TallyAllDieScore(ADice);
				AUsed:= VAL_SET_DICEALL;
				end;
			slYahtzeeBonus1..slYahtzeeBonus3:
				if  HaveCountDie(5, ADice, AUsed) then
					Result:= 100
				else
					Result:= 0;
			else
				Result:= VAL_KND_SCOREINVALID;
			end;
	end;

function  IsYahtzee(ADice: TDice): Boolean;
	var
	i: Integer;
	d: Integer;

	begin
	Result:= True;

	d:= ADice[0];
	for i:= 1 to 4 do
		if  ADice[i] <> d then
			begin
			Result:= False;
			Break;
			end;
	end;

function  IsYahtzeeBonus(ASheet: TScoreSheet; var ALocation: TScoreLocation): Boolean;
	var
	i: TScoreLocation;

	begin
	Result:= False;

	if  ASheet[slYahtzee] <> VAL_KND_SCOREINVALID then
		begin
		Result:= True;

		for i:= slYahtzeeBonus1 to slYahtzeeBonus3 do
			if  ASheet[i] = VAL_KND_SCOREINVALID then
				begin
				ALocation:= i;
				Break;
				end;
		end;
	end;

function  YahtzeeBonusStealLocs(ASheet: TScoreSheet; ADice: TDice): TScoreLocations;
	var
	i: TScoreLocation;

	begin
	Result:= [];

	if  ASheet[TScoreLocation(ADice[0] - 1)] = VAL_KND_SCOREINVALID then
		Result:= [TScoreLocation(ADice[0] - 1)]
	else
		begin
		if  ASheet[slThreeKind] = VAL_KND_SCOREINVALID then
			Include(Result, slThreeKind);

		if  ASheet[slFourKind] = VAL_KND_SCOREINVALID then
			Include(Result, slFourKind);

		if  Result = [] then
			begin
			for i:= slFullHouse to slLrgStraight do
				if  ASheet[i] = VAL_KND_SCOREINVALID then
					Include(Result, i);

			if  ASheet[slChance] = VAL_KND_SCOREINVALID then
				Include(Result, slChance);
			end;
		end;

	if  Result = [] then
		for i:= slAces to slSixes do
			if  ASheet[i] = VAL_KND_SCOREINVALID then
				Include(Result, i);
	end;

function  YahtzeeBonusStealScore(ALocation: TScoreLocation; ADice: TDice): Word;
	var
	u: TDieSet;

	begin
	u:= [];

	if  ALocation in [slAces..slSixes] then
		Result:= TallyDieScoreFor(Ord(ALocation) + 1, ADice, u)
	else if ALocation in [slThreeKind..slFourKind, slChance] then
		Result:= TallyAllDieScore(ADice)
	else if ALocation = slFullHouse then
		Result:= 25
	else if ALocation = slSmlStraight then
		Result:= 30
	else if ALocation = slLrgStraight then
		Result:= 40
	else
		Result:= 0;
	end;


{ TMessage }

procedure TMessage.Assign(AMessage: TMessage);
	var
	i: Integer;

	begin
	Category:= AMessage.Category;
	Method:= AMessage.Method;

	SetLength(Data, Length(AMessage.Data));
	Move(AMessage.Data[0], Data[0], Length(AMessage.Data));

	Params.Clear;
	for i:= 0 to AMessage.Params.Count - 1 do
		Params.Add(AMessage.Params[i]);
	end;

constructor TMessage.Create;
	begin
	inherited Create;

	Params:= TList<AnsiString>.Create;
	end;

procedure TMessage.DataFromParams;
	var
	s: AnsiString;
	i: Integer;

	begin
	s:= AnsiString('');
	for i:= 0 to Params.Count - 1 do
		begin
		s:= s + Params[i];
		if  i < (Params.Count - 1) then
			s:= s + AnsiString(' ');
		end;

{$IFDEF ANDROID}
	SetLength(Data, AnsiLength(s));
	for i:= 1 to AnsiLength(s) do
		Data[i - 1]:= Byte(s[i]);
{$ELSE}
	SetLength(Data, Length(s));
	for i:= Low(s) to High(s) do
		Data[i - Low(s)]:= Ord(s[i]);
{$ENDIF}
	end;

function TMessage.DataToString: AnsiString;
	var
	i: Integer;

	begin
	Result:= AnsiString('');
	for i:= 0 to High(Data) do
{$IFDEF ANDROID}
		Result.Append(Data[i], 1);
{$ELSE}
		Result:= Result + AnsiChar(Data[i]);
{$ENDIF}
	end;

procedure TMessage.Decode(AComsData: TIdBytes);
	var
	i: Integer;
	c: Byte;

	begin
	if  (Length(AComsData) > 0)
	and (Length(AComsData) = (AComsData[0] + 1)) then
		begin
		SetLength(Data, Length(AComsData) - 2);

		c:= AComsData[1] shr 4;
		if  c in [Ord(Low(TMsgCategory))..Ord(High(TMsgCategory))] then
			begin
			Category:= TMsgCategory(AComsData[1] shr 4);
			Method:= AComsData[1] and $0F;
			end
		else
			begin
			Category:= mcSystem;
			Method:= $0E;
			end;

{$IFDEF ANDROID}
//		DataText:= '';
{$ENDIF}

		for i:= 2 to High(AComsData) do
			begin
			Data[i - 2]:= AComsData[i];

{$IFDEF ANDROID}
//			DataText:= DataText + '$' + IntToHex(AComsData[i], 2) + ' ';
{$ENDIF}
			end;
		end
	else
		begin
		SetLength(Data, 0);
		Category:= mcSystem;
		Method:= $0F;

{$IFDEF ANDROID}
//		DataText:= '';
{$ENDIF}
		end;
	end;

destructor TMessage.Destroy;
	begin
	Params.Free;

	inherited;
	end;

procedure TMessage.Encode(var AComsData: TIdBytes);
	var
	i: Integer;
	c: Byte;

	begin
	SetLength(AComsData, 2 + Length(Data));

	AComsData[0]:= Length(AComsData) - 1;

	c:= (Ord(Category) shl 4) or (Method and $0F);
	AComsData[1]:= c;

	for i:= 0 to High(Data) do
		AComsData[2 + i]:= Data[i];
	end;

procedure TMessage.ExtractParams;
	var
	i: Integer;
	s: AnsiString;
{$IFDEF ANDROID}
	t: string;
{$ENDIF}

	begin
	Params.Clear;
	s:= AnsiString('');
	for i:= 0 to High(Data) do
		if  Data[i] = $20 then
			begin
			Params.Add(s);
			s:= AnsiString('');
			end
		else
{$IFDEF ANDROID}
			begin
//			s.Append(Data[i], 1);
			s.Length:= s.Length + 1;
			s.Chars[s.Length - 1]:= AnsiChar(Data[i]);

//			if  (Category = mcPlay)
//			and (Method = $01)
//			and (i = High(Data)) then
//				begin
//				t:= '$' + IntToHex(Byte(s.Chars[0]), 2);
//				DebugMsgs.PushItem(AnsiString(t));
//				end;
			end;
{$ELSE}
			s:= s + AnsiChar(Data[i]);
{$ENDIF}

{$IFDEF ANDROID}
	if  AnsiLength(s) > 0 then
{$ELSE}
	if  Length(s) > 0 then
{$ENDIF}
		Params.Add(s);

{$IFDEF ANDROID}
//	if  (Category = mcPlay)
//	and (Method = $01)
//	and (Params.Count > 2) then
//		begin
//		t:= '';
//		for i:= 0 to AnsiLength(Params[2]) - 1 do
//			t:= '$' + IntToHex(Byte(Params[2][i]), 2) + ' ';
//
//		DebugMsgs.PushItem(AnsiString(t));
//		end;
{$ENDIF}
	end;


initialization
{$IFNDEF FPC}
	DebugMsgs:= TLogMessages.Create(512, 1);
{$ELSE}
	DebugMsgs:= TLogMessages.Create;
{$ENDIF}


finalization
	DebugMsgs.Free;

end.
