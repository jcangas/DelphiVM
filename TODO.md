# BUGS

## Remove -deploy option from vendor command

## current ide
 Posibilidad de que se pueda lanzar delphivm desde uno de los sub-dir D190-XE5,
 y se autoconfigure el idetag pero funcione como si se estuviera en el 
 prj root (como ahora)

# FEATURES

## Templates
 Explorar la idea de sustituir el modelo de templates por scripts con un DSL:
 
 template "App", desc: "Genera un esqueleto de aplicación" do
   prj = Snippet.new(params[:ide_version], :name => "MyProject.dpr")
 
 end