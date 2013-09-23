
## Delphi Version Manager

### Install

 Download and copy on your local disk!. 
 
### Usage

```
		delphivm help  // show avaiable commands
		
		delphi help prj:make  // show usage for command prj:make

```

### Templates


```
delphivm gen:app TGSQL

```

Crea una carpeta TGSQL en el directorio donde se invoco el comando. la carpeta contiene un esqueleto de aplicación para el idd con todas la configuracion de compilación lista y soporte para múltiples  IDES y plataformas.


```

delphivm gen:app TGSQL  --no-samples --no-tests

```

Lo mismo que la anterior, pero no genera la estructura necesaria para proyectos de ejemplo ni tests unitarios. Se pueden generar a posteriori con

```
delphivm gen:samples Sample1

```

Genera la estructura para samples con un proyecto de ejemplo llamado Sample1

```

delphivm gen:tests Test1

```

Genera la estructura para tests con un proyecto de ejemplo llamado Test1

Adicionalemnte se pueden crear nuevos proyectos en la estructura:

```
delphivm gen:dproj Proyecto1 --template=src

delphivm gen:dproj Sample2  --template=sample 

delphivm gen:test Test2 --template=test

```


