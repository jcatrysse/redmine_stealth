# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class StealthApiTest < Redmine::ApiTest::Base
  include RedmineStealthTestHelper

  fixtures :projects, :users, :email_addresses, :user_preferences, :members, :member_roles, :roles

  def setup
    super
    grant_stealth_permission
  end

  def test_toggle_json
    post '/stealth/toggle.json', headers: credentials('jsmith')
    assert_response :success
    assert_equal({ 'is_cloaked' => true }, JSON.parse(response.body))
    assert cloaked_in_db?(User.find(2))
  end

  def test_toggle_xml_with_explicit_state
    set_cloaked(User.find(2), true)
    post '/stealth/toggle.xml', params: { toggle: 'false' },
         headers: { 'X-Redmine-API-Key' => User.find(2).api_key }
    assert_response :success
    assert_select 'is_cloaked', text: 'false'
    assert_not cloaked_in_db?(User.find(2))
  end

  def test_api_ignores_csrf
    saved = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    post '/stealth/toggle.json', params: { toggle: 'true' }, headers: credentials('jsmith')
    assert_response :success
    assert cloaked_in_db?(User.find(2))
  ensure
    ActionController::Base.allow_forgery_protection = saved
  end

  def test_toggle_without_permission_is_forbidden
    post '/stealth/toggle.json', headers: credentials('dlopper', 'foo')
    assert_response :forbidden
    assert_not cloaked_in_db?(User.find(3))
  end

  def test_toggle_without_credentials_is_unauthorized
    post '/stealth/toggle.json'
    assert_response :unauthorized
  end

  def test_toggle_with_rest_api_disabled_is_refused
    Setting.rest_api_enabled = '0'
    post '/stealth/toggle.json', headers: { 'X-Redmine-API-Key' => User.find(2).api_key }
    assert_response :forbidden
    assert_not cloaked_in_db?(User.find(2))
  end
end
