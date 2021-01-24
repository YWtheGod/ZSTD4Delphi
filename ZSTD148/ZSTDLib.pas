unit ZSTDLib;

interface
const
  ZSTD_VERSION_MAJOR = 1;
  ZSTD_VERSION_MINOR = 4;
  ZSTD_VERSION_RELEASE = 8;
  ZSTD_VERSION_NUMBER = ZSTD_VERSION_MAJOR*100*100+ZSTD_VERSION_MINOR*100+
    ZSTD_VERSION_RELEASE;
  ZSTD_VERSION_STRING = '1.4.8';
  ZSTD_CLEVEL_DEFAULT = 3;

type
  ZSTD_CCtx=Pointer;
  ZSTD_DCtx=Pointer;
  ZSTD_strategy=(
               ZSTD_fast=1,
               ZSTD_dfast=2,
               ZSTD_greedy=3,
               ZSTD_lazy=4,
               ZSTD_lazy2=5,
               ZSTD_btlazy2=6,
               ZSTD_btopt=7,
               ZSTD_btultra=8,
               ZSTD_btultra2=9
  );
  ZSTD_cParameter=(
    {* compression parameters
     * Note: When compressing with a ZSTD_CDict these parameters are superseded
     * by the parameters used to construct the ZSTD_CDict.
     * See ZSTD_CCtx_refCDict() for more info (superseded-by-cdict). *}
    ZSTD_c_compressionLevel=100, {* Set compression parameters according to pre-defined cLevel table.
                              * Note that exact compression parameters are dynamically determined,
                              * depending on both compression level and srcSize (when known).
                              * Default level is ZSTD_CLEVEL_DEFAULT==3.
                              * Special: value 0 means default, which is controlled by ZSTD_CLEVEL_DEFAULT.
                              * Note 1 : it's possible to pass a negative compression level.
                              * Note 2 : setting a level does not automatically set all other compression parameters
                              *   to default. Setting this will however eventually dynamically impact the compression
                              *   parameters which have not been manually set. The manually set
                              *   ones will 'stick'. *}
    {* Advanced compression parameters :
     * It's possible to pin down compression parameters to some specific values.
     * In which case, these values are no longer dynamically selected by the compressor *}
    ZSTD_c_windowLog=101,    {* Maximum allowed back-reference distance, expressed as power of 2.
                              * This will set a memory budget for streaming decompression,
                              * with larger values requiring more memory
                              * and typically compressing more.
                              * Must be clamped between ZSTD_WINDOWLOG_MIN and ZSTD_WINDOWLOG_MAX.
                              * Special: value 0 means "use default windowLog".
                              * Note: Using a windowLog greater than ZSTD_WINDOWLOG_LIMIT_DEFAULT
                              *       requires explicitly allowing such size at streaming decompression stage. *}
    ZSTD_c_hashLog=102,      {* Size of the initial probe table, as a power of 2.
                              * Resulting memory usage is (1 << (hashLog+2)).
                              * Must be clamped between ZSTD_HASHLOG_MIN and ZSTD_HASHLOG_MAX.
                              * Larger tables improve compression ratio of strategies <= dFast,
                              * and improve speed of strategies > dFast.
                              * Special: value 0 means "use default hashLog". *}
    ZSTD_c_chainLog=103,     {* Size of the multi-probe search table, as a power of 2.
                              * Resulting memory usage is (1 << (chainLog+2)).
                              * Must be clamped between ZSTD_CHAINLOG_MIN and ZSTD_CHAINLOG_MAX.
                              * Larger tables result in better and slower compression.
                              * This parameter is useless for "fast" strategy.
                              * It's still useful when using "dfast" strategy,
                              * in which case it defines a secondary probe table.
                              * Special: value 0 means "use default chainLog". *}
    ZSTD_c_searchLog=104,    {* Number of search attempts, as a power of 2.
                              * More attempts result in better and slower compression.
                              * This parameter is useless for "fast" and "dFast" strategies.
                              * Special: value 0 means "use default searchLog". *}
    ZSTD_c_minMatch=105,     {* Minimum size of searched matches.
                              * Note that Zstandard can still find matches of smaller size,
                              * it just tweaks its search algorithm to look for this size and larger.
                              * Larger values increase compression and decompression speed, but decrease ratio.
                              * Must be clamped between ZSTD_MINMATCH_MIN and ZSTD_MINMATCH_MAX.
                              * Note that currently, for all strategies < btopt, effective minimum is 4.
                              *                    , for all strategies > fast, effective maximum is 6.
                              * Special: value 0 means "use default minMatchLength". *}
    ZSTD_c_targetLength=106, {* Impact of this field depends on strategy.
                              * For strategies btopt, btultra & btultra2:
                              *     Length of Match considered "good enough" to stop search.
                              *     Larger values make compression stronger, and slower.
                              * For strategy fast:
                              *     Distance between match sampling.
                              *     Larger values make compression faster, and weaker.
                              * Special: value 0 means "use default targetLength". *}
    ZSTD_c_strategy=107,     {* See ZSTD_strategy enum definition.
                              * The higher the value of selected strategy, the more complex it is,
                              * resulting in stronger and slower compression.
                              * Special: value 0 means "use default strategy". *}

    {* LDM mode parameters *}
    ZSTD_c_enableLongDistanceMatching=160, {* Enable long distance matching.
                                     * This parameter is designed to improve compression ratio
                                     * for large inputs, by finding large matches at long distance.
                                     * It increases memory usage and window size.
                                     * Note: enabling this parameter increases default ZSTD_c_windowLog to 128 MB
                                     * except when expressly set to a different value. *}
    ZSTD_c_ldmHashLog=161,   {* Size of the table for long distance matching, as a power of 2.
                              * Larger values increase memory usage and compression ratio,
                              * but decrease compression speed.
                              * Must be clamped between ZSTD_HASHLOG_MIN and ZSTD_HASHLOG_MAX
                              * default: windowlog - 7.
                              * Special: value 0 means "automatically determine hashlog". *}
    ZSTD_c_ldmMinMatch=162,  {* Minimum match size for long distance matcher.
                              * Larger/too small values usually decrease compression ratio.
                              * Must be clamped between ZSTD_LDM_MINMATCH_MIN and ZSTD_LDM_MINMATCH_MAX.
                              * Special: value 0 means "use default value" (default: 64). *}
    ZSTD_c_ldmBucketSizeLog=163, {* Log size of each bucket in the LDM hash table for collision resolution.
                              * Larger values improve collision resolution but decrease compression speed.
                              * The maximum value is ZSTD_LDM_BUCKETSIZELOG_MAX.
                              * Special: value 0 means "use default value" (default: 3). *}
    ZSTD_c_ldmHashRateLog=164, {* Frequency of inserting/looking up entries into the LDM hash table.
                              * Must be clamped between 0 and (ZSTD_WINDOWLOG_MAX - ZSTD_HASHLOG_MIN).
                              * Default is MAX(0, (windowLog - ldmHashLog)), optimizing hash table usage.
                              * Larger values improve compression speed.
                              * Deviating far from default value will likely result in a compression ratio decrease.
                              * Special: value 0 means "automatically determine hashRateLog". *}

    {* frame parameters *}
    ZSTD_c_contentSizeFlag=200, {* Content size will be written into frame header _whenever known_ (default:1)
                              * Content size must be known at the beginning of compression.
                              * This is automatically the case when using ZSTD_compress2(),
                              * For streaming scenarios, content size must be provided with ZSTD_CCtx_setPledgedSrcSize() *}
    ZSTD_c_checksumFlag=201, {* A 32-bits checksum of content is written at end of frame (default:0) *}
    ZSTD_c_dictIDFlag=202,   {* When applicable, dictionary's ID is written into frame header (default:1) *}

    {* multi-threading parameters *}
    {* These parameters are only useful if multi-threading is enabled (compiled with build macro ZSTD_MULTITHREAD).
     * They return an error otherwise. *}
    ZSTD_c_nbWorkers=400,    {* Select how many threads will be spawned to compress in parallel.
                              * When nbWorkers >= 1, triggers asynchronous mode when used with ZSTD_compressStream*() :
                              * ZSTD_compressStream*() consumes input and flush output if possible, but immediately gives back control to caller,
                              * while compression work is performed in parallel, within worker threads.
                              * (note : a strong exception to this rule is when first invocation of ZSTD_compressStream2() sets ZSTD_e_end :
                              *  in which case, ZSTD_compressStream2() delegates to ZSTD_compress2(), which is always a blocking call).
                              * More workers improve speed, but also increase memory usage.
                              * Default value is `0`, aka "single-threaded mode" : no worker is spawned, compression is performed inside Caller's thread, all invocations are blocking *}
    ZSTD_c_jobSize=401,      {* Size of a compression job. This value is enforced only when nbWorkers >= 1.
                              * Each compression job is completed in parallel, so this value can indirectly impact the nb of active threads.
                              * 0 means default, which is dynamically determined based on compression parameters.
                              * Job size must be a minimum of overlap size, or 1 MB, whichever is largest.
                              * The minimum size is automatically and transparently enforced. *}
    ZSTD_c_overlapLog=402,   {* Control the overlap size, as a fraction of window size.
                              * The overlap size is an amount of data reloaded from previous job at the beginning of a new job.
                              * It helps preserve compression ratio, while each job is compressed in parallel.
                              * This value is enforced only when nbWorkers >= 1.
                              * Larger values increase compression ratio, but decrease speed.
                              * Possible values range from 0 to 9 :
                              * - 0 means "default" : value will be determined by the library, depending on strategy
                              * - 1 means "no overlap"
                              * - 9 means "full overlap", using a full window size.
                              * Each intermediate rank increases/decreases load size by a factor 2 :
                              * 9: full window;  8: w/2;  7: w/4;  6: w/8;  5:w/16;  4: w/32;  3:w/64;  2:w/128;  1:no overlap;  0:default
                              * default value varies between 6 and 9, depending on strategy *}

    {* note : additional experimental parameters are also available
     * within the experimental section of the API.
     * At the time of this writing, they include :
     * ZSTD_c_rsyncable
     * ZSTD_c_format
     * ZSTD_c_forceMaxWindow
     * ZSTD_c_forceAttachDict
     * ZSTD_c_literalCompressionMode
     * ZSTD_c_targetCBlockSize
     * ZSTD_c_srcSizeHint
     * Because they are not stable, it's necessary to define ZSTD_STATIC_LINKING_ONLY to access them.
     * note : never ever use experimentalParam? names directly;
     *        also, the enums values themselves are unstable and can still change.
     *}
     ZSTD_c_experimentalParam1=500,
     ZSTD_c_experimentalParam2=10,
     ZSTD_c_experimentalParam3=1000,
     ZSTD_c_experimentalParam4=1001,
     ZSTD_c_experimentalParam5=1002,
     ZSTD_c_experimentalParam6=1003,
     ZSTD_c_experimentalParam7=1004,
     ZSTD_c_experimentalParam8=1005,
     ZSTD_c_experimentalParam9=1006,
     ZSTD_c_experimentalParam10=1007,
     ZSTD_c_experimentalParam11=1008,
     ZSTD_c_experimentalParam12=1009
  );
  ZSTD_bounds = record
    error : NativeInt;
    lowerBound,upperBound:integer;
  end;
  ZSTD_ResetDirective=(
    ZSTD_reset_session_only = 1,
    ZSTD_reset_parameters = 2,
    ZSTD_reset_session_and_parameters = 3
  );
  ZSTD_dParameter=(
    ZSTD_d_windowLogMax=100, {* Select a size limit (in power of 2) beyond which
                              * the streaming API will refuse to allocate memory buffer
                              * in order to protect the host from unreasonable memory requirements.
                              * This parameter is only useful in streaming mode, since no internal buffer is allocated in single-pass mode.
                              * By default, a decompression context accepts window sizes <= (1 << ZSTD_WINDOWLOG_LIMIT_DEFAULT).
                              * Special: value 0 means "use default maximum windowLog". *}

    {* note : additional experimental parameters are also available
     * within the experimental section of the API.
     * At the time of this writing, they include :
     * ZSTD_d_format
     * ZSTD_d_stableOutBuffer
     * Because they are not stable, it's necessary to define ZSTD_STATIC_LINKING_ONLY to access them.
     * note : never ever use experimentalParam? names directly
     *}
     ZSTD_d_experimentalParam1=1000,
     ZSTD_d_experimentalParam2=1001,
     ZSTD_d_experimentalParam3=1002
  );
  ZSTD_inBuffer = record
    src : Pointer;
    size, pos : NativeInt;
  end;
  ZSTD_outBuffer = record
    dst : Pointer;
    size, pos : NativeInt;
  end;
  ZSTD_CStream = ZSTD_CCtx;
  ZSTD_DStream = ZSTD_DCtx;
  ZSTD_EndDirective=(
    ZSTD_e_continue=0, {* collect more data, encoder decides when to output compressed result, for optimal compression ratio *}
    ZSTD_e_flush=1,    {* flush any data provided so far,
                        * it creates (at least) one new block, that can be decoded immediately on reception;
                        * frame will continue: any future data can still reference previously compressed data, improving compression.
                        * note : multithreaded compression will block to flush as much output as possible. *}
    ZSTD_e_end=2       {* flush any remaining data _and_ close current frame.
                        * note that frame is only closed after compressed data is fully flushed (return value == 0).
                        * After that point, any additional data starts a new frame.
                        * note : each frame is independent (does not reference any content from previous frame).
                        : note : multithreaded compression will block to flush as much output as possible. *}
  );
  ZSTD_CDict = Pointer;
  ZSTD_DDict = Pointer;

{$IFDEF WIN32}
function ZSTD_versionNumber:Cardinal; inline;
function ZSTD_versionString:PAnsiChar; inline;
function ZSTD_compress(dst:Pointer; dstCapacity : NativeInt; src:Pointer;
  srcSize : NativeInt; compressionLevel : integer):NativeInt; inline;
function ZSTD_decompress(dst:Pointer; dstCapacity:NativeInt; src:Pointer;
  compressedSize:NativeInt):NativeInt; inline;
function ZSTD_getFrameContentSize(const src:Pointer; srcsize:NativeInt):UInt64;
  inline;
function ZSTD_getDecompressedSize(const src:Pointer; srcSize:NativeInt):UInt64;
  inline;
function ZSTD_findFrameCompressedSize(const src:Pointer; srcSize:NativeInt):
  NativeInt; inline;
function ZSTD_COMPRESSBOUND(srcSize:NativeInt):NativeInt; inline;
function ZSTD_isError(code : NativeInt):Cardinal; inline;
function ZSTD_getErrorName(code : NativeInt):PAnsiChar; inline;
function ZSTD_minCLevel:integer; inline;
function ZSTD_maxCLevel:integer; inline;
function ZSTD_createCCtx:ZSTD_CCtx; inline;
function ZSTD_freeCCtx(cctx: ZSTD_CCtx):NativeInt; inline;
function ZSTD_compressCCtx(cctx:ZSTD_CCtx; dst:Pointer; dstCapacity:NativeInt;
  src:Pointer; srcSize:NativeInt; compressionLevel:integer):NativeInt; inline;
function ZSTD_createDCtx:ZSTD_DCtx; inline;
function ZSTD_freeDCtx(dctx: ZSTD_DCtx):NativeInt; inline;
function ZSTD_decompressDCtx(dctx:ZSTD_CCtx; dst:Pointer; dstCapacity:NativeInt;
  src:Pointer; srcSize:NativeInt):NativeInt; inline;
function ZSTD_cParam_getBounds(cParam : ZSTD_cParameter): ZSTD_bounds; inline;
function ZSTD_CCtx_setParameter(cctx : ZSTD_CCtx; param:ZSTD_cParameter;
  value : integer):NativeInt; inline;
function ZSTD_CCtx_setPledgedSrcSize(cctx : ZSTD_CCtx; pledgedScrSize:Uint64)
  :NativeInt; inline;
function ZSTD_CCtx_reset(cctx:ZSTD_CCtx; reset: ZSTD_ResetDirective):NativeInt;
  inline;
function ZSTD_compress2(cctx:ZSTD_CCtx; dst:Pointer; dstCapacity:NativeInt;
  src:Pointer; srcSize:NativeInt):NativeInt; inline;
function ZSTD_dParam_getBounds(dParam : ZSTD_dParameter):ZSTD_bounds; inline;
function ZSTD_DCtx_setParameter(dctx:ZSTD_DCTx; param: ZSTD_dParameter;
  value : integer):NativeInt; inline;
function ZSTD_DCtx_reset(dctx:ZSTD_DCtx; reset:ZSTD_ResetDirective):NativeInt;
  inline;
function ZSTD_createCStream: ZSTD_CStream; inline;
function ZSTD_freeCStream(zsc : ZSTD_CStream):NativeInt; inline;
function ZSTD_compressStream2(cctx:ZSTD_CCtx; var output:ZSTD_outBuffer;
  var input:ZSTD_inBuffer; endOp:ZSTD_EndDirective):NativeInt; inline;
function ZSTD_CStreamInSize:NativeInt; inline;
function ZSTD_CStreamOutSize:NativeInt; inline;
function ZSTD_initCStream(zcs:ZSTD_CStream; compressionLevel:integer):NativeInt;
  inline;
function ZSTD_compressStream(zcs:ZSTD_CStream; var output:ZSTD_outBuffer;
  var input:ZSTD_inBuffer):NativeInt; inline;
function ZSTD_flushStream(zcs:ZSTD_CStream; var output:ZSTD_outBuffer):NativeInt;
  inline;
function ZSTD_endStream(zcs:ZSTD_CStream; var output:ZSTD_outBuffer):NativeInt;
  inline;
function ZSTD_createDStream: ZSTD_DStream; inline;
function ZSTD_freeDStream(zds : ZSTD_DStream):NativeInt; inline;
function ZSTD_initDStream(zds : ZSTD_DStream):NativeInt; inline;
function ZSTD_decompressStream(zds:ZSTD_DStream; var output:ZSTD_outBuffer;
  var input:ZSTD_inBuffer):NativeInt; inline;
function ZSTD_DStreamInSize:NativeInt; inline;
function ZSTD_DStreamOutSize:NativeInt; inline;
function ZSTD_compress_usingDict(ctx:ZSTD_CCtx; dst:Pointer;
  dstCapacity:NativeInt; src:Pointer; srcSize:NativeInt; dict:Pointer;
  dictSize:NativeInt; compressionLevel:integer):NativeInt; inline;
function ZSTD_decompress_usingDict(dctx:ZSTD_DCtx; dst:Pointer;
  dstCapacity:NativeInt; src:Pointer; srcSize:NativeInt; dict:Pointer;
  dictSize:NativeInt):NativeInt; inline;
function ZSTD_createCDict(const dictBuffer:Pointer; dictSize:NativeInt;
  compressionLevel:integer):ZSTD_CDict; inline;
function ZSTD_freeCDict(CDict:ZSTD_CDict):NativeInt; inline;
function ZSTD_compress_usingCDict(cctx:ZSTD_CCtx; dst:Pointer;
  dstCapacity:NativeInt; src:Pointer; srcSize:NativeInt; cdict:ZSTD_CDict):
  NativeInt; inline;
function ZSTD_createDDict(const dictBuffer:Pointer; dictSize:NativeInt):
  ZSTD_DDict; inline;
function ZSTD_freeDDict(CDict:ZSTD_DDict):NativeInt; inline;
function ZSTD_decompress_usingDDict(dctx:ZSTD_DCtx; dst:Pointer;
  dstCapacity:NativeInt; src:Pointer; srcSize:NativeInt; ddict:ZSTD_DDict):
  NativeInt; inline;
function ZSTD_getDictID_fromDict(const dict:Pointer; dictSize:NativeInt):
  Cardinal; inline;
function ZSTD_getDictID_fromDDict(const dict:ZSTD_DDict; dictSize:NativeInt):
  Cardinal; inline;
function ZSTD_getDictID_fromFrame(const src:Pointer; srcSize:NativeInt):Cardinal;
  inline;
function ZSTD_CCtx_loadDictionary(cctx:ZSTD_CCtx; const dict:Pointer;
  dictSize:NativeInt):NativeInt; inline;
function ZSTD_CCtx_refCDict(cctx:ZSTD_CCtx; const cdict:ZSTD_CDict):NativeInt;
  inline;
function ZSTD_CCtx_refPrefix(cctx:ZSTD_CCtx; const prefix:Pointer;
  prefixSize:NativeInt):NativeInt; inline;
function ZSTD_DCtx_loadDictionary(dctx:ZSTD_DCtx; const dict:Pointer;
  dictSize:NativeInt):NativeInt; inline;
function ZSTD_DCtx_refDDict(dctx:ZSTD_DCtx; const ddict:ZSTD_DDict):NativeInt;
  inline;
function ZSTD_DCtx_refPrefix(dctx:ZSTD_DCtx; const prefix:Pointer;
  prefixSize:NativeInt):NativeInt; inline;
function ZSTD_sizeof_CCtx(const cctx:ZSTD_CCtx):NativeInt; inline;
function ZSTD_sizeof_DCtx(const dctx:ZSTD_DCtx):NativeInt; inline;
function ZSTD_sizeof_CStream(const zcs:ZSTD_CStream):NativeInt; inline;
function ZSTD_sizeof_DStream(const zds:ZSTD_DStream):NativeInt; inline;
function ZSTD_sizeof_CDict(const cdict:ZSTD_CDict):NativeInt; inline;
function ZSTD_sizeof_DDict(const ddict:ZSTD_DDict):NativeInt; inline;

function _ZSTD_versionNumber:Cardinal; cdecl; external;
function _ZSTD_versionString:PAnsiChar; cdecl; external;
function _ZSTD_compress(dst:Pointer; dstCapacity : NativeInt; src:Pointer;
  srcSize : NativeInt; compressionLevel : integer):NativeInt; cdecl; external;
function _ZSTD_decompress(dst:Pointer; dstCapacity:NativeInt; src:Pointer;
  compressedSize:NativeInt):NativeInt; cdecl; external;
function _ZSTD_getFrameContentSize(const src:Pointer; srcsize:NativeInt):UInt64;
  cdecl; external;
function _ZSTD_getDecompressedSize(const src:Pointer; srcSize:NativeInt):UInt64;
  cdecl; external;
function _ZSTD_findFrameCompressedSize(const src:Pointer; srcSize:NativeInt):
  NativeInt; cdecl; external;
function _ZSTD_COMPRESSBOUND(srcSize:NativeInt):NativeInt; cdecl; external;
function _ZSTD_isError(code : NativeInt):Cardinal; cdecl; external;
function _ZSTD_getErrorName(code : NativeInt):PAnsiChar; cdecl; external;
function _ZSTD_minCLevel:integer; cdecl; external;
function _ZSTD_maxCLevel:integer; cdecl; external;
function _ZSTD_createCCtx:ZSTD_CCtx; cdecl; external;
function _ZSTD_freeCCtx(cctx: ZSTD_CCtx):NativeInt; cdecl; external;
function _ZSTD_compressCCtx(cctx:ZSTD_CCtx; dst:Pointer; dstCapacity:NativeInt;
  src:Pointer; srcSize:NativeInt; compressionLevel:integer):NativeInt; cdecl;
  external;
function _ZSTD_createDCtx:ZSTD_DCtx; cdecl; external;
function _ZSTD_freeDCtx(dctx: ZSTD_DCtx):NativeInt; cdecl; external;
function _ZSTD_decompressDCtx(dctx:ZSTD_CCtx; dst:Pointer; dstCapacity:NativeInt;
  src:Pointer; srcSize:NativeInt):NativeInt; cdecl; external;
function _ZSTD_cParam_getBounds(cParam : ZSTD_cParameter): ZSTD_bounds; cdecl; external;
function _ZSTD_CCtx_setParameter(cctx : ZSTD_CCtx; param:ZSTD_cParameter;
  value : integer):NativeInt; cdecl; external;
function _ZSTD_CCtx_setPledgedSrcSize(cctx : ZSTD_CCtx; pledgedScrSize:Uint64)
  :NativeInt; cdecl; external;
function _ZSTD_CCtx_reset(cctx:ZSTD_CCtx; reset: ZSTD_ResetDirective):NativeInt;
  cdecl; external;
function _ZSTD_compress2(cctx:ZSTD_CCtx; dst:Pointer; dstCapacity:NativeInt;
  src:Pointer; srcSize:NativeInt):NativeInt; cdecl; external;
function _ZSTD_dParam_getBounds(dParam : ZSTD_dParameter):ZSTD_bounds; cdecl; external;
function _ZSTD_DCtx_setParameter(dctx:ZSTD_DCTx; param: ZSTD_dParameter;
  value : integer):NativeInt; cdecl; external;
function _ZSTD_DCtx_reset(dctx:ZSTD_DCtx; reset:ZSTD_ResetDirective):NativeInt;
  cdecl; external;
function _ZSTD_createCStream: ZSTD_CStream; cdecl; external;
function _ZSTD_freeCStream(zsc : ZSTD_CStream):NativeInt; cdecl; external;
function _ZSTD_compressStream2(cctx:ZSTD_CCtx; var output:ZSTD_outBuffer;
  var input:ZSTD_inBuffer; endOp:ZSTD_EndDirective):NativeInt; cdecl; external;
function _ZSTD_CStreamInSize:NativeInt; cdecl; external;
function _ZSTD_CStreamOutSize:NativeInt; cdecl; external;
function _ZSTD_initCStream(zcs:ZSTD_CStream; compressionLevel:integer):NativeInt;
  cdecl; external;
function _ZSTD_compressStream(zcs:ZSTD_CStream; var output:ZSTD_outBuffer;
  var input:ZSTD_inBuffer):NativeInt; cdecl; external;
function _ZSTD_flushStream(zcs:ZSTD_CStream; var output:ZSTD_outBuffer):NativeInt;
  cdecl; external;
function _ZSTD_endStream(zcs:ZSTD_CStream; var output:ZSTD_outBuffer):NativeInt;
  cdecl; external;
function _ZSTD_createDStream: ZSTD_DStream; cdecl; external;
function _ZSTD_freeDStream(zds : ZSTD_DStream):NativeInt; cdecl; external;
function _ZSTD_initDStream(zds : ZSTD_DStream):NativeInt; cdecl; external;
function _ZSTD_decompressStream(zds:ZSTD_DStream; var output:ZSTD_outBuffer;
  var input:ZSTD_inBuffer):NativeInt; cdecl; external;
function _ZSTD_DStreamInSize:NativeInt; cdecl; external;
function _ZSTD_DStreamOutSize:NativeInt; cdecl; external;
function _ZSTD_compress_usingDict(ctx:ZSTD_CCtx; dst:Pointer;
  dstCapacity:NativeInt; src:Pointer; srcSize:NativeInt; dict:Pointer;
  dictSize:NativeInt; compressionLevel:integer):NativeInt; cdecl; external;
function _ZSTD_decompress_usingDict(dctx:ZSTD_DCtx; dst:Pointer;
  dstCapacity:NativeInt; src:Pointer; srcSize:NativeInt; dict:Pointer;
  dictSize:NativeInt):NativeInt; cdecl; external;
function _ZSTD_createCDict(const dictBuffer:Pointer; dictSize:NativeInt;
  compressionLevel:integer):ZSTD_CDict; cdecl; external;
function _ZSTD_freeCDict(CDict:ZSTD_CDict):NativeInt; cdecl; external;
function _ZSTD_compress_usingCDict(cctx:ZSTD_CCtx; dst:Pointer;
  dstCapacity:NativeInt; src:Pointer; srcSize:NativeInt; cdict:ZSTD_CDict):
  NativeInt; cdecl; external;
function _ZSTD_createDDict(const dictBuffer:Pointer; dictSize:NativeInt):
  ZSTD_DDict; cdecl; external;
function _ZSTD_freeDDict(CDict:ZSTD_DDict):NativeInt; cdecl; external;
function _ZSTD_decompress_usingDDict(dctx:ZSTD_DCtx; dst:Pointer;
  dstCapacity:NativeInt; src:Pointer; srcSize:NativeInt; ddict:ZSTD_DDict):
  NativeInt; cdecl; external;
function _ZSTD_getDictID_fromDict(const dict:Pointer; dictSize:NativeInt):
  Cardinal; cdecl; external;
function _ZSTD_getDictID_fromDDict(const dict:ZSTD_DDict; dictSize:NativeInt):
  Cardinal; cdecl; external;
function _ZSTD_getDictID_fromFrame(const src:Pointer; srcSize:NativeInt):Cardinal;
  cdecl; external;
function _ZSTD_CCtx_loadDictionary(cctx:ZSTD_CCtx; const dict:Pointer;
  dictSize:NativeInt):NativeInt; cdecl; external;
function _ZSTD_CCtx_refCDict(cctx:ZSTD_CCtx; const cdict:ZSTD_CDict):NativeInt;
  cdecl; external;
function _ZSTD_CCtx_refPrefix(cctx:ZSTD_CCtx; const prefix:Pointer;
  prefixSize:NativeInt):NativeInt; cdecl; external;
function _ZSTD_DCtx_loadDictionary(dctx:ZSTD_DCtx; const dict:Pointer;
  dictSize:NativeInt):NativeInt; cdecl; external;
function _ZSTD_DCtx_refDDict(dctx:ZSTD_DCtx; const ddict:ZSTD_DDict):NativeInt;
  cdecl; external;
function _ZSTD_DCtx_refPrefix(dctx:ZSTD_DCtx; const prefix:Pointer;
  prefixSize:NativeInt):NativeInt; cdecl; external;
function _ZSTD_sizeof_CCtx(const cctx:ZSTD_CCtx):NativeInt; cdecl; external;
function _ZSTD_sizeof_DCtx(const dctx:ZSTD_DCtx):NativeInt; cdecl; external;
function _ZSTD_sizeof_CStream(const zcs:ZSTD_CStream):NativeInt; cdecl; external;
function _ZSTD_sizeof_DStream(const zds:ZSTD_DStream):NativeInt; cdecl; external;
function _ZSTD_sizeof_CDict(const cdict:ZSTD_CDict):NativeInt; cdecl; external;
function _ZSTD_sizeof_DDict(const ddict:ZSTD_DDict):NativeInt; cdecl; external;
{$ELSEIF DEFINED(WIN64)}
//ZSTDLIB_API unsigned ZSTD_versionNumber(void);
function ZSTD_versionNumber:Cardinal; external;
function ZSTD_versionString:PAnsiChar; external;
function ZSTD_compress(dst:Pointer; dstCapacity : NativeInt; src:Pointer;
  srcSize : NativeInt; compressionLevel : integer):NativeInt; external;
function ZSTD_decompress(dst:Pointer; dstCapacity:NativeInt; src:Pointer;
  compressedSize:NativeInt):NativeInt; external;
function ZSTD_getFrameContentSize(const src:Pointer; srcsize:NativeInt):UInt64;
  external;
function ZSTD_getDecompressedSize(const src:Pointer; srcSize:NativeInt):UInt64;
  external;
function ZSTD_findFrameCompressedSize(const src:Pointer; srcSize:NativeInt):
  NativeInt; external;
function ZSTD_COMPRESSBOUND(srcSize:NativeInt):NativeInt; external;
function ZSTD_isError(code : NativeInt):Cardinal; external;
function ZSTD_getErrorName(code : NativeInt):PAnsiChar; external;
function ZSTD_minCLevel:integer; external;
function ZSTD_maxCLevel:integer; external;
function ZSTD_createCCtx:ZSTD_CCtx; external;
function ZSTD_freeCCtx(cctx: ZSTD_CCtx):NativeInt; external;
function ZSTD_compressCCtx(cctx:ZSTD_CCtx; dst:Pointer; dstCapacity:NativeInt;
  src:Pointer; srcSize:NativeInt; compressionLevel:integer):NativeInt; external;
function ZSTD_createDCtx:ZSTD_DCtx; external;
function ZSTD_freeDCtx(dctx: ZSTD_DCtx):NativeInt; external;
function ZSTD_decompressDCtx(dctx:ZSTD_CCtx; dst:Pointer; dstCapacity:NativeInt;
  src:Pointer; srcSize:NativeInt):NativeInt; external;
function ZSTD_cParam_getBounds(cParam : ZSTD_cParameter): ZSTD_bounds; external;
function ZSTD_CCtx_setParameter(cctx : ZSTD_CCtx; param:ZSTD_cParameter;
  value : integer):NativeInt; external;
function ZSTD_CCtx_setPledgedSrcSize(cctx : ZSTD_CCtx; pledgedScrSize:Uint64)
  :NativeInt; external;
function ZSTD_CCtx_reset(cctx:ZSTD_CCtx; reset: ZSTD_ResetDirective):NativeInt;
  external;
function ZSTD_compress2(cctx:ZSTD_CCtx; dst:Pointer; dstCapacity:NativeInt;
  src:Pointer; srcSize:NativeInt):NativeInt; external;
function ZSTD_dParam_getBounds(dParam : ZSTD_dParameter):ZSTD_bounds; external;
function ZSTD_DCtx_setParameter(dctx:ZSTD_DCTx; param: ZSTD_dParameter;
  value : integer):NativeInt; external;
function ZSTD_DCtx_reset(dctx:ZSTD_DCtx; reset:ZSTD_ResetDirective):NativeInt;
  external;
function ZSTD_createCStream: ZSTD_CStream; external;
function ZSTD_freeCStream(zsc : ZSTD_CStream):NativeInt; external;
function ZSTD_compressStream2(cctx:ZSTD_CCtx; var output:ZSTD_outBuffer;
  var input:ZSTD_inBuffer; endOp:ZSTD_EndDirective):NativeInt; external;
function ZSTD_CStreamInSize:NativeInt; external;
function ZSTD_CStreamOutSize:NativeInt; external;
function ZSTD_initCStream(zcs:ZSTD_CStream; compressionLevel:integer):NativeInt;
  external;
function ZSTD_compressStream(zcs:ZSTD_CStream; var output:ZSTD_outBuffer;
  var input:ZSTD_inBuffer):NativeInt; external;
function ZSTD_flushStream(zcs:ZSTD_CStream; var output:ZSTD_outBuffer):NativeInt;
  external;
function ZSTD_endStream(zcs:ZSTD_CStream; var output:ZSTD_outBuffer):NativeInt;
  external;
function ZSTD_createDStream: ZSTD_DStream; external;
function ZSTD_freeDStream(zds : ZSTD_DStream):NativeInt; external;
function ZSTD_initDStream(zds : ZSTD_DStream):NativeInt; external;
function ZSTD_decompressStream(zds:ZSTD_DStream; var output:ZSTD_outBuffer;
  var input:ZSTD_inBuffer):NativeInt; external;
function ZSTD_DStreamInSize:NativeInt; external;
function ZSTD_DStreamOutSize:NativeInt; external;
function ZSTD_compress_usingDict(ctx:ZSTD_CCtx; dst:Pointer;
  dstCapacity:NativeInt; src:Pointer; srcSize:NativeInt; dict:Pointer;
  dictSize:NativeInt; compressionLevel:integer):NativeInt; external;
function ZSTD_decompress_usingDict(dctx:ZSTD_DCtx; dst:Pointer;
  dstCapacity:NativeInt; src:Pointer; srcSize:NativeInt; dict:Pointer;
  dictSize:NativeInt):NativeInt; external;
function ZSTD_createCDict(const dictBuffer:Pointer; dictSize:NativeInt;
  compressionLevel:integer):ZSTD_CDict; external;
function ZSTD_freeCDict(CDict:ZSTD_CDict):NativeInt; external;
function ZSTD_compress_usingCDict(cctx:ZSTD_CCtx; dst:Pointer;
  dstCapacity:NativeInt; src:Pointer; srcSize:NativeInt; cdict:ZSTD_CDict):
  NativeInt; external;
function ZSTD_createDDict(const dictBuffer:Pointer; dictSize:NativeInt):
  ZSTD_DDict; external;
function ZSTD_freeDDict(CDict:ZSTD_DDict):NativeInt; external;
function ZSTD_decompress_usingDDict(dctx:ZSTD_DCtx; dst:Pointer;
  dstCapacity:NativeInt; src:Pointer; srcSize:NativeInt; ddict:ZSTD_DDict):
  NativeInt; external;
function ZSTD_getDictID_fromDict(const dict:Pointer; dictSize:NativeInt):
  Cardinal; external;
function ZSTD_getDictID_fromDDict(const dict:ZSTD_DDict; dictSize:NativeInt):
  Cardinal; external;
function ZSTD_getDictID_fromFrame(const src:Pointer; srcSize:NativeInt):Cardinal;
  external;
function ZSTD_CCtx_loadDictionary(cctx:ZSTD_CCtx; const dict:Pointer;
  dictSize:NativeInt):NativeInt; external;
function ZSTD_CCtx_refCDict(cctx:ZSTD_CCtx; const cdict:ZSTD_CDict):NativeInt;
  external;
function ZSTD_CCtx_refPrefix(cctx:ZSTD_CCtx; const prefix:Pointer;
  prefixSize:NativeInt):NativeInt; external;
function ZSTD_DCtx_loadDictionary(dctx:ZSTD_DCtx; const dict:Pointer;
  dictSize:NativeInt):NativeInt; external;
function ZSTD_DCtx_refDDict(dctx:ZSTD_DCtx; const ddict:ZSTD_DDict):NativeInt;
  external;
function ZSTD_DCtx_refPrefix(dctx:ZSTD_DCtx; const prefix:Pointer;
  prefixSize:NativeInt):NativeInt; external;
function ZSTD_sizeof_CCtx(const cctx:ZSTD_CCtx):NativeInt; external;
function ZSTD_sizeof_DCtx(const dctx:ZSTD_DCtx):NativeInt; external;
function ZSTD_sizeof_CStream(const zcs:ZSTD_CStream):NativeInt; external;
function ZSTD_sizeof_DStream(const zds:ZSTD_DStream):NativeInt; external;
function ZSTD_sizeof_CDict(const cdict:ZSTD_CDict):NativeInt; external;
function ZSTD_sizeof_DDict(const ddict:ZSTD_DDict):NativeInt; external;
{$ELSE}
function ZSTD_versionNumber:Cardinal; external 'libzstd.a';
function ZSTD_versionString:PAnsiChar; external 'libzstd.a';
function ZSTD_compress(dst:Pointer; dstCapacity : NativeInt; src:Pointer;
  srcSize : NativeInt; compressionLevel : integer):NativeInt; external 'libzstd.a';
function ZSTD_decompress(dst:Pointer; dstCapacity:NativeInt; src:Pointer;
  compressedSize:NativeInt):NativeInt; external 'libzstd.a';
function ZSTD_getFrameContentSize(const src:Pointer; srcsize:NativeInt):UInt64;
  external 'libzstd.a';
function ZSTD_getDecompressedSize(const src:Pointer; srcSize:NativeInt):UInt64;
  external 'libzstd.a';
function ZSTD_findFrameCompressedSize(const src:Pointer; srcSize:NativeInt):
  NativeInt; external 'libzstd.a';
function ZSTD_compressBound(srcSize:NativeInt):NativeInt; external 'libzstd.a';
function ZSTD_isError(code : NativeInt):Cardinal; external 'libzstd.a';
function ZSTD_getErrorName(code : NativeInt):PAnsiChar; external 'libzstd.a';
function ZSTD_minCLevel:integer; external 'libzstd.a';
function ZSTD_maxCLevel:integer; external 'libzstd.a';
function ZSTD_createCCtx:ZSTD_CCtx; external 'libzstd.a';
function ZSTD_freeCCtx(cctx: ZSTD_CCtx):NativeInt; external 'libzstd.a';
function ZSTD_compressCCtx(cctx:ZSTD_CCtx; dst:Pointer; dstCapacity:NativeInt;
  src:Pointer; srcSize:NativeInt; compressionLevel:integer):NativeInt; external 'libzstd.a';
function ZSTD_createDCtx:ZSTD_DCtx; external 'libzstd.a';
function ZSTD_freeDCtx(dctx: ZSTD_DCtx):NativeInt; external 'libzstd.a';
function ZSTD_decompressDCtx(dctx:ZSTD_CCtx; dst:Pointer; dstCapacity:NativeInt;
  src:Pointer; srcSize:NativeInt):NativeInt; external 'libzstd.a';
function ZSTD_cParam_getBounds(cParam : ZSTD_cParameter): ZSTD_bounds; external 'libzstd.a';
function ZSTD_CCtx_setParameter(cctx : ZSTD_CCtx; param:ZSTD_cParameter;
  value : integer):NativeInt; external 'libzstd.a';
function ZSTD_CCtx_setPledgedSrcSize(cctx : ZSTD_CCtx; pledgedScrSize:Uint64)
  :NativeInt; external 'libzstd.a';
function ZSTD_CCtx_reset(cctx:ZSTD_CCtx; reset: ZSTD_ResetDirective):NativeInt;
  external 'libzstd.a';
function ZSTD_compress2(cctx:ZSTD_CCtx; dst:Pointer; dstCapacity:NativeInt;
  src:Pointer; srcSize:NativeInt):NativeInt; external 'libzstd.a';
function ZSTD_dParam_getBounds(dParam : ZSTD_dParameter):ZSTD_bounds; external 'libzstd.a';
function ZSTD_DCtx_setParameter(dctx:ZSTD_DCTx; param: ZSTD_dParameter;
  value : integer):NativeInt; external 'libzstd.a';
function ZSTD_DCtx_reset(dctx:ZSTD_DCtx; reset:ZSTD_ResetDirective):NativeInt;
  external 'libzstd.a';
function ZSTD_createCStream: ZSTD_CStream; external 'libzstd.a';
function ZSTD_freeCStream(zsc : ZSTD_CStream):NativeInt; external 'libzstd.a';
function ZSTD_compressStream2(cctx:ZSTD_CCtx; var output:ZSTD_outBuffer;
  var input:ZSTD_inBuffer; endOp:ZSTD_EndDirective):NativeInt; external 'libzstd.a';
function ZSTD_CStreamInSize:NativeInt; external 'libzstd.a';
function ZSTD_CStreamOutSize:NativeInt; external 'libzstd.a';
function ZSTD_initCStream(zcs:ZSTD_CStream; compressionLevel:integer):NativeInt;
  external 'libzstd.a';
function ZSTD_compressStream(zcs:ZSTD_CStream; var output:ZSTD_outBuffer;
  var input:ZSTD_inBuffer):NativeInt; external 'libzstd.a';
function ZSTD_flushStream(zcs:ZSTD_CStream; var output:ZSTD_outBuffer):NativeInt;
  external 'libzstd.a';
function ZSTD_endStream(zcs:ZSTD_CStream; var output:ZSTD_outBuffer):NativeInt;
  external 'libzstd.a';
function ZSTD_createDStream: ZSTD_DStream; external 'libzstd.a';
function ZSTD_freeDStream(zds : ZSTD_DStream):NativeInt; external 'libzstd.a';
function ZSTD_initDStream(zds : ZSTD_DStream):NativeInt; external 'libzstd.a';
function ZSTD_decompressStream(zds:ZSTD_DStream; var output:ZSTD_outBuffer;
  var input:ZSTD_inBuffer):NativeInt; external 'libzstd.a';
function ZSTD_DStreamInSize:NativeInt; external 'libzstd.a';
function ZSTD_DStreamOutSize:NativeInt; external 'libzstd.a';
function ZSTD_compress_usingDict(ctx:ZSTD_CCtx; dst:Pointer;
  dstCapacity:NativeInt; src:Pointer; srcSize:NativeInt; dict:Pointer;
  dictSize:NativeInt; compressionLevel:integer):NativeInt; external 'libzstd.a';
function ZSTD_decompress_usingDict(dctx:ZSTD_DCtx; dst:Pointer;
  dstCapacity:NativeInt; src:Pointer; srcSize:NativeInt; dict:Pointer;
  dictSize:NativeInt):NativeInt; external 'libzstd.a';
function ZSTD_createCDict(const dictBuffer:Pointer; dictSize:NativeInt;
  compressionLevel:integer):ZSTD_CDict; external 'libzstd.a';
function ZSTD_freeCDict(CDict:ZSTD_CDict):NativeInt; external 'libzstd.a';
function ZSTD_compress_usingCDict(cctx:ZSTD_CCtx; dst:Pointer;
  dstCapacity:NativeInt; src:Pointer; srcSize:NativeInt; cdict:ZSTD_CDict):
  NativeInt; external 'libzstd.a';
function ZSTD_createDDict(const dictBuffer:Pointer; dictSize:NativeInt):
  ZSTD_DDict; external 'libzstd.a';
function ZSTD_freeDDict(CDict:ZSTD_DDict):NativeInt; external 'libzstd.a';
function ZSTD_decompress_usingDDict(dctx:ZSTD_DCtx; dst:Pointer;
  dstCapacity:NativeInt; src:Pointer; srcSize:NativeInt; ddict:ZSTD_DDict):
  NativeInt; external 'libzstd.a';
function ZSTD_getDictID_fromDict(const dict:Pointer; dictSize:NativeInt):
  Cardinal; external 'libzstd.a';
function ZSTD_getDictID_fromDDict(const dict:ZSTD_DDict; dictSize:NativeInt):
  Cardinal; external 'libzstd.a';
function ZSTD_getDictID_fromFrame(const src:Pointer; srcSize:NativeInt):Cardinal;
  external 'libzstd.a';
function ZSTD_CCtx_loadDictionary(cctx:ZSTD_CCtx; const dict:Pointer;
  dictSize:NativeInt):NativeInt; external 'libzstd.a';
function ZSTD_CCtx_refCDict(cctx:ZSTD_CCtx; const cdict:ZSTD_CDict):NativeInt;
  external 'libzstd.a';
function ZSTD_CCtx_refPrefix(cctx:ZSTD_CCtx; const prefix:Pointer;
  prefixSize:NativeInt):NativeInt; external 'libzstd.a';
function ZSTD_DCtx_loadDictionary(dctx:ZSTD_DCtx; const dict:Pointer;
  dictSize:NativeInt):NativeInt; external 'libzstd.a';
function ZSTD_DCtx_refDDict(dctx:ZSTD_DCtx; const ddict:ZSTD_DDict):NativeInt;
  external 'libzstd.a';
function ZSTD_DCtx_refPrefix(dctx:ZSTD_DCtx; const prefix:Pointer;
  prefixSize:NativeInt):NativeInt; external 'libzstd.a';
function ZSTD_sizeof_CCtx(const cctx:ZSTD_CCtx):NativeInt; external 'libzstd.a';
function ZSTD_sizeof_DCtx(const dctx:ZSTD_DCtx):NativeInt; external 'libzstd.a';
function ZSTD_sizeof_CStream(const zcs:ZSTD_CStream):NativeInt; external 'libzstd.a';
function ZSTD_sizeof_DStream(const zds:ZSTD_DStream):NativeInt; external 'libzstd.a';
function ZSTD_sizeof_CDict(const cdict:ZSTD_CDict):NativeInt; external 'libzstd.a';
function ZSTD_sizeof_DDict(const ddict:ZSTD_DDict):NativeInt; external 'libzstd.a';
{$ENDIF}
implementation
uses libc;
{$IFDEF WIN32}
{$L ZSTD148.X86.O}
function ZSTD_versionNumber:Cardinal; inline;
begin Result := _ZSTD_versionNumber; end;
function ZSTD_versionString:PAnsiChar; inline;
begin Result := _ZSTD_versionString; end;
function ZSTD_compress(dst:Pointer; dstCapacity : NativeInt; src:Pointer;
  srcSize : NativeInt; compressionLevel : integer):NativeInt; inline;
begin Result := _ZSTD_compress(dst,dstCapacity,src,srcSize,compressionLevel); end;
function ZSTD_decompress(dst:Pointer; dstCapacity:NativeInt; src:Pointer;
  compressedSize:NativeInt):NativeInt; inline;
begin Result:=_ZSTD_decompress(dst,dstCapacity,src,compressedSize);end;
function ZSTD_getFrameContentSize(const src:Pointer; srcsize:NativeInt):UInt64;
  inline;
begin Result:=_ZSTD_getFrameContentSize(src,srcSize);end;
function ZSTD_getDecompressedSize(const src:Pointer; srcSize:NativeInt):UInt64;
  inline;
begin Result:=_ZSTD_getDecompressedSize(src,srcSize);end;
function ZSTD_findFrameCompressedSize(const src:Pointer; srcSize:NativeInt):
  NativeInt; inline;
begin Result:=_ZSTD_findFrameCompressedSize(src,srcSize);end;
function ZSTD_COMPRESSBOUND(srcSize:NativeInt):NativeInt; inline;
begin Result:=_ZSTD_COMPRESSBOUND(srcSize);end;
function ZSTD_isError(code : NativeInt):Cardinal; inline;
begin Result := _ZSTD_isError(code);end;
function ZSTD_getErrorName(code : NativeInt):PAnsiChar; inline;
begin Result:=_ZSTD_getErrorName(code);end;
function ZSTD_minCLevel:integer; inline;
begin Result := _ZSTD_minCLevel; end;
function ZSTD_maxCLevel:integer; inline;
begin Result := _ZSTD_maxCLevel; end;
function ZSTD_createCCtx:ZSTD_CCtx; inline;
begin Result := _ZSTD_createCCtx; end;
function ZSTD_freeCCtx(cctx: ZSTD_CCtx):NativeInt; inline;
begin Result :=_ZSTD_freeCCtx(cctx); end;
function ZSTD_compressCCtx(cctx:ZSTD_CCtx; dst:Pointer; dstCapacity:NativeInt;
  src:Pointer; srcSize:NativeInt; compressionLevel:integer):NativeInt; inline;
begin Result:=_ZSTD_compressCCtx(cctx,dst,dstCapacity,src,srcSize,compressionLevel);end;
function ZSTD_createDCtx:ZSTD_DCtx; inline;
begin Result:=_ZSTD_createDCTX;end;
function ZSTD_freeDCtx(dctx: ZSTD_DCtx):NativeInt; inline;
begin Result := _ZSTD_freeDCtx(dctx);end;
function ZSTD_decompressDCtx(dctx:ZSTD_CCtx; dst:Pointer; dstCapacity:NativeInt;
  src:Pointer; srcSize:NativeInt):NativeInt; inline;
begin Result:=_ZSTD_decompressDCtx(dctx,dst,dstCapacity,src,srcSize);end;
function ZSTD_cParam_getBounds(cParam : ZSTD_cParameter): ZSTD_bounds; inline;
begin Result:=_ZSTD_cParam_getBounds(cParam);end;
function ZSTD_CCtx_setParameter(cctx : ZSTD_CCtx; param:ZSTD_cParameter;
  value : integer):NativeInt; inline;
begin Result:=_ZSTD_CCtx_setParameter(cctx,param,value);end;
function ZSTD_CCtx_setPledgedSrcSize(cctx : ZSTD_CCtx; pledgedScrSize:Uint64)
  :NativeInt; inline;
begin Result:=_ZSTD_CCtx_setPledgedSrcSize(cctx,pledgedScrSize);end;
function ZSTD_CCtx_reset(cctx:ZSTD_CCtx; reset: ZSTD_ResetDirective):NativeInt;
  inline;
begin Result:=_ZSTD_CCtx_reset(cctx,reset);end;
function ZSTD_compress2(cctx:ZSTD_CCtx; dst:Pointer; dstCapacity:NativeInt;
  src:Pointer; srcSize:NativeInt):NativeInt; inline;
begin Result:=_ZSTD_compress2(cctx,dst,dstCapacity,src,srcSize);end;
function ZSTD_dParam_getBounds(dParam : ZSTD_dParameter):ZSTD_bounds; inline;
begin Result:=_ZSTD_dParam_getBounds(dParam)end;
function ZSTD_DCtx_setParameter(dctx:ZSTD_DCTx; param: ZSTD_dParameter;
  value : integer):NativeInt; inline;
begin Result:=_ZSTD_DCtx_setParameter(dctx,param,value);end;
function ZSTD_DCtx_reset(dctx:ZSTD_DCtx; reset:ZSTD_ResetDirective):NativeInt;
  inline;
begin Result:=_ZSTD_DCtx_reset(dctx,reset);end;
function ZSTD_createCStream: ZSTD_CStream; inline;
begin Result:=_ZSTD_createCStream; end;
function ZSTD_freeCStream(zsc : ZSTD_CStream):NativeInt; inline;
begin Result := _ZSTD_freeCStream(zsc); end;
function ZSTD_compressStream2(cctx:ZSTD_CCtx; var output:ZSTD_outBuffer;
  var input:ZSTD_inBuffer; endOp:ZSTD_EndDirective):NativeInt; inline;
begin Result:=_ZSTD_compressStream2(cctx,output,input,endOp);end;
function ZSTD_CStreamInSize:NativeInt; inline;
begin Result:=_ZSTD_CStreamInSize;end;
function ZSTD_CStreamOutSize:NativeInt; inline;
begin Result := _ZSTD_CStreamOutSize; end;
function ZSTD_initCStream(zcs:ZSTD_CStream; compressionLevel:integer):NativeInt;
  inline;
begin Result := _ZSTD_initCStream(zcs,compressionLevel);end;
function ZSTD_compressStream(zcs:ZSTD_CStream; var output:ZSTD_outBuffer;
  var input:ZSTD_inBuffer):NativeInt; inline;
begin Result:=_ZSTD_compressStream(zcs,output,input);end;
function ZSTD_flushStream(zcs:ZSTD_CStream; var output:ZSTD_outBuffer):NativeInt;
  inline;
begin Result:= _ZSTD_flushStream(zcs,output);end;
function ZSTD_endStream(zcs:ZSTD_CStream; var output:ZSTD_outBuffer):NativeInt;
  inline;
begin Result:=_ZSTD_endStream(zcs,output);end;
function ZSTD_createDStream: ZSTD_DStream; inline;
begin  Result:=_ZSTD_createDStream;end;
function ZSTD_freeDStream(zds : ZSTD_DStream):NativeInt; inline;
begin Result:=_ZSTD_freeDStream(zds);end;
function ZSTD_initDStream(zds : ZSTD_DStream):NativeInt; inline;
begin Result:=_ZSTD_initDStream(zds);end;
function ZSTD_decompressStream(zds:ZSTD_DStream; var output:ZSTD_outBuffer;
  var input:ZSTD_inBuffer):NativeInt; inline;
begin Result:=_ZSTD_decompressStream(zds,output,input);end;
function ZSTD_DStreamInSize:NativeInt; inline;
begin Result:=_ZSTD_DStreamInSize;end;
function ZSTD_DStreamOutSize:NativeInt; inline;
begin Result:=_ZSTD_DStreamOutSize;end;
function ZSTD_compress_usingDict(ctx:ZSTD_CCtx; dst:Pointer;
  dstCapacity:NativeInt; src:Pointer; srcSize:NativeInt; dict:Pointer;
  dictSize:NativeInt; compressionLevel:integer):NativeInt; inline;
begin Result:=_ZSTD_compress_usingDict(ctx,dst,dstCapacity,src,srcSize,dict,dictSize,compressionLevel);end;
function ZSTD_decompress_usingDict(dctx:ZSTD_DCtx; dst:Pointer;
  dstCapacity:NativeInt; src:Pointer; srcSize:NativeInt; dict:Pointer;
  dictSize:NativeInt):NativeInt; inline;
begin Result:=_ZSTD_decompress_usingDict(dctx,dst,dstCapacity,src,srcSize,dict,dictSize);end;
function ZSTD_createCDict(const dictBuffer:Pointer; dictSize:NativeInt;
  compressionLevel:integer):ZSTD_CDict; inline;
begin Result:=_ZSTD_createCDict(dictBuffer,dictSize,compressionLevel);end;
function ZSTD_freeCDict(CDict:ZSTD_CDict):NativeInt; inline;
begin Result:=_ZSTD_freeCDict(CDict);end;
function ZSTD_compress_usingCDict(cctx:ZSTD_CCtx; dst:Pointer;
  dstCapacity:NativeInt; src:Pointer; srcSize:NativeInt; cdict:ZSTD_CDict):
  NativeInt; inline;
begin Result:=_ZSTD_compress_usingCDict(cctx,dst,dstCapacity,src,srcSize,cdict);end;
function ZSTD_createDDict(const dictBuffer:Pointer; dictSize:NativeInt):
  ZSTD_DDict; inline;
begin Result:=_ZSTD_createDDict(dictBuffer,dictSize);end;
function ZSTD_freeDDict(CDict:ZSTD_DDict):NativeInt; inline;
begin Result:=_ZSTD_freeDDict(CDict);end;
function ZSTD_decompress_usingDDict(dctx:ZSTD_DCtx; dst:Pointer;
  dstCapacity:NativeInt; src:Pointer; srcSize:NativeInt; ddict:ZSTD_DDict):
  NativeInt; inline;
begin Result:=_ZSTD_decompress_usingDDict(dctx,dst,dstCapacity,src,srcSize,ddict);end;
function ZSTD_getDictID_fromDict(const dict:Pointer; dictSize:NativeInt):
  Cardinal; inline;
begin Result:=_ZSTD_getDictID_fromDict(dict,dictSize);end;
function ZSTD_getDictID_fromDDict(const dict:ZSTD_DDict; dictSize:NativeInt):
  Cardinal; inline;
begin Result:=_ZSTD_getDictID_fromDDict(dict,dictSize);end;
function ZSTD_getDictID_fromFrame(const src:Pointer; srcSize:NativeInt):Cardinal;
  inline;
begin Result:=_ZSTD_getDictID_fromFrame(src,srcSize);end;
function ZSTD_CCtx_loadDictionary(cctx:ZSTD_CCtx; const dict:Pointer;
  dictSize:NativeInt):NativeInt; inline;
begin Result:=_ZSTD_CCtx_loadDictionary(cctx,dict,dictSize);end;
function ZSTD_CCtx_refCDict(cctx:ZSTD_CCtx; const cdict:ZSTD_CDict):NativeInt;
  inline;
begin Result:=_ZSTD_CCtx_refCDict(cctx,cdict);end;
function ZSTD_CCtx_refPrefix(cctx:ZSTD_CCtx; const prefix:Pointer;
  prefixSize:NativeInt):NativeInt; inline;
begin Result:=_ZSTD_CCtx_refPrefix(cctx,prefix,prefixSize);end;
function ZSTD_DCtx_loadDictionary(dctx:ZSTD_DCtx; const dict:Pointer;
  dictSize:NativeInt):NativeInt; inline;
begin Result:=_ZSTD_DCtx_loadDictionary(dctx,dict,dictSize);end;
function ZSTD_DCtx_refDDict(dctx:ZSTD_DCtx; const ddict:ZSTD_DDict):NativeInt;
  inline;
begin Result:=_ZSTD_DCtx_refDDict(dctx,ddict);end;
function ZSTD_DCtx_refPrefix(dctx:ZSTD_DCtx; const prefix:Pointer;
  prefixSize:NativeInt):NativeInt; inline;
begin Result:=_ZSTD_DCtx_refPrefix(dctx,prefix,prefixSize);end;
function ZSTD_sizeof_CCtx(const cctx:ZSTD_CCtx):NativeInt; inline;
begin Result:=_ZSTD_sizeof_CCtx(cctx);end;
function ZSTD_sizeof_DCtx(const dctx:ZSTD_DCtx):NativeInt; inline;
begin Result:=_ZSTD_sizeof_DCtx(dctx);end;
function ZSTD_sizeof_CStream(const zcs:ZSTD_CStream):NativeInt; inline;
begin Result:=_ZSTD_sizeof_CStream(zcs);end;
function ZSTD_sizeof_DStream(const zds:ZSTD_DStream):NativeInt; inline;
begin Result:=_ZSTD_sizeof_DStream(zds);end;
function ZSTD_sizeof_CDict(const cdict:ZSTD_CDict):NativeInt; inline;
begin Result:=_ZSTD_sizeof_CDict(cdict);end;
function ZSTD_sizeof_DDict(const ddict:ZSTD_DDict):NativeInt; inline;
begin Result:=_ZSTD_sizeof_DDict(ddict);end;
{$ENDIF}
{$IFDEF WIN64}
{$L ZSTD148.X64.O}
{$ENDIF}
end.



