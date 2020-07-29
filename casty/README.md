casty
=====

Implementacion
=====

La arquitectura que plantea en primer lugar `casty` implica tener un proceso llamado `client` que se comunica con otro proceso llamado `proxy` que es un `proxy` del servidor de `shoutcast`, nuestro cliente multimedia (firefox, chrome, VLC) se comunica con el proceso _client_ para poder escuchar el _stream_.

![casty](https://gitlab.com/g.pasquale/sistemas-distribuidos/-/raw/master/casty/images/casty.png)

Un problema de la primera arquitectura propuesta es que solo puede un `client` por `proxy`. Para este problema el enunciado propone una solucion donde tenemos un modulo `dist` el cual se conecta al `server proxy` y acepta multiple conexiones de `clients` a los cuales reenvia todo lo que recibe de proxy.

![dist](https://gitlab.com/g.pasquale/sistemas-distribuidos/-/raw/master/casty/images/dist.png)

Pruebas
=====

Para levantar la aplicacion ejecutamos `test:direct().` donde crea el proceso _proxy_ y _dist_ con sus respectivos _clients_, con cualquier reproductor multimedia apuntando a los puertos `3001`, `3002`, `3003` se deberia poder escuchar el _stream_.

Conclusiones
=====

Pudimos observar y entender que la arquitectura propuesta sirve para poder disminuir la carga sobre el servidor de _shoutcast_ ya que al tener multiples clientes conectados a un dist en lugar de un servidor todos los clients pueden recibir el stream pero el servidor solo esta conectado a un _client_ (`dist`). 
Ademas pudimos comprender mejor como funcionan los binary y las binary notations en erlang.

Build
-----

    $ rebar3 compile