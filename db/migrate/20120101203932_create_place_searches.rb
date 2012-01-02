class CreatePlaceSearches < ActiveRecord::Migration
  def self.up
    create_table :place_searches do |t|
      t.integer     :place_id,        :nullable => true
      t.string      :query
      t.boolean     :active,          :default => true
      t.datetime    :created_at
    end

    add_index :place_searches, [:query], :unique => true
  end

  def self.down
    drop_table :place_searches
  end
end
