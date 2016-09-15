module Spree
	Api::V1::OrdersController.class_eval do 

		include Spree::Api::ApiHelpers
		include Spree::Core::ControllerHelpers::Order

		before_action :load_order, only: [:show]
		before_action :find_store, only: [:show]
		before_action :find_driver, only: [:index, :show]
		skip_before_filter :authenticate_user, only: [:apply_coupon_code]

		def index
			@orders_list = []
			params[:lat] = @user.api_tokens.last.try(:latitude)
			params[:lng] = @user.api_tokens.last.try(:longitude)
			@search = Sunspot.search(Merchant::Store) do
				order_by_geodist(:loctn, params[:lat], params[:lng])
			end
			@stores = @search.results
			unless @stores.blank?
				@stores.each do |store|
					unless store.pickable_store_orders.blank?
						store.pickable_store_orders.each do |s_o|
							line_items = s_o.line_items.joins(:product).where(spree_line_items: {delivery_type: "home_delivery"}, spree_products: {store_id: store.id})
							line_item_ids = line_items.collect(&:id)
							@orders_list.push({order_number: s_o.number, store_name: store.name, line_item_ids: line_item_ids, state: line_items.collect(&:delivery_state).uniq.join, location: {lat: store.try(:latitude), long: store.try(:longitude)}})
						end						
					end
				end
			end
			render json: @orders_list.as_json()
		# rescue Exception => e
		# 	api_exception_handler(e)
		# ensure
		# 	render json: @orders_list.as_json()
		end

		def create
			begin
			  authorize! :create, Order
			  order_user = if @current_user_roles.include?('admin') && order_params[:user_id]
			    Spree.user_class.find(order_params[:user_id])
			  elsif params[:user_id]
			    Spree::user_class.find(params[:user_id])
			  else
			    current_api_user
			  end

			  import_params = if @current_user_roles.include?("admin")
			    params[:order].present? ? params[:order].permit! : {}
			  else
			    order_params
			  end

			  @order = Spree::Core::Importer::Order.import(order_user, import_params)
			  respond_with(@order, default_template: :show, status: 201)
			rescue Exception => e
				render json: {
					status: 0,
					message: e.message
				}		  	
		  end
		end    

		def show
			# @user = Spree::ApiToken.where(token: params[:token]).try(:first).try(:user)
			line_items = @order.line_items.joins(:product).where(spree_line_items: {delivery_type: "home_delivery"}, spree_products: {store_id: @store.id})
			pick_up_and_delivery = {
																store_address: @store.address, 
																store_zipcode: @store.zipcode, 
																buyer_name: @order.buyer_name, 
																buyer_address: @order.delivery_address, 
																buyer_zipcode: @order.buyer_zipcode, 
																lat_long: @store.location
															}
		rescue Exception => e
			api_exception_handler(e)
		ensure
			render json: {
				product_details: line_items.as_json({
					only: [:id, :price, :quantity], 
					methods: [:product_name]
				}),
				state: line_items.collect(&:delivery_state).uniq.join,
				pick_up_and_delivery: pick_up_and_delivery
			}
		end

		private

			def order_params
        if params[:order]
          normalize_params
          params.require(:order).permit(permitted_order_attributes)
        else
          {}
        end
    	end

    	def add_cart
        if params[:order]
          params.require(:order).permit(:variant_id , :quantity)
        else
          {}
        end
       end

      def normalize_params
        params[:order][:payments_attributes] = params[:order].delete(:payments) if params[:order][:payments]
        params[:order][:shipments_attributes] = params[:order].delete(:shipments) if params[:order][:shipments]
        params[:order][:line_items_attributes] = params[:order].delete(:line_items) if params[:order][:line_items]
        params[:order][:ship_address_attributes] = params[:order].delete(:ship_address) if params[:order][:ship_address]
        params[:order][:bill_address_attributes] = params[:order].delete(:bill_address) if params[:order][:bill_address]
      end

			def load_order
				id = params[:id] || params[:order_id]
				@order = Spree::Order.find_by_number(id)
			end

			def find_store
				@store = Merchant::Store.find_by_name(params[:store_name])
				render json: {status: 0, message: "Store not found, invalid store name"} unless @store.present?
			end 

			def find_driver
				@user = Spree::ApiToken.where(token: params[:token]).first.try(:user)
				render json: {status: 0, message: "Driver not found"} unless @user.present?
			end

	end
end