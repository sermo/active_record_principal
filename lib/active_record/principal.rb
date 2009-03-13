# This module provides access to the curent_user object as a principal within active record.
# This principal object can be used to assign created_by and updated_by to the model when saving
# This principal will fall back to a calling context when there is no reference to a current user (being accessed
# through a cron job or API execution)
# If neither are available, the principal will be nil
module ActiveRecord
  module Principal
    # ActiveRecord::Principal needs to know what method on your ApplicationController will return the current user,
    # if available. This defaults to the :current_user method. You may configure this in your environment.rb if you
    # have a different setup.
    def self.current_user_method=(v); @@current_user_method = v; end
    def self.current_user_method; @@current_user_method; end
    @@current_user_method = :current_user
    
    def self.set_principal(principal) 
      # ideally, this method would take a real user as an argument, not an ID. This user would have to be 
      # fetched from the session service by session ID. Since we don't have that capability yet, we're letting
      # ourselves "authenticate" manually by passing in an ID
      fake_user = Class.new { attr_accessor :id }.new 
      fake_user.id = principal[:id]
      ActiveRecord::Base.current_user_proc = proc { fake_user }
      ActiveRecord::Base.originating_ip_proc = proc { principal[:ip] }    
    end
    
    # This is a module aimed at making the current_user available to ActiveRecord models for permissions.
    module Controller
      def self.included(base)
        base.prepend_before_filter :assign_principal_to_models
      end

      # We need to give the ActiveRecord classes a handle to the current user (principal). We don't want to just pass the object,
      # because the object may change (someone may log in or out). So we give ActiveRecord a proc that ties to the
      # current_user_method on this ApplicationController.
      def assign_principal_to_models
        ActiveRecord::Base.current_user_proc = proc {send(ActiveRecord::Principal.current_user_method)}
        ActiveRecord::Base.originating_ip_proc = proc { request.remote_ip }
      end
    end

    module Model
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        # The proc to call that retrieves the current_user from the ApplicationController.
        attr_accessor :current_user_proc
        attr_accessor :originating_ip_proc
        
        # Class-level access to the current user
        def current_user
          ActiveRecord::Base.current_user_proc.call if ActiveRecord::Base.current_user_proc
        end
        
        def originating_ip
          ActiveRecord::Base.originating_ip_proc.call if ActiveRecord::Base.originating_ip_proc
        end
        
        def principal
          { :id => current_user.id, :ip => originating_ip } if current_user
        end
        
        def validates_principal(options = {})
          options = options.symbolize_keys.reverse_merge( :id => true, :ip => false)

          requires_id = options.delete :id 
          requires_ip = options.delete :ip
          
          # Declare the validation.
          send(validation_method(options[:on] || :save), options) do |record|
            if requires_id and (record.principal.nil? or record.principal[:id].nil?)
              record.errors.add_to_base("Could not determine a principal ID")
            end
            if requires_ip and (record.principal.nil? or record.principal[:ip].nil?)
              record.errors.add_to_base("Could not determine a principal IP address")
            end            
          end
        end
      end

      # Instance-level access to the current user
      def current_user
        self.class.current_user
      end
      
      def originating_ip
        self.class.originating_ip
      end
      
      def principal
        self.class.principal
      end
  
    end
  end
end