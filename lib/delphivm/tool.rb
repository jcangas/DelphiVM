class Delphivm
  class Tool
    attr_reader :app
    attr_reader :title

    def initialize(app: '', title: 'unknown', ide_prj: ide_prj)
      @app = app
      @title = title
      @ide_prj = ide_prj
    end

    def idever
      @ide_prj.idever
    end

    def prj_slug
      @ide_prj.prj_slug
    end

    def prj_regkey
      @ide_prj.prj_regkey
    end

    def reg(key)
      @ide_prj[key]
    end

    def args(args = nil)
      args ? (@args = args; self) : (@args ||= {})
    end

    def call(out)
      cmd = %("#{app}" #{cmdln_args.join(' ').strip}).encode(Encoding.default_external)
      out.puts cmd
    end

    def cmdln_args
      cmd_args = default_args.dup
      cmd_args.merge!(args)
      cmd_args.map { |name, value| arg_to_cmdln(name, value) }.compact
    end

    def default_args
      {}
    end

    def arg_to_cmdln(arg_name, arg_value = args[arg_name])
      case arg_name
      when :file
        %("#{arg_value}")
      else
        "#{arg_value}"
      end
    end
  end

  class MSBuild < Tool
    def initialize(ide_prj)
      super(app: 'msbuild', title: 'MS-Build', ide_prj: ide_prj)
    end

    def call(out)
      out.puts %("#{reg('RootDir')}bin\\rsvars.bat")
      super
    end

    def default_args
      { msbuild_args:  (IDEInfos[idever].msbuild_args || Delphivm.configuration.msbuild_args || '').strip	}
    end

    def arg_to_cmdln(arg_name, arg_value)
      case arg_name
      when :target
        "/t:#{arg_value}"
      when :config
        arg_value ||= {}
        arg_value.inject([]) { |prms, item| prms << '/p:' + item.join('=') }.join(' ')
      else
        super
      end
    end
  end

  class IDETool < Tool
    def initialize(ide_prj)
      ideexe = ide_prj.ide_app_path
      super(app: ideexe, title: 'IDE Compiler', ide_prj: ide_prj)
    end

    def default_args
      { idecaption: "#{prj_slug}", reg: "DelphiVM\\#{prj_slug}", personality: 'Delphi' }
    end

    def arg_to_cmdln(arg_name, arg_value)
      case arg_name
      when :reg
        %(-r#{arg_value})
      when :idecaption
        %(-idecaption=#{arg_value})
      when :personality
        %(-p#{arg_value})
      when :target
        "-#{arg_value[0].downcase}"
      when :config
        nil # ignore it
      else
        super
      end
    end
  end
end
