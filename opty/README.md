opty
=====

Implementación
===========
`server:start(N)` instancia un servidor, con N tuplas disponibles para guardar datos
y queda registrado bajo el nombre de `servidor` en el proceso. También, instancia un proceso contador que usamos para 
llevar registro de las transacciones que se pudieron commitear y de las que fueron abortadas.

`client:init(servidor, nombre_del_atomo_para_registrar_el_handler)` Inicializa el handler para un cliente con el cual 
va a poder realizar su transacción.

`client:open(servidor)` Inicializa el handler para un cliente e inmediatamente realiza operaciones random durante 1 
segundo o hasta commitear, lo que suceda primero.

`client:start_concurrent(N)` levanta N cantidad de procesos diferentes como clientes que realizan transacciones de 
forma random hasta commitear o hasta llegar a 1 segundo de transacciones (al llegar al segundo commitea las realizadas 
hasta ese momento), lo que suceda primero.

Un cliente puede realizar `read`, `write` donde van quedando almacenados en el handler que se inicializo.
Tambien cuenta con el metodo `commit` para finalizar la transacción y guardar los cambios realizados.
Ademas un cliente puede abortar su transacción en cualquier momento utilizando `client:abort(handler).`
y consultar el estado del `store` con los respectivos `read` y `write` realizados en la transacción con `client:state(handler)`.

Pruebas
============
* Para un servidor con 10 tuplas y con 10 clientes realizando transacciones de forma _random_ 4 de los clientes no pudieron commitear de forma exitosa sus transacciones.
* Para un servidor con 20 tuplas y con 20 clientes realizando transacciones de forma _random_ 3 de los clientes no pudieron commitear de forma exitosa sus transacciones.
* Para un servidor con 100 tuplas y 100 clientes realizando transacciones de forma _random_ 68 de los clientes no pudieron commitear de forma exitosa sus transacciones.


Todas estas pruebas las realizamos primero inicializando el servidor con `server:start(<cantidad_de_tuplas>)`, luego 
ejecutamos la función `client:start_concurrent(<canitdad_de_clientes>)` y luego de eso con `contador ! state` podemos 
ver en pantalla la cantidad de transacciones que fueron commiteadas y las que fueron abortadas.  
 
Resultados
============

Pudimos notar como la cantidad de fallos depende de:

* La cantidad de transacciones y el tipo: A mayor cantidad de escrituras entre lecturas es más probable caer en un error
 ante el commit.
* La cantidad de tuplas disponibles para guardar datos: A menor cantidad de tuplas es  mas probable que varios procesos 
intenten leer y escribir sobre la misma tupla, llevando a un fallo en el commit.
* La cantidad de tiempo que hay entre commits: Mientras mas transacciones realice un cliente antes de commitear, es mas probable que en el 
momento de commit otro proceso ya haya commiteado alguna lectura sobre una tupla leída. Tambien al estar mas tiempo 
realizando lecturas y escrituras random, aumenta la chance de intentar leer/esciribir la misma tupla que otro proceso.
