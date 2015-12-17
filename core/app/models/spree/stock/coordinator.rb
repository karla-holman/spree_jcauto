module Spree
  module Stock
    class Coordinator
      attr_reader :order, :inventory_units

      def initialize(order, inventory_units = nil)
        @order = order
        @inventory_units = inventory_units || InventoryUnitBuilder.new(order).units
      end

      def shipments
        packages.map do |package|
          package.to_shipment.tap { |s| s.address = order.ship_address }
        end
      end

      def packages
        packages = build_packages
        packages = prioritize_packages(packages)
        packages = estimate_packages(packages)
      end

      # Build packages as per stock location
      #
      # It needs to check whether each stock location holds at least one stock
      # item for the order. In case none is found it wouldn't make any sense
      # to build a package because it would be empty. Plus we avoid errors down
      # the stack because it would assume the stock location has stock items
      # for the given order
      # 
      # Returns an array of Package instances
      def build_packages(packages = Array.new)
        test_units = inventory_units
        StockLocation.active.each do |stock_location|
          variant_ids_check = test_units.map(&:variant_id).uniq
          # move on unless one or more stock item contains a variant we are looking for
          found_variant = false
          stock_location.stock_items.each do |stock_item|
            if variant_ids_check.include?(stock_item.variant.id)
              found_variant = true
            end
          end
          next unless found_variant # stock_location.stock_items.where(:variant_id => variant_ids_check).exists?
          packer = build_packer(stock_location, test_units)
          packages += packer.packages

          # don't add same inventory units to multiple locations
          length = 0
          packer.packages.each do |package|
            package.contents.each do |content|
              test_units.delete(content.inventory_unit)
            end
          end
          # test_units.slice!(0, length) # removed used inventory units for next stock location
        end
        packages
      end

      private
      def prioritize_packages(packages)
        # byebug
        prioritizer = Prioritizer.new(inventory_units, packages)
        prioritizer.prioritized_packages
      end

      def estimate_packages(packages)
        # byebug
        estimator = Estimator.new(order)
        packages.each do |package|
          package.shipping_rates = estimator.shipping_rates(package)
        end
        packages
      end

      def build_packer(stock_location, inventory_units)
        Packer.new(stock_location, inventory_units, splitters(stock_location))
      end

      def splitters(stock_location)
        # byebug
        # extension point to return custom splitters for a location
        Rails.application.config.spree.stock_splitters
      end
    end
  end
end
