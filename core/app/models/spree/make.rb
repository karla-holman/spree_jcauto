module Spree
	class Make < Spree::Base
		has_many :models

		after_create :create_application_if_not_exist

		def create_application_if_not_exist
			# Create application for just make
  			unless application = Application.find_by(make_id: id, model_id: nil)
          		application = Application.create(make_id: id, model_id: nil)
          	end
        end
	end
end
