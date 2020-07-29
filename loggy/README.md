LOGGY
=====

Aclaraciones
============

En la branch [master](https://gitlab.com/g.pasquale/sistemas-distribuidos/-/tree/master/loggy) esta la solucion usando el algoritmo Lamport y en la branch [vector](https://gitlab.com/g.pasquale/sistemas-distribuidos/-/tree/vector/loggy) se encuentra la solucion usando el algoritmo vetor clock.
El readme es el mismo para ambas soluciones y branch.

Implementación
============

Primero corrimos los test y vimos los logs para comprender el programa y cuales mensajes se estaban imprimiendo en un orden incorrecto.
Empezamos con una solucion con un solo contador numerico para el `time` y vimos enseguida que no era una buena solucion.
Luego implementamos el algoritmo Lamport utilizando una lista de tuplas donde contiene el nombre del atomo del worker y un contador numerico (Ej con 4 workers: `[{john,0}, {paul,0}, {ringo,0}, {george,0}]`). 
Para decidir si era seguro imprimir un mensaje o no, comparamos el tiempo del mensaje y si es menor a cada uno de los tiempos de la lista del `time`, consideramos que es seguro.
En el logger tenemos una cola de retención y el estado actual del `time` y cada vez que llega un evento `log` agregamos el mensaje a la cola de retencion, ordenamos dicha lista y imprimimos los mensajes que son seguros, el resto seguiran en la lista esperando el proximo evento. Al final en el `stop` ordenamos y imprimimos todos los mesajes de la lista de retencion. 
Para testiar y correr loggy usamos `test:run(Sleep, Jitter)` donde creamos el proceso de logging y cuatro workers, cuando los workers han sido creados les enviamos un mensaje con sus respectivos pares. 

Vector Clock
============

En la implementacion del vector clock solo modificamos `time` donde utilizamos un array de numeros (inicializados en 0) con el tamaño fijo de la cantidad de workers (Ej con 4 workers: `array:[0, 0, 0, 0]`).
Para decidir si era seguro imprimir un mensaje o no, comparamos cada tiempo del mensaje con cada y tiempo del array, y si todos los tiempos del `time` son mayores consideramos que es seguro.
El logger es el mismo y la manera de testiar y correr loggy es la misma (`test:run(Sleep, Jitter)`) salvo que ahora tenemos que especificar la posicion del worker y la cantidad total de workers.

Dificultades
============

Se nos complico poder definir cuando un mensaje es seguro de imprimir, estuvimos 2 horas pensando y probando hasta que llegamos a una solucion. Despues quedo mas claro de la solucion que hicimos cuando investigamos sobre el algoritmo Lamport. Con el algoritmo vector clock salio mas rapido.
Tambien no nos dimos cuenta de ordenar la cola de retención en el logger cuando imprime los mensajes en caso de ser seguros.

Pruebas
============

Podemos observar los siguientes casos de prueba: `test:run(<sleep>, <jitter>)`. Donde _sleep_ es la cantidad de tiempo 
entre mensajes aleatorios a otro worker y _jitter_ intervalo entre el envio del mensaje al worker y el pedido 
de impresion de ese mensaje al logger.

##### `test:run(100, 3)` 
* **Total de mensajes**: 112
* **Lamport** quedan 25 mensajes en la cola de retención
* **Vector clock** quedan 8 mensajes en la cola de retencion.

##### `test:run(10, 3)` 
* **Total de mensajes**: 721
* **Lamport** quedan 11 mensajes en la cola de retención
* **Vector clock** quedan 5 mensajes en la cola de retencion.

##### `test:run(300, 3)` 
* **Total de mensajes**: 43
* **Lamport** quedan 11 mensajes en la cola de retención
* **Vector clock** quedan 4 mensajes en la cola de retencion.

##### `test:run(1, 3)` 
* **Total de mensajes**: 1538
* **Lamport** quedan 13 mensajes en la cola de retención
* **Vector clock** quedan 5 mensajes en la cola de retencion.

Resultados
============

Pudimos notar que los mensajes se imprimen en el orden correcto y que con el algoritmo vector clock menos mensajes quedan retenidos en la cola de retención del logger (casi la mitad que utilizando la solucion con Lamport)

Build
-----

    $ rebar3 compile

    or

    $ c(loggy), c(worker), c(time), c(test).
