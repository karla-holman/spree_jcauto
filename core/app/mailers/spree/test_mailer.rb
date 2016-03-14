module Spree
  class TestMailer < BaseMailer
    def test_email(email)
      # attachments.inline['Logo.png'] = File.read(Rails.root.join("public", "Logo-new.png"))
      subject = "#{Spree::Store.current.name} #{Spree.t('test_mailer.test_email.subject')}"
      mail(to: email, from: from_address, subject: subject)
    end
  end
end
