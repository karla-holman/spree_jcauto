module Spree
  module Admin
    class VendorsController < ResourceController
      def index
        respond_with(@collection)
      end

      before_action :set_country, only: :new

      private

      def collection
        return @collection if @collection.present?
        # params[:q] can be blank upon pagination
        params[:q] = {} if params[:q].blank?

        @collection = super
        @search = @collection.ransack(params[:q])
        @collection = @search.result.
              page(params[:page]).
              per(Spree::Config[:properties_per_page])

        @collection
      end

      def set_country
        @vendor.country = Spree::Country.default
        rescue ActiveRecord::RecordNotFound
        flash[:error] = Spree.t(:stock_locations_need_a_default_country)
        redirect_to admin_vendors_path
      end
    end
  end
end
