class Vendor < BuildTarget
   desc 'clean', 'clean vendor products', for: :clean
   desc 'make',  'make vendor products', for: :make
   desc 'build', 'build vendor products', for: :build
   method_option :group, type: :string, aliases: '-g',
                         default: configuration.build_args, desc: 'Use BuildGroup', for: :clean
   method_option :group,
                 type: :string,
                 aliases: '-g',
                 default: configuration.build_args,
                 desc: 'Use BuildGroup',
                 for: :make
   method_option :group,
                 type: :string,
                 aliases: '-g',
                 default: configuration.build_args,
                 desc: 'Use BuildGroup', for: :build

   desc 'init', 'create and initialize vendor directory'
   def init
     create_file(PRJ_IMPORTS_FILE, skip: true) do
       <<-EOS
      # sample imports file for delphivm

      # set source url
      source "my_imports_path"

      # can use environment vars anywhere
      # source "\#{ENV['IMPORTS_PATH']}"

      # set IDE version
      uses 'D150'

      # now, you can declare some imports

      import "FastReport", "4.13.1" do
        ide_install('dclfs15.bpl','dclfsADO15.bpl', 'dclfrxIBX15.bpl')
      end

      # or if we don't need ide install

      import "TurboPower", "7.0.0"

      # repeat for other sources and/or IDEs

      EOS
     end
   end

   desc 'import', 'download and install vendor imports'
   method_option :force, type: :boolean, aliases: '-f', default: false, desc: 'force download when already in local cache'
   method_option :reset, type: :boolean, aliases: '-r', default: false, desc: 'clean prj vendor before import'
   method_option :sym, type: :boolean, aliases: '-s', default: false, desc: 'use symlinks'
   def import
     say 'WARN: ensure your project folder supports symlinks!!' if options.sym?
     do_reset if options.reset?
     prepare
     silence_warnings { DSL.run_imports_dvm_script(PRJ_IMPORTS_FILE, options) }
   end

   desc 'reset', 'erase vendor imports.'
   def reset
     do_reset
     prepare
   end

   desc 'reg', 'IDE register vendor packages'
   def reg
     silence_warnings { DSL.register_imports_dvm_script(PRJ_IMPORTS_FILE) }
   end

   protected

   def do_clean(idetag, cfg)
     do_build_action(idetag, cfg, 'Clean')
   end

   def do_make(idetag, cfg)
     do_build_action(idetag, cfg, 'Make')
   end

   def do_build(idetag, cfg)
     do_build_action(idetag, cfg, 'Build')
     silence_warnings { DSL.register_imports_dvm_script(PRJ_IMPORTS_FILE) }
   end

   def do_reset
     remove_dir(PRJ_IMPORTS)
   end

   def prepare
     PRJ_IMPORTS.mkpath
   end

   def adjust_prj_paths(prj_paths, import)
     vendor_prj_paths = {}
     vendor_path = PRJ_IMPORTS.relative_path_from(PRJ_ROOT)
     prj_paths.each { |key, val| vendor_prj_paths[key] = "#{vendor_path}/#{import}/#{val}" }
     IDEServices.prj_paths(vendor_prj_paths)
   end

   def do_build_action(idetag, cfg, action)
     cfg = {} unless cfg
     cfg['BuildGroup'] = options[:group] if options.group?
     script = DSL.load_dvm_script(PRJ_IMPORTS_FILE, options)
     ide = IDEServices.new(idetag)
     prj_paths = IDEServices.prj_paths
     script.imports.values.map(&:lib_tag).each do |import|
       adjust_prj_paths(prj_paths, import)
       ide.call_build_tool(action, cfg)
     end
   end
end
