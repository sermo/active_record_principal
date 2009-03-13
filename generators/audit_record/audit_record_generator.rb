class AuditRecordGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      # Model class
      m.template 'audit_record.rb',      File.join('app/models/audit_record.rb')
      #m.template 'unit_test.rb',       File.join('test/unit', class_path, "#{file_name}_test.rb")
      
      # Migration
      m.migration_template 'migration.rb', 'db/migrate', :migration_file_name => "create_audit_records"
    end
  end

end
