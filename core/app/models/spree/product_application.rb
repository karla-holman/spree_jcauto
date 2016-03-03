module Spree
  class ProductApplication < Spree::Base
    belongs_to :product, touch: true, class_name: 'Spree::Product', inverse_of: :product_applications
    belongs_to :application, class_name: 'Spree::Application', inverse_of: :product_applications


  	validates :start_year, numericality: true
  	validates :start_year, :inclusion => {:in => 1900..Time.now.year }
  	validates :end_year, numericality: true
  	validates :end_year, :inclusion => {:in => 1900..Time.now.year }
    validates :application_id, uniqueness: { scope: [:start_year, :end_year, :notes, :product_id] }

  	validate :start_year_cannot_be_greater_than_end_year
    validate :years_cannot_be_outside_model_date

  	before_save :update_name
  	after_create :update_name_first

  	self.whitelisted_ransackable_attributes = ['name']
  	self.whitelisted_ransackable_attributes = ['start_year']
  	self.whitelisted_ransackable_attributes = ['end_year']

    self.whitelisted_ransackable_attributes = %w[name start_year end_year]
    self.whitelisted_ransackable_associations = %w[application]

  	def start_year_cannot_be_greater_than_end_year
  		if start_year > end_year
  			errors.add(:start_year, "can't be greater than end year")
  		end
  	end

    # Check if application years fit with model years
    def years_cannot_be_outside_model_date
      if self.application && self.application.model
        model_start = self.application.model.start_year
        model_end = self.application.model.end_year
        if self.start_year > model_end || self.end_year < model_start
          errors.add(:start_year, "can't be outside of model construction dates")
        end
      end
    end

  	# virtual attributes for use with AJAX completion stuff

    # Get application name
    def application_name
      application.name if application
    end

    # Set application name
    def application_name=(name)
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
        if application_name || self.notes != ""
          my_notes = self.notes != "" ? " (" + self.notes + ")" : self.notes
          my_app = application_name ? " " + application_name : ""
          self.update_column(:name, range + my_app + my_notes)
        else
      	  self.update_column(:name, "No application and/or description specified")
        end
      end
    end

    def update_name_first
    	self.name = "new name"
    	self.save
    end

    def range
    	if start_year && end_year
        if start_year == end_year
          range = start_year.to_s
        else
    		  range = start_year.to_s + "-" + end_year.to_s
        end
    	else
    		range = "N/A - N/A"
    	end
    end
  end
end
