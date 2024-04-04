class CreateStripeEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :stripe_events, id: false do |t|
      t.string :stripe_id, primary_key: true
      t.string :event_type, null: false
      t.jsonb :data, null: false

      t.timestamp :created_at, null: false
    end
  end
end
