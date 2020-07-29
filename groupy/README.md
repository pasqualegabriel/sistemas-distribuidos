groupy
=====

Comentarios
=============
* GMS3: Para llegar a solucionar el GMS3, la mayor complicación que tuvimos
fue entender en que momentos incrementar el _N_ esperado por los esclavos. Una vez 
que llegamos a comprender quien enviaba cada mensaje pudimos identificar los mensajes 
que solo eran enviados por el lider hacia el esclavo y solo incrementamos cuando esos 
mensajes son recibidos. Otra complicacion fue entender qué guardar como `Last`  en el slave, si solo el contenido del 
mensaje o exactamente lo ultimo que me llego. Un par de console.logs despues, quedo claro que era una copia de lo que 
habia llegado. Tambien, luego de varias pruebas fuimos encontrando que no teniamos en cuenta de sumar el `N` esperado 
cuando recibiamos mensajes desde la inicializacion.

Pruebas
===========
* GMS2: Cuando empezamos a considerar la posibilidad de tener fallos con el mensaje `bcast` que tenia una posibilidad 
de _crashear_ vimos que la solucion no era correcta. Si el nodo lider fallaba sin haber completado el _broadcast_ 
hacia todos sus nodos esclavos, aquellos que no recibieron el mensaje no quedaban actualizados con el estado correcto.
Además, al perder el nodo lider, aquellos que no recibieron el ultimo mensaje no van a recibir nunca ese mensaje.
* GMS3: Con las pruebas que hicimos con esta implementacion pudimos lograr que los esclavos que aun no habian recibido 
el ultimo mensaje que mando el lider lo reciban. Se agregaba la complejidad de no aceptar mensajes duplicados (cosa que 
en principio no teniamos en cuenta ya que nuestro estado eran colores y al estar duplicados no podiamos notar si acepto 
un mensaje duplicado). 

test.erl
===========
Para realizar las pruebas tenemos dos funciones que son `startLeader(Id, modulo)` que instancia un gms usando el modulo 
que se le pasa como argumento y lo establece como lider. Y un `startSlave(Id, modulo, NodoDeGrupo)` que instancia un 
gms usando el modulo que recibe como argumento y lo deja como esclavo pidiendo sumarse al grupo de broadcast enviando un 
`join` al nodo del grupo que recibe como argumento. Ambos, imprimern en pantalla el nodo del grupo que conocen, esto lo 
usamos para poder instanciar esclavos y su PID para poder usarlos como capa de aplicacion para enviar mensajes. Estas 
capas de aplicacion pueden responder y enviar un mensaje particular que es `{color, unColor}` este mensaje setea la GUI 
de cada nodo de capa de aplicacion con el color enviado (acepta: red, blue, yellow). Para pedir un broadcast de este 
mensaje se le puede enviar a la capa de aplicacion un mensaje `{send, Msg}`. Entonces si enviamos  `{send, {color, UnColor}}` 
va a realizar un broadcast a todos los miembros del grupo. De esta forma comprobamos el comprtamiendo correcto del gms.

Conclusiones
=============
Pudimos llegar a entender mejor como poder tener un estado sincronizado mediante la comunicación entre varios nodos y sus 
complicaciones. Tambien entendemos que esta solucion puede no llegar a ser 100% correcta ya que tenemos suposiciones que 
nos evitan problemas que existen en _la vida real_. Por ejemplo, asumimos que el `DOWN` solo se envia cuando un nodo 
realmente murio, cuando sabemos que en caso de perder la conexión momentaneamente tambien recibimos ese mensaje.
Tambien, asumimos que los nodos no fallan durante la vista, lo cual tranquilamente podria suceder y deberiamos tenerlo 
en cuenta.
 
Build
-----

    $ rebar3 compile

    c(test), c(gms1), c(gms2), c(gms3), c(gui).
