# BUGS

# FEATURES

## BrickDef
-   imitar gemspec para shipping:
        Brick:Definition.new("D200") do |brick|
            brick.import(...)
            brick.bin_files = 
            brick.test_files =
        end

# descargas centralizadas y no por proyecto:
-   en cada proyecto usar un vendor.optset o actualizar el search path
    en el regsitro del prpoyecto (Tool/library path) usando
    \$(DVM\bricks)-X.Y.Z-D150

# REFACTOR

## extraer Configurable a nueva gem




