# Configure Spree Preferences
#
# Note: Initializing preferences available within the Admin will overwrite any changes that were made through the user interface when you restart.
#       If you would like users to be able to update a setting with the Admin it should NOT be set here.
#
# Note: If a preference is set here it will be stored within the cache & database upon initialization.
#       Just removing an entry from this initializer will not make the preference value go away.
#       Instead you must either set a new value or remove entry, clear cache, and remove database entry.
#
# In order to initialize a setting do:
# config.setting_name = 'new value'
Spree.config do |config|
  # Example:
  # Uncomment to stop tracking inventory levels in the application
  # config.track_inventory_levels = false
end

Spree.user_class = "Spree::LegacyUser"
Spree::PermittedAttributes.line_item_attributes.push :delivery_type
Spree::PermittedAttributes.user_attributes.push :first_name, :last_name ,:mobile_number, stores_attributes: [:name, :active, :payment_mode, :description, :manager_first_name, :manager_last_name, :phone_number, :store_type, :street_number, :city, :state, :zipcode, :country, :site_url, :terms_and_condition, :payment_information, :logo, spree_taxon_ids: [], store_users_attributes: [:spree_user_id, :store_id, :id]]
Spree::PermittedAttributes.product_attributes.push :asin
Spree::PermittedAttributes.address_attributes.push :user_id
Spree::BackendConfiguration.class_eval do 
	SELLER_TAB			||= [:merchants]
end