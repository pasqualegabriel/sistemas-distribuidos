detector
=====

Conclusiones
===========
Vimos que el monitor es una buena herramienta para controlar los casos de error en el proceso. El `monitor` tambien brinda informacion 
sobre porque se envio el mensaje `DOWN`, lo cual suponemos que puede ser util para identificar el tipo de fallo.Si bien nos es util  
para saber cuando
un proceso del cual depende nuestra aplicacion/proceso fallo, hay casos donde vemos que no es 100% confiable.
Por ejemplo, cuando desconectamos el `producer` la cantidad suficiente de tiempo para que el  `consumer` tire error por time out. El
`monitor` del `producer` envia un mensaje `DOWN` al `consumer`, pero si despues de esto el `producer` retoma la conexión el consumer puede seguir 
consuemiendo los mensajes de ping, con la particularidad de que se pierden varios de los mensajes.  
Build
-----

    $ rebar3 compile
