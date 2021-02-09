module Pay
  module Paddle
    class Subscription < Processors::Subscription
      def cancel
        subscription = processor_subscription
        ::PaddlePay::Subscription::User.cancel(processor_id)
        if on_trial?
          update(status: :canceled, ends_at: trial_ends_at)
        else
          update(status: :canceled, ends_at: DateTime.parse(subscription.next_payment[:date]))
        end
      rescue ::PaddlePay::PaddlePayError => e
        raise Error, e.message
      end

      def cancel_now!
        ::PaddlePay::Subscription::User.cancel(processor_id)
        update(status: :canceled, ends_at: Time.zone.now)
      rescue ::PaddlePay::PaddlePayError => e
        raise Error, e.message
      end

      def pause
        attributes = {pause: true}
        response = ::PaddlePay::Subscription::User.update(processor_id, attributes)
        update(status: :paused, ends_at: DateTime.parse(response[:next_payment][:date]))
      end

      def resume
        attributes = {pause: false}
        ::PaddlePay::Subscription::User.update(processor_id, attributes)
        update(status: :active, ends_at: nil)
      rescue ::PaddlePay::PaddlePayError => e
        raise Error, e.message
      end

      def swap(plan)
        attributes = {plan_id: plan, prorate: prorate}
        attributes[:quantity] = quantity if quantity?
        ::PaddlePay::Subscription::User.update(processor_id, attributes)
      rescue ::PaddlePay::PaddlePayError => e
        raise Error, e.message
      end
    end
  end
end
