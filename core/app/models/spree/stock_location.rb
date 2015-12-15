module Spree
  class StockLocation < Spree::Base
    has_many :shipments
    has_many :stock_items, dependent: :delete_all, inverse_of: :stock_location
    has_many :stock_movements, through: :stock_items

    belongs_to :state, class_name: 'Spree::State'
    belongs_to :country, class_name: 'Spree::Country'

    validates_presence_of :name

    scope :active, -> { where(active: true) }
    scope :order_default, -> { order(default: :desc, name: :asc) }

    after_create :create_stock_items, :if => "self.propagate_all_variants?"
    after_save :ensure_one_default

    def state_text
      state.try(:abbr) || state.try(:name) || state_name
    end

    # Wrapper for creating a new stock item respecting the backorderable config
    def propagate_variant(variant, sub_location=nil)
      self.stock_items.create!(variant: variant, sub_location: sub_location, backorderable: self.backorderable_default)
    end

    # Return either an existing stock item or create a new one. Useful in
    # scenarios where the user might not know whether there is already a stock
    # item for a given variant
    def set_up_stock_item(variant, sub_location=nil)
      self.stock_item(variant, sub_location) || propagate_variant(variant, sub_location)
    end

    # Returns an instance of StockItem for the variant id.
    #
    # @param variant_id [String] The id of a variant.
    #
    # @return [StockItem] Corresponding StockItem for the StockLocation's variant.
    def stock_item(variant_id, sub_location=nil)
      byebug
      stock_items.where(variant_id: variant_id, sub_location: sub_location).order(:id).first
    end
    def find_stock_items(variant_id)
      byebug
      stock_items.where(variant_id: variant_id).order(:id)
    end

    # Attempts to look up StockItem for the variant, and creates one if not found.
    # This method accepts an instance of the variant.
    # Other methods in this model attempt to pass a variant,
    # but controller actions can pass just the variant id as a parameter.
    #
    # @param variant [Variant] Variant instance.
    #
    # @return [StockItem] Corresponding StockItem for the StockLocation's variant.
    def stock_item_or_create(variant, sub_location=nil)
      stock_item(variant, sub_location) || stock_items.create(variant_id: variant.id, sub_location: sub_location)
    end

    def count_on_hand(variant)
      stock_item(variant).try(:count_on_hand)
    end

    def backorderable?(variant)
      stock_item(variant).try(:backorderable?)
    end

    def restock(variant, quantity, originator = nil)
      move(variant, quantity, originator)
    end

    def restock_backordered(variant, quantity, originator = nil)
      item = stock_item_or_create(variant)
      item.update_columns(
        count_on_hand: item.count_on_hand + quantity,
        updated_at: Time.now
      )
    end

    def unstock(variant, quantity, originator = nil)
      move(variant, -quantity, originator)
    end

    def move(variant, quantity, originator = nil)
      stock_item_or_create(variant).stock_movements.create!(quantity: quantity,
                                                            originator: originator)
    end

    def fill_status(variant, quantity)
      # get stock_items for variant and location, loop through for each sub_location
      # if item = stock_item(variant)
      if items = find_stock_items(variant)
        on_hand = 0
        backordered = 0
        items.each do |item|
          # if order can be fulfilled with this stock item
          if (item.count_on_hand + on_hand) >= quantity
            on_hand = quantity
            backordered = 0
            break
          else #otherwise order cannot be fulfilled, try next item
            on_hand += item.count_on_hand
            on_hand = 0 if on_hand < 0
          end
        end
        if on_hand < quantity # if still less than quantity
          backordered = item.backorderable? ? (quantity - on_hand) : 0
        end
        [on_hand, backordered]
      else
        [0, 0]
      end
    end

    private
      def create_stock_items
        Variant.includes(:product).find_each do |variant|
          propagate_variant(variant)
        end
      end

      def ensure_one_default
        if self.default
          StockLocation.where(default: true).where.not(id: self.id).each do |stock_location|
            stock_location.default = false
            stock_location.save!
          end
        end
      end
  end
end
