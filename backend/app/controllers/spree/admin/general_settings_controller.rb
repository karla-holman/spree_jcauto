module Spree
  module Admin
    class GeneralSettingsController < Spree::Admin::BaseController
      include Spree::Backend::Callbacks

      before_action :set_store

      def edit
        @preferences_security = [:check_for_spree_alerts]
      end

      def update
        params.each do |name, value|
          next unless Spree::Config.has_preference? name
          Spree::Config[name] = value
        end

        current_store.update_attributes store_params

        flash[:success] = Spree.t(:successfully_updated, resource: Spree.t(:general_settings))
        redirect_to edit_admin_general_settings_path
      end

      def dismiss_alert
        if request.xhr? and params[:alert_id]
          dismissed = Spree::Config[:dismissed_spree_alerts] || ''
          Spree::Config.set dismissed_spree_alerts: dismissed.split(',').push(params[:alert_id]).join(',')
          filter_dismissed_alerts
          render nothing: true
        end
      end

      def clear_cache
        Rails.cache.clear
        invoke_callbacks(:clear_cache, :after)
        head :no_content
      end

      ##############################################################################
      # EXCEL UPLOADS
      ##############################################################################

      def upload
        @path = ""
      end

      # Upload excel document to populate database
      def upload_product_excel
        begin
          my_excel = Spree::Excel.new(params[:file])
        rescue Exception => e
          flash[:error] = e.message
        end

        if (my_excel)
          my_excel.import_product_file()
          @errors = my_excel.get_errors
        end
        if @errors && @errors.length > 0
          flash[:error] = "Errors in upload, see table below"
        end
        render :action => :upload
      end

      # Upload excel document to populate database
      def upload_inventory_excel
        begin
          my_excel = Spree::Excel.new(params[:file])
        rescue Exception => e
          flash[:error] = e.message
        end

        if (my_excel)
          my_excel.import_inventory_file()
          @errors = my_excel.get_errors
        end
        if @errors && @errors.length > 0
          flash[:error] = "Errors in upload, see table below"
        end
        render :action => :upload
      end

      def upload_vendor_excel
        begin
          my_excel = Spree::Excel.new(params[:file])
        rescue Exception => e
          flash[:error] = e.message
        end

        if (my_excel)
          my_excel.import_vendor_file()
          @errors = my_excel.get_errors
        end
        if @errors && @errors.length > 0
          flash[:error] = "Errors in upload, see table below"
        end
        render :action => :upload
      end

      ##############################################################################
      # EXCEL UPLOADS
      ##############################################################################

      # Handle Quickbooks uploads
      def clear_jobs
        number_of_jobs = QBWC.clear_jobs

        flash[:info] = "Removed " + number_of_jobs.to_s + " job(s)"

        redirect_to quickbooks_edit_admin_general_settings_path
      end

      # Return customer requests
      def create_customer_requests
        # Clear any existing job
        QBWC.delete_job(:add_customer)

        customer_requests = []
        Spree::User.all.each do |user|
          customer_requests << 
          { 
            :customer_add_rq => {
              :customer_add => {
                :name => "#{user.bill_address ? user.bill_address.firstname : user.email} #{user.bill_address ? user.bill_address.lastname : "" }", 
                :is_active => true
              }
            }
          } 
        end

        # Check XML for requests
        customer_requests.each do |request| 
          if !QBWC.parser.to_qbxml(request, {:validate => true})
            flash[:error] = "Request " + request + " failed."
            render :action => :quickbooks_edit
          end
        end

        # Add job if all XML passes
        QBWC.add_job(:add_customer, true, '', CustomerWorker, customer_requests)

        flash[:success] = "Customer job added."
        redirect_to quickbooks_edit_admin_general_settings_path
      end

      def create_invoice_requests
        requests = []

        # Clear any existing job
        QBWC.delete_job(:add_invoice)

        my_orders = Spree::Order.where("in_quickbooks=?", false)
        # for each order, check customers, invoices, and payments
        my_orders.each do |order|
          # Add customer and order only if user attached (should always be the case)
          if order.user 
            # variables -------------------------------------------------------------
            my_user = order.user
            # get address (whether shipping or billing)
            address = my_user.bill_address ? my_user.bill_address : (my_user.ship_address ? my_user.ship_address : nil)
          else 
            my_user = order
            address = order.bill_address ? order.bill_address : (order.ship_address ? order.ship_address : nil)
          end
          # get name from address
          name = "#{address ? address.lastname : order.email}#{address ? ", " + address.firstname : "" }"
          full_name = "#{address ? address.firstname : order.email}#{address ? " " + address.lastname : "" }"

          # Add customer ----------------------------------------------------------
          requests << 
          { 
            :customer_add_rq => {
              :customer_add => {
                :name => name, 
                :is_active => true,
                :first_name => "#{address ? address.firstname : my_user.email}",
                :last_name => "#{address ? address.lastname : ""}",
                :bill_address => {
                  :addr_1 => "#{my_user.bill_address ? my_user.bill_address.address1 : ""}",
                  :addr_2 => "#{my_user.bill_address ? my_user.bill_address.address2 : ""}",
                  :city => "#{my_user.bill_address ? my_user.bill_address.city : ""}",
                  :state => "#{my_user.bill_address ? Spree::State.find(my_user.bill_address.state_id).name : ""}",
                  :postal_code => "#{my_user.bill_address ? my_user.bill_address.zipcode : ""}",
                  :country => "#{my_user.bill_address ? Spree::Country.find(my_user.bill_address.country_id).name : ""}"
                },
                :ship_address => {
                  :addr_1 => "#{my_user.ship_address ? my_user.ship_address.address1 : ""}",
                  :addr_2 => "#{my_user.ship_address ? my_user.ship_address.address2 : ""}",
                  :city => "#{my_user.ship_address ? my_user.ship_address.city : ""}",
                  :state => "#{my_user.ship_address ? Spree::State.find(my_user.ship_address.state_id).name : ""}",
                  :postal_code => "#{my_user.ship_address ? my_user.ship_address.zipcode : ""}",
                  :country => "#{my_user.ship_address ? Spree::Country.find(my_user.ship_address.country_id).name : ""}"
                },
                :phone => "#{address ? address.phone : ""}",
                :email => "#{my_user.email}",
                :sales_tax_code_ref => {
                  :full_name => "Tax"
                },
                :item_sales_tax_ref => {
                  :full_name => (address.state_id == 3577 ? "WA State Excise Tax" : "Out of State")
                }
              }
            }
          }

          # Add Order as Invoice ------------------------------------------------------
          
          # generate line items
          invoice_lines = []
          order.line_items.each do |item|
            invoice_lines << 
            {
              :item_ref => {
                :full_name => "inventory"
              },
              :desc => item.variant.description,
              :quantity => item.quantity,
              :amount => sprintf('%.2f', item.price)
            }
          end

          # Add shipping
          order.shipments.each do |shipment|
            invoice_lines <<
            {
              :item_ref => {
                :full_name => "Shipping"
              },
              :desc => shipment.shipping_method.name.gsub(/[^\w\s]/, ''),
              :amount => sprintf('%.2f', shipment.cost)
            }
          end

          # Add discounts
          order.adjustments.each do |promotion|
            invoice_lines <<
            {
              :item_ref => {
                :full_name => "Promotion"
              },
              :desc => promotion.label,
              :amount => sprintf('%.2f', promotion.amount).gsub("-", "")
            }
          end

          # Add invoice
          requests << 
          {
            :invoice_add_rq => {
              :invoice_add => {
                :customer_ref => {
                  :full_name => full_name
                },
                :ar_account_ref => {
                  :full_name => "Accounts Receivable"
                },
                :txn_date => order.created_at.strftime("%Y-%m-%d"),
                :ref_number => order.number,
                :bill_address => {
                  :addr_1 => "#{order.bill_address ? order.bill_address.address1 : ""}",
                  :addr_2 => "#{order.bill_address ? order.bill_address.address2 : ""}",
                  :city => "#{order.bill_address ? order.bill_address.city : ""}",
                  :state => "#{order.bill_address ? Spree::State.find(order.bill_address.state_id).name : ""}",
                  :postal_code => "#{order.bill_address ? order.bill_address.zipcode : ""}",
                  :country => "#{order.bill_address ? Spree::Country.find(order.bill_address.country_id).name : ""}"
                },
                :ship_address => {
                  :addr_1 => "#{order.ship_address ? order.ship_address.address1 : ""}",
                  :addr_2 => "#{order.ship_address ? order.ship_address.address2 : ""}",
                  :city => "#{order.ship_address ? order.ship_address.city : ""}",
                  :state => "#{order.ship_address ? Spree::State.find(order.ship_address.state_id).name : ""}",
                  :postal_code => "#{order.ship_address ? order.ship_address.zipcode : ""}",
                  :country => "#{order.ship_address ? Spree::Country.find(order.ship_address.country_id).name : ""}"
                },
                :customer_sales_tax_code_ref => {
                  :full_name => "Tax"
                },
                :invoice_line_add => invoice_lines
              }
            }
          }

          # Add payments -------------------------------------------------------------
          if order.payment_state == "paid"
            # add new payment_requests
            order.payments.each do |payment|
              requests <<
              {
                :receive_payment_add_rq => {
                  :receive_payment_add => {
                    :customer_ref => {
                      :full_name => full_name
                    },
                    :ar_account_ref => {
                      :full_name => "Accounts Receivable"
                    },
                    :txn_date => payment.created_at.strftime("%Y-%m-%d"),
                    :ref_number => payment.number,
                    :total_amount => sprintf('%.2f', payment.amount),
                    :payment_method_ref => {
                      :full_name => payment.payment_method.name
                    },
                    :deposit_to_account_ref => { 
                      :full_name => "Undeposited Funds" 
                    },
                    :is_auto_apply => true
                  }
                }
              }
            end # end payments.each
          end # end if payments
        end # Loop through each order

        # Check XML for requests
        requests.each do |request| 
          if !QBWC.parser.to_qbxml(request, {:validate => true})
            flash[:error] = "Request " + request + " failed."
            render :action => :quickbooks_edit
          end
        end

        # Add job if all XML passes
        QBWC.add_job(:add_invoice, true, '', InvoiceWorker, requests)
        my_orders.each do |order|
          order.update_attribute("in_quickbooks", true)
        end

        flash[:success] = "Invoice job added. Remember to run Quickbooks Web Connector!"

        redirect_to quickbooks_edit_admin_general_settings_path
      end

      def quickbooks_edit
        @path = ""
      end


      private
      def store_params
        params.require(:store).permit(permitted_store_attributes)
      end

      def set_store
        @store = current_store
      end
  
    end
  end
end
