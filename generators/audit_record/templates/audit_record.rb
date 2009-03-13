class AuditRecord < ActiveRecord::Base
  belongs_to :auditable, :polymorphic => true
end
