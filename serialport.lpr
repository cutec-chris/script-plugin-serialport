library serialport;

{$mode objfpc}{$H+}

uses
  Classes,sysutils,synaser,utils, general_nogui{$IFDEF WINDOWS},Windows,registry{$ENDIF}
  ;

type
  TParityType = (NoneParity, OddParity, EvenParity);

var
  Ports : TList = nil;
  aData: String;

function SerOpen(const DeviceName: String): Integer;stdcall;
var
  aDev: TBlockSerial;
  i : Integer;
begin
  Result := -1;
  try
    if not Assigned(Ports) then
      Ports := TList.Create;
    for i := 0 to Ports.Count-1 do
      if TBlockSerial(Ports[i]).Device=DeviceName then
        begin
          aDev := TBlockSerial(Ports[i]);
          if aDev.Handle=INVALID_HANDLE_VALUE then
            aDev.Connect(DeviceName);
          if aDev.Handle<>INVALID_HANDLE_VALUE then
            begin
              Result := i;
              exit;
            end;
        end;
    aDev := TBlockSerial.Create;
    aDev.Connect(DeviceName);
    if aDev.Handle<>INVALID_HANDLE_VALUE then
      begin
        Ports.Add(aDev);
        Result := Ports.Count-1;
      end
    else aDev.Free;
  except
  end;
end;

procedure SerClose(Handle: LongInt); stdcall;
var
  i: Integer;
  aDev: TBlockSerial;
begin
  try
    if not Assigned(Ports) then exit;
    for i := 0 to Ports.Count-1 do
      if i=Handle then
        begin
          aDev := TBlockSerial(Ports[i]);
          Ports.Remove(aDev);
          aDev.CloseSocket;
          aDev.Free;
          exit;
        end;
  except
  end;
end;
procedure SerCloseAll; stdcall;
var
  i: Integer;
  aDev: TBlockSerial;
begin
  try
    if not Assigned(Ports) then exit;
    for i := 0 to Ports.Count-1 do
      begin
        aDev := TBlockSerial(Ports[i]);
        Ports.Remove(aDev);
        aDev.Free;
      end;
  except
  end;
end;
procedure SerFlush(Handle: LongInt); stdcall;
var
  i: Integer;
begin
  try
    if not Assigned(Ports) then exit;
    for i := 0 to Ports.Count-1 do
      if i=Handle then
        begin
          TBlockSerial(Ports[i]).Flush;
          exit;
        end;
  except
  end;
end;

procedure SerParams(Handle: LongInt; BitsPerSec: LongInt; ByteSize: Integer; Parity: TParityType; StopBits: Integer);stdcall;
var
  i: Integer;
begin
  try
    if not Assigned(Ports) then exit;
    case StopBits of
    1:StopBits:=0;
    2:StopBits:=2;
    3:StopBits:=1;
    end;
    for i := 0 to Ports.Count-1 do
      if i=Handle then
        begin
          case Parity of
          NoneParity:TBlockSerial(Ports[i]).Config(BitsPerSec,ByteSize,'N',StopBits,False,False);
          OddParity:TBlockSerial(Ports[i]).Config(BitsPerSec,ByteSize,'O',StopBits,False,False);
          EvenParity:TBlockSerial(Ports[i]).Config(BitsPerSec,ByteSize,'E',StopBits,False,False);
          end;
          exit;
        end;
  except
  end;
end;

function SerReadEx(Handle: LongInt;Count: LongInt) : PChar;stdcall;
var
  Data,aData: String;
  i: Integer;
  a: Integer;
begin
  try
    if not Assigned(Ports) then exit;
    for i := 0 to Ports.Count-1 do
      if i=Handle then
        begin
          SetLength(Data,Count);
          TBlockSerial(Ports[i]).RecvBuffer(@Data[1],Count);
          aData := '';
          for a := 1 to length(Data) do
            aData := aData+IntToHex(ord(Data[a]),2);
          Result := @aData[1];
          exit;
        end;
  except
  end;
end;

function SerReadTimeoutEx(Handle: LongInt;var Data : PChar;Timeout: Integer;Count: LongInt) : Integer;stdcall;
var
  i: Integer;
  iData: String;
  a: Integer;
  aTime: Int64;
begin
  try
    if not Assigned(Ports) then exit;
    for i := 0 to Ports.Count-1 do
      if i=Handle then
        begin
          aTime := GetTicks;
          iData := '';
          iData := TBlockSerial(Ports[i]).RecvPacket(Timeout);
          while (length(iData)<Count) and (GetTicks-aTime<Timeout) do
            iData := iData+TBlockSerial(Ports[i]).RecvPacket(Timeout);
          Result := length(iData);
          aData := '';
          for a := 1 to length(iData) do
            aData := aData+IntToHex(ord(iData[a]),2);
          Data := PChar(aData);
          exit;
        end;
  except
  end;
end;

function SerGetCTS(Handle: LongInt) : Boolean;stdcall;
var
  i: Integer;
begin
  try
    if not Assigned(Ports) then exit;
    for i := 0 to Ports.Count-1 do
      if i=Handle then
        begin
          Result := TBlockSerial(Ports[i]).CTS;
          exit;
        end;
  except
  end;
end;

function SerGetDSR(Handle: LongInt) : Boolean;stdcall;
var
  i: Integer;
begin
  try
    if not Assigned(Ports) then exit;
    for i := 0 to Ports.Count-1 do
      if i=Handle then
        begin
          Result := TBlockSerial(Ports[i]).DSR;
          exit;
        end;
  except
  end;
end;

procedure SerSetRTS(Handle: LongInt;Value : Boolean);stdcall;
var
  i: Integer;
begin
  try
    if not Assigned(Ports) then exit;
    for i := 0 to Ports.Count-1 do
      if i=Handle then
        begin
          TBlockSerial(Ports[i]).RTS := Value;
          exit;
        end;
  except
  end;
end;

procedure SerRTSToggle(Handle: LongInt;Value : Boolean);stdcall;
var
  i: Integer;
begin
  try
    if not Assigned(Ports) then exit;
    for i := 0 to Ports.Count-1 do
      if i=Handle then
        begin
          TBlockSerial(Ports[i]).EnableRTSToggle(Value);
          if Value then
            TBlockSerial(Ports[i]).Tag:=1
          else TBlockSerial(Ports[i]).Tag:=0;
          exit;
        end;
  except
  end;
end;

procedure SerSetDTR(Handle: LongInt;Value : Boolean);stdcall;
var
  i: Integer;
begin
  try
    if not Assigned(Ports) then exit;
    for i := 0 to Ports.Count-1 do
      if i=Handle then
        begin
          TBlockSerial(Ports[i]).DTR := Value;
          exit;
        end;
  except
  end;
end;

function SerWrite(Handle: LongInt; Data : PChar;Len : Integer): LongInt;stdcall;
var
  i: Integer;
begin
  try
    if not Assigned(Ports) then exit;
    for i := 0 to Ports.Count-1 do
      if i=Handle then
        begin
          TBlockSerial(Ports[i]).SendBuffer(Data,Len);
          Result := length(Data);
          exit;
        end;
  except
  end;
end;

procedure ScriptCleanup;stdcall;
var
  i: Integer;
begin
  try
    if not Assigned(Ports) then exit;
    for i := 0 to Ports.Count-1 do
      begin
        TBlockSerial(Ports[i]).CloseSocket;
        TBlockSerial(Ports[i]).Free;
      end;
    Ports.Clear;
    FreeAndNil(Ports);
  except
  end;
end;

function SerPortNames: PChar;stdcall;
var
  {$IFDEF WINDOWS}
  l: TStringList;
  v: TStringList;
  reg: TRegistry;
  n: Integer;
  aPort: String;
  {$ENDIF}
  AllPorts : string;
begin
  try
    AllPorts := '';
    {$IFDEF WINDOWS}
    l := TStringList.Create;
    v := TStringList.Create;
    reg := TRegistry.Create;
    try
  {$IFNDEF VER100}
  {$IFNDEF VER120}
      reg.Access := KEY_READ;
  {$ENDIF}
  {$ENDIF}
      reg.RootKey := HKEY_LOCAL_MACHINE;
      reg.OpenKey('\HARDWARE\DEVICEMAP\SERIALCOMM', false);
      reg.GetValueNames(l);
      for n := 0 to l.Count - 1 do
        begin
          aPort := l[n];
          aPort := StringReplace(reg.ReadString(aPort),#0,'',[rfReplaceAll]);
          if AllPorts<>'' then
            Allports += LineEnding;
          AllPorts += aPort;
        end;
      Result := PChar(Allports);
    finally
      reg.Free;
      l.Free;
      v.Free;
    end;
    {$ELSE}
    Result := PChar(StringReplace(GetSerialPortNames,',',LineEnding,[rfReplaceAll]));
    {$ENDIF}
  except
  end;
end;

function ScriptUnitDefinition : PChar;stdcall;
begin
  Result := 'unit SerialPort;'
       +#10+'interface'
       +#10+'type'
       +#10+'  TParityType = (NoneParity, OddParity, EvenParity);'
       +#10+'  function SerOpen(const DeviceName: String): Integer;external ''SerOpen@%dllpath% stdcall'';'
       +#10+'  procedure SerClose(Handle: LongInt);external ''SerClose@%dllpath% stdcall'';'
       +#10+'  procedure SerCloseAll;external ''SerCloseAll@%dllpath% stdcall'';'
       +#10+'  procedure SerFlush(Handle: LongInt);external ''SerFlush@%dllpath% stdcall'';'
       +#10+'  function SerRead(Handle: LongInt; Count: LongInt): string;'
       +#10+'  function SerReadTimeout(Handle: LongInt;Timeout: Integer;Count: LongInt) : string;'
       +#10+'  function SerWrite(Handle: LongInt; Data : PChar;Len : Integer): LongInt;external ''SerWrite@%dllpath% stdcall'';'
       +#10+'  procedure SerParams(Handle: LongInt; BitsPerSec: LongInt; ByteSize: Integer; Parity: TParityType; StopBits: Integer);external ''SerParams@%dllpath% stdcall'';'
       +#10+'  function SerGetCTS(Handle: LongInt) : Boolean;external ''SerGetCTS@%dllpath% stdcall'';'
       +#10+'  function SerGetDSR(Handle: LongInt) : Boolean;external ''SerGetDSR@%dllpath% stdcall'';'
       +#10+'  procedure SerSetRTS(Handle: LongInt;Value : Boolean);external ''SerSetRTS@%dllpath% stdcall'';'
       +#10+'  procedure SerSetDTR(Handle: LongInt;Value : Boolean);external ''SerSetDTR@%dllpath% stdcall'';'
       +#10+'  procedure SerRTSToggle(Handle: LongInt;Value : Boolean);external ''SerRTSToggle@%dllpath% stdcall'';'
       +#10+'  function SerPortNames: PChar;external ''SerPortNames@%dllpath% stdcall'';'

       +#10+'  function SerReadEx(Handle: LongInt; Count: LongInt): PChar;external ''SerReadEx@%dllpath% stdcall'';'
       +#10+'  function SerReadTimeoutEx(Handle: LongInt;var Data : PChar;Timeout: Integer;Count: LongInt) : Integer;external ''SerReadTimeoutEx@%dllpath% stdcall'';'
       +#10+'implementation'
       +#10+'  function SerRead(Handle: LongInt; Count: LongInt): string;'
       +#10+'  var aOut : PChar;'
       +#10+'      bOut : string;'
       +#10+'      i : Integer;'
       +#10+'  begin'
       +#10+'    Result := '''';'
       +#10+'    aOut := SerReadEx(Handle,Count);'
       +#10+'    bOut := aOut;'
       +#10+'    SetLength(Result,Count);'
       +#10+'    for i := 0 to Count-1 do'
       +#10+'      begin'
       +#10+'        Result := Result+chr(StrToInt(''$''+copy(bOut,0,2)));'
       +#10+'        bOut := copy(bOut,3,length(bOut));'
       +#10+'        if bOut='''' then break;'
       +#10+'      end;'
       +#10+'  end;'
       +#10+'  function SerReadTimeout(Handle: LongInt;Timeout: Integer;Count: LongInt) : string;'
       +#10+'  var aOut : PChar;'
       +#10+'      bOut : string;'
       +#10+'      a : Integer;'
       +#10+'  begin'
       +#10+'    Result := '''';'
       +#10+'    a := SerReadTimeoutEx(Handle,aOut,Timeout,Count);'
       +#10+'    bOut := aOut;'
       +#10+'    Result := '''''
       +#10+'    while a > 0 do'
       +#10+'      begin'
       +#10+'        Result := Result+chr(StrToInt(''$''+copy(bOut,0,2)));'
       +#10+'        bOut := copy(bOut,3,length(bOut));'
       +#10+'        if bOut='''' then break;'
       +#10+'        dec(a);'
       +#10+'      end;'
       +#10+'  end;'
       +#10+'end.'
            ;
end;

exports
  SerOpen,
  SerClose,
  SerCloseAll,
  SerFlush,
  SerReadEx,
  SerReadTimeoutEx,
  SerWrite,
  SerParams,
  SerGetCTS,
  SerGetDSR,
  SerSetRTS,
  SerSetDTR,
  SerRTSToggle,
  SerPortNames,

  ScriptUnitDefinition,
  ScriptCleanup;

end.

