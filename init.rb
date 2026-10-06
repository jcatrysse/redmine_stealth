# frozen_string_literal: true

require_relative 'lib/redmine_stealth'
require_relative 'lib/redmine_stealth/hooks'
require_relative 'lib/redmine_stealth/issue_stealth_patch'
require_relative 'lib/redmine_stealth/journal_stealth_patch'

Redmine::Plugin.register :redmine_stealth do
  name 'Redmine Stealth plugin'
  author 'Tomasz Gietek for Omega Code Sp. z o.o., updated by Jan Catrysse'
  description 'Enables users to disable Redmine email notifications for their actions'
  version '0.8.0'
  author_url 'https://github.com/omegacodepl'

  Redmine::AccessControl.map do |map|
    map.permission :toggle_stealth_mode, { stealth: [:toggle] }, global: true
  end

  toggle_url = { controller: 'stealth', action: 'toggle' }

  decide_toggle_display = lambda do |_project|
    user = User.current
    user && user.allowed_to?(:toggle_stealth_mode, nil, global: true)
  end

  stealth_menuitem_captioner = lambda do |_project|
    is_cloaked = RedmineStealth.cloaked?
    RedmineStealth.status_label(is_cloaked)
  end

  # Belangrijk: hier GEEN l(...) doen
  menu_options = {
    html: {
      'id' => 'stealth_toggle',
      'remote' => true,
      'method' => :post
    }
  }

  menu :account_menu, :stealth, toggle_url, {
    first: true,
    if: decide_toggle_display,
    caption: stealth_menuitem_captioner
  }.merge(menu_options)
end
