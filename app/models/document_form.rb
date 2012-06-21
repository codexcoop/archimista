class DocumentForm < ActiveRecord::Base

  extend Cleaner

  belongs_to :updater,  :class_name => "User", :foreign_key => "updated_by"

  has_many :document_form_editors, :dependent => :destroy, :order => :edited_at
  has_many :rel_fond_document_forms, :dependent => :destroy

  accepts_nested_attributes_for :document_form_editors,
    :allow_destroy => true,
    :reject_if => Proc.new { |a| a['name'].blank? }

  # Validations

  validates_presence_of :name

  # Callbacks

  squished_fields :name
  trimmed_fields  :description, :note

  # Named scopes
  # FIXME: copia / incolla last minute. Gli scopes utili a relations andranno tutti rivisti

   named_scope :autocomplete_list, lambda{|term|
     {
       :select => "id, name, name AS value",
       :conditions => ["LOWER(name) LIKE ?", "%#{term.downcase.squish}%"],
       :order => "name ASC",
       :limit => 10
     }
   }

end

