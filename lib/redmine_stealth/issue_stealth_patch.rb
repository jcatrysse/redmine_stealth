module RedmineStealth
  module IssueStealthPatch
    def send_notification
      return if RedmineStealth.cloaked?
      super
    end

    class Initializer < Rails::Railtie
      config.before_initialize do
        Issue.prepend(IssueStealthPatch)
      end
    end
  end
end
