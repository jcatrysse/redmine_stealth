# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

class StealthNotificationTest < ActiveSupport::TestCase
  include RedmineStealthTestHelper

  fixtures :projects, :users, :email_addresses, :user_preferences, :members, :member_roles, :roles,
           :trackers, :projects_trackers, :issue_statuses, :issues, :enumerations,
           :enabled_modules, :journals, :journal_details, :workflows, :watchers

  def setup
    ActionMailer::Base.deliveries.clear
  end

  def teardown
    User.current = nil
  end

  def new_issue
    Issue.new(project_id: 1, tracker_id: 1, author_id: 3, status_id: 1,
              priority: IssuePriority.first, subject: 'stealth test')
  end

  def test_issue_creation_sends_mail_when_not_cloaked
    User.current = User.find(3)
    with_settings notified_events: %w(issue_added) do
      assert new_issue.save
    end
    assert_operator ActionMailer::Base.deliveries.size, :>, 0
  end

  def test_issue_creation_sends_no_mail_when_cloaked
    User.current = User.find(3)
    set_cloaked(User.current, true)
    with_settings notified_events: %w(issue_added) do
      assert new_issue.save
    end
    assert_equal 0, ActionMailer::Base.deliveries.size
  end

  def test_journal_sends_mail_when_not_cloaked
    User.current = User.find(3)
    issue = Issue.find(1)
    with_settings notified_events: %w(issue_updated) do
      issue.init_journal(User.current, 'a note')
      assert issue.save
    end
    assert_operator ActionMailer::Base.deliveries.size, :>, 0
  end

  def test_journal_sends_no_mail_when_cloaked
    User.current = User.find(3)
    set_cloaked(User.current, true)
    issue = Issue.find(1)
    with_settings notified_events: %w(issue_updated) do
      issue.init_journal(User.current, 'a note')
      assert issue.save
    end
    assert_equal 1, Journal.where(journalized: issue, notes: 'a note').count
    assert_equal 0, ActionMailer::Base.deliveries.size
  end

  def test_other_users_still_notify_while_one_user_is_cloaked
    set_cloaked(User.find(2), true)
    User.current = User.find(3)
    with_settings notified_events: %w(issue_added) do
      assert new_issue.save
    end
    assert_operator ActionMailer::Base.deliveries.size, :>, 0
  end

  # Prepended, not alias-chained: redmine_checklists prepends
  # Journal#send_notification too, and an alias chain applied after that
  # prepend recursed until SystemStackError on every journal.
  def test_patches_are_prepended
    [[Issue, RedmineStealth::IssueStealthPatch], [Journal, RedmineStealth::JournalStealthPatch]].each do |klass, patch|
      assert_operator klass.ancestors.index(patch), :<, klass.ancestors.index(klass)
      assert_not klass.method_defined?(:send_notification_without_stealth)
      assert_not klass.private_method_defined?(:send_notification_without_stealth)
    end
  end

  def test_another_prepended_send_notification_still_runs
    calls = []
    klass = Class.new do
      define_method(:send_notification) { calls << :core }
    end
    klass.prepend(Module.new { define_method(:send_notification) { calls << :other; super() } })
    klass.prepend(RedmineStealth::JournalStealthPatch)
    User.current = User.find(3)
    klass.new.send_notification
    assert_equal [:other, :core], calls
    set_cloaked(User.current, true)
    calls.clear
    klass.new.send_notification
    assert_equal [], calls
  end

  # Redmine 7 webhooks are integrations, not notifications to people: stealth
  # mode leaves them alone (see docs/REDMINE7-MIGRATION.md, open questions).
  if defined?(::Webhook)
    def test_webhooks_are_still_triggered_when_cloaked
      User.current = User.find(3)
      set_cloaked(User.current, true)
      events = []
      recorder = Module.new do
        define_method(:trigger) do |event, object|
          events << event
          super(event, object)
        end
      end
      Webhook.singleton_class.prepend(recorder)
      with_settings notified_events: %w(issue_added) do
        assert new_issue.save
      end
      assert_includes events, 'issue.created'
      assert_equal 0, ActionMailer::Base.deliveries.size
    end
  end
end
