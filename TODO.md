
# Templates
 Explorar la idea de sustituir el modelo de templates por scripts con un DSL:
 
 template "App", desc: "Genera un esqueleto de aplicación" do
   prj = Snippet.new(params[:ide_version], :name => "MyProject.dpr")
 
 end