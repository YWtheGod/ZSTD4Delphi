unit libc;

interface
{$IFDEF WIN32}
// void * memmove(void * dst, void * src, size_t count)
function _memmove(dst,src : pointer; count : NativeInt):Pointer; cdecl; external;
// void * memcpy(void * dst, void * src, size_t count)
function _memcpy(dst,src : pointer; count : NativeInt):Pointer; cdecl; external;
//void * memset ( void * ptr, int value, size_t num );
function _memset(ptr : Pointer; Value:integer; num : NativeInt):Pointer; cdecl; external;
//int memcmp ( const void * ptr1, const void * ptr2, size_t num );
function _memcmp(ptr1,ptr2 : Pointer; num : NativeInt):integer; cdecl; external;
//void *malloc(size_t size)
function _malloc(size : NativeInt):Pointer; cdecl;
//void *calloc(size_t nitems, size_t size)
function _calloc(nitems,size : NativeInt):Pointer; cdecl;
//void free(void *ptr)
procedure _free(ptr : Pointer); cdecl;
procedure ___chkstk_ms; cdecl; external;
function ___divdi3(a,b:int64):Int64;cdecl;external;
function ___udivdi3(a,b:UInt64):UInt64; cdecl; external;
{$ENDIF}
{$IFDEF WIN64}
// void * memmove(void * dst, void * src, size_t count)
function memmove(dst,src : pointer; count : NativeInt):Pointer; external;
// void * memcpy(void * dst, void * src, size_t count)
function memcpy(dst,src : pointer; count : NativeInt):Pointer; external;
//void * memset ( void * ptr, int value, size_t num );
function memset(ptr : Pointer; Value:integer; num : NativeInt):Pointer; external;
//int memcmp ( const void * ptr1, const void * ptr2, size_t num );
function memcmp(ptr1,ptr2 : Pointer; num : NativeInt):integer; external;
//void *malloc(size_t size)
function malloc(size : NativeInt):Pointer;
//void *calloc(size_t nitems, size_t size)
function calloc(nitems,size : NativeInt):Pointer;
//void free(void *ptr)
procedure free(ptr : Pointer);
procedure ___chkstk_ms; external;
{$ENDIF}

implementation
uses SysUtils;
{$IFDEF WIN32}
{$L memcpy.X86.O}
{$L memset.X86.O}
{$L memcmp.X86.O}
{$L chkstk.x86.o}
{$L divdi3.x86.o}
{$L udivdi3.x86.o}
function _malloc(size : NativeInt):Pointer;
begin
  GetMem(Result,size);
end;

function _calloc(nitems,size : NativeInt):Pointer;
begin
  Result := Allocmem(nitems*size);
end;

procedure _free(ptr : Pointer);
begin
  FreeMem(ptr);
end;
{$ENDIF}
{$IFDEF WIN64}
{$L memcpy.X64.O}
{$L memset.X64.O}
{$L memcmp.X64.O}
{$L chkstk.x64.o}
function malloc(size : NativeInt):Pointer;
begin
  GetMem(Result,size);
end;

function calloc(nitems,size : NativeInt):Pointer;
begin
  Result := Allocmem(nitems*size);
end;

procedure free(ptr : Pointer);
begin
  FreeMem(ptr);
end;
{$ENDIF}

end.
