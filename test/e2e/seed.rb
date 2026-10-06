# Plugin data for the end-to-end scenarios, run by start_server.sh after the
# generic seed. Idempotent.
#
# - manager and reporter get mail for every event in their projects, so the
#   mail scenario has recipients whichever of them acts;
# - every seeded user starts with stealth mode off;
# - Redmine 7 webhooks are enabled with one hook (owner manager, e2e-project,
#   issue created/updated) to the listener test/e2e/webhook.mjs starts on
#   port 3999 of this machine's first non-loopback IPv4 address (core refuses
#   loopback targets); written to tmp/e2e-webhook-url.txt for the scenario.

require 'socket'

Setting.notified_events = (Setting.notified_events | %w(issue_added issue_updated issue_note_added))

%w(admin manager reporter outsider).each do |login|
  user = User.find_by(login: login) or next
  user.pref[:stealth_mode] = false
  user.pref.save!
  next unless %w(manager reporter).include?(login)

  user.mail_notification = 'all'
  user.save!(validate: false)
end

if defined?(::Webhook)
  Setting.webhooks_enabled = '1'
  manager = User.find_by!(login: 'manager')
  ip = Socket.ip_address_list.find { |a| a.ipv4? && !a.ipv4_loopback? }&.ip_address
  abort 'No non-loopback IPv4 address for the webhook listener' unless ip
  url = "http://#{ip}:3999/stealth-hook"
  File.write(Rails.root.join('tmp/e2e-webhook-url.txt'), url)
  hook = Webhook.where(user_id: manager.id).where('url LIKE ?', '%:3999/stealth-hook').first || Webhook.new
  hook.url = url
  hook.user = manager
  hook.active = true
  hook.events = %w(issue.created issue.updated)
  hook.projects = [Project.find_by!(identifier: 'e2e-project')]
  hook.trackers = Tracker.all.to_a if hook.respond_to?(:trackers=)
  hook.save!
  puts "Webhook #{hook.id}: #{url} (#{hook.events.join(', ')})"
end
