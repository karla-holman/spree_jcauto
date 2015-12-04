module Spree
	class Vendor < Spree::Base
	    # has_and_belongs_to_many :prototypes, join_table: 'spree_applications_prototypes'

	    has_many :product_vendors, dependent: :delete_all, inverse_of: :vendor
	    has_many :variants, through: :product_vendors

	    belongs_to :state, class_name: 'Spree::State'
    	belongs_to :country, class_name: 'Spree::Country'

	    validates :name, presence: true
	    validates :name, uniqueness: true
	    # validates :make_id, :model_id, presence: true

	    scope :sorted, -> { order(:model) }

	    after_touch :touch_all_products
	    before_save :set_country_create, only: :create
	    # before_save :update_name
	    # after_create :update_name_first

	    self.whitelisted_ransackable_attributes = ['name']
	    self.whitelisted_ransackable_attributes = ['phone']

	    def state_text
	      state.try(:abbr) || state.try(:name) || state_name
	    end

	    private

	    def touch_all_products
	      products.update_all(updated_at: Time.current)
	    end

		def set_country_create
			self.country ||= Spree::Country.default
			rescue ActiveRecord::RecordNotFound
			flash[:error] = Spree.t(:vendor_need_a_default_country)
		end
	end
end

