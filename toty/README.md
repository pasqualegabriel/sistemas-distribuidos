toty
=====

Implementacion
-----

Primero comenzamos armando un multicast basico, donde creamos workers con sus respectivos managers, y cada cierto tiempo _sleep_ envian mensajes notificando a su respectivo manager, y este se encarga de entregar el mensaje (con un retardo de _jitter_) al resto de los managers y entregarlos al worker.
Para poder asegurar el orden de los mensajes entregados, lo que tuvimos que agregar al manager es la logica para darles un orden a los mismos. Para eso se usan referencias de cada mensaje las cuales son dadas por cada manager al momento de enviarlo. El problema esta en poder lograr que todos los managers les pongan las mismas referencias a los mensajes a pesar del orden que llegan. Aca donde se agrega a su vez la logica para consensuar la referencia. Entonces cada vez que un manager recive un pedido para hacer multicast de un mensaje, este le envia a sus managers pares una request para poder enviar ese mensaje con una (referencia)[42 de toty], sus pares le responden con una propuesta, una vez recibidas todas las propuestas, el manager se queda con la mayor y le notifica a los pares (y a si mismo) cual fue el valor de referencia consensuado, con esto cada manager actualiza la propuesta de cada referencia, ordena su lista de mensajes segun la nueva referencia actualizada, pero los primeros mensajes que ya fueron actualizados con una referencia consensuada son entregados al worker. Manteniento el resto de los mensajes.

Pruebas
-----

Para realizar las pruebas ejecutamos `test:run(<workers>, <sleep>, <jitter>, <workTime>)`. Donde _workers_ es la cantidad de workers cun sus respectivos managers, _sleep_ es el tiempo de cuanto deben esperar los workers hasta el envío del siguiente mensaje, _jitter_ intervalo entre el envio de cada mensaje de un worker y _workTime_ es el tiempo que va a ejecutar el programa.
Cada mensaje recibido por un worker se envian a otro proceso el cual los acumula y los imprime al final de la ejecucion. 
Donde podemos ver una columna por cada mensaje recibido a un worker en orden. Cabe aclarar que solo se muestran los mensajes que fueron recibidos por todos los workers. Y al final se muestran la cantidad de mensajes totales con sus fallas.

##### `test:run(5, 100, 100, 10).` 
* **Total de mensajes**: 196
* **Fallas** 0

##### `test:run(25, 100, 100, 10).` 
* **Total de mensajes**: 195
* **Fallas** 0

##### `test:run(5, 1000, 1000, 10).` 
* **Total de mensajes**: 19
* **Fallas** 0

##### `test:run(25, 100, 100, 10).` 
* **Total de mensajes**: 19
* **Fallas** 0

Conclusiones
-----

En comparacion con la estrategia vista en groupy, esta forma de hacer multicas para garantizar el orden, distribuye de manera mas equitativa el trabajo de hacer el multicast, ya que no hay un solo nodo lider que se encarga de hacerlo sino que cada manager es el encargado de hacer el multicast del mensaje que recibio de su worker. Una ventaja de esto es que la cantidad de workers no afecta cuantos mensajes multicast podemos hacer por segundo, la cantidad de mensajes que podemos hacer por segundo varian unicamente por el _sleep_, _jitter_ y el _workTime_. Ademas, vemos que ataca un tipo de problema diferente ya que si bien asegura el orden de los mensajes, no asegura el sincronismo entre los nodos.

Build
-----

c(worker), c(gui), c(toty), c(test), c(show), c(seq).
test:run(5, 100, 100, 10).
