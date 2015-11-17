module Spree
  module Admin
    class ProductApplicationsController < ResourceController
      belongs_to 'spree/product', :find_by => :slug
      before_action :find_applications
      before_action :setup_application, only: :index

      private
        # Used for form auto complete
        def find_applications
          # get list of all applications to auto populate
          @applications = Spree::Application.pluck(:name)
        end

        def setup_application
          # create new product application "row"
          @product.product_applications.build
        end
    end
  end
end
