# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class StealthControllerTest < Redmine::ControllerTest
  include RedmineStealthTestHelper

  fixtures :projects, :users, :email_addresses, :user_preferences, :members, :member_roles, :roles

  def setup
    grant_stealth_permission
  end

  def test_toggle_with_permission_cloaks_and_answers_javascript
    @request.session[:user_id] = 2
    post :toggle, xhr: true, format: :js
    assert_response :success
    assert_equal 'RedmineStealth.cloak("Disable Stealth Mode");', response.body
    assert cloaked_in_db?(User.find(2))

    post :toggle, xhr: true, format: :js
    assert_equal 'RedmineStealth.decloak("Enable Stealth Mode");', response.body
    assert_not cloaked_in_db?(User.find(2))
  end

  def test_toggle_param_sets_the_given_state
    @request.session[:user_id] = 2
    post :toggle, xhr: true, format: :js, params: { toggle: 'true' }
    assert cloaked_in_db?(User.find(2))
    post :toggle, xhr: true, format: :js, params: { toggle: 'true' }
    assert cloaked_in_db?(User.find(2)), 'toggle=true must not flip an enabled stealth mode off'
    post :toggle, xhr: true, format: :js, params: { toggle: 'false' }
    assert_not cloaked_in_db?(User.find(2))
  end

  def test_toggle_without_permission_is_forbidden
    @request.session[:user_id] = 3
    post :toggle, xhr: true, format: :js
    assert_response :forbidden
    assert_not cloaked_in_db?(User.find(3))
  end

  def test_toggle_as_anonymous_is_refused
    post :toggle, xhr: true, format: :js
    assert_response :unauthorized
  end
end
