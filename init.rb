
ActionController::Base.class_eval { include ActiveRecord::Principal::Controller }
ActiveRecord::Base.class_eval { include ActiveRecord::Principal::Model }
ActiveRecord::Base.class_eval { include ActiveRecord::AuditTrail::Model }
