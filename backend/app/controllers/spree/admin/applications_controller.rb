module Spree
  module Admin
    class ApplicationsController < ResourceController
      def index
        respond_with(@collection)
      end

      private

      def collection
        return @collection if @collection.present?
        # params[:q] can be blank upon pagination
        params[:q] = {} if params[:q].blank?

        @collection = super
        @search = @collection.ransack(params[:q])
        @collection = @search.result.order("name asc").
              page(params[:page]).
              per(Spree::Config[:properties_per_page])

        @collection
      end
    end
  end
end
