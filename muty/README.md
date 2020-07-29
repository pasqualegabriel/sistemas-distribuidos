MUTY
=====

Implementación
============

**lock2**
- Lock_solicitante_id > Lock_receptor_id:
En caso del que el propio lock tenga prioridad se agrega la referencia (la cual vino en la _request_) del lock solicitante en la lista _waiting_ con el fin de esperar el _ok_ de este ultimo, ya que es necesario para entrar en la zona critica (ya que el lock receptor al tener prioridad deberia ingresar antes que el lock que recibio la request). Y el lock receptor vuelve a entrar en estado de espera.
- Lock_solicitante_id < Lock_receptor_id:
En caso de que el lock solicitante tenga mayor prioridad al lock receptor, es decir el id del lock solicitante es menor al id del lock receptor, le enviamos el _ok_ al solicitante ya que deberia continuar y tambien hacemos el pedido correspondiente al lock solicitante para entrar en la zona critica despues de el, enviando en ese mensaje una nueva referencia la cual se agrega a la lista de _refs_ necesarios para entrar en la seccion critica. Esta nueva referencia es necesaria ya que si no tenemos en cuenta el _ok_ del proceso al cual le dimos prioridad, podriamos llegar a acceder a la zona critica mientras este se ecuentra ahi.

**lock3** 
- Para el este lock implementamos una solucion que utiliza el algoritmo del reloj Lamport, entonces las acciones que realiza el lock incrementa el valor de tiempo del Lamport. Cada vez que un lock procesa un mensaje `take`, `ok` o `request` (en cualquiera de sus 3 estados: cuando quiero acceder, cuando estoy o cuando no necesita entar en la zona critica) el tiempo es incrementado.
Cuando un proceso que se encuentra en estado de espera para acceder a la zona critica recibe un pedido de otro lock para acceder, se comparan los tiempos de Lamport en los cuales cada uno quiso ingresar. En caso de que el solicitante haya hecho el pedido en un momento previo (tiempo de lamport menor al receptor) se procede con la misma logica que lock2 en el caso de proceso solicitante menor al receptor (Lock_solicitante_id < Lock_receptor_id). En caso contrario se agrega la referencia de la request a la lista _waiting_ y vuelve a entrar en estado waiting. <br>
Aclaraciones: 
- Todo lock que esta en estado _wait_ conoce dos relojes, el reloj de la ejecucion actual y el reloj del momento en cual busco acceder a la seccion critica, de esta forma podemos realizar la comparacion con las request entrantes.
- Hay un caso particular donde dos lock quieren entrar con el mismo momento, en ese caso la prioridad se determinara por el id, el de menor tendra la prioridad. Esta decicion fue nuestra porque este caso es muy raro pero se puede dar.

Dificultades
============

Nos costo darnos cuenta que (cuando dos workers quieren acceder a la zona critica) dos workers estaban en la zona critica al mismo tiempo si no mandamos un request al lock con mayor prioridad para que cuando salga de la zona mande un ok para podes eliminarlo de la lista de referencias.

Pruebas
============

Podemos observar los siguientes casos de prueba: `muty:start(<lock>, <sleep>, <work>)`. Donde _lock_ es el modulo a ejecutar, _sleep_ es la cantidad de tiempo a esperar para pedir tomar el lock y _work_ es la cantidad de tiempo que va a permacer en la zona critica.

Todas las pruebas tienen una duracion de 10 segundos.

### Lock 1

#### `muty:start(lock1, 100, 1000)`
* John  : 6 locks taken, average of 1178.9091666666668 ms, 0 deadlock
* Ringo : 7 locks taken, average of 1241.3734285714286 ms, 0 deadlock
* Paul  : 6 locks taken, average of 1431.2691666666667 ms, 0 deadlock
* George: 7 locks taken, average of 1008.5722857142857 ms, 0 deadlock

#### `muty:start(lock1, 1, 100)`
* John  : 0 locks taken, average of 0.0 ms, 3 deadlock
* Ringo : 0 locks taken, average of 0.0 ms, 3 deadlock
* Paul  : 0 locks taken, average of 0.0 ms, 3 deadlock
* George: 0 locks taken, average of 0.0 ms, 3 deadlock

### Lock 2

John  , Id: 1
Ringo , Id: 2
Paul  , Id: 3
George, Id: 4

#### `muty:start(lock2, 1000, 100)`
* John  : 17 locks taken, average of 6.297058823529412 ms, 0 deadlock
* Ringo : 15 locks taken, average of 13.114533333333332 ms, 0 deadlock
* Paul  : 14 locks taken, average of 12.563214285714286 ms, 0 deadlock
* George: 20 locks taken, average of 25.921950000000002 ms, 0 deadlock

#### `muty:start(lock2, 100, 1000)`
* John  : 12 locks taken, average of 409.1015 ms, 0 deadlock
* Ringo : 11 locks taken, average of 473.04209090909086 ms, 0 deadlock
* Paul  : 2 locks taken, average of 1106.9385 ms, 2 deadlock
* George: 2 locks taken, average of 1608.287 ms, 2 deadlock

#### `muty:start(lock2, 1000, 1000)`
* John  : 8 locks taken, average of 140.436625 ms, 0 deadlock
* Ringo : 9 locks taken, average of 197.43533333333335 ms, 0 deadlock
* Paul  : 5 locks taken, average of 808.628 ms, 0 deadlock
* George: 3 locks taken, average of 1363.9746666666667 ms, 1 deadlock

#### `muty:start(lock2, 100, 100)`
* John  : 73 locks taken, average of 36.559123287671234 ms, 0 deadlock
* Ringo : 61 locks taken, average of 56.90070491803279 ms, 0 deadlock
* Paul  : 43 locks taken, average of 126.72888372093023 ms, 0 deadlock
* George: 20 locks taken, average of 406.449 ms, 0 deadlock

### Lock 3

#### `muty:start(lock3, 1, 100)`
* John  : 50 locks taken, average of 160.10712 ms, 0 deadlock
* Ringo : 49 locks taken, average of 146.323 ms, 0 deadlock
* Paul  : 49 locks taken, average of 150.8662857142857 ms, 0 deadlock
* George: 49 locks taken, average of 152.7338775510204 ms, 0 deadlock

#### `muty:start(lock3, 100, 1000)`
* John  : 6 locks taken, average of 1177.9953333333333 ms, 0 deadlock
* Ringo : 7 locks taken, average of 1240.7241428571429 ms, 0 deadlock
* Paul  : 6 locks taken, average of 1430.3681666666666 ms, 0 deadlock
* George: 7 locks taken, average of 1008.0348571428572 ms, 0 deadlock

#### `muty:start(lock3, 1000, 1000)`
* John  : 5 locks taken, average of 826.3034 ms, 0 deadlock
* Ringo : 6 locks taken, average of 848.824 ms, 0 deadlock
* Paul  : 5 locks taken, average of 956.9618 ms, 0 deadlock
* George: 6 locks taken, average of 730.2028333333334 ms, 0 deadlock

Resultados
============

#### `lock1`
Podemos notar que cuando incrementamos el riesgo de un conflicto de lock (tiempo entre request para entrar en la seccion critica) al momento en que dos procesos quisieron entrar al mismo momento en la seccion critica observamos que caen en un deadlock ya que ambos nunca van a recibir el ok del otro

#### `lock2`
Observamos que a mayor tiempo de _work_ y menor tiempo de _sleep_, incrementa las chances de deadlock debido a que los locks con menor prioridad pierden reiteradas veces y no logran acceder al lock produciendo deadlocks. 
Tambien notamos que los tiempos de espera promedio para acceder al lock son muy desparejos.

#### `lock3`
Notamos que no se produce ningun deadlock, que no hay mas un worker en la zona critica al mismo tiempo y que los workers ya respetan el momento en que solicitaron entrar.
Con esta solucion notamos que los tiempos de espera promedio para acceder al lock son mas parejos.

Build
-----

    $ rebar3 compile
    or 
    $ c(gui), c(lock1), c(muty), c(worker), c(lock2), c(lock3), c(time), c(csv_gen).
