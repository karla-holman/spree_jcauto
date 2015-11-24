module Spree
  module Admin
    class GeneralSettingsController < Spree::Admin::BaseController
      include Spree::Backend::Callbacks

      before_action :set_store

      def edit
        @preferences_security = [:check_for_spree_alerts]
      end

      def update
        params.each do |name, value|
          next unless Spree::Config.has_preference? name
          Spree::Config[name] = value
        end

        current_store.update_attributes store_params

        flash[:success] = Spree.t(:successfully_updated, resource: Spree.t(:general_settings))
        redirect_to edit_admin_general_settings_path
      end

      def dismiss_alert
        if request.xhr? and params[:alert_id]
          dismissed = Spree::Config[:dismissed_spree_alerts] || ''
          Spree::Config.set dismissed_spree_alerts: dismissed.split(',').push(params[:alert_id]).join(',')
          filter_dismissed_alerts
          render nothing: true
        end
      end

      def clear_cache
        Rails.cache.clear
        invoke_callbacks(:clear_cache, :after)
        head :no_content
      end

      def upload
        @path = ""
      end

      def upload_excel
        byebug
        auto_tax_category_id = Spree::TaxCategory.where("name=?", "Auto Parts").first.id
        shipping_category_id = Spree::ShippingCategory.where("name=?", "Default").first.id

        part_number_id = Spree::Property.where("name=?", "Part Number").first.id
        cast_number_id = Spree::Property.where("name=?", "Cast Number").first.id
        cross_number_id = Spree::Property.where("name=?", "Cross Reference").first.id

        condition = Spree::OptionType.where("name=?", "Condition").first

        # Option values
        value_nos = Spree::OptionValue.where("name=?", "NOS").first
        value_nors = Spree::OptionValue.where("name=?", "NORS").first
        value_new = Spree::OptionValue.where("name=?", "new").first
        value_used = Spree::OptionValue.where("name=?", "used").first
        value_rebuilt = Spree::OptionValue.where("name=?", "rebuilt").first
        value_repro = Spree::OptionValue.where("name=?", "repro").first
        value_remolded = Spree::OptionValue.where("name=?", "remolded").first

        workbook = RubyXL::Parser.parse("C:/products.xlsx")
        worksheet = workbook[0]
        worksheet.each { |row|
          # create master product if not already exists - return existing product if already created
          new_product = create_product(row, auto_tax_category_id, shipping_category_id)

          # Update master variant based on spreadsheet
          new_product_variant = update_master_variant(row, auto_tax_category_id, new_product.id)
          
          # Update properties based on spreadsheet
          update_properties(row, new_product.id, part_number_id, cast_number_id, cross_number_id)

          # Create Condition Option
          new_product_condition = update_conditions(row, new_product.id, condition.id, auto_tax_category_id)
        
          # Create option values
          byebug
          case row.cells[15].value.to_s.downcase
            when "nos"
              new_product_condition.option_values << value_nos
            when "nors"
              new_product_condition.option_values << value_nors
            when "new"
              new_product_condition.option_values << value_new
            when "used"
              new_product_condition.option_values << value_used
            when "rebuilt"
              new_product_condition.option_values << value_rebuilt
            when "repro"
              new_product_condition.option_values << value_repro
            when "remolded"
              new_product_condition.option_values << value_remolded
            else
              byebug
          end  
        }
      end

      private
      def store_params
        params.require(:store).permit(permitted_store_attributes)
      end

      def set_store
        @store = current_store
      end

      def create_product(row, auto_tax_category_id, shipping_category_id)
        new_product = Spree::Product.create :name => row.cells[0].value, 
                   :description => row.cells[2].value,
                   :available_on => DateTime.new(2015,1,1),
                   :slug => row.cells[0].value.to_s,
                   :tax_category_id => auto_tax_category_id, 
                   :shipping_category_id => shipping_category_id,
                   :promotionable => true,
                   :price => row.cells[4].value # Defines master price
      end

      def update_master_variant(row, auto_tax_category_id, new_product_id)
        new_product_variant = Spree::Variant.where("product_id=?", new_product_id).first
        new_product_variant.update_column("sku", row.cells[0].value)
        new_product_variant.update_column("weight", row.cells[11].value) if row.cells[11].value.present?
        new_product_variant.update_column("height", row.cells[10].value) if row.cells[10].value.present?
        new_product_variant.update_column("width", row.cells[9].value) if row.cells[9].value.present?
        new_product_variant.update_column("depth", row.cells[8].value) if row.cells[8].value.present?
        new_product_variant.update_column("tax_category_id", auto_tax_category_id)
        new_product_variant.price = row.cells[4].value
        new_product_variant
      end

      def update_properties(row, new_product_id, part_number_id, cast_number_id, cross_number_id)
        new_product_part_num = Spree::ProductProperty.create :value => row.cells[0].value,
                       :product_id => new_product_id,
                       :property_id => part_number_id

        # If cast number present
        if(row.cells[17].value.present?)
        new_product_cast_num = Spree::ProductProperty.create :value => row.cells[17].value,
                       :product_id => new_product_id,
                       :property_id => cast_number_id
        end

        # If cross reference present               
        if(row.cells[16].value.present?)
          new_product_cross_num = Spree::ProductProperty.create :value => row.cells[16].value,
                       :product_id => new_product_id,
                       :property_id => cross_number_id
        end
      end

      def update_conditions(row, new_product_id, condition_id, auto_tax_category_id)
        new_product_option_type = Spree::ProductOptionType.create :product_id => new_product_id,
                            :option_type_id => condition_id

        # Create condition variants
        new_product_condition = Spree::Variant.create :sku => row.cells[0].value,
                :is_master => false,
                :product_id => new_product_id,
                :track_inventory => true,
                :tax_category_id => auto_tax_category_id,
                :stock_items_count => 0

        new_product_condition.update_column("weight", row.cells[11].value) if row.cells[11].value.present?
        new_product_condition_price = Spree::Price.where("variant_id = ?", new_product_condition.id)
        new_product_condition_price.first.update_attribute("amount", row.cells[4].value)
        new_product_condition_price.first.update_attribute("core", row.cells[18].value) if row.cells[18].value.present?

        new_product_condition
      end
    end
  end
end
