module Spree
  class ProductsController < Spree::StoreController
    before_action :load_product, only: :show
    before_action :load_taxon, only: :index

    rescue_from ActiveRecord::RecordNotFound, :with => :render_404
    helper 'spree/taxons'

    respond_to :html

    def index
      # Constants
      part_number_length = 7
      year_length = 4
      part_cast_words = []
      make_model_year_words = {:keywords => []}
      taxon_words = []

      # get all keywords for part/cast number search
      search_words = params[:keywords]? params[:keywords].split : []
      # Handle special search values
      search_words.each do |word|
        if word.length === part_number_length
          part_cast_words << word
        elsif word.length === year_length
          make_model_year_words[:keywords] << word
        # tie in with database later
        elsif "chrysler dodge plymouth imperial desoto truck".include?(word)
          make_model_year_words[:keywords] << word
        end
      end

      # check make/model/year params
      if params[:make_id]
        make_model_year_words[:make_id] = params[:make_id]
      end
      if params[:model_id]
        make_model_year_words[:model_id] = params[:model_id] === "" ? nil : params[:model_id] 
      end
      if params[:year]
        make_model_year_words[:year] = params[:year]
      end

      # Get general search results
      @searcher = build_searcher(params.merge(include_images: true))

      # Hash of { "scope" => base_scope } for each scope type
      @products = @searcher.retrieve_products(part_cast_words, taxon_words, make_model_year_words) # get all products that match name and description

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
  end
end
