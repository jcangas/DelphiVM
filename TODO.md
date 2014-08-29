# BUGS


# FEATURES

## extraer Configurable a nueva gem
## Personalizacion de las tareas
- Usando configurable. Un fichero en el ROOT/dvm. Idea central:
    
        # Configuracion de la tarea Ship
        Ship.configure do |cfg|
            cfg.publish_to = "my_target_url"
        end

        # Configuracion de la tarea Project
        Project.configure do |prj|
            prj.on_build do |build|
                build.auto_inc_version = :patch
            end
            prj.opcion_x = bla,bla
        end
        
- Ademas de esto, la tarea debe tener suficiente granularidad en su métodos, para permitir reabrir la clase y redefinir su comportamiento, creando una tarea en el directorio ROOT/dvm del proyecto


## current ide

Posibilidad de que se pueda lanzar delphivm desde uno de los sub-dir
D190-XE5, y se autoconfigure el idetag pero funcione como si se
estuviera en el prj root (como ahora)


## Templates

Explorar la idea de sustituir el modelo de templates por scripts con un
DSL:

template "App", desc: "Genera un esqueleto de aplicación" do prj =
Snippet.new(params[:ide\_version], :name =\> "MyProject.dpr")

end

## Registry template

- reg copy hkcu\Software\Embarcadero\BDS\14.0 hkcu\Software\Embarcadero\DelphiVM\TGIPADSYNC\14.0 /s /f

## BricDef
-   imitar gemspec para shipping:
    
        Using "D200" do
          Brick:Definition.new do |def|
            def.import(...)
            def.bin_files = 
            def.test_files =

          end
        end
-   guardar las descargas centralizadas y no por proyecto

-   en cada proyecto usar un vendor.optset o actualizar el search path
    en el regsitro del prpoyecto (Tool/library path) usando
    \$(DVM\_STONES)-X.Y.Z-D150




