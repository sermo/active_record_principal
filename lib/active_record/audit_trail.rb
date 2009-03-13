module ActiveRecord
  module AuditTrail
    
    module Model
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        def acts_as_audited(options = {})
          class_eval <<-EOV
            has_many :audit_records, :as => :auditable
            after_create :audit_create_event
            after_update :audit_update_event
            after_destroy :audit_destroy_event
          EOV
        end
      end
      
      def audit_create_event
        create_audit_record(self, "CREATE")
      end

      def audit_update_event
        create_audit_record(self, "UPDATE")
      end

      def audit_destroy_event
        create_audit_record(self, "DESTROY")
      end

      private
        def create_audit_record(object, action)
           if object.class.principal
             AuditRecord.create :auditable => object, 
                                :principal_id => object.class.principal[:id],
                                :principal_ip_address => object.class.principal[:ip],
                                :action => action
          else 
            # FIXME: Do we blow up here? There was no principal defined
          end
        end
    end
  end
end