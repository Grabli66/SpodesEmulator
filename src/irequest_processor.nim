type
    # Интерфейс обработчика запросов
    IRequestProcessor* = ref object
        processRequest:proc():void