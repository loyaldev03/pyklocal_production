module Spree
	Product.class_eval do 
		belongs_to :pyklocal_store
	end
end