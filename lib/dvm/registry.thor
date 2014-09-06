
class Registry < DvmTask
  namespace :reg

  desc "copy IDE-TAG  ", "create reg key for IDE-TAG"
  method_option :template,  type: :string, aliases: '-t', desc: "source prj-key (default: installed IDE)"
  method_option :key, type: :string, aliases: '-k', desc: "destination prj-key (default: current)"
  def copy(idever=nil)
    idever ||= IDEServices.default_ide
    ide = IDEServices.new(idever, ROOT)
    regkey = Pathname(ide.ide_regkey)
    version = regkey.basename
    
    tt_path  = options[:template] ? ide.prj_regkey(options[:template]).upcase : regkey.parent.basename + version

    regkey = regkey.parent.parent 

    source = Pathname(tt_path)
    dest = Pathname(ide.prj_regkey(options[:key])) + version

    say "create #{idever} reg key #{dest.win} based on #{source.win}"

    directory(Pathname(ENV['APPDATA']) + regkey.basename + source, Pathname(ENV['APPDATA']) + regkey.basename + dest)
    
    say cmd = 'reg copy ' + (Pathname('hkcu') + regkey + source).win + ' ' + (Pathname('hkcu') + regkey + dest).win + ' /s /f'
    system cmd
  end

  desc "show IDE-TAG  ", "show reg keys for IDE-TAG"
  def show(idever=nil)
    idever ||= IDEServices.default_ide
    ide = IDEServices.new(idever, ROOT)
    
    regkey = Pathname(ide.ide_regkey)
    version = regkey.basename

    reg_path = regkey.parent.parent + ide.prj_regkey('') 
    cmd = "reg query HKCU\\" + reg_path.win + " /s /k /f #{version}"
    list = %x(#{cmd}).split("\n").map{|x| Pathname(x).parent.basename.to_s}[1..-2]
    say "#{list.length} keys found for #{idever}:"
    say list.sort.join("\n")    
  end

  desc "del IDE-TAG  ", "delete reg key for IDE-TAG"
  method_option :key, type: :string, aliases: '-k', desc: "destination prj-key (default: current)"
  def del(idever=nil)
    idever ||= IDEServices.default_ide
    ide = IDEServices.new(idever, ROOT)
    
    regkey = Pathname(ide.ide_regkey)
    version = regkey.basename

    regkey = regkey.parent.parent 

    dest = Pathname(ide.prj_regkey(options[:key]).upcase) + version

    say "delete #{idever} reg key #{dest.win}"
    p cmd = 'reg delete ' + (Pathname('hkcu') + regkey + dest).win + ' /f'
    say %x(#{cmd})

    cmd = 'reg query ' + (Pathname('hkcu') + regkey + dest).parent.win + ' /k /f *'
    list = %x(#{cmd}).split("\n").map{|x| Pathname(x).basename.to_s}[1..-2]
    
    cmd = 'reg delete ' + (Pathname('hkcu') + regkey + dest).parent.win + ' /f' 
    say %x(#{cmd}) if list.empty?

    product = regkey.basename + dest
    say_status :remove, product.win, :red
    product = Pathname(ENV['APPDATA']) + product
  
    product.rmtree if product.exist?
    product = product.parent
    product.rmtree if product.exist? && product.children.empty?

  end
end