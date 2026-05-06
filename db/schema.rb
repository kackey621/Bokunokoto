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

ActiveRecord::Schema[8.1].define(version: 2026_05_06_000104) do
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

  add_foreign_key "contents", "vaults"
  add_foreign_key "permissions", "users"
  add_foreign_key "permissions", "vaults"
  add_foreign_key "vaults", "users"
end
