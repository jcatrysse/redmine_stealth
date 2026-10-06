# frozen_string_literal: true

require File.expand_path('../../../test/test_helper', __dir__)

module RedmineStealthTestHelper
  # Role 1 (Manager, jsmith on project 1) may toggle; role 2 (Developer,
  # dlopper) may not.
  def grant_stealth_permission
    Role.find(1).add_permission!(:toggle_stealth_mode)
  end

  def set_cloaked(user, value)
    pref = user.pref
    pref[RedmineStealth::PREF_STEALTH_ENABLED] = value
    pref.save!
  end

  def cloaked_in_db?(user)
    !!UserPreference.find_by(user_id: user.id)&.[](RedmineStealth::PREF_STEALTH_ENABLED)
  end
end
