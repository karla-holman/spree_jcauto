module Spree
  class ProductVendor < Spree::Base
    belongs_to :variant, touch: true, class_name: 'Spree::Variant', inverse_of: :product_vendors
    belongs_to :vendor, class_name: 'Spree::Vendor', inverse_of: :product_vendors

    validates :vendor_id, presence: true
    validates :variant_id, presence: true
    validates :vendor_id, uniqueness: { scope: [:variant_id] }
    validates :vendor_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  	# before_save :update_name
  	# after_create :update_name_first

  	self.whitelisted_ransackable_attributes = ['vendor_part_number']
  	self.whitelisted_ransackable_attributes = ['vendor_price']
  	self.whitelisted_ransackable_attributes = ['vendor_id']
    self.whitelisted_ransackable_attributes = ['product_id']

    def price
      return Spree::Money.new(self.vendor_price, currency: (self.vendor ? self.vendor.currency : "USD")).to_s
    end
  	# virtual attributes for use with AJAX completion stuff

    # Get vendor name
    def vendor_name
      vendor.name if vendor
    end

    # Set vendor name
    def vendor_name=(name)
      unless name.blank?
        unless ven = Vendor.find_by(name: name)
          ven = Vendor.create(name: name)
        end
        self.vendor = ven
      end
    end
  end
end
