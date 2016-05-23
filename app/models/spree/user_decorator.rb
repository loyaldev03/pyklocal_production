Spree::User.class_eval do

  #------------------------ Associations
  has_many :store_users, foreign_key: :spree_user_id, class_name: 'Merchant::StoreUser'
  has_many :stores, through: :store_users, class_name: 'Merchant::Store' 

  has_many :ordered_line_items, through: :orders, :source => :line_items, class_name: 'Spree::LineItem'
  has_many :raitings, foreign_key: :spree_user_id

  has_many :parse_links, foreign_key: :user_id, class_name: 'Spree::ParseLink'
  accepts_nested_attributes_for :parse_links, :reject_if => lambda { |a| a[:url].blank? }

  belongs_to :spree_buy_privilege
  belongs_to :spree_sell_privilege 

  after_create :assign_api_key

  def mailboxer_email(object)
    return email
  end

  def has_store
    stores.present?
  end

  def active_store
    if stores.present?
      stores.first.active
    end
  end

  def full_name
    if bill_address
      [bill_address.firstname, bill_address.lastname].compact.join(" ")
    else
      email
    end
  end

  def full_address
    if bill_address
      [bill_address.address1, bill_address.address2].compact.join(" ")
    else
      "D-42 Sector 59"
    end
  end

  def ordered_products
    ordered_line_items.map{|o| o.product}
  end

  def review_product?(product)
    ordered_products.include?(product)
  end

  def ordered_from_stores
    ordered_products.map{|p| p.store}.uniq
  end

  def review_store?(store)
    ordered_from_stores.include?(store)
  end

  private

    def assign_api_key
      self.generate_spree_api_key!
    end

end
