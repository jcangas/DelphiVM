require 'fiddle'
require 'fiddle/import'
require 'win32ole'

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

	def self.run_as(program, args, initial_dir=nil)
		shell = WIN32OLE.new('Shell.Application')
		# shell.ShellExecute(program, args, initial_dir, operation, show)
		shell.ShellExecute(program, args, initial_dir, 'runas', 0)
	end

	def self.winpath=(path)
		run_as('reg', %Q{add "HKLM\\#{keyname}" /v PATH /d "#{path}" /f} )
		User32.SendMessageTimeout(HWND_BROADCAST, WM_SETTINGCHANGE, 0, 'Environment', SMTO_ABORTIFHUNG, 5000, 0)
		path
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
