require_dependency 'spree/shipping_calculator'

module Spree
  module Calculator::Shipping
    class FlatRateInsurance < ShippingCalculator
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
      preference :insurance_8_top, :decimal, default: 0
      preference :insurance_8_amount, :decimal, default: 0
      preference :insurance_9_top, :decimal, default: 0
      preference :insurance_9_amount, :decimal, default: 0
      preference :insurance_10_top, :decimal, default: 0
      preference :insurance_10_amount, :decimal, default: 0
      preference :insurance_11_top, :decimal, default: 0
      preference :insurance_11_amount, :decimal, default: 0
      preference :insurance_12_top, :decimal, default: 0
      preference :insurance_12_amount, :decimal, default: 0
      preference :insurance_13_top, :decimal, default: 0
      preference :insurance_13_amount, :decimal, default: 0
      preference :insurance_14_top, :decimal, default: 0
      preference :insurance_14_amount, :decimal, default: 0
      preference :insurance_15_top, :decimal, default: 0
      preference :insurance_15_amount, :decimal, default: 0
      preference :insurance_16_top, :decimal, default: 0
      preference :insurance_16_amount, :decimal, default: 0
      preference :insurance_17_top, :decimal, default: 0
      preference :insurance_17_amount, :decimal, default: 0
      preference :insurance_18_top, :decimal, default: 0
      preference :insurance_18_amount, :decimal, default: 0
      preference :insurance_19_top, :decimal, default: 0
      preference :insurance_19_amount, :decimal, default: 0
      preference :insurance_20_top, :decimal, default: 0
      preference :insurance_20_amount, :decimal, default: 0
      preference :insurance_21_top, :decimal, default: 0
      preference :insurance_21_amount, :decimal, default: 0
      preference :insurance_22_top, :decimal, default: 0
      preference :insurance_22_amount, :decimal, default: 0
      preference :insurance_23_top, :decimal, default: 0
      preference :insurance_23_amount, :decimal, default: 0
      preference :insurance_24_top, :decimal, default: 0
      preference :insurance_24_amount, :decimal, default: 0
      preference :insurance_25_top, :decimal, default: 0
      preference :insurance_25_amount, :decimal, default: 0
      preference :insurance_26_top, :decimal, default: 0
      preference :insurance_26_amount, :decimal, default: 0
      preference :insurance_27_top, :decimal, default: 0
      preference :insurance_27_amount, :decimal, default: 0
      preference :insurance_28_top, :decimal, default: 0
      preference :insurance_28_amount, :decimal, default: 0
      preference :insurance_29_top, :decimal, default: 0
      preference :insurance_29_amount, :decimal, default: 0
      preference :insurance_30_top, :decimal, default: 0
      preference :insurance_30_amount, :decimal, default: 0
      preference :insurance_max_base_price, :decimal, default: 0
      preference :insurance_max_per, :decimal, default: 0
      preference :currency, :string, default: ->{ Spree::Config[:currency] }

      def self.description
        Spree.t(:shipping_flat_rate_per_item_with_insurance)
      end

      def compute_package(package)
        # compute_from_price(total(package.contents))
        compute_from_price(package.contents)
      end

      def compute_from_price(contents)
        total_price = 0
        contents.each do |item|
          price = item.price
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
          elsif price < self.preferred_insurance_8_top
            total_price += self.preferred_insurance_8_amount
          elsif price < self.preferred_insurance_9_top
            total_price += self.preferred_insurance_9_amount
          elsif price < self.preferred_insurance_10_top
            total_price += self.preferred_insurance_10_amount
          elsif price < self.preferred_insurance_11_top
            total_price += self.preferred_insurance_11_amount
          elsif price < self.preferred_insurance_12_top
            total_price += self.preferred_insurance_12_amount
          elsif price < self.preferred_insurance_13_top
            total_price += self.preferred_insurance_13_amount
          elsif price < self.preferred_insurance_14_top
            total_price += self.preferred_insurance_14_amount
          elsif price < self.preferred_insurance_15_top
            total_price += self.preferred_insurance_15_amount
          elsif price < self.preferred_insurance_16_top
            total_price += self.preferred_insurance_16_amount
          elsif price < self.preferred_insurance_17_top
            total_price += self.preferred_insurance_17_amount
          elsif price < self.preferred_insurance_18_top
            total_price += self.preferred_insurance_18_amount
          elsif price < self.preferred_insurance_19_top
            total_price += self.preferred_insurance_19_amount
          elsif price < self.preferred_insurance_20_top
            total_price += self.preferred_insurance_20_amount
          elsif price < self.preferred_insurance_21_top
            total_price += self.preferred_insurance_21_amount
          elsif price < self.preferred_insurance_22_top
            total_price += self.preferred_insurance_22_amount
          elsif price < self.preferred_insurance_23_top
            total_price += self.preferred_insurance_23_amount
          elsif price < self.preferred_insurance_24_top
            total_price += self.preferred_insurance_24_amount
          elsif price < self.preferred_insurance_25_top
            total_price += self.preferred_insurance_25_amount
          elsif price < self.preferred_insurance_26_top
            total_price += self.preferred_insurance_26_amount
          elsif price < self.preferred_insurance_27_top
            total_price += self.preferred_insurance_27_amount
          elsif price < self.preferred_insurance_28_top
            total_price += self.preferred_insurance_28_amount
          elsif price < self.preferred_insurance_29_top
            total_price += self.preferred_insurance_29_amount
          elsif price < self.preferred_insurance_30_top
            total_price += self.preferred_insurance_30_amount
          else # Over top limit, use calculator
            additional = self.preferred_insurance_max_base_price + ((price - self.preferred_insurance_30_top) / 100) * self.preferred_insurance_max_per
            total_price += additional
          end
        end
        total_price
      end
    end
  end
end
