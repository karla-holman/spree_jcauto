module Spree
  module Admin
    class RootController < Spree::Admin::BaseController

      skip_before_action :authorize_admin, raise: false

      def index
        redirect_to admin_root_redirect_path
      end

      protected

      def admin_root_redirect_path
        spree.admin_orders_path
      end
    end
  end
end
