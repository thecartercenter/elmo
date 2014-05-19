# defines all user abilities/permissions
class Ability
  include CanCan::Ability

  attr_reader :user

  CRUD = [:new, :show, :edit, :create, :update, :destroy]

  # returns a list of roles that can be assigned by the given user
  def self.assignable_roles(user)
    # admins can assign any role
    if user.admin?
      User::ROLES
    # otherwise return everything below coordinator
    else
      User::ROLES[0...User::ROLES.index("coordinator")]
    end
  end

  # defines user's abilities
  def initialize(user, admin_mode = false)

    # save user
    @user = user

    if user

      # anybody can see the welcome page
      can :show, Welcome

      # anybody can edit self
      can :update, User, :id => user.id

      # anybody can generate map markers
      can :read, Marker

      # admin abilities that don't depend on a mission being set
      if user.admin?
        can :view, :admin_mode

        # standard objects, missions, settings, and all users are available in no-mission (admin) mode
        if admin_mode
          [Form, Questioning, Condition, Question, OptionSet, Optioning, Option].each do |k|
            can :manage, k, :is_standard => true
          end
          can :manage, Mission
          can :manage, User
          can :manage, Assignment
          can :manage, Setting, :mission_id => nil
        end

        # admin can switch to any mission, regardless of mode
        can :switch_to, Mission

        # only admins can give/take admin (adminify) to/from others, but not from themselves
        cannot :adminify, User
        can :adminify, User, ["id != ?", user.id] do |other_user|
          user.id != other_user.id
        end
      end

      # anybody can access missions to which assigned (but don't need this permission if admin)
      if !user.admin?
        can :switch_to, Mission, Mission.for_user(user) do |mission|
          user.assignments.detect{|a| a.mission == mission}
        end
      end

      # user can submit to any form if they can access the form's mission
      can :submit_to, Form do |form|
        user.accessible_missions.include?(form.mission)
      end

      # all the rest of the permissions require a current mission to be set
      if user.current_mission_id

        # observer abilities
        if user.role?(:observer)
          # can view and export users in same mission
          can [:index, :read, :export], User, :assignments => {:mission_id => user.current_mission_id}

          # can do reports for the current mission
          can :manage, Report::Report, :mission_id => user.current_mission_id

          # only need these abilities if not also a staffer
          unless user.role?(:staffer)
            # can only see own responses
            can [:index, :read, :export], Response, :user_id => user.id, :mission_id => user.current_mission_id

            # observers can only mark a form as 'incomplete' if the form permits it
            can :submit_incomplete, Response do |r|
              r.form.allow_incomplete?
            end

            # can only submit/edit/delete own responses, and only if mission is not locked
            unless user.current_mission.locked?
              can [:create, :update, :destroy], Response,
                :user_id => user.id, :mission_id => user.current_mission_id, :reviewed => false
            end
          end

          # can read published forms for the mission
          # only need this ability if not also a coordinator
          unless user.role?(:coordinator)
            can [:index, :read, :download], Form, :mission_id => user.current_mission_id, :published => true
          end

        end

        # staffer abilities
        if user.role?(:staffer)
          # can send broadcasts for the current mission
          can :manage, Broadcast, :mission_id => user.current_mission_id

          # can do reports for the current mission
          can :manage, Report::Report, :mission_id => user.current_mission_id

          if user.current_mission.locked?
            # can index, read, export responses for a locked mission
            can [:index, :read, :export], Response, :mission_id => user.current_mission_id
          else
            # can manage responses for anybody for an unlocked mission
            can :manage, Response, :mission_id => user.current_mission_id

            # can do sms tests for an unlocked mission
            can :create, Sms::Test
          end

          # can view the dashboard (individual dashboard components are checked separately)
          can :view, :dashboard
        end

        # coordinator abilities
        if user.role?(:coordinator)

          # permissions for locked missions only
          if user.current_mission.locked?
            # coord can index, read, export these classes for a locked mission
            can [:index, :read, :export], [Form, Question, OptionSet], :mission_id => user.current_mission_id

          # permissions for non-locked mission
          else
            # can manage users in current mission
            # special change_assignments permission is given so that users cannot update their own assignments via edit profile
            can [:create, :update, :login_instructions, :change_assignments], User, :assignments => {:mission_id => user.current_mission_id}

            # can create user batches
            can :manage, UserBatch

            # can destroy users only if they have only one mission and it's the current mission
            can :destroy, User do |other_user|
              other_user.assignments.count == 1 && other_user.assignments.first.mission_id == user.current_mission_id
            end

            # coord can manage these classes for the current mission
            [Form, OptionSet, Question, Questioning, Option].each do |klass|
              can :manage, klass, :mission_id => user.current_mission_id
            end

            can :manage, Group, :mission_id => user.current_mission_id
            can :manage, UserGroup, :mission_id => user.current_mission_id
          end

          # coord can manage these classes for the current mission even if locked
          [Setting, Sms::Message].each do |klass|
            can :manage, klass, :mission_id => user.current_mission_id
          end

          # there is no Questioning index
          cannot :index, Questioning
        end
      end
    end

    ###############
    # these permissions are user-independent

    # published forms and forms with responses can't be deleted
    cannot :destroy, Form do |f|
      f.published? || f.has_responses?
    end

    # standard forms can't be cloned (hard to implement and not currently needed)
    cannot :clone, Form, :is_standard => true

    cannot [:add_questions, :remove_questions, :reorder_questions], Form do |f|
      f.standard_copy? || f.published?
    end

    cannot :rename, Form do |f|
      f.standard_copy?
    end

    # standard forms cannot be published and do not have versions, which are only assigned on publish
    cannot :publish, Form, :is_standard => true

    # cannot destroy/update a questioning if it's a standard copy or published
    cannot [:destroy, :update, :update_core], Questioning do |q|
      q.standard_copy? || q.published?
    end

    # BUT can update questioning (though not its core) if can update related question
    # we need this because questions are updated via questionings
    # so a question (though not its core) may be updatable even though it's published
    # and we need to allow access to that question via the questioning index
    can :update, Questioning do |q|
      can? :update, q.question
    end

    cannot :destroy, Questioning do |q|
      q.has_answers?
    end

    # update_core refers to the core fields: question type, option set, constraints
    cannot :update_core, Question do |q|
      q.standard_copy? || q.published? || q.has_answers?
    end

    # update_code refers to the question code attribute
    cannot :update_code, Question do |q|
      q.standard_copy?
    end

    cannot :destroy, Question do |q|
      q.standard_copy? && q.has_standard_copy_form? || q.published? || q.has_answers?
    end

    # we need these specialized permissions because option names/hints are updated via option set
    cannot [:update_core, :add_options, :remove_options, :reorder_options], OptionSet do |o|
      o.standard_copy? || o.published?
    end

    # the geographic option is used only for reporting so doesnt matter if published, etc.
    # only matters if standard_copy, b/c the value does get copied on replication
    cannot :change_geographic, OptionSet do |o|
      o.standard_copy?
    end

    cannot :destroy, OptionSet do |o|
      o.has_answers? || o.has_questions? || o.published?
    end

    # only published forms can be downloaded
    cannot :download, Form, :published => false

    # nobody can assign anybody to a locked mission
    cannot :assign_to, Mission, :locked => true

    # nobody can edit assignments for a locked mission
    cannot [:create, :update, :destroy], Assignment, :mission => {:locked => true}
  end
end
