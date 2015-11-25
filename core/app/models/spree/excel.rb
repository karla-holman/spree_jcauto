module Spree
  class Excel
    # Class variables
    @@auto_tax_category_id = Spree::TaxCategory.where("name=?", "Auto Parts").first.id
    @@shipping_category_id = Spree::ShippingCategory.where("name=?", "Default").first.id

    @@part_number_id = Spree::Property.where("name=?", "Part Number").first.id
    @@cast_number_id = Spree::Property.where("name=?", "Cast Number").first.id
    @@cross_number_id = Spree::Property.where("name=?", "Cross Reference").first.id

    @@condition = Spree::OptionType.where("name=?", "Condition").first

    # Option values
    @@value_nos = Spree::OptionValue.where("name=?", "NOS").first
    @@value_nors = Spree::OptionValue.where("name=?", "NORS").first
    @@value_new = Spree::OptionValue.where("name=?", "new").first
    @@value_used = Spree::OptionValue.where("name=?", "used").first
    @@value_rebuilt = Spree::OptionValue.where("name=?", "rebuilt").first
    @@value_repro = Spree::OptionValue.where("name=?", "repro").first
    @@value_remolded = Spree::OptionValue.where("name=?", "remolded").first
    @@value_rechromed = Spree::OptionValue.where("name=?", "rechromed").first
    @@value_resleeved = Spree::OptionValue.where("name=?", "resleeved").first
    @@value_core = Spree::OptionValue.where("name=?", "core").first
    @@value_restored = Spree::OptionValue.where("name=?", "restored").first

    # Auto Abbreviations (Make and Model)

    # pass in file object from params[:file]
    def initialize(file)
      uploaded_file = file #params[:file]
      @workbook = RubyXL::Parser.parse(uploaded_file.to_io)
      @worksheet_products = @workbook[0]
      @errors = []
    end

    # Import spreadsheet that fits product structure
    def import_product_file()
      @worksheet_products.each { |row|
        if(@product_row = build_row_hash(row))
          import_product()
        end
      }
    end

    ################################################################
    # IMPORT PRODUCT
    ################################################################

    # return hash of fields and values from spreadsheet
    def build_row_hash(row)
      if(!row.cells[0].value)
        return nil # Skip row if no name
      end

      product_name = row.cells[0].value.to_s

      # If name is mopar part number
      if product_name.match(/^\d{7}/) 
        product_name = product_name[0,7]
      end

      # handle date formatting from excel
      if row.cells[1].value.is_a?(DateTime)
        my_category = row.cells[1].value.strftime("%-m-%-d")
      else 
        my_category = row.cells[1].value.to_s
      end

      @product_row = {
        :name => product_name,
        :category => my_category,
        :description => row.cells[2].value.tr('***', ''),
        :tax_code => row.cells[3].value,
        :price => row.cells[4].value,
        :cost => row.cells[5].value,
        :vendor => row.cells[6].value,
        :vendor_price => row.cells[7].value,
        :length => row.cells[8].value,
        :width => row.cells[9].value,
        :height => row.cells[10].value,
        :weight => row.cells[11].value,
        :notes => row.cells[12].value,
        :application => row.cells[13].value,
        :location => row.cells[14].value,
        :condition => row.cells[15].value,
        :cross_ref => row.cells[16].value,
        :cast_num => row.cells[17].value,
        :core => row.cells[18].value,
        :available => row.cells[19].value,
        :online => row.cells[20].value,
        :active => row.cells[21].value
      }

    end

    def import_product()
      # create master product if not already exists - return existing product if already created
      if (matching_products = Spree::Product.where("name=?", @product_row[:name])).length > 0
        # Product and master variant exist
        @new_product = matching_products.first
      else
        # Create product and master variant
        @new_product = create_product()

        # Add part categories
        add_part_group_taxon()

        @new_product_variant = update_master_variant()
        # Update properties based on spreadsheet
        update_properties()

        # add applications
        add_applications()
      end

      # If option type exists
      if(@new_product.option_types.where("name=?", "Condition").length > 0)
          @new_product_variant = create_condition_variant()
          # Check for existing values
          if(!update_conditions_value())
            # delete this variant if duplicate exists
            @new_product_variant.delete
          end
      else # create option type and value
        @new_product_condition = update_condition_type()
        create_condition_variant()
        update_conditions_value()
      end
      
    end

    # Return a new product from each row of worksheet
    def create_product()
      new_product = Spree::Product.create :name => @product_row[:name], 
                 :description => @product_row[:description],
                 :available_on => DateTime.new(2015,1,1),
                 :slug => @product_row[:name],
                 :tax_category_id => @@auto_tax_category_id, 
                 :shipping_category_id => @@shipping_category_id,
                 :promotionable => true,
                 :price => @product_row[:price], # Defines master price
                 :notes => @product_row[:notes]
    end

    def add_part_group_taxon()
      my_taxon = Spree::Taxon.where("description=?", @product_row[:category].to_s)
      my_taxonomy = Spree::Taxon.where("description=?", @product_row[:category].to_s.split('-')[0])
      if(my_taxon.length === 0 || my_taxonomy.length === 0)
        @errors << { :part_number => @product_row[:name], :condition => @product_row[:condition], :message => "Unable to identify proper part group for " + @product_row[:category].to_s }
      end
      @new_product.taxons << my_taxon
      @new_product.taxons << my_taxonomy
    end

    # Return new master variant
    def update_master_variant()
      @new_product_variant = Spree::Variant.where("product_id=?", @new_product.id).first
      @new_product_variant.update_column("sku", @product_row[:name])
      @new_product_variant.update_column("weight", @product_row[:weight]) if @product_row[:weight].present?
      @new_product_variant.update_column("height", @product_row[:height]) if @product_row[:height].present?
      @new_product_variant.update_column("width", @product_row[:width]) if @product_row[:width].present?
      @new_product_variant.update_column("depth", @product_row[:length]) if @product_row[:length].present?
      @new_product_variant.update_column("tax_category_id", @@auto_tax_category_id)
      @new_product_variant.price = @product_row[:price]
      @new_product_variant.core_price = @product_row[:core]
      @new_product_variant
    end

    # Create properties for new variant
    def update_properties()
      new_product_part_num = Spree::ProductProperty.create :value => @product_row[:name],
                     :product_id => @new_product.id,
                     :property_id => @@part_number_id

      # If cast number present
      if(@product_row[:cast_num].present?)
      new_product_cast_num = Spree::ProductProperty.create :value => @product_row[:cast_num],
                     :product_id => @new_product.id,
                     :property_id => @@cast_number_id
      end

      # If cross reference present               
      if(@product_row[:cross_ref].present?)
        new_product_cross_num = Spree::ProductProperty.create :value => @product_row[:cross_ref],
                     :product_id => @new_product.id,
                     :property_id => @@cross_number_id
      end
    end

    # Update Applications
    def add_applications()
      applications = @product_row[:application]

      # app_data = { :start_year => "60", :end_year => "9", :text => "300C; "}
      @app_data = [] # store pieces of each application listed
      my_app_data = scan_app(applications) # app is string "69-70 C ..."

      # for each date and associated makes/models
      @app_data.each do |app_data|
        # get start date
        start_year = "19" + app_data[:start_year]

        # get end date
        case app_data[:end_year]
        when ""
          end_year = start_year
        when /\d{2}/ # end year gets 19 + year
          end_year = "19" + app_data[:end_year]
        when /\d{1}/ # end year gets first digit of start year
          end_year = "19" + app_data[:start_year][0] + app_data[:end_year]
        else
          @errors << { :part_number => @product_row[:name], :condition => @product_row[:condition], :message => "Could not match end year " + app_data[:end_year].to_s }   
        end

        # get make, model, and notes
        make_model_sets = app_data[:text].split(/[,;]/)

        # Create product application for each date/app set
        make_model_sets.each do |make_model_set|
          my_notes = ""
          my_make = nil
          my_model = nil

          if make_model_set.include? "exc"
            my_notes = make_model_set
          else
            # split make, model and notes into text
            words = make_model_set.split
            words.each do |word|
              make_match = false
              model_match = false

              word.gsub!(/\W/,"")
              # try to match abbreviation
              
              if (check = (Spree::Make.where("abbreviation=? OR name=?", word, word).first))
                my_make = check
              elsif (check = (Spree::Model.where("abbreviation=? OR name=?", word, word).first))
                my_model = check
              else
                my_notes += my_notes!="" ? " " + word : word
              end
            end
          end

          if(my_make && my_model)
            my_application = Spree::Application.where("make_id=? AND model_id=?", my_make.id, my_model.id).first
          elsif(my_make)
            my_application = Spree::Application.where("make_id=? AND model_id IS ?", my_make.id, nil).first
          end

          if(my_application || my_notes != "")
            Spree::ProductApplication.create :start_year => start_year.to_i,
                                         :end_year => end_year.to_i,
                                         :application => my_application,
                                         :product => @new_product,
                                         :notes => my_notes
          end

          if(!my_application)
            @errors << { :part_number => @product_row[:name], :condition => @product_row[:condition], :message => "Could find make or model for " + make_model_set }
          end
        end # end make_model_sets "Plymouth Valiant "
      end # end @app_data loop { :start_year => "60", :end_year => "9", :text => "Plymouth Valiant "}
    end # end add_applications()

    def scan_app(app)
      if (!app)
        return @app_data
      end

      date_range = app.scan(/(\d{2})-{0,1}(\d{0,2})\s(.*)/)

      # if no sets left, 
      if(date_range.length == 0)
        return @app_data
      else # scan extra string
        scan_app(date_range[0][2].slice!(/\d{2}-{0,1}\d{0,2}\s.*/))
        @app_data << { :start_year => date_range[0][0], :end_year => date_range[0][1], :text => date_range[0][2].strip}
      end
    end
      
    # Update condition for this variant
    def update_condition_type()
      new_product_option_type = Spree::ProductOptionType.create :product_id => @new_product.id,
                          :option_type_id => @@condition.id

    end

    def create_condition_variant()
      # Create condition variants
      @new_product_condition = Spree::Variant.create :sku => @product_row[:name],
              :is_master => false,
              :product_id => @new_product.id,
              :track_inventory => true,
              :tax_category_id => @@auto_tax_category_id,
              :stock_items_count => 0,
              :notes => ""

      # @new_product_condition.update_column("weight", @product_row.weight) if @product_row.weight.present?
      @new_product_condition_price = Spree::Price.where("variant_id = ?", @new_product_condition.id)
      @new_product_condition_price.first.update_attribute("amount", @product_row[:price])
      @new_product_condition_price.first.update_attribute("core", @product_row[:core]) if @product_row[:core].present?

      @new_product_condition
    end

    def update_conditions_value()
      option_type_values = @new_product.categorise_variants_from_option(@@condition)
      added_value = false
      case @product_row[:condition].to_s.downcase
        when /nos/
          if(!option_type_values[@@value_nos])
            @new_product_condition.option_values << @@value_nos
            added_value = true
          end
        when /nors/
          if(!option_type_values[@@value_nors])
            @new_product_condition.option_values << @@value_nors
            added_value = true
          end
        when /new/
          if(!option_type_values[@@value_new])
            @new_product_condition.option_values << @@value_new
            added_value = true
          end
        when /used/
          notes = @product_row[:condition].to_s.downcase
          notes.slice!("used")
          notes = notes.chomp(" ").tr(",", "")

          if(!option_type_values[@@value_used])
            @new_product_condition.option_values << @@value_used
            @new_product_condition.update_attribute("notes", notes)
            added_value = true
          else
            if(option_type_values[@@value_used].first.notes != notes)
              @new_product_condition.option_values << @@value_used
              @new_product_condition.update_attribute("notes", notes)
              added_value = true
            end
          end
        when /rebuilt/
          if(!option_type_values[@@value_rebuilt])
            @new_product_condition.option_values << @@value_rebuilt
            added_value = true
          end
        when /repro/
          if(!option_type_values[@@value_repro])
            @new_product_condition.option_values << @@value_repro
            added_value = true
          end
        when /remolded/
          if(!option_type_values[@@value_remolded])
            @new_product_condition.option_values << @@value_remolded
            added_value = true
          end
        when /rechromed/
          if(!option_type_values[@@value_rechromed])
            @new_product_condition.option_values << @@value_rechromed
            added_value = true
          end
        when /resleeved/
          if(!option_type_values[@@value_resleeved])
            @new_product_condition.option_values << @@value_resleeved
            added_value = true
          end
        when /restored/
          if(!option_type_values[@@value_restored])
            @new_product_condition.option_values << @@value_restored
            added_value = true
          end
        when /core/
          if(!option_type_values[@@value_core])
            @new_product_condition.option_values << @@value_core
            added_value = true
          end
        else
          @errors << { :part_number => @product_row[:name], :condition => @product_row[:condition], :message => "Could not identify condition" }
          added_value = true
      end

      if (!added_value)
        @errors << { :part_number => @product_row[:name], :condition => @product_row[:condition], :message => "Existing Condition" }
        @new_product_condition.delete
        false
      else 
        true
      end
    end

    ################################################################
    # IMPORT STOCK ITEMS
    ################################################################


    ################################################################
    # DISPLAY ERRORS
    ################################################################
    
    # { :part_number => "", :condition => "", :message => "" }
    def get_errors
      @errors
    end

  end
end
