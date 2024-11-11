import asyncdispatch
import std/strformat
import print
import ../ireader
import ../iprotocol_processor as ipp

type
    # Фрейм HDLC
    HdlcFrame = ref object
        # Адрес получателя
        destAddress:int
        # Адрес отправителя
        sourceAddress:int
        # Признак что есть сегментация
        isSegmentation:bool
        # Поле Control
        controlField:int
        # Данные фрейма
        data:seq[uint8]

# Извлекает HDLC фрейм
proc extractHdlcFrame(reader:IReader) : Future[HdlcFrame] {.async.} =
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
    let frameLength = int(formatSegAndLength and 0x7FFu16)
    let dataLength = frameLength - removeSymbolCount
    # Признак что пакет сегментирован
    let isSegmentation = (formatSegAndLength and 0x800u16) > 0
    
    let frameData = await reader.readArray(dataLength)

    # Читает флаг окончания пакета
    discard (await reader.readUInt8())  
    
    return HdlcFrame(
        data:frameData
    )

# Обрабатывает пакеты протокола
proc processProtocol(reader:IReader) {.async.} =
    while true:
        let frame = await extractHdlcFrame(reader)
        print frame

# Возвращает обработчик протокола HDLC
proc newHdlcProtocolProcessor*():IProtocolProcessor =
    return ipp.createInterface(
        processProtocol
    )