module Spree
	class Application < Spree::Base
	    # has_and_belongs_to_many :prototypes, join_table: 'spree_applications_prototypes'
		belongs_to :model
		belongs_to :make

	    has_many :product_applications, dependent: :delete_all, inverse_of: :application
	    has_many :products, through: :product_applications

	    # validates :make_id, :model_id, presence: true

	    scope :sorted, -> { order(:model) }

	    after_touch :touch_all_products
	    before_save :update_name
	    after_create :update_name_first

	    self.whitelisted_ransackable_attributes = ['make_id']
	    self.whitelisted_ransackable_attributes = ['model_id']

	    private

	    def touch_all_products
	      products.update_all(updated_at: Time.current)
	    end

	    def update_name
	       if self.name
		       make_name = self.make ? make.name : "No Make"
		       model_name = self.model ? model.name : ""
		       self.update_column(:name, make_name + " " + model_name)
		    end
	    end

	    def update_name_first
	    	self.name = "new name"
	    	self.save
	    end
	end
end
