module Spree
  class Api::V1::WishlistsController < Spree::Api::BaseController

   # before_action :authenticate_spree_user!
      skip_before_filter :authenticate_user!

    def index
      @user = Spree::ApiToken.where(token: params[:token]).first.try(:user)
      @products = []
      @wishlist = []
      if @user.present? && @user.wishlists.present?
        @user.wishlists.each do |wish|
          @products.push(wish.variant.try(:product))
          @wishlist.push(wish.id)
        end
        render json: {
          status: 1 ,
          message: "Wishlist Retrieve Successfully" ,
          id: @wishlist.as_json(),
          details: @products.as_json({ only: [:sku, :name, :price, :id, :description],
            methods: [:price, :stock_status, :total_on_hand, :average_ratings, :taxon_ids, :product_images],
            include: [variants: {only: :id, methods: [:price, :option_name, :stock_status, :total_on_hand, :product_images]}]})
        }
      else
        render json: {
          status: 0,
          message: "No item in whislist"
        }
      end
    end

    def create
      @user = Spree::ApiToken.where(token: params[:token]).first.try(:user)
      if @user.present?
        @wishlist = Spree::Wishlist.create(user_id: @user.id , variant_id: params[:wishlist][:variant_id])
        if @wishlist.save
          render json: {
            status: 1 ,
            message: "Item added successfully to wishlist"
          }
        else
          render json: {
            status: 0,
            message: "Something Went Wrong"
          }
        end
      else
        render json: {
          status: 0,
          message: "User not Found"
        }
      end  
    end

    def destroy
      if  Spree::Wishlist.where(id: params[:id]).first.try(:destroy)
        render json: {
            status: 1 ,
            message: "Item deleted successfully"
        } 
      else
         render json: {
            status: 0 ,
            message: "Item not deleted successfully"
        }
      end

    end

    private

      def wishlist_params
        params.require(:wishlist).permit(:variant_id, :user_id)
      end
  end
end