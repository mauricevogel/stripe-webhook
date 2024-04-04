class CreateSubscriptions < ActiveRecord::Migration[7.1]
  enable_extension "pgcrypto"

  def change
    create_table :subscriptions, id: :uuid do |t|
      t.integer :state, null: false, default: 0
      t.string :stripe_id
      t.string :stripe_customer_id
      t.timestamp :paid_at
      t.timestamp :canceled_at

      t.timestamps
    end

    add_index :subscriptions, :stripe_id, unique: true
  end
end
