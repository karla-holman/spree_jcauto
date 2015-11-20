module Spree
  class ProductVendor < Spree::Base
    belongs_to :product, touch: true, class_name: 'Spree::Product', inverse_of: :product_vendors
    belongs_to :vendor, class_name: 'Spree::Vendor', inverse_of: :product_vendors

    validates :vendor_part_number, presence: true

  	# before_save :update_name
  	# after_create :update_name_first

  	self.whitelisted_ransackable_attributes = ['vendor_part_number']
  	self.whitelisted_ransackable_attributes = ['vendor_price']
  	self.whitelisted_ransackable_attributes = ['vendor_id']
    self.whitelisted_ransackable_attributes = ['product_id']

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

=begin
    # Set Up name and range
    def update_name
       if self.name
	       if application_name && range
				self.update_column(:name, application_name + " " + range)
	    	else
				self.update_column(:name, "No application and/or range specified")
	    	end
	    end
    end

    def update_name_first
    	self.name = "new name"
    	self.save
    end

    def range
    	if start_year && end_year
    		range = start_year.to_s + "-" + end_year.to_s
    	else
    		range = "N/A - N/A"
    	end
    end
=end
  end
end
