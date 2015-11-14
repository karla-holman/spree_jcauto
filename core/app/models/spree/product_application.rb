module Spree
  class ProductApplication < Spree::Base
    belongs_to :product, touch: true, class_name: 'Spree::Product', inverse_of: :product_applications
    belongs_to :application, class_name: 'Spree::Application', inverse_of: :product_applications

=begin
	validates :start_year, numericality: true
	validates :start_year, :inclusion => {:in => 1900..2020 }
	validates :end_year, numericality: true
	validates :end_year, :inclusion => {:in => 1900..2020 }

	validate :start_year_cannot_be_greater_than_end_year
=end

	before_save :update_name
	after_create :update_name_first

  	self.whitelisted_ransackable_attributes = ['name']
  	self.whitelisted_ransackable_attributes = ['start_year']
  	self.whitelisted_ransackable_attributes = ['end_year']

	def start_year_cannot_be_greater_than_end_year
		if start_year > end_year
			errors.add(:start_year, "can't be greater than end year")
		end
	end
	# virtual attributes for use with AJAX completion stuff

    # Get application name
    def application_name
      byebug
      application.name if application
    end

    # Set application name
    def application_name=(name)
      byebug
      unless name.blank?
      	app_make = name.split[0]
      	app_model = name.split[1]

        unless app = Application.find_by(name: name)
          app = Application.create(
          	make_id: Make.find_by(name: app_make).id ? Make.find_by(name: app_make).id : Make.create(name: app_make).id, 
          	model_id: Model.find_by(name: app_model) ? Model.find_by(name: app_model).id : Model.create(name: app_model).id)
        end
        self.application = app
      end
    end

    # Set Up name and range
    def update_name
       if self.name
	       if application_name && range
				self.update_column(:name, application_name + " " + range)
	    	else
				self.update_column(:name, "No application and/or range specified")
	    	end
	    end
    end

    def update_name_first
    	self.name = "new name"
    	self.save
    end

    def range
    	if start_year && end_year
    		range = start_year.to_s + "-" + end_year.to_s
    	else
    		range = "N/A - N/A"
    	end
    end
  end
end
