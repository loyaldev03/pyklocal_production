module Spree
	Product.class_eval do 
		belongs_to :store, class_name: "Merchant::Store"
		has_many :order_variants, -> { order("#{::Spree::Variant.quoted_table_name}.position ASC") },
    inverse_of: :product, class_name: 'Spree::Variant'
    attr_accessor :image_url

    searchable do
      text :name
    end
    
	end
end