class User < ActiveRecord::Base

  extend Cleaner

  devise :database_authenticatable, :rememberable

  ROLES = ['superadmin', 'admin', 'author', 'supervisor']
  roles = ROLES

  belongs_to :group
  has_many :imports

  validates_presence_of :username, :first_name, :last_name, :role, :group_id
  validates_presence_of :password, :on => :create

  validates_uniqueness_of :username, :email
  validates_confirmation_of :password

  validates_format_of :email, :with => Devise::EMAIL_REGEX
  validates_format_of :username, :with => /^([a-zA-Z0-9_]+)$/

  validates_exclusion_of :username, :in => roles

  # Setup accessible (or protected) attributes for your model
  attr_accessor :login

  attr_accessible :email, :password, :password_confirmation, :remember_me, :remember_token,
    :remember_created_at, :group_id, :role, :active, :username, :login,
    :first_name, :last_name, :qualifier

  squished_fields :username, :first_name, :last_name, :qualifier

  roles.each do |role|
    define_method "is_#{role}?" do
      self.role == role
    end

    define_method "is_at_least_#{role}?" do
      roles.index(self.role).to_i <= roles.index(role).to_i
    end
  end

  def valid_for_authentication?(attributes)
      super && active?
  end

  def self.filter_roles_for(role)
    case role
    when 'superadmin' then
      ROLES.select {|r| r != 'superadmin'}
    when 'admin' then
      ROLES.select {|r| r == 'author' || r == 'admin'}
    else
      ROLES.select{|r| r == role}
    end
  end

  # Virtual attributes

  def full_name
    "#{first_name} #{last_name}"
  end

  def reverse_full_name
    "#{last_name} #{first_name}"
  end

  protected

  def self.find_for_authentication(conditions={})
    login = conditions.delete(:login)
    conditions = "username = '#{login}' OR email = '#{login}'"
    find(:first, :conditions => conditions)
  end

end

