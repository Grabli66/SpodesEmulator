# Эмулятор СПОДЭС счетчика
# Физический уровень TCP/IP
# Канальный: HDLC, Wrapper

# Поднимает сокет сервер
# В зависимости от настроек канального уровня использует обработчик канального протокола
# Выделяет прикладной пакет
# Отдаёт на обработку
# Формирует ответ упаковывая прикладной пакет в канальный уровень
# Отправляет

import asyncdispatch, asyncnet
import std/strformat
import ireader
import iprotocol_processor
import protocol_processors/hdlc_protocol_processor as hpp

type
  # Тип протокола
  ProtocolType {.pure.} = enum
    Hdlc = 0,
    Wrapper = 1

const protocol = ProtocolType.Hdlc

# Читает HDLC фрейм формата: HDLC frame format type 3
proc readHdlcFrame(reader : IReader) : Future[seq[uint8]] {.async.} =
  # Байт начала пакета
  const flag = 0x7Eu8

  # Читает пока не найдёт начало пакета
  while (await reader.readUInt8()) != flag:
    discard

  # Читает формат фрейма, сенмантацию и длину пакета
  let formatSegAndLength = await reader.readUInt16(Endianness.bigEndian)  

  # Количество символов которое нужно удалить из длины
  const removeSymbolCount = 2
  # Длина фрейма
  let frameLength = int(formatSegAndLength and 0x7FFu16) - removeSymbolCount
  # Признак что пакет сегментирован
  let isSegmentation = (formatSegAndLength and 0x800u16) > 0
  
  let frameData = await reader.readArray(frameLength)

  # Читает флаг окончания пакета
  discard (await reader.readUInt8())  

  echo &"formatSegAndLength: {formatSegAndLength} frameLength: {frameLength} isSegmentation: {isSegmentation}"
  echo $frameData

# Обрабатывает клиента
proc processClient(client : AsyncSocket) {.async.} =
  # Освобождает клиента при выходе из функции
  defer: 
    try:
      client.close
    except:
      discard

  try:
    let reader = ireader.newReader(client)  
    when protocol == ProtocolType.Hdlc:
      let protorolProcessor = hpp.newHdlcProtocolProcessor()
      await protorolProcessor.processProtocol(reader)
        
  except EOFError:
    echo "Client disconnected"
  except CatchableError as ex:         
    echo ex.msg

# Запускает сервер
proc startServer() {.async.} =
  let socket = asyncnet.newAsyncSocket()
  socket.bindAddr(Port(26301))
  socket.listen()

  while true:    
    let client = await socket.accept()
    asyncCheck processClient(client)    

when isMainModule:
  waitFor startServer()
  