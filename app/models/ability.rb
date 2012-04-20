class Ability

  include CanCan::Ability

  def initialize(current_user)
    case current_user.role

    when "superadmin"
      can :manage, :all
      cannot [:update, :destroy], User, :role => 'superadmin'
      cannot [:update, :destroy], Group, :name => 'default'

    when "admin"
      can :manage, [Fond, Creator, Custodian, Source, DigitalObject, Institution, DocumentForm,
        Project, Editor, Heading, Import], :group_id => current_user.group_id
      can :manage, User, :group_id => current_user.group_id
      cannot [:update, :destroy], User, :role => 'superadmin'

    when "author"
      can :manage, [Fond, Creator, Custodian, Source, DigitalObject, Institution, DocumentForm,
       Project, Editor, Heading, Import], :group_id => current_user.group_id
      can :update, User, :id => current_user.id

    when "supervisor"
      can :read, :all
      can :update, User, :id => current_user.id

    end
  end

end

