require_dependency 'spree/shipping_calculator'

module Spree
  module Calculator::Shipping
    class FlatRateInsurance < ShippingCalculator
      preference :amount, :decimal, default: 0
      preference :insurance_1_top, :decimal, default: 0
      preference :insurance_1_amount, :decimal, default: 0
      preference :insurance_2_top, :decimal, default: 0
      preference :insurance_2_amount, :decimal, default: 0
      preference :insurance_3_top, :decimal, default: 0
      preference :insurance_3_amount, :decimal, default: 0
      preference :insurance_4_top, :decimal, default: 0
      preference :insurance_4_amount, :decimal, default: 0
      preference :insurance_5_top, :decimal, default: 0
      preference :insurance_5_amount, :decimal, default: 0
      preference :insurance_6_top, :decimal, default: 0
      preference :insurance_6_amount, :decimal, default: 0
      preference :insurance_7_top, :decimal, default: 0
      preference :insurance_7_amount, :decimal, default: 0
      preference :insurance_max_base_price, :decimal, default: 0
      preference :insurance_max_per, :decimal, default: 0
      preference :currency, :string, default: ->{ Spree::Config[:currency] }

      def self.description
        Spree.t(:shipping_flat_rate_per_order_with_insurance)
      end

      def compute_package(package)
        compute_from_price(total(package.contents))
      end

      def compute_from_price(price)
        total_price = self.preferred_amount
        if price < self.preferred_insurance_1_top
          total_price += self.preferred_insurance_1_amount
        elsif price < self.preferred_insurance_2_top
          total_price += self.preferred_insurance_2_amount
        elsif price < self.preferred_insurance_3_top
          total_price += self.preferred_insurance_3_amount
        elsif price < self.preferred_insurance_4_top
          total_price += self.preferred_insurance_4_amount
        elsif price < self.preferred_insurance_5_top
          total_price += self.preferred_insurance_5_amount
        elsif price < self.preferred_insurance_6_top
          total_price += self.preferred_insurance_6_amount
        elsif price < self.preferred_insurance_7_top
          total_price += self.preferred_insurance_7_amount
        else # Over top limit, use calculator
          additional = self.preferred_insurance_max_base_price + ((price - self.preferred_insurance_7_top) / 100) * self.preferred_insurance_max_per
          total_price += additional
        end
        total_price
      end
    end
  end
end
