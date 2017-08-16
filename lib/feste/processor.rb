module Feste
  class Processor
    def initialize(message, mailer, action)
      @message = message
      @mailer = mailer
      @action = action
    end

    attr_reader :message, :mailer, :action

    def process
      if mailer.class.feste_whitelist.any?
        return true unless mailer.class.feste_whitelist.include?(action)
      elsif mailer.class.feste_blacklist.any?
        return true if mailer.class.feste_blacklist.include?(action)
      end
      stop_delivery_to_unsubscribed_emails!
    end

    private

    def stop_delivery_to_unsubscribed_emails!
      message.to = message.to.reject do |email|
        unsubscibed_email?(email)
      end
    end

    def unsubscibed_email?(email)
      sub = Feste::Subscriber.find_or_create_by(email: email)
      return true if sub.cancelled
      email = Feste::Email.find_or_create_by(mailer: mailer.class.name, action: action.to_s)
      cancellation = Feste::CancelledSubscription.find_or_create_by(
        subscriber: sub,
        email: email
      )
      cancellation.cancelled
    end
  end
end