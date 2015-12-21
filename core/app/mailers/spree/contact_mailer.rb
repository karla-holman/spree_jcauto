module Spree
  class ContactMailer < BaseMailer
    def contact_email(user, message, images)
      @user = user
      @message = message

      # User uploaded images
      count = 1
      images.each do |image|
        attachments.inline["User-#{count}.png"] = image
        count += 1
      end

      # JC Auto Logo
      attachments.inline['Logo.png'] = File.read(Rails.root.join("public", "Logo-new.png"))
      
      # determine subject based on form
      if(user[:part_numbers])
      	subject = "#{Spree::Store.current.name} Sell Request From Customer"
      elsif(user[:quote_car])
        subject = "#{Spree::Store.current.name} Service Request From Customer"
      else
      	subject = "#{Spree::Store.current.name} Contact From Customer"
      end
      
      mail(to: from_address, from: user[:address], subject: subject)
    end
  end
end
