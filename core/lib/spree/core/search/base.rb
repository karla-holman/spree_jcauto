module Spree
  module Core
    module Search
      class Base
        attr_accessor :properties
        attr_accessor :current_user
        attr_accessor :current_currency
        # logger = Logger.new('C:\Users\JC Auto 1\Desktop\Karla\base.log')

        def initialize(params)
          self.current_currency = Spree::Config[:currency]
          @properties = {}
          prepare(params)
        end

        def retrieve_products(part_num_words, taxon_words)
          # logger.debug("Debug-Logging: Base (16), calling get_base_scope")
          @products = get_base_scope(part_num_words, taxon_words)

          curr_page = page || 1

          unless Spree::Config.show_products_without_price
            @products["base"] = @products["base"].where("spree_prices.amount IS NOT NULL").where("spree_prices.currency" => current_currency)
          end

          # Paginate keyword search and num pages
          @products["base"] = @products["base"].page(curr_page).per(per_page)

          @products
        end

        def method_missing(name)
          if @properties.has_key? name
            @properties[name]
          else
            super
          end
        end

        protected
          def get_base_scope(part_num_words, taxon_words)
            # Get all available products
            if current_user && current_user.admin?
              base_scope = Spree::Product.not_deleted
            else
              base_scope = Spree::Product.active
            end

            # returns products in child taxons
            base_scope = base_scope.in_taxon(taxon) unless taxon.blank?

            # Get new scope based on base_scope (matches name and description)
            if part_num_words.length > 0
              part_num_scope = perform_custom_search(base_scope, part_num_words, "with_part_cast_number")
            end
            if taxon_words.length > 0
              taxon_scope = perform_custom_search(base_scope, taxon_words, "taxon_words")
            end

            # Handle regular search
            base_scope = get_products_conditions_for(base_scope, keywords)

            # search based on filters (ex. price)
            base_scope = add_search_scopes(base_scope)

            base_scope = add_eagerload_scopes(base_scope)

            # Sort by name and uniq entries if no taxon present, otherwise already sorted
            base_scope = base_scope.uniq.order("name ASC") unless !taxon.blank?

            base_scope_hash = {"base" => base_scope, "part_num" => part_num_scope, "taxon" => taxon_scope} #, "application" => application_scope, "application_filter" => application_filter_scope}
          end

          def add_eagerload_scopes scope
            # TL;DR Switch from `preload` to `includes` as soon as Rails starts honoring
            # `order` clauses on `has_many` associations when a `where` constraint
            # affecting a joined table is present (see
            # https://github.com/rails/rails/issues/6769).
            #
            # Ideally this would use `includes` instead of `preload` calls, leaving it
            # up to Rails whether associated objects should be fetched in one big join
            # or multiple independent queries. However as of Rails 4.1.8 any `order`
            # defined on `has_many` associations are ignored when Rails builds a join
            # query.
            #
            # Would we use `includes` in this particular case, Rails would do
            # separate queries most of the time but opt for a join as soon as any
            # `where` constraints affecting joined tables are added to the search;
            # which is the case as soon as a taxon is added to the base scope.
            scope = scope.preload(master: :prices)
            scope = scope.preload(master: :images) if include_images
            scope
          end

          # find custom search results - return first match for each
          def perform_custom_search(base_scope, word_list, list_type)
            scope_name = list_type.to_sym # "with_part_number"
            found_match = false
            word_list.each do |scope_attribute|
              if base_scope.respond_to?(:search_scopes) && base_scope.search_scopes.include?(scope_name.to_sym)
                # Invokes scope_name method, passing *scope_attributes
                if(!base_scope.send(scope_name, scope_attribute).empty? && !found_match)
                  base_scope = base_scope.send(scope_name, scope_attribute)
                  found_match = true
                end
              else
                base_scope = base_scope.merge(Spree::Product.ransack({scope_name => scope_attribute}).result)
              end
            end if word_list
            if(found_match)
              base_scope
            else
              nil
            end
          end

          # find custom search results - return all matches
          # word_list: Hash containing conditions and values to search on (ex. {:make_id => "1"})
          def perform_custom_filter(base_scope, word_list, list_type)
            scope_name = list_type.to_sym # "with_part_number"
            # word_list.each do |scope_attribute|
              # word_list = {:make_id => "1", :model_id => "1", :year => 1955}
              if base_scope.respond_to?(:search_scopes) && base_scope.search_scopes.include?(scope_name.to_sym)
                # Invokes scope_name method, passing *scope_attributes
                if(base_scope.send(scope_name, word_list))
                  # Filter down based on params
                  base_scope = base_scope.send(scope_name, word_list)
                end
              #else
                # base_scope = base_scope.merge(Spree::Product.ransack({scope_name => scope_attribute}).result)
              end
            # end if word_list

            base_scope
          end

          # add filters to search results
=begin
          def add_search_scopes(base_scope)
            filter.each do |name, scope_attribute|
              scope_name = name.to_sym # "with_part_number"
              # :search_scopes defined in scopes.rb, Returns true if obj responds to the given method
              if base_scope.respond_to?(:search_scopes) && base_scope.search_scopes.include?(scope_name.to_sym)
                # Invokes scope_name method, passing *scope_attributes
                base_scope = base_scope.send(scope_name, *scope_attribute)
              else
                base_scope = base_scope.merge(Spree::Product.ransack({scope_name => scope_attribute}).result)
              end
            end if filter
            base_scope
          end
=end
          # Handle Filters
          def add_search_scopes(base_scope)
            search.each do |name, scope_attribute|
              scope_name = name.to_sym
              # Handle date comparison
              if scope_name === :created_at_gteq
                case scope_attribute
                when "prev_month"
                  base_scope = base_scope.merge(Spree::Product.where("spree_products.created_at >= ?", DateTime.now.prev_month))
                when "prev_week"
                  base_scope = base_scope.merge(Spree::Product.where("spree_products.created_at >= ?", DateTime.now.prev_week))
                when "prev_day"
                  base_scope = base_scope.merge(Spree::Product.where("spree_products.created_at >= ?", DateTime.now.prev_day))
                end
              elsif base_scope.respond_to?(:search_scopes) && base_scope.search_scopes.include?(scope_name.to_sym)
                base_scope = base_scope.send(scope_name, *scope_attribute)
              else
                # Narrow down all scopes except make and model (want to get all makes and models)
                if (scope_name == :product_applications_application_make_id_eq) || (scope_name == :product_applications_application_model_id_eq)
                  make = search[:product_applications_application_make_id_eq] ? search[:product_applications_application_make_id_eq].to_i : nil
                  model = search[:product_applications_application_model_id_eq] ? search[:product_applications_application_model_id_eq].to_i : nil
                  # handle just make
                  if make && model
                    model_object = Spree::Model.find(model)
                    word_list = {:make_id => make, :model_id => model, :year_start => model_object.start_year, :year_end => model_object.end_year}
                    base_scope = base_scope.send(:in_make_model, word_list)
                  elsif make
                    word_list = {:make_id => make}
                    base_scope = base_scope.send(:in_make, word_list)
                  end
                else
                  base_scope = base_scope.merge(Spree::Product.ransack({scope_name => scope_attribute}).result)
                end
              end
            end if search

            base_scope
          end

=begin
          def check_for_make_model(base_scope)
            make_id = search["product_applications_application_make_id_eq"]
            model_id = search["product_applications_application_model_id_eq"]
            # If no make or model nothing to do
            if make_id && model_id
              base_scope += Spree::Product.ransack({:product_applications_application_make_id_eq => nil}.result
              base_scope = base_scope.merge(Spree::Product.ransack({:product_applications_application_model_id_eq => nil}).result)
            end
          end
=end

          # method should return new scope based on base_scope
          def get_products_conditions_for(base_scope, query)
            unless query.blank? # search query
              # Get name and desdcription for each product and check for match
              base_scope = base_scope.like_any([:name, :description], query.split)
            end
            base_scope
          end

          def prepare(params)
            @properties[:taxon] = params[:taxon].blank? ? nil : Spree::Taxon.find(params[:taxon])
            @properties[:keywords] = params[:keywords]
            @properties[:filter] = params[:filter]
            @properties[:include_images] = params[:include_images]

            # Handle filters
            if(params[:search] && params[:search][:name_or_meta_keywords_or_description_or_product_properties_value_cont_any])
              if params[:match_exact]
                keyword_string = params[:search][:name_or_meta_keywords_or_description_or_product_properties_value_cont_any]
                params[:search].delete(:name_or_meta_keywords_or_description_or_product_properties_value_cont_any)
                params[:search][:name_or_meta_keywords_or_description_or_product_properties_value_cont] = keyword_string
              else
                params[:search][:name_or_meta_keywords_or_description_or_product_properties_value_cont_any] = params[:search][:name_or_meta_keywords_or_description_or_product_properties_value_cont_any].gsub(/[^A-Za-z0-9\s]/, '').split
              end
            end
            @properties[:search] = params[:search] ? params[:search].reject{|_, v| v == ""} : params[:search] # don't take empty search filters

            puts "Debug-Logging: Base prepared with search #{@properties[:search]}"
            per_page = params[:per_page].to_i
            @properties[:per_page] = per_page > 0 ? per_page : Spree::Config[:products_per_page]
            if params[:page].respond_to?(:to_i)
              @properties[:page] = (params[:page].to_i <= 0) ? 1 : params[:page].to_i
            else
              @properties[:page] = 1
            end
          end
      end
    end
  end
end
