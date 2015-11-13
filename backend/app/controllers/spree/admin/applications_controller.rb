module Spree
  module Admin
    class ApplicationsController < ResourceController
      belongs_to 'spree/product', :find_by => :slug
      before_action :find_applications
      before_action :setup_application, only: :index

      private
        def find_applications
          @applications = @product.applications
        end

        def setup_application
          @product.applications.build
        end
    end
  end
end
