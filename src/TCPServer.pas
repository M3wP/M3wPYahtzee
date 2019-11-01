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
    protected
		Bucket: Integer;
		SendMessages: TIdentMessages;

	public
		Ident: TGUID;
		Ticket: string;
		RemoteAddress: string;
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
	TTCPWorker = class;

    TTCPConnections = TThreadList<TTCPConnection>;

	{ TTCPConnectBucket }
	 TTCPConnectBucket = record
    	Worker: TTCPWorker;
		Connections: TTCPConnections;
	end;

	TTCPConnectBuckets = array[0..31] of TTCPConnectBucket;

	{ TTCPWorker }
    TTCPWorker = class(TThread)
    private
		FConnections: TTCPConnections;
		FServer: TTCPServer;
		FIndex: Integer;
		FExpired: TTCPConnections;

	protected
        function  ProcessConnection(AConnection: TTCPConnection): Boolean;

		procedure Execute; override;

	public
//		SendMessages: TIdentMessages;

		constructor Create(const AServer: TTCPServer; const AIndex: Integer;
				AConnections: TTCPConnections);
		destructor  Destroy; override;
	end;


    TTCPWorkers = TThreadList<TTCPWorker>;

    TTCPConnectNotify = procedure(const AConnection: TTCPConnection) of object;
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

		FConnectBuckets: TTCPConnectBuckets;
		FConnections: TTCPConnections;
		FWorkers: TTCPWorkers;

	protected
		function  ConnectionByIdent(const AIdent: TGUID): TTCPConnection;

		procedure AddConnection(const AConnection: TTCPConnection;
				const AIndex: Integer);
		procedure RemoveConnection(const AConnection: TTCPConnection;
				const AIndex: Integer);

	public
		constructor Create;
		destructor  Destroy; override;

		procedure AddSendMessage(const AIdent: TGUID;
				AMessage: TBaseIdentMessage);
		procedure DisconnectByIdent(const AIdent: TGUID);

//FIXME:  Need locking?!?!
		property  OnConnect: TTCPConnectNotify read FOnConnect write FOnConnect;
		property  OnDisconnect: TTCPConnectNotify read FOnDisconnect write FOnDisconnect;
        property  OnReject: TTCPRejectNotify read FOnReject write FOnReject;
		property  OnReadData: TTCPReadDataNotify read FOnReadData write FOnReadData;

		property  MaxConnections: Cardinal read FMaxConnects write FMaxConnects;
	end;


	function GUIDToTicket(const AGUID: TGUID): string;
	function GUIDToBucket(const AGUID: TGUID): Integer;

var
	TCPServer: TTCPServer;
	TCPListener: TTCPListener;


implementation

{$IFDEF LINUX}
const
	SOL_TCP = 6;
	TCP_KEEPIDLE = 4;	/* Start keeplives after this period */
    TCP_KEEPINTVL = 5;	/* Interval between keepalives */
    TCP_KEEPCNT = 6;	/* Number of keepalives before death */
{$ENDIF}

{$IFDEF WINDOWS}
const
	IOC_IN	=		$80000000;
	IOC_VENDOR =    $18000000;
	SIO_KEEPALIVE_VALS = IOC_IN or IOC_VENDOR or 4;

type
    tcp_keepalive = packed record
		onoff: Cardinal;
      	keepalivetime: Cardinal;
      	keepaliveinterval: Cardinal;
    end;
{$ENDIF}

var
	BucketHashVector: array[0..31] of Byte;


function GUIDToTicket(const AGUID: TGUID): string;
	var
	i: Integer;
	b: Byte;

	begin
	Result:= '';

	for i:= 0 to SizeOf(TGUID) - 1 do
		begin
        b:= PByte(@AGUID)[i] and $7F;
		b:= b or $20;
		if  b = $7F then
			b:= $20;

		Result:= Result + Char(b);
		end;
	end;

procedure InitBucketHashVector;
    var
	i: Integer;

	begin
    Randomize;

	for i:= 0 to 31 do
    	BucketHashVector[i]:= Random(32);
	end;

function GUIDToBucket(const AGUID: TGUID): Integer;
    var
	bytes: array[0..16] of Byte;
    i,
	j: Integer;
	o,
	m,
    b,
	v,
	r: Byte;

	begin
    for i:= 0 to 15 do
		bytes[i]:= PByte(@AGUID)[i];

	bytes[16]:= 0;

    i:= 0;
    r:= 0;
	while i < 130 do
		begin
		b:= 0;

		for j:= 0 to 4 do
			begin
        	o:= i div 8;
        	m:= 1 shl (i - (o * 8));

            if  (bytes[o] and m) <> 0 then
            	b:= b or (1 shl j);

			Inc(i);
			end;

        Assert(b < 32, 'Error in hash function vector!');

		v:= BucketHashVector[b];
		r:= r xor v;
        end;

    Assert(r < 32, 'Error in hash function result!');

	Result:= r;
	end;

{ TTCPServer }

function TTCPServer.ConnectionByIdent(const AIdent: TGUID): TTCPConnection;
    var
	i: Integer;

	begin
	Result:= nil;

	with FConnections.LockList do
        try
		for  i:= 0 to Count - 1 do
			if  CompareMem(@AIdent, @Items[i].Ident, SizeOf(TGUID)) then
				begin
				Result:= Items[i];
				Break;
				end;

        	finally
            FConnections.UnlockList;
			end;
	end;

procedure TTCPServer.AddConnection(const AConnection: TTCPConnection;
		const AIndex: Integer);
	begin
	FLock.Acquire;
	try
    	if  FMaxConnects > 0 then
        	with FConnections.LockList do
				try
                    if  Cardinal(Count) >= FMaxConnects then
						begin
                        if  Assigned(FOnReject) then
                    		FOnReject(AConnection);
						Exit;
						end;
					finally
	            	FConnections.UnlockList;
					end;

		AConnection.Bucket:= AIndex;
    	FConnections.Add(AConnection);

        if  Assigned(FOnConnect) then
    		FOnConnect(AConnection);

    	if  not Assigned(FConnectBuckets[AIndex].Worker) then
         	begin
			FConnectBuckets[AIndex].Connections:= TTCPConnections.Create;
			FConnectBuckets[AIndex].Connections.Add(AConnection);

			FConnectBuckets[AIndex].Worker:= TTCPWorker.Create(Self,
					AIndex, FConnectBuckets[AIndex].Connections);
			end
		else
			FConnectBuckets[AIndex].Connections.Add(AConnection);

		finally
        FLock.Release;
		end;
	end;

procedure TTCPServer.RemoveConnection(const AConnection: TTCPConnection;
		const AIndex: Integer);
	begin
    FLock.Acquire;
    try
    	FConnections.Remove(AConnection);

		if  Assigned(FConnectBuckets[AIndex].Connections) then
			begin
	    	FConnectBuckets[AIndex].Connections.Remove(AConnection);

	        with FConnectBuckets[AIndex].Connections.LockList do
				if  Count = 0 then
					begin
	                FConnectBuckets[AIndex].Worker.Terminate;
					FConnectBuckets[AIndex].Worker:= nil;

					FConnectBuckets[AIndex].Connections.Free;
	                FConnectBuckets[AIndex].Connections:= nil;
					end;

			end;

        if  Assigned(FOnDisconnect) then
    		FOnDisconnect(AConnection);

		finally
        FLock.Release;
		end;

	AConnection.Free;
	end;

constructor TTCPServer.Create;
	begin
    inherited;

    FLock:= TCriticalSection.Create;

	FConnections:= TTCPConnections.Create;
	FWorkers:= TTCPWorkers.Create;

	end;

destructor TTCPServer.Destroy;
    var
	i: Integer;

	begin
   	with FWorkers.LockList do
		try
        	for i:= Count - 1 downto 0 do
				Items[i].Terminate;

			finally
        	FWorkers.UnlockList;
			end;

	while True do
		begin
		with FConnections.LockList do
			try
				if  Count = 0 then
					Break;

				finally
                FConnections.UnlockList;
				end;

		Sleep(10);
		end;

	FWorkers.Free;

    for i:= 0 to High(FConnectBuckets) do
  		if  Assigned(FConnectBuckets[i].Connections) then
			FConnectBuckets[i].Connections.Free;

	FConnections.Free;

    FLock.Free;

	inherited;
	end;

procedure TTCPServer.AddSendMessage(const AIdent: TGUID;
		AMessage: TBaseIdentMessage);
    var
	c: TTCPConnection;

	begin
    FLock.Acquire;
	try
        c:= ConnectionByIdent(AIdent);

		if  Assigned(c) then
			c.SendMessages.Add(AMessage);

		finally
        FLock.Release;
		end;
	end;

procedure TTCPServer.DisconnectByIdent(const AIdent: TGUID);
    var
	c: TTCPConnection;

	begin
    FLock.Acquire;
	try
        c:= ConnectionByIdent(AIdent);

		if  Assigned(c) then
			RemoveConnection(c, c.Bucket);

		finally
        FLock.Release;
		end;
	end;


{ TTCPWorker }

function TTCPWorker.ProcessConnection(AConnection: TTCPConnection): Boolean;
    var
	i,
	j: Integer;
	s,
	s2: string;
	im: TBaseIdentMessage;
	buf: TMsgData;
	TimeV: TTimeVal;
	FDSet: TFDSet;

	begin
	Result:= True;

	TimeV.tv_usec:= 1000;
	TimeV.tv_sec:= 0;
	FDSet:= AConnection.Socket.FdSet;
	if  synsock.Select(AConnection.Socket.Socket, nil, nil, @FDSet, @TimeV) > 0 then
		begin
		Result:= False;
		AddLogMessage(slkInfo, '"' + AConnection.Ticket +
				'" lost connection - error.');

		Exit;
		end;

	i:= AConnection.Socket.WaitingData;

//	if  i = 0 then
//		begin
// 		if  AConnection.Socket.CanRead(1) then
//			begin
//			Result:= False;
//			AddLogMessage(slkInfo, '"' + AConnection.Ticket +
//					'" lost connection - informed.');
//			Exit;
//			end;
//		end;

  	if  i > 0 then
		begin
		SetLength(buf, i);

        j:= AConnection.Socket.RecvBufferEx(TMemory(@(buf[0])), i, 100);

        Assert(i >= j, 'Buffer exceeded bounds!');

		if  j > 0 then
			begin
        	if  j < i then
		    	SetLength(buf, j);

			if  AConnection.Socket.LastError = 0 then
				begin
				if  Assigned(FServer.FOnReadData) then
					FServer.FOnReadData(AConnection.Ident, buf);
				end
			else
				begin
    			Result:= False;
    			AddLogMessage(slkInfo, '"' + AConnection.Ticket +
    					'" error while reading socket.');
    			Exit;
				end;
			end;
		end;

	with  AConnection.SendMessages.LockList do
		try
            while Count > 0 do
				begin
				im:= Items[0];

                buf:= im.Encode;

                s2:= '<<' + IntToStr(buf[0]) + ' $' +
						IntToHex(buf[1], 2) + ': ';
				for i:= 2 to High(buf) do
					s2:= s2 + Char(buf[i]);

				AddLogMessage(slkDebug, '"' + AConnection.Ticket + '" ' + s2);

				AConnection.Socket.SendBuffer(TMemory(@(buf[0])),
						Length(buf));

				if  AConnection.Socket.LastError <> 0 then
					begin
        			Result:= False;
        			AddLogMessage(slkInfo, '"' + AConnection.Ticket +
        					'" error while writing socket.');
        			Exit;
					end;

                Delete(0);
				im.Free;
				end;

			finally
        	AConnection.SendMessages.UnlockList;
			end;
	end;

procedure TTCPWorker.Execute;
    var
	i: Integer;

	begin
	while not Terminated do
		try
	        Sleep(100);

	        with FExpired.LockList do
				try
	                while Count > 0 do
						begin
						FServer.RemoveConnection(Items[Count - 1], FIndex);
						Delete(Count - 1);
						end;
					finally
	                FExpired.UnlockList;
					end;

            if  Terminated then
				begin
				FConnections:= nil;
				Continue;
				end;

	        with FConnections.LockList do
				try
	                for i:= 0 to Count - 1 do
						if  not ProcessConnection(Items[i]) then
							FExpired.Add(Items[i]);

					finally
	                FConnections.UnlockList;
					end;

	        except
			AddLogMessage(slkError, 'TCPWorker error!');
			Terminate;
			end;

	if  Assigned(FConnections) then
		with  FConnections.LockList do
			try
	            for i:= 0 to Count - 1 do
					FExpired.Add(Items[i]);

				finally
	            FConnections.UnlockList;
				end;
	end;

constructor TTCPWorker.Create(const AServer: TTCPServer; const AIndex: Integer;
		AConnections: TTCPConnections);
	begin
    FreeOnTerminate:= True;

	FServer:= AServer;
	FIndex:= AIndex;

    FConnections:= AConnections;
	FExpired:= TTCPConnections.Create;

	inherited Create(False);
	end;

destructor TTCPWorker.Destroy;
	var
	i: Integer;

	begin
	with FExpired.LockList do
		try
            for i:= Count - 1 downto 0 do
				FServer.RemoveConnection(Items[i], FIndex);

			finally
            FExpired.UnlockList;
			end;

	FExpired.Free;

    if  Assigned(FServer) then
	    FServer.FWorkers.Remove(Self);

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
            try
				aclient:= TTCPConnection.Create(FConnection.Socket);

				except
                AddLogMessage(slkError, 'Failed to accept connection');
				Continue
				end;

          	TCPServer.AddConnection(aclient, GUIDToBucket(aclient.Ident));
            Sleep(10);
			end;
		end;

//	FConnection.Socket.CloseSocket;
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
    inherited;

	if  CreateGUID(Ident) <> 0 then
		raise Exception.Create('Unable to create connection ident!');
    Ticket:= GUIDToTicket(Ident);

	SendMessages:= TIdentMessages.Create;

    Socket:= TTCPBlockSocket.Create;
	end;

constructor TTCPConnection.Create(AListener: TTCPBlockSocket);
	var
{$IFDEF WINDOWS}
    vInBuffer: tcp_keepalive;
    cbBytesReturned: Cardinal;
{$ENDIF}

	begin
    if  CreateGUID(Ident) <> 0 then
		raise Exception.Create('Unable to create connection ident!');
    Ticket:= GUIDToTicket(Ident);

    Socket:= TTCPBlockSocket.Create;
	Socket.Socket:= AListener.Accept;

	if  AListener.LastError <> 0 then
		raise Exception.Create('Unable to accept connection (' +
				AListener.GetErrorDescEx + ')!');

	SendMessages:= TIdentMessages.Create;

    RemoteAddress:= Socket.GetRemoteSinIP;

{$IFDEF WINDOWS}
//	vInBuffer.onoff:= 1;
//	vInBuffer.keepalivetime:= 10000;
//	vInBuffer.keepaliveinterval:= 1000;

//	if  WSAIoctl(Socket.Socket, // descriptor identifying a socket
//			SIO_KEEPALIVE_VALS,                  // dwIoControlCode
// 			@vInBuffer,    // pointer to tcp_keepalive struct
// 			SizeOf(tcp_keepalive),      // length of input buffer
// 			nil,         // output buffer
// 			0,       // size of output buffer
// 			@cbBytesReturned,    // number of bytes returned
//			nil,   // OVERLAPPED structure
// 			nil // completion routine
//			) <> 0 then
//		begin
//		AddLogMessage(slkWarning, 'Failed to set Windows keep alive');
//		end
//	else
//		begin
//		AddLogMessage(slkDebug, 'Set Windows keep alive');
//		end;
{$ENDIF}
	end;

destructor TTCPConnection.Destroy;
	var
	i: Integer;

	begin
	with  SendMessages.LockList do
		try
        	for i:= Count - 1 downto 0 do
				begin
				Items[i].Free;
				Delete(i);
				end;

			finally
            SendMessages.UnlockList;
			end;

    SendMessages.Free;

	try
        if  Assigned(Socket) then
            Socket.CloseSocket;
		except
		end;

	try
        if  Assigned(Socket) then
            Socket.Free;
		except
		end;

    inherited;
	end;

initialization
	InitBucketHashVector;

finalization
    if  Assigned(TCPServer) then
        TCPServer.Free;

end.

