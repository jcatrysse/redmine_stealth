# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class RedmineStealthTest < ActiveSupport::TestCase
  include RedmineStealthTestHelper

  fixtures :users, :email_addresses, :user_preferences

  def teardown
    User.current = nil
  end

  def test_cloak_and_decloak_store_the_preference
    user = User.find(2)
    User.current = user
    assert_equal true, RedmineStealth.cloak!
    assert RedmineStealth.cloaked?
    assert cloaked_in_db?(user)
    assert_equal false, RedmineStealth.decloak!
    assert_not RedmineStealth.cloaked?
    assert_not cloaked_in_db?(user)
  end

  def test_toggle_flips_the_preference
    User.current = User.find(2)
    assert_equal true, RedmineStealth.toggle_stealth_mode!
    assert_equal false, RedmineStealth.toggle_stealth_mode!
  end

  def test_anonymous_is_never_cloaked
    User.current = User.anonymous
    assert_not RedmineStealth.cloaked?
  end

  def test_status_label
    assert_equal 'Enable Stealth Mode', RedmineStealth.status_label(false)
    assert_equal 'Disable Stealth Mode', RedmineStealth.status_label(true)
  end

  def test_javascript_toggle_statement
    assert_equal 'RedmineStealth.cloak("Disable Stealth Mode");', RedmineStealth.javascript_toggle_statement(true)
    assert_equal 'RedmineStealth.decloak("Enable Stealth Mode");', RedmineStealth.javascript_toggle_statement(false)
  end

  def test_javascript_toggle_statement_escapes_the_label
    I18n.backend.store_translations(:en, enable_stealth_mode: %q{Don't "hide" </script>})
    js = RedmineStealth.javascript_toggle_statement(false)
    assert_equal 'RedmineStealth.decloak("Don\'t \"hide\" \u003c/script\u003e");', js
  ensure
    I18n.reload!
  end

  def test_every_locale_has_the_same_keys
    dir = File.expand_path('../../config/locales', __dir__)
    keys = Dir[File.join(dir, '*.yml')].to_h do |file|
      yaml = YAML.safe_load_file(file)
      [File.basename(file), yaml.values.first.keys.sort]
    end
    assert_equal [keys['en.yml']], keys.values.uniq, keys.inspect
  end
end
