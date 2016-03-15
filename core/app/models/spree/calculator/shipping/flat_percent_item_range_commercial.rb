require_dependency 'spree/shipping_calculator'

module Spree
  module Calculator::Shipping
    class FlatPercentItemRangeCommercial < ShippingCalculator
      preference :flat_percent_low, :decimal, default: 0
      preference :flat_percent_med, :decimal, default: 0
      preference :flat_percent_high, :decimal, default: 0
      preference :cutoff_low, :decimal, default: 0
      preference :cutoff_med, :decimal, default: 0
      preference :minimal_amount, :decimal, default: 0

      def self.description
        "Flat percent based on price range for commercial addresses"
      end

      def compute_package(package)
        compute_from_price(total(package.contents))
      end

      def compute_from_price(price)
        # get amount to add
        if price <= self.preferred_cutoff_low
          value = price * BigDecimal(self.preferred_flat_percent_low.to_s) / 100.0
        elsif price <= self.preferred_cutoff_med
          value = price * BigDecimal(self.preferred_flat_percent_med.to_s) / 100.0
        else
          value = price * BigDecimal(self.preferred_flat_percent_high.to_s) / 100.0
        end

        # get dollar value
        dollar_val = (value * 100).round.to_f / 100

        # check if minimum met
        if dollar_val < self.preferred_minimal_amount
          self.preferred_minimal_amount
        else
          dollar_val
        end
      end

      def commercial
        true
      end
    end
  end
end