module Spree
	class Model < Spree::Base
		validates :name, presence: true
		belongs_to :make
		has_many :applications, dependent: :destroy

		validates :name, presence: true
		validates :name, uniqueness: { scope: [:make_id] }
		validates :abbreviation, uniqueness: true, :allow_blank => true

		validates :start_year, numericality: true
	  	validates :start_year, :inclusion => {:in => 1900..Time.now.year }
	  	validates :end_year, numericality: true
	  	validates :end_year, :inclusion => {:in => 1900..Time.now.year }

	  	validate :start_year_cannot_be_greater_than_end_year

	  	after_create :create_application_if_not_exist

	  	def start_year_cannot_be_greater_than_end_year
	  		if start_year > end_year
	  			errors.add(:start_year, "can't be greater than end year")
	  		end
  		end

  		def create_application_if_not_exist
  			unless application = Application.find_by(make_id: make_id, model_id: id)
          		application = Application.create(make_id: make_id, model_id: id)
          	end
        end
	end
end