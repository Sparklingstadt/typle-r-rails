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

ActiveRecord::Schema[8.1].define(version: 2026_11_23_000000) do
  create_table "devices", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.string "layout", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_devices_on_user_id"
  end

  create_table "packs", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.string "catalog_id"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.string "category"
    t.json "tags", default: [], null: false
    t.index ["user_id", "catalog_id"], name: "index_packs_on_user_id_and_catalog_id", unique: true
    t.index ["user_id"], name: "index_packs_on_user_id"
  end

  create_table "practice_records", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "word_list_id", null: false
    t.integer "time_ms", null: false
    t.integer "mistakes", default: 0, null: false
    t.decimal "accuracy", precision: 5, scale: 2, null: false
    t.integer "word_count", null: false
    t.string "mode"
    t.json "missed", default: [], null: false
    t.datetime "practiced_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "device_key"
    t.string "device_name"
    t.string "device_layout"
    t.index ["user_id", "practiced_at"], name: "index_practice_records_on_user_id_and_practiced_at"
    t.index ["user_id"], name: "index_practice_records_on_user_id"
    t.index ["word_list_id"], name: "index_practice_records_on_word_list_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "login_id"
    t.string "password_digest"
    t.boolean "ignore_accents", default: false, null: false
    t.boolean "ignore_case", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "guest", default: false, null: false
    t.string "email"
    t.datetime "email_confirmed_at"
    t.string "github_uid"
    t.string "github_login"
    t.json "interests"
    t.string "sid_sub"
    t.string "name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["github_uid"], name: "index_users_on_github_uid", unique: true
    t.index ["login_id"], name: "index_users_on_login_id", unique: true
    t.index ["sid_sub"], name: "index_users_on_sid_sub", unique: true
  end

  create_table "word_lists", force: :cascade do |t|
    t.integer "pack_id", null: false
    t.integer "user_id", null: false
    t.string "name", null: false
    t.string "category"
    t.string "level"
    t.string "origin_list_id"
    t.integer "position", default: 0, null: false
    t.datetime "weak_reviewed_at"
    t.json "weak_review_missed", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "writing_language"
    t.index ["pack_id"], name: "index_word_lists_on_pack_id"
    t.index ["user_id"], name: "index_word_lists_on_user_id"
  end

  create_table "words", force: :cascade do |t|
    t.integer "word_list_id", null: false
    t.string "display", null: false
    t.string "input", null: false
    t.string "annotation", default: "", null: false
    t.string "input_type"
    t.integer "position", default: 0, null: false
    t.index ["word_list_id"], name: "index_words_on_word_list_id"
  end

  add_foreign_key "devices", "users"
  add_foreign_key "packs", "users"
  add_foreign_key "practice_records", "users"
  add_foreign_key "practice_records", "word_lists"
  add_foreign_key "sessions", "users"
  add_foreign_key "word_lists", "packs"
  add_foreign_key "word_lists", "users"
  add_foreign_key "words", "word_lists"
end
