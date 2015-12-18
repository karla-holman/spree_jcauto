module Spree
  class ContactMailer < BaseMailer
    def contact_email(user, message)
      @user = user
      @message = message
      attachments.inline['Logo.png'] = File.read(Rails.root.join("public", "Logo-new.png"))
      if(user[:part_numbers])
      	subject = "#{Spree::Store.current.name} Sell Request From Customer"
      else
      	subject = "#{Spree::Store.current.name} Contact From Customer"
      end
      mail(to: from_address, from: user[:address], subject: subject)
    end
  end
end
