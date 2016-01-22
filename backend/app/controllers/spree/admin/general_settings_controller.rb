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

      # Handle Quickbooks upload
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
