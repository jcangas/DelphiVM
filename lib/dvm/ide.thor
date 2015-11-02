# encoding: UTF-8

class Ide < DvmTask

  desc "list CRITERIA", "list IDEs info. CRITERIA=(config|installed|*prj) => delgpivm.cfg|this machine|this project"
  def list(kind = :prj)
    IDEServices.report_ides(IDEServices.idelist(kind), kind)
  end

  desc "start IDE-TAG  ", "start IDE with IDE-TAG"
  def start(idever=nil)
    idever ||= IDEServices.default_ide
    if idever.empty?
      IDEServices.report_ides(IDEServices.idelist(:prj), :prj)
      say "Error: no IDE files found at this project folder" 
    else
      ide = IDEServices.new(idever, PRJ_ROOT)
      ide.start
    end
  end

  desc "use IDE-TAG", "use IDE with IDE-TAG"
  def use(ide_tag)
    say "activating IDE #{ide_tag}"
    IDEServices.use(ide_tag)
  end

end
