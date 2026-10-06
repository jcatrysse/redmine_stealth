module RedmineStealth
  module JournalStealthPatch
    def send_notification
      return if RedmineStealth.cloaked?
      super
    end

    class Initializer < Rails::Railtie
      config.before_initialize do
        Journal.prepend(JournalStealthPatch)
      end
    end
  end
end
