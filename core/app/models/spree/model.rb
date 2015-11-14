module Spree
	class Model < Spree::Base
		validates :name, presence: true
		belongs_to :make
	end
end