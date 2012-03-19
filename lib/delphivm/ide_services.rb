module	Delphivm
	class IDEServices
    REG_KEYS = {
      'D150' => 'Software\Embarcadero\BDS\8.0',
      'D160' => 'Software\Embarcadero\BDS\9.0'
     }
    attr :idever
    attr :workdir
    def initialize(idever, workdir)
      @idever = idever
      @workdir = workdir
      @reg = Win32::Registry::HKEY_CURRENT_USER     
    end
     
    def [](key)
      @reg.open(REG_KEYS[idever]) {|r|  r[key] }
    end
      
    def set_env
      ENV["PATH"] =  '$(BDSCOMMONDIR)\bpl;' + ENV["PATH"]
      ENV["PATH"] = self['RootDir'] + 'bin;' + ENV["PATH"]
      ENV["BDSPROJECTGROUPDIR"] = workdir.win
      ENV["IDEVERSION"] = idever
    end

    def start
      set_env
      prj_slug = workdir.basename.to_s.upcase
      Process.detach(spawn "#{self['App']}", "-r#{prj_slug}")
      say "started bds -r#{prj_slug}"
    end

    def msbuild(config, target)
      set_env
      winshell(out_filter: ->(line){line =~ /(error|Tiempo)/}) do |i|
        Pathname.glob(workdir + "#{idever}**/*.groupproj") do |f|
          f_to_show = f.relative_path_from(workdir)
          say "#{target} (#{config}) #{f_to_show} ...."
          # paths can contains spaces so we need use quotes
          i.puts %Q["#{self['RootDir'] + 'bin\rsvars.bat'}"]
          i.puts %Q[msbuild /nologo /t:#{target} /p:Config=#{config} "#{f.win}"]
        end  
      end    
    end
    
  private
    def say(msg)
      puts msg
    end
    
    def winshell(options = {})
      acmd = options[:cmd] || 'cmd /k'
      out_filter = options[:out_filter] || ->(line){true}
      err_filter = options[:err_filter] || ->(line){true}

      Open3.popen3(acmd) do |i,o,e,t|
        err_t = Thread.new(e) do |stm|
            while (line = stm.gets)
              say "STDERR: #{line}" if err_filter.call(line)
            end
        end 

        out_t = Thread.new(o) do |stm|
            while (line = stm.gets)
              say "#{line}" if out_filter.call(line) 
            end
        end

        begin
          yield i if block_given?
          i.close
          err_t.join
          out_t.join
          o.close
          e.close
        rescue Exception => excep
          say excep
        end
        t.value
      end      
    end
  end
end