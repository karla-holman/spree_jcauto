module Spree
	class Model < Spree::Base
		validates :name, presence: true
		belongs_to :brand
	end
end