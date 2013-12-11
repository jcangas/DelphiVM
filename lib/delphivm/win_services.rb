require 'fiddle'
require 'fiddle/import'

module User32
	extend Fiddle::Importer
	dlload 'user32'
	extern 'long SendMessageTimeout(long, long, long, void*, long, long, void*)'
end

module WinServices
	include Delphivm::Talk

	HWND_BROADCAST = 0xffff
	WM_SETTINGCHANGE = 0x001A
	SMTO_ABORTIFHUNG = 2

	def self.winpath=(path)
		Win32::Registry::HKEY_CURRENT_USER.open('Environment', Win32::Registry::KEY_WRITE) do |r| 
			r['PATH'] = path
		end
		User32.SendMessageTimeout(HWND_BROADCAST, WM_SETTINGCHANGE, 0, 'Environment', SMTO_ABORTIFHUNG, 5000, 0)    
	end

	def self.winshell(options = {})
		acmd = options[:cmd] || 'cmd /k'
		out_filter = options[:out_filter] || ->(line){true}
		err_filter = options[:err_filter] || ->(line){true}

		Open3.popen3(acmd) do |i, o, e, t|
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