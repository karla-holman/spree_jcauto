# Spree Configuration
SESSION_KEY = '_spree_session_id'

attachment_config = {

  s3_credentials: {
    access_key_id:     ENV['AWS_ACCESS_KEY_ID'],
    secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
    bucket:            ENV['S3_BUCKET_NAME']
  },

  storage:        :s3,
  s3_headers:     { "Cache-Control" => "max-age=31557600" },
  s3_protocol:    "https",
  bucket:         ENV['S3_BUCKET_NAME'],
  url:            ":s3_domain_url",

  styles: {
      mini:     "48x48>",
      small:    "100x100>",
      product:  "240x240>",
      large:    "600x600>"
  },

  path:           "/:class/:id/:style/:basename.:extension",
  default_url:    "/:class/:id/:style/:basename.:extension",
  default_style:  "product"
}

attachment_config.each do |key, value|
  Spree::Image.attachment_definitions[:attachment][key.to_sym] = value
end

# Shipping calculator
config = Rails.application.config
config.spree.calculators.shipping_methods << Spree::Calculator::Shipping::FlatPercentItemMinResidential
config.spree.calculators.shipping_methods << Spree::Calculator::Shipping::FlatPercentItemMinCommercial
config.spree.calculators.shipping_methods << Spree::Calculator::Shipping::FlatPercentItemRangeResidential
config.spree.calculators.shipping_methods << Spree::Calculator::Shipping::FlatPercentItemRangeCommercial
config.spree.calculators.shipping_methods << Spree::Calculator::Shipping::FlatRateInsurance
config.spree.calculators.shipping_methods << Spree::Calculator::Shipping::FlatRateInsuranceMany