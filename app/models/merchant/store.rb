module Merchant
  class Store < ActiveRecord::Base

    self.table_name = "pyklocal_stores" 

    validates :name, :manager_first_name, :manager_last_name, :phone_number, :spree_taxons, presence: true
    # validates :terms_and_condition, acceptance: { accept: true }
    
  	has_many :store_users, dependent: :delete_all, foreign_key: :store_id, class_name: "Merchant::StoreUser"
    has_many :store_taxons, dependent: :delete_all, foreign_key: :store_id, class_name: "Merchant::StoreTaxon"
    has_many :spree_taxons , through: :store_taxons
    has_many :spree_products, dependent: :delete_all, foreign_key: :store_id, class_name: 'Spree::Product'
    has_many :email_tokens, as: :resource
    has_many :raitings, as: :rateable

    accepts_nested_attributes_for :store_users, allow_destroy: true 
    attr_accessor :taxon_ids
    
    after_save :notify_admin

    has_attached_file :logo,  
      Pyklocal::Configuration.paperclip_options[:stores][:logo]
    validates_attachment :logo, content_type: { content_type: /\Aimage\/.*\Z/ }

    extend FriendlyId
    friendly_id :name, use: :slugged


    def average_raiting
      return 0 unless raitings.present?
      _raiting = (raitings.average(:rate) / raitings.count)*100
      _raiting < 0 ? 0 :  _raiting
    end

    def manager_full_name
      "#{manager_first_name} #{manager_last_name}"
    end

    def find_by_slug(slug)
      Merchant::Store.where(slug: slug).first
    end

    def address
      [street_number, city, state, country].compact.join(", ")
    end

    def is_located?
      latitude?
    end

    def item_count_of_this_store(order_number)
      count = 0
      Spree::Order.find_by_number(order_number).line_items.each do |item|
        if item.product.try(:store_id) == id
          count += 1
        end
      end
      return count
    end

    def product_line_items
      store_line_items = []
      spree_products.each do |product|
        store_line_items << product.line_items
      end
      return store_line_items.flatten
    end

    def store_orders
      product_line_items.collect(&:order).uniq.flatten
    end

    def pickable_line_items
      store_line_items = []
      spree_products.each do |product|
        store_line_items << product.line_items.where(delivery_state: "ready_to_pick", delivery_type: "home_delivery")
      end
      return store_line_items.flatten
    end

    def pickable_store_orders
      pickable_line_items.collect(&:order).uniq.flatten
    end

    private

      # def set_taxons
      # 	if taxon_ids.blank?
      # 		errors.add(:taxon_ids, 'You must select atleast one category.')
      # 		false
      # 	else
      #     taxon_ids.each do |taxon_id|
      #       self.store_taxons.build taxon_id: taxon_id
      #     end
      #   end
      # end

      def notify_admin
        unless self.changes.include?(:active)
          UserMailer.notify_store_save(self).deliver
        end
      end

  end
end
