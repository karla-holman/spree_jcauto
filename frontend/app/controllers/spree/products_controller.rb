module Spree
  class ProductsController < Spree::StoreController
    before_action :load_product, only: :show
    before_action :load_taxon, only: :index

    rescue_from ActiveRecord::RecordNotFound, :with => :render_404
    helper 'spree/taxons'

    respond_to :html

    def index
      # Constants
      year_length = 4
      part_cast_words = []
      # make_model_year_words = {:keywords => []}
      taxon_words = []

      # get all keywords for part/cast number search
      search_words = params[:keywords]? params[:keywords].split : []
      if search_words.length > 0
        # set up search params (simulate filter)
        params[:search] = {:product_applications_application_make_id_eq => "",
                           :product_applications_application_model_id_eq => "",
                           :year_range_any => ""}
      end
      # Handle special search values
      search_words.each do |word|
        # handle numerical values
        if integer?(word)
          # Check for year
          if (word.length === year_length) && (1924..Date.today.year).include?(word.to_i)
            params[:search][:year_range_any] = word
          end

          # Check for part number
          part_cast_words << word

        # check for make / model 
        else
          possible_make = Spree::Make.where("lower(abbreviation)=? OR lower(name)=?", word.downcase, word.downcase)
          possible_model = Spree::Model.where("lower(abbreviation)=? OR lower(name)=?", word.downcase, word.downcase)

          # try to add make first, if make exists try to add model
          if possible_make.length > 0 && (!params[:search][:product_applications_application_make_id_eq] || params[:search][:product_applications_application_make_id_eq] == "")
            params[:search][:product_applications_application_make_id_eq] = possible_make.first.id.to_s
          elsif possible_model.length > 0 && (!params[:search][:product_applications_application_model_id_eq] || params[:search][:product_applications_application_model_id_eq] == "")
            params[:search][:product_applications_application_model_id_eq] = possible_model.first.id.to_s
          end
        end
      end

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
  end
end
