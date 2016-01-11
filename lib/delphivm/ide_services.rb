require 'delphivm/tool'
require 'delphivm/win_services'

class Delphivm
  IDEInfos = Delphivm.configuration.known_ides || {}

  class IDEServices
    attr_reader :idever
    attr_reader :workdir
    attr_reader :build_tool

    def self.root_path
      @root_path || PRJ_ROOT
    end

    def self.root_path=(value)
      @root_path = value
    end

    def self.prj_paths(value = nil)
      return @prj_paths = value if value
      @prj_paths ||= { src: 'src', samples: 'samples', test: 'test' }
    end

    def self.idelist(kind = :installed)
      ide_filter_valid?(kind) ? send("ides_in_#{kind}") : []
    end

    def self.ide_filter_valid?(kind)
      %w(config installed prj).include?(kind.to_s)
    end

    def self.default_ide
      @default_ide ||= (ides_in_prj & ides_in_installed).last.to_s
    end

    def self.ides_in_config
      @ides_in_config ||= IDEInfos.to_h.keys.sort
    end

    def self.ides_in_installed
      @ides_in_installed ||= ides_filter(ides_in_config, :installed)
    end

    def self.ides_in_prj
      @ides_in_prj = ides_filter(ides_in_config, :prj)
    end

    def self.ides_filter(ides, kind)
      ide_filter_valid?(kind) ? ides.select { |ide| send("ide_in_#{kind}?", ide) } : []
    end

    def self.ide_in_config?(ide)
      ides_in_config.include?(ide)
    end

    def self.ide_in_installed?(ide)
      Win32::Registry::HKEY_CURRENT_USER.open(IDEInfos[ide][:regkey]) do |reg|
        reg
      end
    rescue
      false
    end

    def self.report_ides(ides, kind = :found)
      say
      say '%30s IDEs: %d' % ["#{kind.to_s.upcase}", ides.size], :green, true
      infos = Delphivm::IDEInfos
      say '+%s-%s-%s+' % ['-' * 7, '-' * 12, '-' * 42]
      say '| %5.5s | %10.10s | %40.40s |' % %w(Tag Name Description)
      ides.map do |ide|
        say '|%s+%s+%s|' % ['-' * 7, '-' * 12, '-' * 42]
        say '| %5.5s | %10.10s | %40.40s |' % [ide.to_s, infos[ide][:name], infos[ide][:desc]]
      end
      say '+%s-%s-%s+' % ['-' * 7, '-' * 12, '-' * 42]
    end

    def self.prj_paths_glob
      @prj_paths_glob = "{#{prj_paths.values.join(',')}}"
    end

    def self.ide_in_prj?(ide)
      unless false && @dproj_paths
        ide_tags = ::Delphivm::IDEInfos.to_h.keys.join(',')
         #p ":)", root_path
         @dproj_paths = root_path.glob("#{prj_paths_glob}/**/{#{ide_tags}}*/").uniq
      end
      !@dproj_paths.select { |path| /#{ide.to_s}.*/.match(path) }.empty?
    end

    def self.platforms_in_prj(_ide)
      result = []
      Pathname.glob(PRJ_ROOT + "#{prj_paths_glob}/**/*.dproj") do |f|
        doc = Nokogiri::XML(File.open(f))
        result |= doc.css('Platforms Platform').select do |node|
          node.content == 'True'
        end.map do |node|
          node.attr(:value)
        end
      end
      result
    end

    def self.configs_in_prj(_ide)
      result = []
      Pathname.glob(PRJ_ROOT + "#{prj_paths_glob}/**/*.dproj") do |f|
        doc = Nokogiri::XML(File.open(f))
        result |= doc.css("BuildConfiguration[@Include != 'Base']").map { |node| node.attr('Include') }
      end
      result
    end

    # FIX: parece que falta algun path del ide
    def self.use(ide_tag, activate = true)
      paths_to_remove = []
      ides_in_installed.each { |tag| paths_to_remove += ide_paths(tag) }
      paths_to_remove.map!(&:win)
      path = ENV['PATH'].split(';')
      new_path = ide_paths(ide_tag.upcase) + path - paths_to_remove
      path = new_path.join(';')
      WinServices.winpath = path if activate
      path
    end

    def initialize(idever, workdir = root_path)
      @idever = idever.to_s.upcase
      @workdir = workdir
      @reg = Win32::Registry::HKEY_CURRENT_USER
      @build_tool = supports_msbuild? ? MSBuild.new(self) : IDETool.new(self)
    end

    def [](key)
      @reg.open(IDEInfos[idever][:regkey]) { |r| r[key] }
    end

    def set_env
      ENV['PATH'] = prj_bin_paths.join(';') + ';' + vendor_bin_paths.join(';') + ';' + IDEServices.use(idever, false)

      ENV['DVM_IDETAG'] = idever.to_s
      ENV['DVM_PRJDIR'] = workdir.win
    end

    def prj_slug
      workdir.basename.to_s.upcase
    end

    def prj_regkey(prjslug = nil)
      prjslug ||= prj_slug
      "DelphiVM\\#{prjslug}"
    end

    def ide_regkey
      IDEInfos[idever][:regkey]
    end

    def pkg_regkey
      regkey = Pathname(ide_regkey)
      "HKCU\\#{regkey.parent.parent}\\#{prj_regkey}\\#{regkey.basename}\\Known Packages"
    end

    def ide_root_path
      Pathname(self['RootDir'])
    end

    def ide_app_path
      Pathname(self['App'])
    end

    def vendor_bin_paths
      Pathname.glob(PRJ_IMPORTS + idever + 'Win32/{Debug,Release}/bin').map(&:win)
    end

    def prj_bin_paths
      Pathname.glob(workdir + 'out' + idever + 'Win32/{Debug,Release}/bin').map(&:win)
    end

    def supports_msbuild?
      ide_number = idever[1..-1].to_i
      ide_number > 140
    end

    def group_file_ext
      supports_msbuild? ? 'groupproj' : '{bdsgroup,bpg}'
    end

    def proj_file_ext
      'dproj'
    end

    def get_main_group_file
      srcdir = workdir + IDEServices.prj_paths[:src] + '**'
      Pathname.glob(srcdir + "#{idever}**/#{prj_slug}App.#{group_file_ext}").first ||
        Pathname.glob(srcdir + "#{idever}**/*.#{group_file_ext}").first ||
        Pathname.glob(srcdir + "*.#{group_file_ext}").first ||
        Pathname.glob(workdir + "*.#{group_file_ext}").first
    end

    def start(main_group_file = nil)
      set_env
      main_group_file ||= get_main_group_file
      # ideexe_args = IDETool.new(self).args(file: main_group_file.win).cmdln_args
      ide_tool = IDETool.new(self)
      ideexe_args = ide_tool.cmdln_args

      spawn(%(#{ide_tool.app}), *ideexe_args)
      say "[#{idever}] IDE start with #{ideexe_args.join(' ')}"
    end

    def call_build_tool(target, config)
      set_env
      buildidr = workdir + "#{IDEServices.prj_paths_glob}/**/#{idever}**/*.#{group_file_ext}"

      Pathname.glob(buildidr) do |f|
        f_to_show = f.relative_path_from(workdir)
        build_tool.args(config: config, target: target, file: f.win)
        say "[#{idever}] ", :green
        say "#{target.upcase}: #{f_to_show}"
        say("[#{build_tool.title}] ", :green)
        say(build_tool.cmdln_args.join(' '))
        say
        WinServices.winshell(out_filter: ->(line) { line =~ /\b(warning|hint|error)\b/i }) do |i|
          # WinServices.winshell do |i|
          build_tool.call(i)
        end
      end
    end

    private

    def self.say(*args)
      Delphivm.shell.say(*args)
    end

    def say(*args)
      self.class.say(*args)
    end

    def self.ide_paths(idetag = IDEServices.default_ide)
      public_path = Pathname(ENV['PUBLIC']) + 'Documents'
      ide = IDEServices.new(idetag)
      base_path = ide.ide_root_path
      brand_path = Pathname(base_path.each_filename.to_a[1..-1].join('/'))
      bin_paths = [base_path + 'bin', base_path + 'bin64'].map { |p| Pathname(p.win) }
      bpl_paths = [public_path + brand_path + 'Bpl', public_path + brand_path + 'Bpl' + 'Win64'].map { |p| Pathname(p.win) }
      bin_paths + bpl_paths
    end
  end
end
