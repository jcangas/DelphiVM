class Vendor < BuildTarget
   desc 'clean', 'clean vendor products', for: :clean
   desc 'make',  'make vendor products', for: :make
   desc 'build', 'build vendor products', for: :build
   method_option :group,
                 type: :string, aliases: '-g',
                 default: configuration.build_args,
                 desc: 'Use BuildGroup',
                 for: :clean
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
                 desc: 'Use BuildGroup',
                 for: :build

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
   method_option :multi, type: :boolean, aliases: '-m', default: false, desc: 'multi-project aware mode'
   def import(*idevers)
     say 'WARN: ensure your project folder supports symlinks!!' if options.sym?
     silence_warnings do
       DSL.new_dvm_script(PRJ_ROOT, options).send :proccess
     end
   end

   desc 'reset', 'erase vendor imports.'
   def reset
     silence_warnings do
       script = DSL.new_dvm_script(PRJ_ROOT, options)
       script.reset
       script.prepare
     end
   end

   desc 'tree MAX_LEVEL', 'show dependencs tree. defaul MAX_LEVEL = 100'
   method_option :multi, type: :boolean, aliases: '-m', default: false, desc: 'multi-project aware mode'
   method_option :format, type: :string, required: true, aliases: '-f', default: 'draw', desc: 'render format: draw, uml'
   def tree(max_level = 100)
     silence_warnings do
       DSL.new_dvm_script(PRJ_ROOT, options).send(:tree, max_level.to_i, options.format)
     end
   end

   desc 'reg', 'IDE register vendor packages'
   def reg
     do_reg
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
     do_reg
   end

   def do_reg
     silence_warnings do
       DSL.load_dvm_script(PRJ_IMPORTS_FILE).send :ide_install
     end
   end

   def do_build_action(idetag, cfg, action)
     idetag = [idetag] unless idetag.is_a? Array
     cfg ||= {}
     cfg['BuildGroup'] = options[:group] if options.group?

     script = DSL.new_dvm_script(PRJ_ROOT, options)
     script.build(idetag, cfg, action)
   end
end
