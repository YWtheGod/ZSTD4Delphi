unit ZSTD;

interface
uses classes, sysutils, ZSTDLib;

const
  ZSTD_VERSION_MAJOR = ZSTDLib.ZSTD_VERSION_MAJOR;
  ZSTD_VERSION_MINOR = ZSTDLib.ZSTD_VERSION_MINOR;
  ZSTD_VERSION_RELEASE = ZSTDLib.ZSTD_VERSION_RELEASE;
  ZSTD_VERSION_NUMBER = ZSTD_VERSION_MAJOR*100*100+ZSTD_VERSION_MINOR*100+
    ZSTD_VERSION_RELEASE;
  ZSTD_VERSION_STRING = ZSTDLib.ZSTD_VERSION_STRING;
  ZSTD_CLEVEL_DEFAULT = ZSTDLib.ZSTD_CLEVEL_DEFAULT;

type
  TCustomZSTDStream = class(TStream)
  private
    FStream: TStream;
    FStreamStartPos: Int64;
    FStreamPos: Int64;
    FInBuffer :ZSTD_inBuffer;
    FOutBuffer : ZSTD_outBuffer;
    total_in, total_out : NativeInt;
  protected
    constructor Create(stream: TStream);
  end;

  TZSTDCompressStream=class(TCustomZSTDStream)
  private
    FCStream : ZSTD_CStream;
    flevel : integer;
    function GetCompressionRate: Single;
  public
    constructor Create(dest: TStream; compressionLevel: Integer=3);
    destructor Destroy; override;
    function Read(var buffer; count: Longint): Longint; override;
    function Write(const buffer; count: Longint): Longint; override;
    function Read(Buffer: TBytes; Offset, Count: Longint): Longint; override;
    function Write(const Buffer: TBytes; Offset, Count: Longint): Longint; override;

    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    property CompressionRate: Single read GetCompressionRate;
  end;

  TZSTDDecompressStream = class(TCustomZSTDStream)
  private
    FOwnsStream: Boolean;
    FDStream : ZSTD_DStream;
    _eof : boolean;
  public
    constructor Create(source: TStream; OwnsStream: Boolean=false);
    destructor Destroy; override;
    function Read(var buffer; count: Longint): Longint; override;
    function Write(const buffer; count: Longint): Longint; override;
    function Read(Buffer: TBytes; Offset, Count: Longint): Longint; override;
    function Write(const Buffer: TBytes; Offset, Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
  end;

function CompressData(source : Pointer;srcSize:NativeInt; dst:Pointer;
  dstCapacity:NativeInt; compressionLevel:integer=3):NativeInt; overload;
function DecompressData(Source:Pointer;srcSize:NativeInt;dst:Pointer;
  dstCapacity:NativeInt):NativeInt; overload;
function CompressData(source :TBytes;index:NativeInt=0;size:NativeInt=-1;
  compressionLevel:integer=3):TBytes; overload;
function DecompressData(Source:TBytes;Size:NativeInt=-1):TBytes; overload;
implementation
type
  Context = record
    class function GetCCTX:ZSTD_CCTX; static;
    class function GetDCTX:ZSTD_DCTX; inline; static;
    class procedure FreeCCTX(C : ZSTD_CCTX); static;
    class procedure FreeDCTX(C : ZSTD_DCTX); inline; static;
    class constructor Create;
    class destructor Destroy;
  end;
var
  [volatile]_CCTX : ZSTD_CCtx;
  [volatile]_DCTX : ZSTD_DCtx;

function CompressData(source : Pointer;srcSize:NativeInt; dst:Pointer;
  dstCapacity:NativeInt; compressionLevel:integer=3):NativeInt; overload;
var TX : ZSTD_CCTX;
begin
  TX := Context.GetCCTX;
  try
    Result:= ZSTD_CompressCCTX(TX,dst,dstCapacity,source,srcSize,compressionLevel);
  finally
    Context.FreeCCTX(TX);
  end;
end;
function CompressData(source :TBytes;index:NativeInt=0;size:NativeInt=-1;compressionLevel:integer=3):TBytes;
  overload;
begin
  if size=-1 then size := Length(source);
  if size=0 then exit(nil);
  setlength(Result,ZSTD_COMPRESSBOUND(size));
  setLength(Result,CompressData(@Source[0],size,@Result[0],Length(Result),
    compressionLevel));
end;
function DecompressData(Source:Pointer;srcSize:NativeInt;dst:Pointer;
  dstCapacity:NativeInt):NativeInt; overload;
var TX : ZSTD_DCTX;
begin
  TX := Context.GetDCTX;
  try
    Result := ZSTD_decompressDCTX(TX,dst,dstCapacity,source,srcSize);
  finally
    Context.FreeDCTX(TX);
  end;
end;
function DecompressData(Source:TBytes;Size:NativeInt=-1):TBytes; overload;
begin
  if Size=-1 then Size := Length(Source);
  SetLength(Result,Size*32);
  SetLength(Result,DecompressData(@Source[0],Size,@Result[0],Length(Result)));
end;
{ TZSTDStream }

constructor TZSTDCompressStream.Create(dest: TStream; compressionLevel: Integer=3);
begin
  inherited Create(dest);
  FCStream := ZSTD_createCStream;
  flevel :=compressionLevel;
  ZSTD_initCStream(FCStream,flevel);
  FoutBuffer.size := ZSTD_CStreamOutSize;
  GetMem(FoutBuffer.dst,FoutBuffer.size);
  FoutBuffer.pos := 0;
end;

destructor TZSTDCompressStream.Destroy;
begin
  ZSTD_flushStream(FCStream,FoutBuffer);
  FStream.Write(FoutBuffer.dst^,FoutBuffer.pos);
  Freemem(FoutBuffer.dst);
  ZSTD_freeCStream(FCStream);
  inherited;
end;

function TZSTDCompressStream.GetCompressionRate: Single;
begin
  if total_in = 0 then result := 0
  else result := (1.0 - (total_out / total_in)) * 100.0;
end;

function TZSTDCompressStream.Read(var buffer; count: Longint): Longint;
begin
  raise Exception.Create('Compress Stream is WriteOnly');
end;

function TZSTDCompressStream.Read(Buffer: TBytes; Offset, Count: Longint): Longint;
begin
  raise Exception.Create('Compress Stream is WriteOnly');
end;

function TZSTDCompressStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  if (offset = 0) and (origin = soCurrent) then
  begin
    result := total_in;
  end
  else Result := -1;
end;

function TZSTDCompressStream.Write(const Buffer: TBytes; Offset,
  Count: Longint): Longint;
begin
  Result := Write(Buffer[Offset],Count);
end;

function TZSTDCompressStream.Write(const buffer; count: Longint): Longint;
begin
  Finbuffer.src := @buffer;
  Finbuffer.size := count;
  Finbuffer.pos := 0;
  while Finbuffer.pos<Finbuffer.size do begin
    ZSTD_compressStream2(FCStream,Foutbuffer,FinBuffer,ZSTD_e_continue);
    if FoutBuffer.pos>0 then begin
      FStream.Write(FoutBuffer.dst^,FoutBuffer.pos);
      total_out := total_out+FoutBuffer.pos;
      FoutBuffer.pos := 0;
    end;
  end;
  total_in := total_in+count;
  Result := Count;
end;

{ TCustomZSTDStream }

constructor TCustomZSTDStream.Create(stream: TStream);
begin
  inherited Create;
  FStream := stream;
  FStreamStartPos := Stream.Position;
  FStreamPos := FStreamStartPos;
end;

{ TZDecompressionStream }

constructor TZSTDDecompressStream.Create(source: TStream; OwnsStream: Boolean=false);
begin
  inherited Create(source);
  FOwnsStream := OwnsStream;
  FDStream := ZSTD_createDStream;
  FinBuffer.size := ZSTD_DStreamInSize; //128K
  GetMem(FinBuffer.src,FinBuffer.size);
  total_in := FStream.Read(FinBuffer.src^,FinBuffer.size);
  _eof := total_in<FinBuffer.size;
  FinBuffer.size := total_in;
end;

destructor TZSTDDecompressStream.Destroy;
begin
  Freemem(FinBuffer.src);
  ZSTD_freeDStream(FDStream);
  if FOwnsStream then
    FStream.Free;
  inherited;
end;

function TZSTDDecompressStream.Read(Buffer: TBytes; Offset,
  Count: Longint): Longint;
begin
  Result := Read(Buffer[Offset],Count);
end;

function TZSTDDecompressStream.Read(var buffer; count: Longint): Longint;
var a,b : NativeInt;
begin
  FoutBuffer.dst := @Buffer;
  FoutBuffer.size := Count;
  FoutBuffer.pos := 0;
  repeat
    b := ZSTD_decompressStream(FDStream,FoutBuffer,FinBuffer);
    if ZSTD_iserror(b)<>0 then raise Exception.Create('ZSTD Error '+b.toString);
    if (FInBuffer.pos=FInBuffer.size) then begin
      if _eof then break;
      a := FStream.Read(FInBuffer.src^,FInBuffer.size);
      total_in := total_in+a;
      _eof := a<FInBuffer.size;
      FInBuffer.size:= a;
      FInBuffer.pos := 0;
    end;
  until FoutBuffer.pos=FoutBuffer.size;
  total_out:=total_out+FoutBuffer.pos;
  Result := FOutBuffer.pos;
end;

function TZSTDDecompressStream.Seek(const Offset: Int64;
  Origin: TSeekOrigin): Int64;
begin
  Result := -1;
end;

function TZSTDDecompressStream.Write(const Buffer: TBytes; Offset,
  Count: Longint): Longint;
begin
  raise Exception.Create('Compress Stream is ReadOnly');
end;

function TZSTDDecompressStream.Write(const buffer; count: Longint): Longint;
begin
  raise Exception.Create('Compress Stream is ReadOnly');
end;

{ Contex }

class constructor Context.Create;
begin
  _CCtx := ZSTD_CreateCCTX;
  _DCTX := ZSTD_CreateDCTX;
end;

class destructor Context.Destroy;
begin
  if _CCTX<>nil then ZSTD_FreeCCTX(_CCtx);
  if _DCTX<>nil then ZSTD_FreeDCTX(_DCTX);
end;

class procedure Context.FreeCCTX(C: ZSTD_CCTX);
begin
  ZSTD_CCTX_reset(C,ZSTD_reset_session_only);
  C := atomicExchange(_CCTX,C);
  if C<>nil then ZSTD_FreeCCTX(c);
end;

class procedure Context.FreeDCTX(C: ZSTD_DCTX);
begin
  ZSTD_CCTX_reset(C,ZSTD_reset_session_only);
  C := atomicExchange(_DCTX,C);
  if C<>nil then ZSTD_FreeDCTX(c);
end;

class function Context.GetCCTX: ZSTD_CCTX;
begin
  Result := nil;
  Result := atomicExchange(_CCTX,Result);
  if Result=nil then Result := ZSTD_CreateCCTX;
end;

class function Context.GetDCTX: ZSTD_DCTX;
begin
  Result := nil;
  Result := atomicExchange(_DCTX,Result);
  if Result=nil then Result := ZSTD_CreateDCTX;
end;

end.
