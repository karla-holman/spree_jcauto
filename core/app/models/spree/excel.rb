module Spree
  class Excel < Spree::Base
    has_attached_file :spreadsheet, url: '/spreadsheets/:id/:style/:basename.:extension'
    #validates_attachment :spreadsheet, presence: true
    validates_attachment_file_name :spreadsheet, :matches => [/xlsx\Z/, /xls\Z/, /csv\Z/]
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
    @@value_relined = Spree::OptionValue.where("name=?", "relined").first

    # Stock Locations
    @@loc_suite2 = Spree::StockLocation.where("admin_name=?", "Suite 2").first
    @@loc_suite2_nfs = Spree::StockLocation.where("admin_name=?", "Suite 2 (nfs)").first
    @@loc_suite3 = Spree::StockLocation.where("admin_name=?", "Suite 3").first
    @@loc_home = Spree::StockLocation.where("admin_name=?", "Home").first
    @@loc_home_nfs = Spree::StockLocation.where("admin_name=?", "Home (nfs)").first
    @@loc_warehouse = Spree::StockLocation.where("admin_name=?", "Warehouse").first
    @@loc_east_racks = Spree::StockLocation.where("admin_name=?", "East Racks").first
    @@loc_attic = Spree::StockLocation.where("admin_name=?", "George's Attic").first

    # pass in file object from params[:file]
=begin
    def initialize(file)
      uploaded_file = file #params[:file]
    end
=end

    # Import spreadsheet that fits product structure
    def import_product_file()
      # local
      # file = open(self.spreadsheet.path)
      file = open(self.spreadsheet.url(:original))
      full_file = File.open(file.path)
      @workbook = RubyXL::Parser.parse(full_file)
      @worksheet_products = @workbook[0]
      @errors = []
      @worksheet_products.each { |row|
        if(@product_row = build_row_hash(row))
          import_product()
        end
      }
    end

    # Import spreadsheet that fits product structure
    def import_inventory_file()
      @worksheet_products.each { |row|
        if(@inventory_row = build_inventory_hash(row))
          import_inventory()
        end
      }
    end

    # Import spreadsheet that fits product structure
    def import_vendor_file()
      @worksheet_products.each { |row|
        if(@vendor_row = build_vendor_hash(row))
          import_vendor()
        end
      }
    end

    ################################################################
    # IMPORT PRODUCT
    ################################################################

    # return hash of fields and values from spreadsheet
    def build_row_hash(row)
      if(!row.cells[0].value) # skip empty rows
        return nil # Skip row if no name or header
      elsif(row.cells[0].datatype == "s" && row.cells[0].value.match(/name|item|\A\D*\Z/i))
        @errors << { :part_number => "N/A", :condition => "N/A", :message => "Found and skipped excel header" }
        return nil # Skip row if  header
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
        :description => (row.cells[2] ? row.cells[2].value.tr('***', '').chomp('-') : ''),
        :meta_keywords => (row.cells[3] ? row.cells[3].value : ''),
        :price => (row.cells[9] ? row.cells[9].value : 0),
        :core => (row.cells[10] ? row.cells[10].value : 0),
        :cost => (row.cells[15] ? row.cells[15].value : 0),
        :vendor => (row.cells[16] ? row.cells[16].value : ''),
        :vendor_price => (row.cells[17] ? row.cells[17].value : 0),
        :vendor_part_number => (row.cells[18] ? row.cells[18].value : ''),
        :length => (row.cells[19] ? row.cells[19].value : ''),
        :width => (row.cells[20] ? row.cells[20].value : ''),
        :height => (row.cells[21] ? row.cells[21].value : ''),
        :weight => (row.cells[22] ? row.cells[22].value : ''),
        :notes => (row.cells[12] ? row.cells[12].value : ''),
        :application => (row.cells[4] ? row.cells[4].value : ''),
        :location => (row.cells[5] ? row.cells[5].value : ''),
        :condition => (row.cells[6] ? row.cells[6].value : ''),
        :cross_ref => (row.cells[7] ? row.cells[7].value : ''),
        :cast_num => (row.cells[8] ? row.cells[8].value : ''),
        :available => (row.cells[13] ? row.cells[13].value : 'N'), # for sale? (count in inventory)
        :active => (row.cells[14] ? row.cells[14].value : 'FALSE'), # active (visible to users)
        :quantity => (row.cells[11] ? row.cells[11].value : 0),
        :package => (row.cells[23] ? row.cells[23].value : '')
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

      # If condition option type does not exist
      if(@new_product.option_types.where("name=?", "Condition").length == 0)
        @errors << { :part_number => @product_row[:name], :condition => @product_row[:condition], :message => "Updating Condition Type" }
        # update_condition_type
      end

      # only continue if this condition and part number does not already exist
      if update_conditions_value
        @errors << { :part_number => @product_row[:name], :condition => @product_row[:condition], :message => "Updating Condition Value" }
        if @product_row[:quantity] && @product_row[:quantity] > 0
          add_quantity(@product_row[:quantity], @new_product_condition, @product_row[:location], @product_row)
        end

      end

      # add vendor
      if @product_row[:vendor]
        add_vendor()
      end
    end

    # Return a new product from each row of worksheet
    def create_product()
      # check for existing slug
      slug = @product_row[:name]
      if(Spree::Product.where("slug=?", slug).length > 0)
        @errors << { :part_number => @product_row[:name], :condition => @product_row[:condition], :message => "Found duplicate slug (url) for " + slug }
      end

      # Get description
      description = @product_row[:description]
      # Get with from w/
      if @product_row[:description].downcase.include? "w/o"
        description = @product_row[:description].gsub(/w\/o/i,"without ")
        description.strip!
      elsif @product_row[:description].downcase.include? "w/"
        description = @product_row[:description].gsub(/w\//i,"with ")
        description.strip!
      end
      new_product = Spree::Product.create :name => @product_row[:name],
                 :description => description,
                 :meta_keywords => @product_row[:meta_keywords],
                 :available_on => DateTime.new(2015,1,1),
                 :slug => slug,
                 :tax_category_id => @@auto_tax_category_id,
                 :shipping_category_id => @@shipping_category_id,
                 :promotionable => true,
                 :price => @product_row[:price], # Defines master price
                 :notes => @product_row[:notes]
    end

    # parse part group number and add appropriate taxon
    def add_part_group_taxon()
      new_taxons = @product_row[:category].to_s.split(",")
      new_taxons.each do |category|
        category.strip!
        my_taxon = Spree::Taxon.where("description=?", category)
        my_taxonomy = Spree::Taxon.where("description=?", category.split('-')[0])
        if(my_taxon.length === 0 || my_taxonomy.length === 0)
          @errors << { :part_number => @product_row[:name], :condition => @product_row[:condition], :message => "Unable to identify proper part group for " + @product_row[:category].to_s }
        end
        @new_product.taxons << my_taxon
        @new_product.taxons << my_taxonomy
      end

      # add package taxon
      if(@product_row[:package] && @product_row[:package].to_s.downcase === "y")
        package_taxon = Spree::Taxon.where("name=?", "Packages and Assemblies")
        @new_product.taxons << package_taxon
      end
    end

    # Update and return master variant for new product
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

    # Create properties for new product
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

    # Update Applications for new product
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
        if make_model_sets.empty? # if empty text set could be all
          make_model_sets = [" "]
          @errors << { :part_number => @product_row[:name], :condition => @product_row[:condition], :message => "No application text sets for this product" }
        end
        make_model_sets_enum = make_model_sets.to_enum

        # Create product application for each date/app set
        make_model_sets_enum.each do |make_model_set|
          my_notes = ""
          my_exceptions = ""
          my_make = nil
          my_model = nil

          # If exception, it includes remaining words
          if (exceptions = make_model_set.match(/(.*|\A)(exc{0,1}[\.\s]{1})(.*)/)) || (exceptions = make_model_set.match(/(.*|\A)(except\s{0,1})(.*)/))
            next_values = ""
            found_current=false
            while true # loop to find exception, then add all words after it to exception notes
              begin
                if(found_current) # add words following exception to notes
                  next_values += next_values!="" ? ", " + make_model_sets_enum.next : make_model_sets_enum.next
                elsif(make_model_sets_enum.next == make_model_set) # If you've reached exception
                  found_current=true
                end
              rescue StopIteration
                break
              end
            end


            my_exceptions = "except " + exceptions[3].strip + next_values
            make_model_set = exceptions[1].strip

          end

          # split make, model and notes into text
          words = make_model_set.split
          words.each do |word| # loop through each to match to make, model, or notes
            next if (word.match(/\d{1,2}-{1}\d{1,2}/) && exceptions) # don't keep if range for exception

            # Get with from w/
            if word.downcase.include? "w/o"
              word.gsub!(/w\/o/i,"without ").strip!
            elsif word.downcase.include? "w/"
              word.gsub!(/w\//i,"with ").strip!
            end

            word.gsub!(/[\W&&[^- ]]/,"") # Replace all non-word characters except - or space with ""
            # try to match abbreviation

            # If no make spefied
            if !my_make
              # try to find a make
              if (check = (Spree::Make.where("abbreviation=? OR name=?", word, word).first))
                my_make = check
              # otherwise try to find a model
              elsif (check = (Spree::Model.where("abbreviation=? OR name=?", word, word).first))
                my_model = check
              # Otherwise no matching make or model, add to notes
              else
                my_notes += my_notes!="" ? " " + word : word
              end
            # If make already exists, find model with that make
            else
              if (check = (Spree::Model.where("(abbreviation=? OR name=?) AND make_id=?", word, word, my_make.id).first))
                my_model = check
              else # No matching make for that model
                # check for any matching model
                if (check = (Spree::Model.where("abbreviation=? OR name=?", word, word).first))
                  my_model = check
                # otherwise add to notes
                else
                  my_notes += my_notes!="" ? " " + word : word
                end
              end
            end # end if statement
          end # end word loop


          if(my_make && my_model)
            my_application = Spree::Application.where("make_id=? AND model_id=?", my_make.id, my_model.id).first
          elsif(my_make)
            my_application = Spree::Application.where("make_id=? AND model_id IS ?", my_make.id, nil).first
          elsif(my_model)
            my_application = Spree::Application.where("model_id=?", my_model.id).first
          else # Applies to all
            my_application = Spree::Application.where("make_id IS ? AND model_id IS ?", nil, nil).first
          end

          # if my notes and my model is empty, applies to all
          my_notes = ((!my_notes || my_notes=="") && !my_model) ? "all models" : my_notes

          # add exceptions to the end of notes
          my_notes += (my_notes!="" && my_exceptions != "") ? " " + my_exceptions : my_exceptions

          if(my_application || my_notes != "")
            Spree::ProductApplication.create :start_year => start_year.to_i,
                                         :end_year => end_year.to_i,
                                         :application => my_application,
                                         :product => @new_product,
                                         :notes => my_notes
          end

          if( !my_make && !my_model )
            @errors << { :part_number => @product_row[:name], :condition => @product_row[:condition], :message => "Could not find make or model for " + make_model_set }
          end

          if(my_exceptions != "")
            break # break out of make_model_set loop if remaining words are exception
          end
        end # end make_model_sets ex. "Plymouth Valiant "
      end # end @app_data loop ex. { :start_year => "60", :end_year => "9", :text => "Plymouth Valiant "}
    end # end add_applications()

    # build array of years and applications
    def scan_app(app)
      format_regular = true
      if (!app) # end recursion
        return @app_data
      end

      # remove leading ;
      if app.is_a? Integer # for applications that are just one year
        app = app.to_s
      else
        app.sub!(/^\;/, "")
      end

      # check for string starting with dates
      date_range = app.scan(/\A\W*(\d{2})-{0,1}(\d{0,2})\s(.*)/)

      # if reverse format (text first, then date)
      if(date_range.length == 0)
        # check if make/model are before date
        if((date_range2 = app.scan(/(\D*)(\d{2})-{0,1}(\d{0,2})\s*(.*)/)).length == 0)
          return @app_data
        else # Set correct values
          format_regular = false
          date_range[0] = []
          date_range[0][0] = date_range2[0][1] # set correct start year
          date_range[0][1] = date_range2[0][2] # set correct end year
          date_range[0][2] = date_range2[0][0] + " " + date_range2[0][3] # set correct text
        end
      end

      #if(date_range[0][2].slice(/\;.*/)) # scan items separated by semi-colon
        scan_app(date_range[0][2].slice!(/\;.*/))
      #else
        #scan_app(date_range[0][2].slice!(/\d{2}-{0,1}\d{0,2}\s.*/)) # scan dates remaining
      #end

      @app_data << { :start_year => date_range[0][0], :end_year => date_range[0][1], :text => date_range[0][2].strip}
      # end
    end

    # called if vendor specified in spreadsheet
    def add_vendor
      vendor = @product_row[:vendor].match(/[\D\s]*/)
      vendors = Spree::Vendor.where("name ILIKE ?", "%#{vendor[0].strip}%")
      if !(vendors.empty?)
        if(@product_row[:vendor].match(/goers/i))
          notes = notes = "" ? @product_row[:vendor] : notes + ", " + @product_row[:vendor]
        end

        @new_product_vendor = Spree::ProductVendor.create :variant_id => @new_product_condition.id,
              :vendor_id => vendors.first.id,
              :vendor_part_number => @product_row[:vendor_part_number],
              :vendor_price => @product_row[:vendor_price],
              :notes => notes
      else
        @errors << { :part_number => @product_row[:name], :condition => @product_row[:condition], :message => "Could not match vendor " + @product_row[:vendor] }
      end
    end

    # Add condition option type for this product
    def update_condition_type()
      new_product_option_type = Spree::ProductOptionType.create :product_id => @new_product.id,
                          :option_type_id => @@condition.id
    end

    # called if no condition value exists
    def create_condition_variant(option_value)
      active = (@product_row[:active] == 1) ? true : false
      # Create condition variants
      @new_product_condition = Spree::Variant.create :sku => @product_row[:name],
              :is_master => false,
              :product_id => @new_product.id,
              :track_inventory => true,
              :tax_category_id => @@auto_tax_category_id,
              :stock_items_count => 0,
              :active => active,
              :notes => ""

      # Set price and core price
      @new_product_condition_price = Spree::Price.where("variant_id = ?", @new_product_condition.id)
      @new_product_condition_price.first.update_attribute("amount", @product_row[:price])
      @new_product_condition_price.first.update_attribute("core", @product_row[:core]) if @product_row[:core].present?

      # Add option value
      @new_product_condition.option_values << option_value

      @new_product_condition
    end

    # determine if new condition and/or stock location
    def update_conditions_value()
      # get all condition variants
      option_type_values = @new_product.categorise_variants_from_option(@@condition)
      @notes = "" # for used parts with extra condition details

      # determine condition value
      if(!(value = determine_condition(@product_row[:condition])))
        return false
      end

      if(!option_type_values[value]) # if value does not already exist
        @new_product_condition = create_condition_variant(value) # create new variant with value
        if(@notes != "") # if used part with additional condition information
          @new_product_condition.update_attribute("notes", @notes)
        end
      else # otherwise check for used condition variations
        if(@notes != "") # if used note variants
          if(option_type_values[value].first.notes != @notes) # create new variant with notes if does not exist
            @new_product_condition = create_condition_variant(value)
            @new_product_condition.update_attribute("notes", @notes)
          else # if value and notes already exists get existing variant
            @new_product_condition = option_type_values[value].first
          end
        else # otherwise get existing condition
          @new_product_condition = option_type_values[value].first
        end
      end
      # try to add new stock_item sub location
      if(create_stock_item)
        true # return true for new condition or location
      else
        @errors << { :part_number => @product_row[:name], :condition => @product_row[:condition], :message => "Existing Condition and location" }
        false # return false for existing condition and location
      end
    end

    # return OptionValue object
    def determine_condition(condition)
      case condition.to_s.downcase
        when /nos/
          @@value_nos
        when /nors/
          @@value_nors
        when /new/
          @@value_new
        when /used/
          @notes = @product_row[:condition].to_s.downcase
          @notes.slice!("used")
          @notes = @notes.tr(",", "").strip
          @@value_used
        when /rebuilt/
          @@value_rebuilt
        when /repro/
          @@value_repro
        when /remolded/
          @@value_remolded
        when /rechromed/
          @@value_rechromed
        when /resleeved/
          @@value_resleeved
        when /restored/
          @@value_restored
        when /core/
          @@value_core
        when /relined/
          @@value_relined
        else
          @errors << { :part_number => @product_row[:name], :condition => @product_row[:condition], :message => "Could not identify condition" }
          return false
      end
    end

    ################################################################
    # IMPORT STOCK ITEMS
    ################################################################

    # return true if new stock location created
    def create_stock_item

      added_new_stock_item = false
      # Get stock location for appropriate location
      @product_row[:location].split(',').each do |sub_location|
        sub_location.chomp!
        stock_location = case sub_location.to_s.downcase
        when /george/
          @@loc_attic
        # NFS no matter what - JC10 OR buffalo display case OR back shop
        when /jc\d{1,2}|buffalo|back\sshop|attic/
          @@loc_home_nfs
        # NFS if listed as not for sale (don't count in quantity)
        when /w\d{1,2}/
          (@product_row[:available] && @product_row[:available].downcase == "n") ? @@loc_home_nfs : @@loc_home
        when /[[:alpha:]]\d{2,3}|D\d{3}\.\d|h\d|file\scabinet|suite\s2/
          (@product_row[:available] && @product_row[:available].downcase == "n") ? @@loc_suite2_nfs : @@loc_suite2
        # NWC08
        when /nw[[:alpha:]]\d{1,2}|ste3/
          @@loc_suite3
        # Warehouse
        when /warehouse/
          @@loc_warehouse
        # West trailer OR east racks
        when /east\sracks|west\strailer/
          @@loc_east_racks
        else # if unidentifiable location
          @errors << { :part_number => @product_row[:name], :condition => @product_row[:condition], :message => "Cannot identify location " + sub_location }
          next # skip to next location
        end

        # if no exisiting sub location, add one
        if(@new_product_condition.add_sub_location(sub_location, stock_location))
          added_new_stock_item = true
        end

      end # end location loop

      added_new_stock_item # return true if at least one new stock item added

    end

    # Add quantity to variant at sub_location
    def add_quantity(quantity, variant, sub_location, row_hash)
      # if only one sub location listed
      if sub_location.split(",").length > 1
        @errors << { :part_number => row_hash[:name], :condition => row_hash[:condition], :message => "Cannot add initial quantity for part with multiple sub locations (#{sub_location})" }
      # otherwise if there is a sub_location stock item
      elsif stock_item = variant.sub_location(sub_location)
      #if !(stock_item = @new_product_condition.where("sub_location=?", sub_location)).empty
        stock_item.adjust_count_on_hand(quantity)
      else
        @errors << { :part_number => row_hash[:name], :condition => row_hash[:condition], :message => "Cannot find stock item for " + sub_location }
      end

    end

    # return hash of fields and values from spreadsheet
    def build_inventory_hash(row)
      if(!row.cells[0].value) # skip empty rows
        return nil # Skip row if no name or header
      elsif(row.cells[0].datatype == "s" && row.cells[0].value.match(/name|item|\A\D*\Z/i))
        @errors << { :part_number => "N/A", :condition => "N/A", :message => "Found and skipped excel header" }
        return nil # Skip row if  header
      end

      product_name = row.cells[0].value.to_s

      # Get name (and condition if specified)
      if matches = product_name.match(/^(\d{7})(.*)/)
        product_name = matches[1]
        condition = matches[2] != "" ? matches[2] : ""
      end

      @inventory_row = {
        :name => product_name,
        :condition => condition,
        :location => row.cells[1].value,
        :quantity => row.cells[3].value
      }

    end

    def import_inventory()
      # add inventory to existing part
      if (matching_products = Spree::Product.where("name=?", @inventory_row[:name])).length > 0
        # Product and master variant exist
        @new_product = matching_products.first
      else # if no part generate error
        # Create product and master variant
        @errors << { :part_number => @inventory_row[:name], :condition => @inventory_row[:condition], :message => "Cannot find existing part " + @inventory_row[:name] }
        return false
      end

      # if no condition specified in name, add to first variant at location
      if(@inventory_row[:condition] == "")
        if(stock_item = @new_product.stock_items.detect { |l| l.sub_location == (@inventory_row[:location]) })
          stock_item.adjust_count_on_hand(@inventory_row[:quantity])
        else # location cannot be found for that part
           @errors << { :part_number => @inventory_row[:name], :condition => @inventory_row[:condition], :message => "Cannot find variant with location of " + @inventory_row[:location]}
        end
      else
        # determine condition value
        if(value = determine_condition(@inventory_row[:condition]))
          # get variant and stock item
          option_type_values = @new_product.categorise_variants_from_option(@@condition)
          if((variant = option_type_values[value]) && (stock_item = variant.first.sub_location(@inventory_row[:location])))
            # set stock item count
            stock_item.adjust_count_on_hand(@inventory_row[:quantity])
          else
            @errors << { :part_number => @inventory_row[:name], :condition => @inventory_row[:condition], :message => "Cannot find variant with condition " + @inventory_row[:condition] + " and sub location of " + @inventory_row[:location] }
          end
        else
          # value does not exist!
          @errors << { :part_number => @inventory_row[:name], :condition => @inventory_row[:condition], :message => "Cannot find variant with condition of " + @inventory_row[:condition] }
        end
      end
    end

    ################################################################
    # IMPORT VENDORS
    ################################################################
    # return hash of fields and values from spreadsheet
    def build_vendor_hash(row)
      if(!row.cells[0].value) # skip empty rows
        return nil # Skip row if no name or header
      elsif(row.cells[0].datatype == "s" && row.cells[0].value.match(/name/i))
        @errors << { :part_number => "N/A", :condition => "N/A", :message => "Found and skipped excel header" }
        return nil # Skip row if  header
      end

      @vendor_row = {
        :name => row.cells[0] ? row.cells[0].value : nil,
        :address1 => row.cells[6] ? row.cells[6].value : nil,
        :address2 => row.cells[7] ? row.cells[7].value : nil,
        :phone => row.cells[2] ? row.cells[2].value : nil,
        :email => row.cells[4] ? row.cells[4].value : nil,
        :fax => row.cells[3] ? row.cells[3].value : nil,
        :website => row.cells[5] ? row.cells[5].value : nil,
        :contact_name => row.cells[1] ? row.cells[1].value : nil,
        :city => row.cells[8] ? row.cells[8].value : nil,
        :state => row.cells[9] ? row.cells[9].value : nil,
        :country => row.cells[10] ? row.cells[10].value : nil,
        :zipcode => row.cells[11] ? row.cells[11].value : nil,
        :notes => row.cells[13] ? row.cells[13].value : nil,
        :currency => row.cells[12] ? row.cells[12].value : nil
      }

    end

    def import_vendor()
      # get state_id and country_id
      if(@vendor_row[:country])
        countries = Spree::Country.where("iso3 ILIKE ? OR name ILIKE ?", "%#{@vendor_row[:country]}%", "%#{@vendor_row[:country]}%")
      else
        countries = []
      end

      if countries.empty?
        if(@vendor_row[:country])
          @errors << { :part_number => @vendor_row[:name], :condition => "N/A", :message => "Cannot identify country with name #{@vendor_row[:country]}" }
        else
          @errors << { :part_number => @vendor_row[:name], :condition => "N/A", :message => "No country listed, setting to default (#{Spree::Country.default})" }
        end
      else
        country_id = countries.first.id
        if(@vendor_row[:state])
          states = Spree::State.where("(abbr ILIKE ? OR name ILIKE ?) AND country_id = ?", "%#{@vendor_row[:state]}%", "%#{@vendor_row[:state]}%", countries.first.id)
        else
          states = []
        end

        if states.empty?
          @errors << { :part_number => @vendor_row[:name], :condition => "N/A", :message => "Cannot identify state with name #{@vendor_row[:state]}"  }
        else
          state_id = states.first.id
        end
      end

      # make sure website is http://
      if @vendor_row[:website]
        website = @vendor_row[:website].match(/http:\/\//) ? @vendor_row[:website] : "http://" + @vendor_row[:website]
      end

      # add inventory to existing part
      @vendor = Spree::Vendor.create :name => @vendor_row[:name],
                                     :address1 => @vendor_row[:address1],
                                     :address2 => @vendor_row[:address2],
                                     :phone => @vendor_row[:phone],
                                     :fax => @vendor_row[:fax],
                                     :email => @vendor_row[:email],
                                     :website => website,
                                     :contact_name => @vendor_row[:contact_name],
                                     :city => @vendor_row[:city],
                                     :state_name => @vendor_row[:state],
                                     :zipcode => @vendor_row[:zipcode],
                                     :notes => @vendor_row[:notes],
                                     :country_id => country_id,
                                     :state_id => state_id,
                                     :currency => @vendor_row[:currency]

    end

    ################################################################
    # DISPLAY ERRORS
    ################################################################

    # { :part_number => "", :condition => "", :message => "" }
    def get_errors
      @errors
    end
  end
end
