module Spree
  module ProductsHelper
    # returns the formatted price for the specified variant as a full price or a difference depending on configuration
    def variant_price(variant)
      # if Spree::Config[:show_variant_full_price]
        variant_full_price(variant)
      # else
        # variant_price_diff(variant)
      # end
    end

    # returns the formatted price for the specified variant as a difference from product price
    def variant_price_diff(variant)
      # Amount (Price)
      variant_amount = variant.amount_in(current_currency)
      product_amount = variant.product.amount_in(current_currency)

      # Core
      product_core_amount = variant.product.core_price_in(current_currency)
      variant_core_amount = variant.core_price_in(current_currency)

      # Return if no differences
      return if (variant_amount == product_amount && variant_core_amount == product_core_amount) || product_amount.nil?
      diff   = variant.amount_in(current_currency) - product_amount
      amount = Spree::Money.new(diff.abs, currency: current_currency).to_html
      label  = diff > 0 ? :add : :subtract
      core_diff = variant_core_amount ? variant_core_amount : 0 - product_core_amount ? product_core_amount : 0
      core_amount = Spree::Money.new(core_diff.abs, currency: current_currency).to_html 
      core_label = core_diff > 0 ? :add_core : :subtract_core
      "(#{Spree.t(label)}: #{amount}, #{Spree.t(core_label)}: #{core_amount})".html_safe
    end

    # returns the formatted full price for the variant, if at least one variant price differs from product price
    def variant_full_price(variant)
      product = variant.product
      #unless product.variants.active(current_currency).all? { |v| v.price == product.price && v.core_price ? v.core_price == 0 : true }
        new_price = "Price: " + Spree::Money.new(variant.price, { currency: current_currency }).to_html
        if variant.core_price && variant.core_price > 0
          new_price += " Core: " + Spree::Money.new(variant.core_price ? variant.core_price : 0, { currency: current_currency }).to_html
        end
        new_price
      #end
    end

    # converts line breaks in product description into <p> tags (for html display purposes)
    def product_description(product)
      if Spree::Config[:show_raw_product_description]
        raw(product.description)
      else
        raw(product.description.gsub(/(.*?)\r?\n\r?\n/m, '<p>\1</p>'))
      end
    end

    def line_item_description(variant)
      ActiveSupport::Deprecation.warn "line_item_description(variant) is deprecated and may be removed from future releases, use line_item_description_text(line_item.description) instead.", caller

      line_item_description_text(variant.product.description)
    end

    def line_item_description_text description_text
      if description_text.present?
        truncate(strip_tags(description_text.gsub('&nbsp;', ' ').squish), length: 100)
      else
        Spree.t(:product_has_no_description)
      end
    end

    def cache_key_for_products
      count = @products["base"].count
      max_updated_at = (@products["base"].maximum(:updated_at) || Date.today).to_s(:number)
      "#{I18n.locale}/#{current_currency}/spree/products/all-#{params[:page]}-#{max_updated_at}-#{count}"
    end
  end
end
