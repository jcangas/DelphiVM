class Delphivm
  module DSL
    # Each import statement
    class Importer
      include Delphivm::Talk
      attr_reader :idevers
      attr_reader :script
      attr_reader :dependences_script
      attr_accessor :dependences_scriptname
      attr_reader :source
      attr_reader :source_uri
      attr_reader :idever
      attr_reader :libopts
      attr_reader :libname
      attr_reader :libver
      attr_reader :ide_pkgs

      def initialize(script, libname, libver, liboptions = {}, &block)
        @script = script
        @index = script.imports.size
        @idevers = [script.idever]
        @source = script.source
        @idever = script.idever
        @libname = libname
        @libver = libver
        @libopts = liboptions
        @source_uri = libopts[:uri] || Pathname(source) + lib_file
        @ide_pkgs = []
        @dependences_scriptname = script.vendor_path + lib_tag + IMPORTS_FNAME
        instance_eval(&block) if block
      end

      def lib_tag
        @llib_tag ||= "#{libname}-#{libver}"
      end

      def lib_file
        @lib_file ||= "#{lib_tag}-#{idever}.zip"
      end

      # import.dvm file must exist in vendor
      # in order to vendorize? method works
      def ensure_dependences_script
        fname = dependences_scriptname
        return if fname.exist?
        fname.dirname.mkpath
        fname.open('w')
      end

      def dependences_script
        unless @dependences_script && @dependences_script.loaded
          @dependences_script = DSL.load_dvm_script(dependences_scriptname, script.options, self)
        end
        @dependences_script
      end

      def satisfied?
        script.send(:satisfied, lib_tag)
      end

      def already_fetch?
        script.send(:already_fetch, lib_tag)
      end

      def build(idetag, cfg, action)
        dependences_script.build(idetag, cfg, action)
        setup_ide_paths
        ides_in_prj = IDEServices.idelist(:prj).map(&:to_s)
        ides_installed = IDEServices.idelist(:installed).map(&:to_s)

        use_ides = idevers & ides_in_prj
        use_ides &= idetag unless idetag.empty?
        use_ides &= ides_installed

        use_ides.each do |use_ide|
          unless build_as_copy(use_ide, action)
            ide = IDEServices.new(use_ide)
            ide.call_build_tool(action, cfg)
          end
        end
      end

      private

      def setup_ide_paths
        IDEServices.root_path = script.root_path
        import_root_path = script.vendor_path + lib_tag
        vendor_prj_paths = {}
        vendor_path = import_root_path.relative_path_from(script.root_path)
        IDEServices.default_prj_paths.each do |key, val|
          vendor_prj_paths[key] = "#{vendor_path}/#{val}"
        end
        IDEServices.prj_paths(vendor_prj_paths)
      end

      def build_as_copy(ide_tag, action)
        import_out_path = PRJ_IMPORTS + lib_tag + 'out' + ide_tag
        return false unless import_out_path.exist?
        say_status(action.upcase.to_sym, "copy imported #{import_out_path.relative_path_from PRJ_IMPORTS}", :yellow)
        Pathname(import_out_path).glob('**/*.*').each do |file|
          rel_route = file.relative_path_from(import_out_path)
          dest_route = PRJ_ROOT + 'out' + ide_tag + rel_route

          if action == 'Clean'
            FileUtils.rm(dest_route, verbose: false, force: true)
          elsif action == 'Make'
            FileUtils.cp(file, dest_route, verbose: false)
          else
            FileUtils.cp(file, dest_route, verbose: false)
          end
        end
        true
      end

      def ide_install(*packages)
        @ide_pkgs = packages
      end

      def do_ide_install
        report = { ok: [], fail: [] }
        ide_pkgs.each do |ide_pkg|
          # El paquete para el IDE debe estar compilado para Win32
          # Preferir Release
          search = (script.root_path + 'out' + idever + 'Win32' + '{Release,Debug}' + 'bin' + ide_pkg)

          pkg_by_cfg = {}
          Pathname.glob(search).each_with_object(pkg_by_cfg) do |pkg, groups|
            groups[pkg.dirname.parent.basename.to_s] = pkg
          end

          target = pkg_by_cfg.values.first

          if target
            report[:ok] << ide_pkg
            register(idever, target)
          else
            report[:fail] << ide_pkg
          end
        end
        show_ide_install_report(report)
      end

      def need_idevers
        @need_idevers ||= (idevers & script.idevers_filter)
      end

      def proccess
        return if satisfied?
        if script.multi_root
          dependences_script.send(:proccess)
          return
        end
        return if need_idevers.empty?
        destination = DVM_IMPORTS + idever
        cache_folder = destination + lib_tag
        exist = cache_folder.exist?

        if exist && script.options.force? && !already_fetch?
          exist = false
          FileUtils.remove_dir(cache_folder.win, true)
        end
        status = exist ? :'cached in' : :'fetch from'
        status_report = exist ? destination.win : source_uri
        say
        say "#{script.prj_name} Importing [#{script.level}] #{lib_file}", [:blue, :bold]
        say_status status, status_report, :green

        unless exist
          fail "import's source undefined" unless @source
          zip_file = download(source_uri, lib_file)
          mark_fetch
          unzip(zip_file, destination) if zip_file
        end
        mark_satisfied
        return unless exist
        vendorize
        ensure_dependences_script
        dependences_script.send(:proccess)
      end

      def show_ide_install_report(report)
        say_status(:IDE, "#{lib_tag} installed #{report[:ok].count} packages", :green) unless report[:ok].empty?
        unless report[:fail].empty?
          say_status :IDE, 'missing packages:', :red
          say report[:fail].join("\n")
        end
      end

      def dvm_vendor_files
        Pathname.glob(DVM_IMPORTS + idever + lib_tag + '**/*')
      end

      def vendorized?
        dependences_scriptname.exist?
      end

      def vendorize
        # p "vendorize to #{script.vendor_path}"
        if vendorized?
          say_status :skip, "#{lib_file}, already in vendor", :yellow
          return
        end
        files = dvm_vendor_files
        pb = ProgressBar.create(total: files.size, title: '  %9s ->' % 'vendorize', format: '%t %J%% %E %B')
        files.each do |file|
          next if file.directory?
          route = file.relative_path_from(DVM_IMPORTS + idever)
          link = script.vendor_path + route
          install_vendor(link, file)
          pb.increment
        end
        pb.finish
      end

      def install_vendor(link, target)
        link.dirname.mkpath
        if @script.options.sym?
          WinServices.mklink(link: link.win, target: target.win)
        else
          FileUtils.cp(target, link)
        end
      end

      def tree(max_level, format, visited)
        send("tree_#{format}", max_level, visited)
        dependences_script.send(:tree, max_level, format, visited) if (max_level > script.level)
      end

      def mark_satisfied
        script.send(:mark_satisfied, lib_tag)
      end

      def mark_fetch
        script.send(:mark_fetch, lib_tag)
      end

      def tree_uml(max_level, visited)
        if script.multi_top_prj
          target = script.prj_tag
        else
          target = script.required_by.lib_tag
        end
        link = "[#{target}] --> [#{lib_tag}]"
        say link unless visited.include?(link) unless script.multi_root
        visited << link
      end

      def tree_draw(max_level, visited)
        if script.level == 0
          indent = ''
        else
          if @index == script.imports.size - 1
            head = "\u2514"
          else
            head = "\u251C"
          end
          indent = ' ' * 2 * (script.level - 1) + ' ' * (script.level - 1) + head + "\u2500 "
        end
        ides_installed = IDEServices.idelist(:installed).map(&:to_s)
        say "-#{"%2s" % script.level}:  ", [:yellow, :bold]
        say "#{indent}#{lib_tag} ", [:blue, :bold]
        idevers.each do |idever|
          ide_color = ides_installed.include?(idever) ? :green : :red
          say "#{idever} ", [ide_color, :bold]
        end
        say
      end

      def register(idever, pkg)
        ide_prj = IDEServices.new(idever)
        WinServices.reg_add(key: ide_prj.pkg_regkey, value: pkg.win, data: ide_prj.prj_slug, force: true)
      end

      def download(source_uri, file_name)
        to_here = DVM_TEMP + file_name
        to_here.delete if to_here.exist?
        pb = nil
        start = lambda do |length|
          pb = ProgressBar.create(total: length, title: '  %9s ->' % 'download', format: '%t %J%% %E %B')
        end
        progress = lambda do |s|
          pb.progress = s
        end
        begin
          open(source_uri, 'rb', content_length_proc: start, progress_proc: progress) do |reader|
            File.open(to_here, 'wb') do |wfile|
              while chunk = reader.read(1024)
                wfile.write(chunk) unless defined? Ocra
              end
            end
          end
        rescue Exception => e
          say_status :ERROR, e, :red
          return nil
        end

        return to_here
      ensure
        pb.finish if pb
      end

      def unzip(file, destination)
        pb = ProgressBar.create(total: file.size, title: '  %9s ->' % 'install', format: '%t %J%% %E %B')
        Zip::InputStream.open(file) do |zip_file|
          while (f = zip_file.get_next_entry)
            f_path = destination + f.name
            next if f_path.directory? || f.name =~ /\/$/
            f_path.dirname.mkpath
            pb.increment
            f.extract(f_path) unless f_path.exist?
          end
        end
        pb.finish
      end
    end
  end
end
