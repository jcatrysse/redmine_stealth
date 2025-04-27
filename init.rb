require 'redmine'
require 'redmine/i18n'
require File.dirname(__FILE__) + '/lib/redmine_stealth'
require File.dirname(__FILE__) + '/lib/redmine_stealth/hooks'
require File.dirname(__FILE__) + '/lib/redmine_stealth/issue_stealth_patch'
require File.dirname(__FILE__) + '/lib/redmine_stealth/journal_stealth_patch'

Redmine::Plugin.register :redmine_stealth do

  extend Redmine::I18n

  plugin_locale_glob = File.join(Rails.root, 'plugins',
                                 'redmine_stealth', 'config', 'locales', '*.yml')

  ::I18n.load_path += Dir.glob(plugin_locale_glob)

  menu_options = {
    :html => {
      'id' => 'stealth_toggle',
      'data-failure-message' => l(RedmineStealth::MESSAGE_TOGGLE_FAILED)
    }
  }

  name 'Redmine Stealth plugin'
  author 'Tomasz Gietek for Omega Code Sp. z o.o., updated by Jan Catrysse'
  description 'Enables users to disable Redmine email notifications for their actions'
  version '0.8.0'
  author_url 'https://github.com/omegacodepl'

  Redmine::AccessControl.map do |map|
    map.permission :toggle_stealth_mode, { :stealth => [:toggle] }, :global => true
  end

  toggle_url = { :controller => 'stealth', :action => 'toggle' }

  decide_toggle_display = lambda do |*_|
    can_toggle = false
    if (user = User.current)
      can_toggle = user.allowed_to?(:toggle_stealth_mode, nil, :global => true)
    end
    can_toggle
  end

  stealth_menuitem_captioner = lambda do |project|
    is_cloaked = RedmineStealth.cloaked?
    RedmineStealth.status_label(is_cloaked)
  end

  menu_options[:html].update('remote' => true, 'method' => :post)
  menu :account_menu, :stealth, toggle_url, {
    :first => true,
    :if => decide_toggle_display,
    :caption => stealth_menuitem_captioner
  }.merge(menu_options)

end