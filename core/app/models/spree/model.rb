module Spree
	class Model < Spree::Base
		validates :name, presence: true
		belongs_to :make

		validates :start_year, numericality: true
	  	validates :start_year, :inclusion => {:in => 1900..Time.now.year }
	  	validates :end_year, numericality: true
	  	validates :end_year, :inclusion => {:in => 1900..Time.now.year }

	  	validate :start_year_cannot_be_greater_than_end_year

	  	def start_year_cannot_be_greater_than_end_year
  		if start_year > end_year
  			errors.add(:start_year, "can't be greater than end year")
  		end
  	end
	end
end