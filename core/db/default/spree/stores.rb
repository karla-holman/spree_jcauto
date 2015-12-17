# Possibly already created by a migration.
unless Spree::Store.where(code: 'jcauto').exists?
  Spree::Store.new do |s|
    s.code              = 'jcauto'
    s.name              = 'JC Auto Restoration'
    s.url               = 'jcauto.com'
    s.mail_from_address = 'holmankarla@gmail.com'
  end.save!
end