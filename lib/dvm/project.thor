# Project actions
class Project < BuildTarget
  namespace :prj

  %w(clean make build).each do |action|
    desc action, "#{action} #{APP_ID} products", for: action.to_sym
    method_option :group,
                  type: :string,
                  aliases: '-g',
                  default: configuration.build_args,
                  desc: 'Use BuildGroup',
                  for: action.to_sym
  end

  desc 'reset', 'erase prj out'
  def reset
    do_reset
  end

  protected

  def do_reset
    remove_dir(root_out_path)
  end

  def do_clean(idetag, cfg)
    do_build_action(idetag, cfg, 'Clean')
  end

  def do_make(idetag, cfg)
    do_build_action(idetag, cfg, 'Make')
  end

  def do_build(idetag, cfg)
    do_build_action(idetag, cfg, 'Build')
  end

  private

  def do_build_action(idetag, cfg, action)
    cfg = {} unless cfg
    cfg['BuildGroup'] = options[:group] if options.group?
    ide = IDEServices.new(idetag, PRJ_ROOT)
    ide.call_build_tool(action, cfg)
  end
end
