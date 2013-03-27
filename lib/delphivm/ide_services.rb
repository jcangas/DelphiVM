# encoding: UTF-8

require 'fiddle'
require 'fiddle/import'

module User32
	extend Fiddle::Importer
	dlload 'user32'
	extern 'long SendMessageTimeout(long, long, long, void*, long, long, void*)'
end

HWND_BROADCAST = 0xffff
WM_SETTINGCHANGE = 0x001A
SMTO_ABORTIFHUNG = 2

class	Delphivm

	class IDEServices
    attr :idever
    attr :workdir
    GROUP_FILE_EXT = ['groupproj', 'bdsgroup']
    IDEInfos = {
			'D100' => {regkey: 'Software\Borland\BDS\4.0', name: '2006', desc: 'Borland Developer Stuido 4.0'},
			'D150' => {regkey: 'Software\Embarcadero\BDS\8.0', name: 'XE', desc: 'Embarcadero RAD Stuido XE'},
			'D160' => {regkey: 'Software\Embarcadero\BDS\9.0', name: 'XE2', desc: 'Embarcadero RAD Stuido XE2'},
			'D170' => {regkey: 'Software\Embarcadero\BDS\10.0', name: 'XE3', desc: 'Embarcadero RAD Stuido XE3'}
    }

    def self.idelist
      result = []
      IDEInfos.each {|ide, info| result << ide if (Win32::Registry::HKEY_CURRENT_USER.open(info[:regkey]) {|reg| reg} rescue false)}
      result.sort.reverse
    end
    
    def self.ideused
			#TODO ensure we return only ides listed at IDEInfos
		  ROOT.glob("{src,samples}/**/*.{#{GROUP_FILE_EXT.join(',')}}").map {|f| f.dirname.basename.to_s.split('-')[0]}.uniq.sort
    end
    
		def self.use(ide_tag)
			bin_paths = ide_paths.map{ |p| p + 'bin' }
			path = Win32::Registry::HKEY_CURRENT_USER.open('Environment'){|r| r['PATH']}

			path = path.split(';')
			path.reject! { |p| bin_paths.include?(p) }
			new_path = ide_paths(ide_tag.upcase).map{ |p| p + 'bin' }.first
			path.unshift new_path
			path = path.join(';')
			self.winpath= path
			return new_path
		end
		
		def initialize(idever, workdir)
			@idever = idever.upcase
			@workdir = workdir
			@reg = Win32::Registry::HKEY_CURRENT_USER     
		end
     
    def [](key)
      @reg.open(IDEInfos[idever][:regkey]) {|r|  r[key] }
    end
      
    def set_env
      ENV["PATH"] =  '$(BDSCOMMONDIR)\bpl;' + ENV["PATH"]
      ENV["PATH"] = self['RootDir'] + 'bin;' + ENV["PATH"]
      ENV["BDSPROJECTGROUPDIR"] = workdir.win
      ENV["IDEVERSION"] = idever
    end

    def start
      set_env
      Process.detach(spawn "#{self['App']}", "-r#{prj_slug}")
      say "started bds -r#{prj_slug}"
    end
    
    def prj_slug
      workdir.basename.to_s.upcase
    end
    
		def supports_msbuild?(idever)
      ide_number = idever[1..-1].to_i
			ide_number > 140			
		end
		
    def msbuild(config, target)
      set_env
      self.class.winshell(out_filter: ->(line){line =~ /(error)/}) do |i|
        Pathname.glob(workdir + "{src,samples}/#{idever}**/*.{#{GROUP_FILE_EXT.join(',')}}") do |f|
          f_to_show = f.relative_path_from(workdir)
          say "#{target} (#{config}) #{f_to_show.win} ...."
          # paths can contains spaces so we need use quotes
					if supports_msbuild?(idever)
          	i.puts %Q["#{self['RootDir'] + 'bin\rsvars.bat'}"]
          	i.puts %Q[msbuild /nologo /t:#{target} /p:Config=#{config} "#{f.win}"]
					else						
          	i.puts %Q[bds -b "#{f.win}"]
					end
        end  
      end    
    end
    
    def self.winshell(options = {})
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

  private
    
		def self.say(msg)
			puts msg
		end
		
    def say(msg)
			self.class.say(msg)
		end

		def self.ide_paths(idetag=nil)
			result = []
  		IDEInfos.each { |key, info|
				Win32::Registry::HKEY_CURRENT_USER.open(info[:regkey]){|r| 				
				  result << r['RootDir'] if (idetag.nil? || idetag.to_s == key)
				} rescue true
			}
			result
		end
    
		def self.winpath=(path)
			Win32::Registry::HKEY_CURRENT_USER.open('Environment', Win32::Registry::KEY_WRITE) do |r| 
				r['PATH'] = path
			end
			User32.SendMessageTimeout(HWND_BROADCAST, WM_SETTINGCHANGE, 0, 'Environment', SMTO_ABORTIFHUNG, 5000, 0)    
		end
  end
end