module Spree
  module Stock
    class InventoryUnitBuilder
      def initialize(order)
        @order = order
      end

=begin
      def units
        @order.line_items.flat_map do |line_item|
          line_item.quantity.times.map do |i|
            @order.inventory_units.includes(
              variant: {
                product: {
                  shipping_category: {
                    shipping_methods: [:calculator, { zones: :zone_members }]
                  }
                }
              }
            ).build(
              pending: true,
              variant: line_item.variant,
              line_item: line_item,
              order: @order
            )
          end
        end
      end
=end

      def units
        @order.reload.line_items.flat_map do |line_item|
          line_item.quantity.times.map do |i|
            @order.inventory_units.build(
              pending: true,
              variant: line_item.variant,
              line_item: line_item,
              order: @order
            )
          end
        end
      end
    end
  end
end
