class PyklocalStore < ActiveRecord::Base

	attr_accessor :taxon_ids
	has_many :pyklocal_store_users, dependent: :delete_all, foreign_key: :store_id
  has_many :pyklocal_store_taxons, dependent: :delete_all, foreign_key: :store_id
  has_many :spree_taxons , through: :pyklocal_store_taxons
  has_many :spree_products, dependent: :delete_all, foreign_key: :store_id, class_name: 'Spree::Product'
  has_many :email_tokens, as: :resource
  has_many :raitings, as: :rateable


  accepts_nested_attributes_for :pyklocal_store_users, allow_destroy: true
  # before_save :set_taxons

  after_save :notify_admin

  validates :name, :manager_first_name, :manager_last_name, :phone_number, presence: true
  validates :terms_and_condition, acceptance: { accept: true }

  has_attached_file :logo,  
    Pyklocal::Configuration.paperclip_options[:stores][:logo]
  validates_attachment :logo, content_type: { content_type: /\Aimage\/.*\Z/ }


  def average_raiting
    return 0 unless raitings.present?
    _raiting = (raitings.average(:rate) / raitings.count)*100
    _raiting < 0 ? 0 :  _raiting
  end

  def manager_full_name
    "#{manager_first_name} #{manager_last_name}"
  end

  def address
    [street_number, city, state, country].compact.join(", ")
  end

  private

    def set_taxons
    	if taxon_ids.blank?
    		errors.add(:taxon_ids, 'You must select atleast one category.')
    		false
    	else
        taxon_ids.each do |taxon_id|
          self.store_taxons.build taxon_id: taxon_id
        end
      end
    end

    def notify_admin
      UserMailer.notify_store_save(self).deliver
    end

end