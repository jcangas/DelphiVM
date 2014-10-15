# BUGS

# FEATURES

## BrickSpec.dvm
-   imitar gemspec para shipping:
        Brick:Definition.new("D200") do |brick|
            brick.name        = "delphivm"
            brick.platforms   = ['Win32']
            brick.authors     = ["Jorge L. Cangas"]
            brick.email       = ["jorge.cangas@gmail.com"]
            brick.homepage    = "http://github.com/jcangas/delphivm"
            brick.summary     = %q{A Ruby gem to manage your multi-IDE delphi projects: build, genenrate docs, and any custom task you want}
            brick.description = %q{Easy way to invoke tasks for all your IDE versions from the command line}
            brick.licence   = 
            brick.src   =
            brick.bin   =
            brick.lib   =
            brick.res   =
            brick.test  =  
            brick.doc   =
            brick.samples     =
            brick.s.add_runtime_dependency "PureMVC", '>=1.6.3.1'
        end

# descargas centralizadas y no por proyecto:
-   en cada proyecto usar un vendor.optset o actualizar el search path
    en el regsitro del prpoyecto (Tool/library path) usando
    \$(DVM\bricks)-X.Y.Z-D150

# REFACTOR

## remove gemspec
## move vendor to spec dir
## extraer Configurable a nueva gem
