module Spree
  class ProductsController < Spree::StoreController
    before_action :load_product, only: :show
    before_action :load_taxon, only: :index

    rescue_from ActiveRecord::RecordNotFound, :with => :render_404
    helper 'spree/taxons'

    respond_to :html

    def index
      taxon_words = []

      part_cast_words = process_keywords      

      # Get general search results
      @searcher = build_searcher(params.merge(include_images: true))

      # Hash of { "scope" => base_scope } for each scope type
      @products = @searcher.retrieve_products(part_cast_words, taxon_words) #, make_model_year_words) # get all products that match name and description

      @part_number_id = Spree::Property.where("name=?", "Part Number")
      @cast_number_id = Spree::Property.where("name=?", "Cast Number")

      # Find all taxonomy's
      @taxonomies = Spree::Taxonomy.includes(root: :children)
    end

    def show
      @variants = @product.variants_including_master.active(current_currency).includes([:option_values, :images])
      @product_properties = @product.product_properties.includes(:property)
      @product_applications = @product.product_applications
      @taxon = Spree::Taxon.find(params[:taxon_id]) if params[:taxon_id]
      redirect_if_legacy_path
    end

    private

      def accurate_title
        if @product
          @product.meta_title.blank? ? @product.name : @product.meta_title
        else
          super
        end
      end

      def load_product
        if try_spree_current_user.try(:has_spree_role?, "admin")
          @products = Product.with_deleted
        else
          @products = Product.active(current_currency)
        end
        @product = @products.friendly.find(params[:id])
      end

      def load_taxon
        @taxon = Spree::Taxon.find(params[:taxon]) if params[:taxon].present?
      end

      def redirect_if_legacy_path
        # If an old id or a numeric id was used to find the record,
        # we should do a 301 redirect that uses the current friendly id.
        if params[:id] != @product.friendly_id
          params.merge!(id: @product.friendly_id)
          return redirect_to url_for(params), status: :moved_permanently
        end
      end

      # Determine if user search words are integer
      def integer?(str)
        /\A[+-]?\d+\z/ === str
      end

      ####################################################################
      # Function:     process_keywords
      # Description:  Handle keywords input from search box
      # Input:        None
      # Return:       Array of possible part or cast numbers
      ####################################################################
      def process_keywords
        # Constants
        year_length = 4
        year_short_length = 2

        # return array
        part_cast_words = []
        
        # symbols for search params
        make_sym = :product_applications_application_make_id_eq
        model_sym = :product_applications_application_model_id_eq
        year_sym = :year_range_any

        # get all keywords
        search_words = params[:keywords] ? params[:keywords].split : []
        if search_words.length > 0
          # set up search params (simulate filter)
          params[:search] = { make_sym => "",
                              model_sym => "",
                              year_sym => ""}
          remaining_words = search_words.map {|w| w}
        end

        # Check and identify each keyword
        search_words.each do |word|
          added = false
          # handle numerical values
          if integer?(word)
            # Check for year
            if (word.length === year_length) && (1924..Date.today.year).include?(word.to_i)
              added = true
              params[:search][year_sym] = word
            elsif (word.length === year_short_length) && (24..99).include?(word.to_i)
              added = true
              params[:search][year_sym] = "19" + word
            end
            # Check for part number
            if word.length >= 4
              added = true
              part_cast_words << word
            end
          end

          # check for make / model (could be integer, ex. 300)
          possible_make = Spree::Make.where("lower(abbreviation)=? OR lower(name)=?", word.downcase, word.downcase)
          possible_model = Spree::Model.where("lower(abbreviation)=? OR lower(name)=?", word.downcase, word.downcase)
          # Add make unless already exists
          if possible_make.length > 0 && !params[:search][make_sym].present?
            added = true
            params[:search][make_sym] = possible_make.first.id.to_s
          elsif possible_model.length > 0 && !params[:search][model_sym].present?
            # check if make already found
            make_id = params[:search][make_sym]
            model = possible_model.first
            if make_id && make_id != ""
              if make_id.to_i == model.make_id
                added = true
                params[:search][model_sym] = model.id.to_s
              end
            else # Add model and applicable make
              added = true
              params[:search][model_sym] = model.id.to_s
              params[:search][make_sym] = model.make_id.to_s

              remaining_words.delete_if{ |w| w.downcase == model.make.name.downcase || w.downcase == model.make.abbreviation.downcase}
            end
          end
          
          # remove from keyword search if identified above
          if added
            remaining_words.delete_if{ |w| w.downcase == word.downcase }
          end
        end

        # loop through remaining keywords
        if remaining_words.length > 0
          params[:keywords] = remaining_words.map { |w| w }.join(' ')
        else
          params.delete(:keywords)
        end

        part_cast_words
      end
  end
end
