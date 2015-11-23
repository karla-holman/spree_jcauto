module Spree
  class Price < Spree::Base
    acts_as_paranoid
    belongs_to :variant, class_name: 'Spree::Variant', inverse_of: :prices, touch: true

    validate :check_price
    validates :amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :core, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validate :validate_amount_maximum

    extend DisplayMoney
    money_methods :amount, :price, :core_price, :total_price

    self.whitelisted_ransackable_attributes = ['amount']

    def money
      Spree::Money.new(amount || 0, { currency: currency })
    end

    def money_core
      Spree::Money.new(core || 0, { currency: currency })
    end

    def money_total
      Spree::Money.new(core + amount || 0, { currency: currency })
    end

    def price
      amount
    end

    def core_price
      core
    end

    def total_price
      amount + core
    end

    def price=(price)
      self[:amount] = Spree::LocalizedNumber.parse(price)
    end

    def core_price=(price)
      self[:core] = Spree::LocalizedNumber.parse(price)
    end

    # Remove variant default_scope `deleted_at: nil`
    def variant
      Spree::Variant.unscoped { super }
    end

    private

    def check_price
      self.currency ||= Spree::Config[:currency]
    end

    def maximum_amount
      BigDecimal '999999.99'
    end

    def validate_amount_maximum
      if amount && amount > maximum_amount
        errors.add :amount, I18n.t('errors.messages.less_than_or_equal_to', count: maximum_amount)
      end
    end
  end
end
