import asyncdispatch, asyncnet
import exceptions
import sequtils

# Таймаут по умолчанию
const defaultTimeoutMs = 10000

# Интерфейс для чтения данных из разных источников
type IReader* = ref object
  # Читает UInt8
  readUInt8:proc(timeoutMs:int):Future[uint8] {.async.}
  # Читает UInt16
  readUInt16:proc(endian:Endianness, timeoutMs:int):Future[uint16] {.async.}
  # Читает массив байт
  readArray:proc(length:int, timeoutMs:int):Future[seq[uint8]] {.async.}

# Читает строку с таймаутом
proc readArrayWithTimeout(ctx:AsyncSocket, length:int, timeoutMs:int) : Future[seq[uint8]] {.async.} =  
  let resFut = ctx.recv(length)
  let resTimeout = await resFut.withTimeout(timeoutMs)
  if not resTimeout:
      resFut.clearCallbacks()
      raise timeoutException

  let str = resFut.read
  if str.len < 1:
    raise disconnectedException

  return str.mapIt(uint8(ord(it)))


# Оборачивает в интерфейс асинхронный сокет
proc newReader*(ctx:AsyncSocket) : IReader =
  result = IReader(
    readUInt8: 
      proc(timeoutMs:int) : Future[uint8] {.async.} =        
        let lctx = ctx
        let str = await lctx.readArrayWithTimeout(1, timeoutMs)
        result = str[0]
    ,
    readUInt16:
      proc(endian:Endianness, timeoutMs:int):Future[uint16] {.async.} =
        let lctx = ctx
        let str = await lctx.readArrayWithTimeout(2, timeoutMs)        
        let b1 = if endian == Endianness.bigEndian: str[0] else: str[1]
        let b2 = if endian == Endianness.bigEndian: str[1] else: str[0]
        let res = uint16((b1 shl 8) + b2)
        return res
    ,
    readArray:
      proc(length:int, timeoutMs:int):Future[seq[uint8]] {.async.} =
        let lctx = ctx
        return await lctx.readArrayWithTimeout(length, timeoutMs)
  )

# Читает UInt8
template readUInt8*(this:IReader, timeoutMs=defaultTimeoutMs): Future[uint8] =
    this.readUInt8(timeoutMs)

# Читает UInt16
template readUInt16*(this:IReader, endian:Endianness, timeoutMs=defaultTimeoutMs): Future[uint16] =
    this.readUInt16(endian, timeoutMs)

template readArray*(this:IReader, length:int, timeoutMs=defaultTimeoutMs):Future[seq[uint8]] =
    this.readArray(length, timeoutMs)
    