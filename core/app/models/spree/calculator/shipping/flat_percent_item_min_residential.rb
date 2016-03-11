require_dependency 'spree/shipping_calculator'

module Spree
  module Calculator::Shipping
    class FlatPercentItemMinResidential < ShippingCalculator
      preference :flat_percent, :decimal, default: 0
      preference :minimal_amount, :decimal, default: 0

      def self.description
        "Flat percent with minimal amount for residential addresses"
      end

      def compute_package(package)
        compute_from_price(total(package.contents))
      end

      def compute_from_price(price)
        # get amount to add
        value = price * BigDecimal(self.preferred_flat_percent.to_s) / 100.0

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
        false
      end
    end
  end
end