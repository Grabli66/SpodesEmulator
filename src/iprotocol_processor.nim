import asyncdispatch
import ireader

type
    # Интерфейс обработчика протокола
    # Занимается установкой связи и выделением пакетов
    IProtocolProcessor* = ref object
        # Обрабатывает запрос от клиента
        processProtocol:proc(reader:IReader):Future[void]

# Создаёт интерфейс обработчика протокола
proc createInterface*(
    processProtocol:proc(reader:IReader):Future[void]
) : IProtocolProcessor =
    return IProtocolProcessor(
        processProtocol:processProtocol
    )

# Обрабатывает запрос от клиента 
template processProtocol*(this:IProtocolProcessor, reader:IReader):Future[void] =
    this.processProtocol(reader)
    