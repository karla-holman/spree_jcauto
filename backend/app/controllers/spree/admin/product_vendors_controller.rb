module Spree
  module Admin
    class ProductVendorsController < ResourceController
      belongs_to 'spree/product', :find_by => :slug
      before_action :find_vendors
      before_action :setup_vendor, only: :index

      private
        # Used for form auto complete
        def find_vendors
          # get list of all applications to auto populate
          @vendors = Spree::Vendor.pluck(:name)
          # @models = Spree::Model.all
        end

        def setup_vendor
          # create new product vendor "row" for edit page
          @product.product_vendors.build
        end
    end
  end
end
