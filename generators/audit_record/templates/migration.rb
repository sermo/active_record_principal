class CreateAuditRecords < ActiveRecord::Migration

  def self.up
    create_table :audit_records do |t|
      t.string :auditable_type
      t.integer :auditable_id
      t.string :principal_id
      t.string :principal_ip_address
      t.string :action
      t.timestamps
    end
  end

  def self.down
    drop_table :audit_records
  end

end
