# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_07_114735) do
  create_table "access_links", force: :cascade do |t|
    t.integer "bound_user_id"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.integer "initial_level", default: 0, null: false
    t.integer "max_uses"
    t.text "preset_context"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.integer "use_count", default: 0, null: false
    t.integer "vault_id", null: false
    t.text "welcome_message"
    t.index [ "bound_user_id" ], name: "index_access_links_on_bound_user_id"
    t.index [ "slug" ], name: "index_access_links_on_slug", unique: true
    t.index [ "vault_id" ], name: "index_access_links_on_vault_id"
  end
  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.integer "content_id"
    t.datetime "created_at", null: false
    t.string "face_snapshot_url"
    t.string "ip_address"
    t.decimal "lat", precision: 9, scale: 6
    t.decimal "lng", precision: 9, scale: 6
    t.datetime "occurred_at", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.integer "vault_id", null: false
    t.index [ "action" ], name: "index_audit_logs_on_action"
    t.index [ "content_id" ], name: "index_audit_logs_on_content_id"
    t.index [ "user_id", "occurred_at" ], name: "index_audit_logs_on_user_id_and_occurred_at"
    t.index [ "user_id" ], name: "index_audit_logs_on_user_id"
    t.index [ "vault_id", "occurred_at" ], name: "index_audit_logs_on_vault_id_and_occurred_at"
    t.index [ "vault_id" ], name: "index_audit_logs_on_vault_id"
  end

  create_table "contents", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.string "format", default: "markdown", null: false
    t.json "permitted_user_ids"
    t.integer "required_level", default: 0, null: false
    t.string "symbol_type"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "vault_id", null: false
    t.index ["vault_id"], name: "index_contents_on_vault_id"
  end

  create_table "permissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "granted_level", default: 0, null: false
    t.text "owner_notes"
    t.text "relationship_context"
    t.string "source_access_link_id"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "vault_id", null: false
    t.index ["user_id"], name: "index_permissions_on_user_id"
    t.index ["vault_id", "user_id"], name: "index_permissions_on_vault_id_and_user_id", unique: true
    t.index ["vault_id"], name: "index_permissions_on_vault_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "bkc_access", default: false, null: false
    t.boolean "can_create_vault", default: true, null: false
    t.datetime "created_at", null: false
    t.string "display_name", null: false
    t.string "email", null: false
    t.string "firebase_uid"
    t.boolean "is_beta_tester", default: false, null: false
    t.datetime "last_seen_at"
    t.text "notes"
    t.string "role", default: "viewer", null: false
    t.string "status", default: "active", null: false
    t.integer "trust_level", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["firebase_uid"], name: "index_users_on_firebase_uid", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["status"], name: "index_users_on_status"
  end

  create_table "vaults", force: :cascade do |t|
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "display_name"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_vaults_on_user_id", unique: true
  end

  add_foreign_key "access_links", "users", column: "bound_user_id"
  add_foreign_key "access_links", "vaults"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "audit_logs", "vaults"
  add_foreign_key "contents", "vaults"
  add_foreign_key "permissions", "users"
  add_foreign_key "permissions", "vaults"
  add_foreign_key "vaults", "users"
end
