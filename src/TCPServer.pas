unit TCPServer;

{$MODE DELPHI}
{$H+}

interface

uses
	Classes, SysUtils, SyncObjs, Generics.Collections, synsock, blcksock,
	YahtzeeClasses;

type
	{ TTCPConnection }
 	TTCPConnection = class
		Ident: TGUID;
		Socket: TTCPBlockSocket;

		constructor Create; overload;
		constructor Create(AListener: TTCPBlockSocket);

		destructor  Destroy; override;
	end;


	{ TTCPListener }
 	TTCPListener = class(TThread)
    private
		FConnection: TTCPConnection;

	protected
		procedure Execute; override;

	public
        constructor Create(APort: string);
		destructor  Destroy; override;
	end;

    TTCPServer = class;

	{ TTCPWorker }

    TTCPWorker = class(TThread)
    private
		FConnection: TTCPConnection;
		FServer: TTCPServer;

	protected
		procedure Execute; override;

	public
		SendMessages: TIdentMessages;

		constructor Create(const AServer: TTCPServer;
				AConnection: TTCPConnection);
		destructor  Destroy; override;
	end;


    TTCPWorkerList = TThreadList<TTCPWorker>;

    TTCPConnectNotify = procedure(const AIdent: TGUID) of object;
	TTCPRejectNotify = procedure(const AConnection: TTCPConnection) of object;
	TTCPReadDataNotify = procedure(const AIdent: TGUID; const AData: TMsgData) of object;


	{ TTCPServer }

 	TTCPServer = class
	private
		FLock: TCriticalSection;
		FOnConnect: TTCPConnectNotify;
		FOnDisconnect: TTCPConnectNotify;
		FOnReject: TTCPRejectNotify;
        FOnReadData: TTCPReadDataNotify;

		FMaxConnects: Cardinal;

	public
		ReadMessages: TIdentMessages;

		Workers: TTCPWorkerList;

		constructor Create;
		destructor  Destroy; override;

		function  WorkerByIdent(const AIdent: TGUID): TTCPWorker;
		procedure SendWorkerMessage(var AMessage: TBaseIdentMessage);
		procedure InitWorkerFromConnection(const ATCPConnection: TTCPConnection);
		procedure DisconnectIdent(const AIdent: TGUID);

//FIXME:  Need locking!
		property  OnConnect: TTCPConnectNotify read FOnConnect write FOnConnect;
		property  OnDisconnect: TTCPConnectNotify read FOnDisconnect write FOnDisconnect;
        property  OnReject: TTCPRejectNotify read FOnReject write FOnReject;
		property  OnReadData: TTCPReadDataNotify read FOnReadData write FOnReadData;

		property  MaxConnections: Cardinal read FMaxConnects write FMaxConnects;
	end;

var
	TCPServer: TTCPServer;
	TCPListener: TTCPListener;


implementation


{ TTCPServer }

function TTCPServer.WorkerByIdent(const AIdent: TGUID): TTCPWorker;
    var
	i: Integer;

	begin
    Result:= nil;
	with Workers.LockList do
		try
            for i:= 0 to Count - 1 do
				if 	CompareMem(@Items[i].FConnection.Ident, @AIdent, SizeOf(TGUID)) then
					begin
					Result:= Items[i];
					Break;
					end;
			finally
            Workers.UnlockList;
			end;
	end;

constructor TTCPServer.Create;
	begin
    inherited;

    FLock:= TCriticalSection.Create;

	ReadMessages:= TIdentMessages.Create;

	Workers:= TTCPWorkerList.Create;

	end;

destructor TTCPServer.Destroy;
    var
	i: Integer;
    w: TTCPWorker;
	im: TBaseIdentMessage;
	s: string;

	begin
	w:= nil;

	repeat
    	with Workers.LockList do
			try
                if  Count > 0 then
                    begin
					w:= Items[0];
                    Delete(0);
                    end
                else
					w:= nil;

				finally
                Workers.UnlockList;
				end;

		if  Assigned(w) then
			begin
            w.FServer:= nil;
			w.Terminate;
//			w.WaitFor;
			end;

    	until not Assigned(w);


	Workers.Free;

	with ReadMessages.LockList do
		try
            for i:= Count - 1 downto 0 do
				begin
				im:= Items[i];
				Delete(i);
				im.Free;
				end;

			finally
            ReadMessages.UnlockList;
			end;

	ReadMessages.Free;

    FLock.Free;

	inherited;
	end;

procedure TTCPServer.SendWorkerMessage(var AMessage: TBaseIdentMessage);
    var
	w: TTCPWorker;

	begin
    w:= WorkerByIdent(AMessage.Ident);

	if  Assigned(w) then
        try
			w.SendMessages.Add(AMessage);

			except
			end
	else
//FIXME:
//		Log message
        AMessage.Free;
	end;

procedure TTCPServer.InitWorkerFromConnection(
		const ATCPConnection: TTCPConnection);
    var
	c: Cardinal;
	w: TTCPWorker;

	begin
//    with  Workers.LockList do
//		try
//			c:= Count;
//
//			finally
//            Workers.UnlockList;
//			end;

	c:= 0;

	if  (FMaxConnects = 0)
	or  ((FMaxConnects > 0)
	and  (c < FMaxConnects)) then
		begin
        w:= TTCPWorker.Create(Self, ATCPConnection);
//FIXME:
//		Log Message?
		end
	else if Assigned(FOnReject) then
		begin
		FOnReject(ATCPConnection);

        try
			ATCPConnection.Socket.CloseSocket;
            ATCPConnection.Free;

			except
			end;

//FIXME:
//		Log Message?
		end;
	end;

procedure TTCPServer.DisconnectIdent(const AIdent: TGUID);
	var
	w: TTCPWorker;

	begin
    w:= WorkerByIdent(AIdent);

	if  Assigned(w) then
		w.Terminate;
	end;

{ TTCPWorker }

procedure TTCPWorker.Execute;
    var
    i,
	j: Integer;
	s,
	s2: string;
	im: TBaseIdentMessage;
	buf: TMsgData;

	begin
    FServer.Workers.Add(Self);

    if  Assigned(FServer.FOnConnect) then
		FServer.FOnConnect(FConnection.Ident);

	while not Terminated do
		try
        Sleep(100);

		i:= FConnection.Socket.WaitingData;
      	if  i > 0 then
			begin
			SetLength(buf, i);

            j:= FConnection.Socket.RecvBufferEx(TMemory(@(buf[0])), i, 100);

            if j > i then
				raise Exception.Create('Buffer exceeded bounds!');

            if  j < i then
			    SetLength(buf, j);

			if  FConnection.Socket.LastError = 0 then
				begin
				if  Assigned(FServer.FOnReadData) then
					FServer.FOnReadData(FConnection.Ident, buf);
				end
			else
				raise Exception.Create('This is bad!');
//FIXME:
//				Server log message
				;
			end;

		with  SendMessages.LockList do
			try
                while Count > 0 do
					begin
					im:= Items[0];

                    buf:= im.Encode;

                    s2:= '<<' + IntToStr(buf[0]) + ' $' +
							IntToHex(buf[1], 2) + ': ';
					for i:= 2 to High(buf) do
						s2:= s2 + Char(buf[i]);

					AddLogMessage(slkDebug, GUIDToString(im.Ident) + ' ' + s2);

					FConnection.Socket.SendBuffer(TMemory(@(buf[0])),
							Length(buf));

					if  FConnection.Socket.LastError <> 0 then
						begin
//FIXME:
//						Server log message
						Terminate;
                        Break;
						end;

                    Delete(0);
					im.Free;
					end;

				finally
            	SendMessages.UnlockList;
				end;
        except
		AddLogMessage(slkError, 'TCPWorker error!');

		Terminate;
		end;

	with  SendMessages.LockList do
		try
        	for i:= Count - 1 downto 0 do
				begin
				im:= Items[i];
				Delete(i);
				im.Free;
				end;

			finally
            SendMessages.UnlockList;
			end;


	if  Assigned(FServer.FOnDisconnect) then
		FServer.FOnDisconnect(FConnection.Ident);

	try
        FConnection.Socket.CloseSocket;
        FConnection.Socket.Free;
		except
//FIXME:
//		Server log message
		end;

    FConnection.Socket:= nil;

    if  Assigned(FServer) then
	    FServer.Workers.Remove(Self);

	FConnection.Free;
	end;

constructor TTCPWorker.Create(const AServer: TTCPServer;
		AConnection: TTCPConnection);
	begin
    FreeOnTerminate:= True;

	FServer:= AServer;
    FConnection:= AConnection;

	SendMessages:= TIdentMessages.Create;

	inherited Create(False);
	end;

destructor TTCPWorker.Destroy;
	begin
	SendMessages.Free;

	inherited;
	end;


{ TTCPListener }

procedure TTCPListener.Execute;
    var
    aclient: TTCPConnection;

	begin
    FConnection.Socket.Listen;
	while not Terminated do
		begin
		if  FConnection.Socket.CanRead(100) then
			begin
			aclient:= TTCPConnection.Create(FConnection.Socket);
            TCPServer.InitWorkerFromConnection(aclient);

            Sleep(10);
			end;
		end;

    FConnection.Socket.CloseSocket;
	end;

constructor TTCPListener.Create(APort: string);
    var
    i: Integer;

    begin
    FreeOnTerminate:= True;

    FConnection:= TTCPConnection.Create;
    if  FConnection.Socket.LastError <> 0 then
		raise Exception.Create('Unable to create listener connection (' +
				FConnection.Socket.GetErrorDescEx + ')!');

    FConnection.Socket.Family:= SF_IP4;

    FConnection.Socket.CreateSocket;
    if  FConnection.Socket.LastError <> 0 then
		raise Exception.Create('Unable to initialise listener connection (' +
				FConnection.Socket.GetErrorDescEx + ')!');

    FConnection.Socket.SetLinger(True, 1000);

    i:= 0;
    while True do
        begin
        FConnection.Socket.Bind('0.0.0.0', APort);

        if  FConnection.Socket.LastError <> 0 then
            begin
            Sleep(100);
            Inc(i);
            if  i >= 500 then
    		    raise Exception.Create('Unable to bind listener connection (' +
    			    	FConnection.Socket.GetErrorDescEx + ')!');
            end
        else
            Break;
        end;

    inherited Create(False);
	end;

destructor TTCPListener.Destroy;
	begin
	FConnection.Free;

	inherited;
	end;

{ TConnection }

constructor TTCPConnection.Create;
	begin
    if  CreateGUID(Ident) <> 0 then
		raise Exception.Create('Unable to create connection ident!');

    Socket:= TTCPBlockSocket.Create;
	end;

constructor TTCPConnection.Create(AListener: TTCPBlockSocket);
	begin
    if  CreateGUID(Ident) <> 0 then
		raise Exception.Create('Unable to create connection ident!');

    Socket:= TTCPBlockSocket.Create;
	Socket.Socket:= AListener.Accept;

	if  AListener.LastError <> 0 then
		raise Exception.Create('Unable to accept connection (' +
				AListener.GetErrorDescEx + ')!');
	end;

destructor TTCPConnection.Destroy;
	begin
	try
        if  Assigned(Socket) then
            Socket.Free;

		except
		end;

    inherited;
	end;

initialization

finalization
    if  Assigned(TCPServer) then
        TCPServer.Free;

end.

