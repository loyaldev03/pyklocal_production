class Merchant::OrdersController < Merchant::ApplicationController

	before_filter :is_active_store
  before_filter :find_order, only: [:edit, :update, :validate_actions, :customer, :adjustments, :payments, :returns, :approve, :cancel]

	def index
    @store = Merchant::Store.find_by_slug(params[:store_id])
    @orders = Kaminari.paginate_array(@store.try(:store_orders)).page(params[:page]).per(10)
  end

  def new
  	if !@current_spree_user.has_spree_role?('admin')
      if @current_spree_user.has_spree_role?('merchant')
        raise CanCan::AccessDenied.new
      end
    end  
    @order = Order.create
    @order.created_by = try_spree_current_user
    @order.save
    redirect_to edit_admin_order_url(@order)
  end

  def edit
  	validate_actions
    unless @order.complete?
      @order.refresh_shipment_rates
    end
  end

  def update
  	validate_actions
    if @order.update_attributes(params[:order]) && @order.line_items.present?
      @order.update!
      unless @order.complete?
        # Jump to next step if order is not complete.
        redirect_to admin_order_customer_path(@order) and return
      end
    else
      @order.errors.add(:line_items, Spree.t('errors.messages.blank')) if @order.line_items.empty?
    end

    render :action => :edit
  end

  def cancel
  	validate_actions
    @order.cancel!
    flash[:success] = Spree.t(:order_canceled)
    redirect_to :back
  end

  def customer
    @customer = @order.user
    @bill_address = @order.try(:bill_address)
  end

  def adjustments
    @adjustments = @order.adjustments
  end

  def payments
    @payments = @order.payments
  end

  def returns
    
  end

  def approve
    if @order.update_attributes(approver_id: current_spree_user.id, approved_at: Time.zone.now, considered_risky: false)
      redirect_to :back, notice: "Order Approved"
    else
      redirect_to :back, notice: @order.errors.full_messages.join(", ")
    end
  end

  def cancel
    validate_actions
    @order.cancel!
    flash[:success] = Spree.t(:order_canceled)
    redirect_to :back
  end

  private 

  	def validate_actions
  		rais_error = true
    	if !@current_spree_user.has_spree_role?('admin')
        if @current_spree_user.has_spree_role?('merchant')
        		@order.line_items.each do |line_item|
        			if line_item.variant.product.store_id == @current_spree_user.stores.first.id
        				rais_error = false
        				break
        			end	
        		end
        	if rais_error
          	raise CanCan::AccessDenied.new
          end	
        end
      end  
  	end

    def find_order
      @order = Spree::Order.where(number: params[:id]).first || Spree::Order.where(number: params[:order_id]).first
    end	

end