program TESTZSTD;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  classes,
  zstd,
  system.hash,
  system.zlib{$IFDEF MSWINDOWS},winapi.Windows{$ENDIF};

var data,c,d,cc,dd : TMemoryStream;
    ZC : TZstdCompressStream;
    ZD : TZSTDDecompressStream;
    ZLC : TZCompressionStream;
    ZLD : TZDeCompressionStream;
    b, e, s : Cardinal;
    buf : array[0..128*1024-1] of byte;
{$IFDEF LINUX64}
function GetTickCount : Cardinal; inline;
begin
  var a := Now;
  Result :=round((a-int(a))*86400000);
end;
{$ENDIF}
begin
  writeln('zstd version: ',ZSTD_VERSION_STRING);
  writeln;
  try
    { TODO -oUser -cConsole Main : Insert code here }
    data := TMemoryStream.Create;
    data.LoadFromFile('glibc-2.31.tar');
    data.Position := 0;
    writeln('Orginal Size: ',data.SIZE,'  Orginal MD5: ',THashMD5.Create.GetHashString(data));
    writeln;
    C := TMemoryStream.Create;
    D := TMemoryStream.Create;
    cc := TMemoryStream.Create;
    dd := TMemoryStream.Create;
    data.Position := 0;
    cc.SetSize(0);
    b := GetTickCount;
    cc.position:= 0;
    ZLC := TZCompressionStream.Create(clFastest,cc);
    ZLC.CopyFrom(data,data.Size);
    ZLC.Free;
    e := GetTickCount;
    cC.Position := 0;
    write('Zlib Fastest Compress in ',e-b,'ms   ');
    writeln('Size: ',Cc.Size,'   MD5: ',THASHMD5.Create.GetHashString(CC));
    b := GetTickCount;
    cC.Position :=0;
    dd.position := 0;
    ZLD := TZDecompressionStream.Create(CC);
    repeat
      s := ZLD.Read(buf,128*1024);
      DD.Write(Buf,s);
    until s<128*1024;
    ZLD.Free;
    e := GetTickCount;
    dD.Position := 0;
    write('Zlib Fastest DeCompress in ',e-b,'ms   ');
    writeln('Size: ',dD.Size,'   MD5: ',THASHMD5.Create.GetHashString(DD));
    writeln;
    data.position := 0;
    c.SetSize(0);
    b := GetTickCount;
    c.position := 0;
    ZC := TZSTDCompressStream.Create(C,1);
    ZC.CopyFrom(data,data.Size);
    ZC.Free;
    e := GetTickCount;
    c.Position := 0;
    write('ZSTD Fastest Compress in ',e-b,'ms   ');
    writeln('Size: ',c.Size,'   MD5: ',THASHMD5.Create.GetHashString(C));
    b := GetTickCount;
    c.Position :=0;
    d.position := 0;
    ZD := TZSTDDecompressStream.Create(C,false);
    repeat
      s := ZD.Read(buf,128*1024);
      D.Write(Buf,s);
    until s<128*1024;
    ZD.Free;
    e := GetTickCount;
    d.Position := 0;
    write('ZSTD Fastest DeCompress in ',e-b,'ms   ');
    writeln('Size: ',d.Size,'   MD5: ',THASHMD5.Create.GetHashString(D));
    writeln;
    data.Position := 0;
    cc.SetSize(0);
    b := GetTickCount;
    cc.position:= 0;
    ZLC := TZCompressionStream.Create(clDefault,cc);
    ZLC.CopyFrom(data,data.Size);
    ZLC.Free;
    e := GetTickCount;
    cC.Position := 0;
    write('Zlib Default Compress in ',e-b,'ms   ');
    writeln('Size: ',Cc.Size,'   MD5: ',THASHMD5.Create.GetHashString(CC));
    b := GetTickCount;
    cC.Position :=0;
    dd.position := 0;
    ZLD := TZDecompressionStream.Create(CC);
    repeat
      s := ZLD.Read(buf,128*1024);
      DD.Write(Buf,s);
    until s<128*1024;
    ZLD.Free;
    e := GetTickCount;
    dD.Position := 0;
    write('Zlib Default DeCompress in ',e-b,'ms   ');
    writeln('Size: ',dD.Size,'   MD5: ',THASHMD5.Create.GetHashString(DD));
    writeln;
    data.position := 0;
    c.SetSize(0);
    b := GetTickCount;
    c.position := 0;
    ZC := TZSTDCompressStream.Create(C);
    ZC.CopyFrom(data,data.Size);
    ZC.Free;
    e := GetTickCount;
    c.Position := 0;
    write('ZSTD Default Compress in ',e-b,'ms   ');
    writeln('Size: ',c.Size,'   MD5: ',THASHMD5.Create.GetHashString(C));
    b := GetTickCount;
    c.Position :=0;
    d.position := 0;
    ZD := TZSTDDecompressStream.Create(C,false);
    repeat
      s := ZD.Read(buf,128*1024);
      D.Write(Buf,s);
    until s<128*1024;
    ZD.Free;
    e := GetTickCount;
    d.Position := 0;
    write('ZSTD Default DeCompress in ',e-b,'ms   ');
    writeln('Size: ',d.Size,'   MD5: ',THASHMD5.Create.GetHashString(D));
    writeln;
    data.Position := 0;
    cc.SetSize(0);
    b := GetTickCount;
    cc.position:= 0;
    ZLC := TZCompressionStream.Create(clMAX,cc);
    ZLC.CopyFrom(data,data.Size);
    ZLC.Free;
    e := GetTickCount;
    cC.Position := 0;
    write('Zlib MAX Compress in ',e-b,'ms   ');
    writeln('Size: ',Cc.Size,'   MD5: ',THASHMD5.Create.GetHashString(CC));
    b := GetTickCount;
    cC.Position :=0;
    dd.position := 0;
    ZLD := TZDecompressionStream.Create(CC);
    repeat
      s := ZLD.Read(buf,128*1024);
      DD.Write(Buf,s);
    until s<128*1024;
    ZLD.Free;
    e := GetTickCount;
    dD.Position := 0;
    write('Zlib MAX DeCompress in ',e-b,'ms   ');
    writeln('Size: ',dD.Size,'   MD5: ',THASHMD5.Create.GetHashString(DD));
    writeln;
    data.position := 0;
    c.SetSize(0);
    b := GetTickCount;
    c.position := 0;
    ZC := TZSTDCompressStream.Create(C,9);
    ZC.CopyFrom(data,data.Size);
    ZC.Free;
    e := GetTickCount;
    c.Position := 0;
    write('ZSTD MAX Compress in ',e-b,'ms   ');
    writeln('Size: ',c.Size,'   MD5: ',THASHMD5.Create.GetHashString(C));
    b := GetTickCount;
    c.Position :=0;
    d.position := 0;
    ZD := TZSTDDecompressStream.Create(C,false);
    repeat
      s := ZD.Read(buf,128*1024);
      D.Write(Buf,s);
    until s<128*1024;
    ZD.Free;
    e := GetTickCount;
    d.Position := 0;
    write('ZSTD MAX DeCompress in ',e-b,'ms   ');
    writeln('Size: ',d.Size,'   MD5: ',THASHMD5.Create.GetHashString(D));
    writeln;
    data.Free;
    c.free;
    d.free;
    cc.free;
    dd.free;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  writeln('Done! press ENTER to quit');
  readln;
end.
