class RelCreatorCreator < ActiveRecord::Base

  # TEMPORARY
  before_validation do |record|
    record.creator_association_type_id ||= 1
  end

 # Callbacks

  after_save do |record|
    if record.inverse_association.nil?
      # puts "NO: non esiste il reciproco"
      RelCreatorCreator.create( :creator_id => record.related_creator_id,
                                :related_creator_id => record.creator_id,
                                :creator_association_type_id => record.creator_association_type.inverse_type_id)
    else
      # puts "SI: esiste il reciproco"
      if record.changed?
        record.inverse_association.update_attributes(:creator_association_type_id => record.creator_association_type.inverse_type_id)
      end
    end
  end

  after_destroy do |record|
    record.inverse_association.destroy rescue nil
  end

 # Associations

 belongs_to :creator
 belongs_to :related_creator, :class_name => "Creator"
 belongs_to :creator_association_type

 def inverse_association
    creator.inverse_rel_creator_creators.find(:first, :conditions => "creator_id = #{self.related_creator_id}")
 end

end

