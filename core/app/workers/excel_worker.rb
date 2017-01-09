module Spree
	class ExcelWorker
		include Sidekiq::Worker
		errors = []

		def perform(file)
			byebug
			begin
				my_excel = Spree::Excel.new(file)
			rescue Exception => e
        errors = e.message
      end

      if (my_excel)
        my_excel.import_product_file()
        errors = my_excel.get_errors
      end

      my_excel.destroy
      message = Spree::ContactMailer.contact_email(try_spree_current_user, errors)
	    message.deliver_later
		end
	end
end