# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class StealthIntegrationTest < Redmine::IntegrationTest
  include RedmineStealthTestHelper

  fixtures :projects, :users, :email_addresses, :user_preferences, :members, :member_roles, :roles,
           :trackers, :projects_trackers, :enabled_modules, :issue_statuses, :issues, :enumerations

  def setup
    super
    grant_stealth_permission
  end

  def test_account_menu_shows_the_toggle_with_permission
    log_user('jsmith', 'jsmith')
    get '/projects/ecookbook'
    assert_response :success
    assert_select '#account a#stealth_toggle[href="/stealth/toggle"][data-remote="true"][data-method="post"]', text: 'Enable Stealth Mode'
    assert_select 'link[href*="stealth"][rel=stylesheet]'
    assert_select 'script', text: /RedmineStealth\.decloak\("Enable Stealth Mode"\)/
  end

  def test_account_menu_hides_the_toggle_without_permission
    log_user('dlopper', 'foo')
    get '/projects/ecookbook'
    assert_response :success
    assert_select '#stealth_toggle', 0
  end

  def test_page_renders_the_cloaked_state
    log_user('jsmith', 'jsmith')
    set_cloaked(User.find(2), true)
    get '/projects/ecookbook'
    assert_select '#stealth_toggle', text: 'Disable Stealth Mode'
    assert_select 'script', text: /RedmineStealth\.cloak\("Disable Stealth Mode"\)/
  end

  def test_login_turns_stealth_mode_off
    set_cloaked(User.find(2), true)
    log_user('jsmith', 'jsmith')
    assert_not cloaked_in_db?(User.find(2))
  end

  def test_toggle_by_get_is_not_routed
    log_user('jsmith', 'jsmith')
    get '/stealth/toggle'
    assert_response :not_found
    assert_not cloaked_in_db?(User.find(2))
  end
end
