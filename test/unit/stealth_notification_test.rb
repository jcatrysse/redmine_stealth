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
