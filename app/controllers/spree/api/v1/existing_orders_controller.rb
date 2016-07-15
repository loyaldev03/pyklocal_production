module Spree
	Api::V1::OrdersController.class_eval do 

		include Spree::Api::ApiHelpers

		before_action :load_order, only: [:show]
		before_action :find_store, only: [:show]
		skip_before_filter :authenticate_user, only: [:apply_coupon_code]

		def index
			@orders_list = []
			@user = Spree::ApiToken.find_by_token(params[:token]).try(:user)
			@stores = Merchant::Store.all
			unless @stores.blank?
				@stores.each do |store|
					unless store.pickable_store_orders.blank?
						store.pickable_store_orders.each do |s_o|
							state = ""
							in_cart = false
							item_ids = []
							s_o.line_items.where(delivery_type: "home_delivery").each do |item|
								if item.product.store_id == store.id
									if item.delivery_state == "in_cart"
										in_cart = true
									end
									item_ids << item.id
								end
							end
							# in_cart = @user.driver_orders.where(order_id: s_o.try(:id), line_item_ids: item_ids.join(", ")).present?
							@orders_list.push({order_number: s_o.number, store_name: store.name, in_cart: in_cart, line_item_ids: item_ids, location: {lat: store.try(:latitude), long: store.try(:longitude)}})
						end						
					end
				end
			end
		rescue Exception => e
			api_exception_handler(e)
		ensure
			render json: @orders_list.as_json()
		end

		def show
			@store_line_items = []
			@pick_up_and_delivery = {}
			@order.line_items.where(delivery_type: "home_delivery").each do |line_item|
				if @store.spree_products.include?(line_item.product)
					@store_line_items.push(line_item)
					@pick_up_and_delivery = {store_address: line_item.pickup_address, store_zipcode: line_item.store_zipcode, buyer_name: line_item.buyer_name, buyer_address: line_item.delivery_address, buyer_zipcode: line_item.buyer_zipcode, lat_long: line_item.store_location}
				end
			end
		rescue Exception => e
			api_exception_handler(e)
		ensure
			render json: {
				product_details: @store_line_items.as_json({
					only: [:id, :price, :quantity], 
					methods: [:product_name]
				}),
				pick_up_and_delivery: @pick_up_and_delivery.as_json()
			}
		end

		private

			def load_order
				id = params[:id] || params[:order_id]
				@order = Spree::Order.find_by_number(id)
			end

			def find_store
				@store = Merchant::Store.find_by_name(params[:store_name])
				render json: {code: 0, message: "Store not found, invalid store name"} unless @store.present?
			end

	end
end