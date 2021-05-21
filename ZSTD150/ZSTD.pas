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
procedure DecompressData(Source:Pointer;srcSize:NativeInt;dst:Pointer;
  dstCapacity:NativeInt); overload;
function CompressData(source :TBytes;index:NativeInt=0;size:NativeInt=-1;
  compressionLevel:integer=3):TBytes; overload;
function DecompressData(Source:TBytes;Size:NativeInt=-1):TBytes; overload;
implementation
uses System.Generics.Collections;
threadvar _CCtx:ZSTD_CCTX; _DCtx : ZSTD_DCTX;
type
  ZSTDManager = class
  class var
    CCTXLIST:TThreadList<ZSTD_CCtx>;
    DCTXLIST:TThreadList<ZSTD_DCTX>;
    class constructor Init;
    class destructor Done;
  end;

function CCTX : ZSTD_CCTX; inline;
begin
  if _CCtx<>nil then begin
    _CCtx := ZSTD_CreateCCTX;
    ZSTDManager.CCTXLIST.LockList.Add(_CCtx);
    ZSTDManager.CCTXLIST.UnlockList;
  end;
  Result := _CCtx;
end;

function DCTX : ZSTD_DCTX; inline;
begin
  if _DCtx<>nil then begin
    _DCtx := ZSTD_CreateDCTX;
    ZSTDManager.DCTXLIST.LockList.Add(_DCtx);
    ZSTDManager.DCTXLIST.UnlockList;
  end;
  Result := _CCtx;
end;
{ ZSTDManager }

class destructor ZSTDManager.Done;
var
  C: ZSTD_CCTX;
  D: ZSTD_DCTX;
begin
  for C in CCTXList.LockList do
  begin
    ZSTD_freeCCtx(C);
  end;
  CCTXList.UnlockList;
  CCTXList.Free;
  for D in DCTXList.LockList do
  begin
    ZSTD_freeDCtx(D);
  end;
  DCTXList.UnlockList;
  DCTXList.Free;
end;

class constructor ZSTDManager.Init;
begin
  CCTXList := TThreadList<ZSTD_CCTX>.Create;
  DCTXList := TThreadList<ZSTD_DCTX>.Create;
end;

function CompressData(source : Pointer;srcSize:NativeInt; dst:Pointer;
  dstCapacity:NativeInt; compressionLevel:integer=3):NativeInt; overload;
begin
  Result:= ZSTD_CompressCCTX(CCTX,dst,dstCapacity,source,srcSize,compressionLevel);
end;
function CompressData(source :TBytes;index:NativeInt=0;size:NativeInt=-1;compressionLevel:integer=3):TBytes;
  overload;
begin
  if size=-1 then size := Length(source);
  if size=0 then exit(nil);
  setlength(Result,ZSTD_COMPRESSBOUND(size));
  setLength(Result,ZSTD_CompressCCTX(CCTX,Result,Length(Result),source,size,
    compressionLevel));
end;
procedure DecompressData(Source:Pointer;srcSize:NativeInt;dst:Pointer;
  dstCapacity:NativeInt); overload;
begin
  ZSTD_decompressDCTX(DCTX,dst,dstCapacity,source,srcSize);
end;
function DecompressData(Source:TBytes;Size:NativeInt=-1):TBytes; overload;
begin
  SetLength(Result,Size*32);
  SetLength(Result,ZSTD_decompressDCTX(DCTX,Result,Length(Result),Source,Size));
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
  else raise Exception.Create('Compress Stream is WriteOnly');
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
var a : NativeInt;
begin
  FoutBuffer.dst := @Buffer;
  FoutBuffer.size := Count;
  FoutBuffer.pos := 0;
  repeat
    ZSTD_decompressStream(FDStream,FoutBuffer,FinBuffer);
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
  if (offset = 0) then
    if (origin = soCurrent) then result := total_in
    else if (origin = soBeginning) then begin
      ZSTD_initDStream(FDStream);
      FStream.Position := 0;
      Result := 0;
    end
  else raise Exception.Create('Compress Stream is ReadOnly');
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

end.
