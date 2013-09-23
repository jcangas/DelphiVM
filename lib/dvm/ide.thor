# encoding: UTF-8

class Ide < Thor

  desc "list", "show instaled(default) or all known IDE versions"
  def list(known_ides=false)
    report_ides IDEServices.idelist(known_ides)
  end

  desc "use IDE-TAG", "use IDE with IDE-TAG"
  def use(ide_tag)
    puts "Active path: " + IDEServices.use(ide_tag)
  end
  
  desc "used", "list used IDEs in project"
  def used
    report_ides IDEServices.ideused
  end

  desc "start IDE-TAG  ", "start IDE with IDE-TAG"
  def start(idever=nil)
    idever ||= IDEServices.default_ide
    ide = IDEServices.new(idever, ROOT)
    ide.start 
  end

private

  def report_ides(ides)
    if ides.empty?
      say "NO IDE(s) found\n"
    else
      say "found IDEs:\n"
      infos = IDEServices::IDEInfos
      say ides.map{|ide| ide.to_s  + ": #{infos[ide][:name]}, #{infos[ide][:desc]}"}.join("\n")
    end
  end

end
