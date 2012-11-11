class CreateConcurs < ActiveRecord::Migration
  def change
    create_table :concurs do |t|
      t.integer :site_id
      t.string :url

      t.timestamps
    end
  end
end
