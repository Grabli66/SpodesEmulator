# Ошибка разрыва связи
let disconnectedException* = newException(EOFError, "Client disconnected")
let timeoutException* = newException(IOError, "Timeout")