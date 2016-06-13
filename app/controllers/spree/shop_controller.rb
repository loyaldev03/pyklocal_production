class Spree::ShopController < Spree::StoreController

  def index   
    @products = Spree::Product.all.page(params[:page]).per(20).order("created_at desc") 
    @taxons = Spree::Taxon.where.not(name:"categories") 
    @taxonomies = Spree::Taxonomy.includes(root: :children) 
    @store = Merchant::Store.all
  end

  def show 
    @taxons = Spree::Taxon.where.not(name:"categories")
    @products = Spree::Taxon.where(name: params[:id]).first.try(:products).page(params[:page]).per(16).order("created_at desc")    
  end

end