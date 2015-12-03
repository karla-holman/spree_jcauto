module Spree
  module Admin
    class ProductVendorsController < ResourceController
      #belongs_to 'spree/product', :find_by => :slug
      #before_action :find_vendors
      #before_action :setup_vendor, only: :index
      before_action :setup_product, only: [:edit, :update, :destroy]

      def create
        product_vendor = Spree::ProductVendor.new(product_vendor_params)

        if product_vendor.save
          flash[:success] = flash_message_for(product_vendor, :successfully_created)
        else
          flash[:error] = "Could not create product vendor."
        end

        redirect_to :back
      end

      # redirect back after update
      def update
        invoke_callbacks(:update, :before)
        if @object.update_attributes(product_vendor_params)
          invoke_callbacks(:update, :after)
          flash[:success] = flash_message_for(@object, :successfully_updated)
          respond_with(@object) do |format|
            format.html { redirect_to :back }
            format.js { render layout: false }
          end
        else
          invoke_callbacks(:update, :fails)
          respond_with(@object) do |format|
            format.html do
              flash.now[:error] = @object.errors.full_messages.join(", ")
              redirect_to :back
            end
            format.js { render layout: false }
          end
        end
      end

      def destroy
        @object.destroy
        redirect_to :back
      end

      def show

      end

      private
        def product_vendor_params
          params.require(:product_vendor).permit(:variant_id, :vendor_id, :vendor_price, :vendor_part_number)
        end
        # find associated product
        def setup_product
          @product = @product_vendor.variant.product
        end
    end
  end
end
