class CreateUrls < ActiveRecord::Migration
  def change
    create_table :urls do |t|
      t.string :link
      t.string :code
      t.string :string

      t.timestamps
    end
  end
end
