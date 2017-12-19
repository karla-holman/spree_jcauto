#module Spree
	class ExcelWorker
		include Sidekiq::Worker
		errors = []

		def perform(excel_id)
			begin
				my_excel = Spree::Excel.find(excel_id)
			rescue Exception => e
        errors = e.message
      end

      if (my_excel)
        my_excel.import_product_file()
				logger.info "File has been imported"
        errors = my_excel.get_errors
      end

      # my_excel.destroy
      message = Spree::ContactMailer.contact_email({excel_upload: true}, errors, [])
	    message.deliver_later
		end
	end
#end
