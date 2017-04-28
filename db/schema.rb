# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170427151659) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "answers", force: :cascade do |t|
    t.datetime "created_at"
    t.date "date_value"
    t.datetime "datetime_value"
    t.boolean "delta", default: true, null: false
    t.integer "inst_num", default: 1, null: false
    t.decimal "latitude", precision: 8, scale: 6
    t.decimal "longitude", precision: 9, scale: 6
    t.integer "option_id"
    t.integer "questioning_id"
    t.integer "rank", default: 1, null: false
    t.integer "response_id"
    t.time "time_value"
    t.datetime "updated_at"
    t.string "uuid", null: false
    t.text "value"
  end

  add_index "answers", ["option_id"], name: "answers_option_id_fk", using: :btree
  add_index "answers", ["questioning_id"], name: "answers_questioning_id_fk", using: :btree
  add_index "answers", %w(response_id questioning_id inst_num rank), name: "answers_full", unique: true, using: :btree
  add_index "answers", ["response_id"], name: "answers_response_id_fk", using: :btree
  add_index "answers", ["uuid"], name: "index_answers_on_uuid", using: :btree

  create_table "assignments", force: :cascade do |t|
    t.datetime "created_at"
    t.integer "mission_id"
    t.string "role", limit: 255
    t.datetime "updated_at"
    t.integer "user_id"
    t.string "uuid", null: false
  end

  add_index "assignments", ["mission_id"], name: "assignments_mission_id_fk", using: :btree
  add_index "assignments", ["user_id"], name: "assignments_user_id_fk", using: :btree
  add_index "assignments", ["uuid"], name: "index_assignments_on_uuid", using: :btree

  create_table "broadcast_addressings", force: :cascade do |t|
    t.integer "addressee_id", null: false
    t.string "addressee_type", limit: 255, null: false
    t.integer "broadcast_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "uuid", null: false
  end

  add_index "broadcast_addressings", ["addressee_id"], name: "broadcast_addressings_user_id_fk", using: :btree
  add_index "broadcast_addressings", ["broadcast_id"], name: "broadcast_addressings_broadcast_id_fk", using: :btree
  add_index "broadcast_addressings", ["uuid"], name: "index_broadcast_addressings_on_uuid", using: :btree

  create_table "broadcasts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at"
    t.string "medium", limit: 255
    t.integer "mission_id"
    t.string "recipient_selection", limit: 255, null: false
    t.text "send_errors"
    t.string "source", limit: 255, default: "manual", null: false
    t.string "subject", limit: 255
    t.datetime "updated_at"
    t.string "uuid", null: false
    t.string "which_phone", limit: 255
  end

  add_index "broadcasts", ["mission_id"], name: "broadcasts_mission_id_fk", using: :btree
  add_index "broadcasts", ["uuid"], name: "index_broadcasts_on_uuid", using: :btree

  create_table "choices", force: :cascade do |t|
    t.integer "answer_id", null: false
    t.datetime "created_at"
    t.decimal "latitude", precision: 8, scale: 6
    t.decimal "longitude", precision: 9, scale: 6
    t.integer "option_id", null: false
    t.datetime "updated_at"
    t.string "uuid", null: false
  end

  add_index "choices", ["answer_id"], name: "choices_answer_id_fk", using: :btree
  add_index "choices", ["option_id"], name: "choices_option_id_fk", using: :btree
  add_index "choices", ["uuid"], name: "index_choices_on_uuid", using: :btree

  create_table "conditions", force: :cascade do |t|
    t.datetime "created_at"
    t.integer "mission_id"
    t.string "op", limit: 255
    t.integer "option_node_id"
    t.integer "questioning_id"
    t.integer "ref_qing_id"
    t.datetime "updated_at"
    t.string "uuid", null: false
    t.string "value", limit: 255
  end

  add_index "conditions", ["mission_id"], name: "index_conditions_on_mission_id", using: :btree
  add_index "conditions", ["option_node_id"], name: "index_conditions_on_option_node_id", using: :btree
  add_index "conditions", ["questioning_id"], name: "conditions_questioning_id_fk", using: :btree
  add_index "conditions", ["ref_qing_id"], name: "conditions_ref_qing_id_fk", using: :btree
  add_index "conditions", ["uuid"], name: "index_conditions_on_uuid", using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.datetime "created_at"
    t.datetime "failed_at"
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "locked_at"
    t.string "locked_by", limit: 255
    t.integer "priority", default: 0, null: false
    t.string "queue", limit: 255
    t.datetime "run_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "form_forwardings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "form_id"
    t.integer "recipient_id"
    t.string "recipient_type", limit: 255
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
  end

  add_index "form_forwardings", %w(form_id recipient_id recipient_type), name: "form_forwardings_full", unique: true, using: :btree
  add_index "form_forwardings", ["form_id"], name: "index_form_forwardings_on_form_id", using: :btree
  add_index "form_forwardings", ["recipient_type", "recipient_id"], name: "index_form_forwardings_on_recipient_type_and_recipient_id", using: :btree
  add_index "form_forwardings", ["uuid"], name: "index_form_forwardings_on_uuid", using: :btree

  create_table "form_items", force: :cascade do |t|
    t.string "ancestry", limit: 255
    t.integer "ancestry_depth", null: false
    t.datetime "created_at"
    t.integer "form_id", null: false
    t.jsonb "group_hint_translations", default: {}
    t.jsonb "group_name_translations", default: {}
    t.boolean "hidden", default: false, null: false
    t.integer "mission_id"
    t.integer "question_id"
    t.integer "rank", null: false
    t.boolean "repeatable"
    t.boolean "required", default: false, null: false
    t.string "type", limit: 255, null: false
    t.datetime "updated_at"
    t.string "uuid", null: false
  end

  add_index "form_items", ["ancestry"], name: "index_form_items_on_ancestry", using: :btree
  add_index "form_items", ["form_id"], name: "questionings_form_id_fk", using: :btree
  add_index "form_items", ["mission_id"], name: "index_questionings_on_mission_id", using: :btree
  add_index "form_items", ["question_id"], name: "questionings_question_id_fk", using: :btree
  add_index "form_items", ["uuid"], name: "index_form_items_on_uuid", using: :btree

  create_table "form_versions", force: :cascade do |t|
    t.string "code", limit: 255
    t.datetime "created_at", null: false
    t.integer "form_id"
    t.boolean "is_current", default: true
    t.integer "sequence", default: 1
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
  end

  add_index "form_versions", ["code"], name: "index_form_versions_on_code", unique: true, using: :btree
  add_index "form_versions", ["form_id"], name: "form_versions_form_id_fk", using: :btree
  add_index "form_versions", ["uuid"], name: "index_form_versions_on_uuid", using: :btree

  create_table "forms", force: :cascade do |t|
    t.string "access_level", limit: 255, default: "private", null: false
    t.boolean "allow_incomplete", default: false, null: false
    t.boolean "authenticate_sms", default: true
    t.datetime "created_at"
    t.integer "current_version_id"
    t.integer "downloads"
    t.boolean "is_standard", default: false
    t.integer "mission_id"
    t.string "name", limit: 255
    t.integer "original_id"
    t.datetime "pub_changed_at"
    t.boolean "published", default: false
    t.integer "responses_count", default: 0
    t.integer "root_id"
    t.boolean "sms_relay", default: false, null: false
    t.boolean "smsable", default: false
    t.boolean "standard_copy", default: false, null: false
    t.datetime "updated_at"
    t.boolean "upgrade_needed", default: false
    t.string "uuid", null: false
  end

  add_index "forms", ["current_version_id"], name: "forms_current_version_id_fk", using: :btree
  add_index "forms", ["mission_id", "name"], name: "index_forms_on_mission_id_and_name", unique: true, using: :btree
  add_index "forms", ["original_id"], name: "index_forms_on_standard_id", using: :btree
  add_index "forms", ["uuid"], name: "index_forms_on_uuid", using: :btree

  create_table "media_objects", force: :cascade do |t|
    t.integer "answer_id"
    t.datetime "created_at", null: false
    t.string "item_content_type", limit: 255
    t.string "item_file_name", limit: 255
    t.integer "item_file_size"
    t.datetime "item_updated_at"
    t.string "token", limit: 255
    t.string "type", limit: 255
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
  end

  add_index "media_objects", ["answer_id"], name: "index_media_objects_on_answer_id", using: :btree
  add_index "media_objects", ["uuid"], name: "index_media_objects_on_uuid", using: :btree

  create_table "missions", force: :cascade do |t|
    t.string "compact_name", limit: 255
    t.datetime "created_at"
    t.boolean "locked", default: false, null: false
    t.string "name", limit: 255
    t.string "shortcode", limit: 255, null: false
    t.datetime "updated_at"
    t.string "uuid", null: false
  end

  add_index "missions", ["compact_name"], name: "index_missions_on_compact_name", using: :btree
  add_index "missions", ["shortcode"], name: "index_missions_on_shortcode", unique: true, using: :btree
  add_index "missions", ["uuid"], name: "index_missions_on_uuid", using: :btree

  create_table "operations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "creator_id", null: false
    t.string "description", limit: 255, null: false
    t.string "job_class", limit: 255, null: false
    t.datetime "job_completed_at"
    t.text "job_error_report"
    t.datetime "job_failed_at"
    t.string "job_id", limit: 255
    t.string "job_outcome_url", limit: 255
    t.datetime "job_started_at"
    t.string "provider_job_id", limit: 255
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
  end

  add_index "operations", ["created_at"], name: "index_operations_on_created_at", using: :btree
  add_index "operations", ["creator_id", "created_at"], name: "index_operations_on_creator_id_and_created_at", using: :btree
  add_index "operations", ["uuid"], name: "index_operations_on_uuid", using: :btree

  create_table "option_nodes", force: :cascade do |t|
    t.string "ancestry", limit: 255
    t.integer "ancestry_depth", default: 0
    t.datetime "created_at", null: false
    t.boolean "is_standard", default: false
    t.integer "mission_id"
    t.integer "option_id"
    t.integer "option_set_id", null: false
    t.integer "original_id"
    t.integer "rank", default: 1, null: false
    t.integer "sequence"
    t.boolean "standard_copy", default: false, null: false
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
  end

  add_index "option_nodes", ["ancestry"], name: "index_option_nodes_on_ancestry", using: :btree
  add_index "option_nodes", ["mission_id"], name: "option_nodes_mission_id_fk", using: :btree
  add_index "option_nodes", ["option_id"], name: "option_nodes_option_id_fk", using: :btree
  add_index "option_nodes", ["option_set_id"], name: "option_nodes_option_set_id_fk", using: :btree
  add_index "option_nodes", ["original_id"], name: "index_option_nodes_on_original_id", using: :btree
  add_index "option_nodes", ["rank"], name: "index_option_nodes_on_rank", using: :btree
  add_index "option_nodes", ["uuid"], name: "index_option_nodes_on_uuid", using: :btree

  create_table "option_sets", force: :cascade do |t|
    t.boolean "allow_coordinates", default: false, null: false
    t.datetime "created_at"
    t.boolean "geographic", default: false, null: false
    t.boolean "is_standard", default: false
    t.text "level_names"
    t.integer "mission_id"
    t.string "name", limit: 255
    t.integer "original_id"
    t.integer "root_node_id"
    t.string "sms_guide_formatting", limit: 255, default: "auto", null: false
    t.boolean "standard_copy", default: false, null: false
    t.datetime "updated_at"
    t.string "uuid", null: false
  end

  add_index "option_sets", ["geographic"], name: "index_option_sets_on_geographic", using: :btree
  add_index "option_sets", ["mission_id"], name: "index_option_sets_on_mission_id", using: :btree
  add_index "option_sets", ["original_id"], name: "index_option_sets_on_standard_id", using: :btree
  add_index "option_sets", ["root_node_id"], name: "option_sets_root_node_id_fk", using: :btree
  add_index "option_sets", ["uuid"], name: "index_option_sets_on_uuid", using: :btree

  create_table "options", force: :cascade do |t|
    t.string "canonical_name", limit: 255, null: false
    t.datetime "created_at"
    t.decimal "latitude", precision: 8, scale: 6
    t.decimal "longitude", precision: 9, scale: 6
    t.integer "mission_id"
    t.jsonb "name_translations", default: {}
    t.datetime "updated_at"
    t.string "uuid", null: false
  end

  add_index "options", ["canonical_name", "mission_id"], name: "index_options_on_canonical_name_and_mission_id", using: :btree
  add_index "options", ["mission_id"], name: "index_options_on_mission_id", using: :btree
  add_index "options", ["uuid"], name: "index_options_on_uuid", using: :btree

  create_table "questions", force: :cascade do |t|
    t.string "access_level", limit: 255, default: "inherit", null: false
    t.text "canonical_name", null: false
    t.string "code", limit: 255
    t.datetime "created_at"
    t.jsonb "hint_translations", default: {}
    t.boolean "is_standard", default: false
    t.boolean "key", default: false
    t.decimal "maximum", precision: 15, scale: 8
    t.boolean "maxstrictly"
    t.decimal "minimum", precision: 15, scale: 8
    t.boolean "minstrictly"
    t.integer "mission_id"
    t.jsonb "name_translations", default: {}
    t.integer "option_set_id"
    t.integer "original_id"
    t.string "qtype_name", limit: 255
    t.boolean "standard_copy", default: false, null: false
    t.boolean "text_type_for_sms", default: false, null: false
    t.datetime "updated_at"
    t.string "uuid", null: false
  end

  add_index "questions", ["mission_id", "code"], name: "index_questions_on_mission_id_and_code", unique: true, using: :btree
  add_index "questions", ["option_set_id"], name: "questions_option_set_id_fk", using: :btree
  add_index "questions", ["original_id"], name: "index_questions_on_standard_id", using: :btree
  add_index "questions", ["qtype_name"], name: "index_questions_on_qtype_name", using: :btree
  add_index "questions", ["uuid"], name: "index_questions_on_uuid", using: :btree

  create_table "report_calculations", force: :cascade do |t|
    t.string "attrib1_name", limit: 255
    t.datetime "created_at"
    t.integer "question1_id"
    t.integer "rank"
    t.integer "report_report_id"
    t.string "type", limit: 255
    t.datetime "updated_at"
    t.string "uuid", null: false
  end

  add_index "report_calculations", ["question1_id"], name: "report_calculations_question1_id_fk", using: :btree
  add_index "report_calculations", ["report_report_id"], name: "report_calculations_report_report_id_fk", using: :btree
  add_index "report_calculations", ["uuid"], name: "index_report_calculations_on_uuid", using: :btree

  create_table "report_option_set_choices", force: :cascade do |t|
    t.integer "option_set_id"
    t.integer "report_report_id"
    t.string "uuid", null: false
  end

  add_index "report_option_set_choices", ["option_set_id"], name: "report_option_set_choices_option_set_id_fk", using: :btree
  add_index "report_option_set_choices", ["report_report_id"], name: "report_option_set_choices_report_report_id_fk", using: :btree
  add_index "report_option_set_choices", ["uuid"], name: "index_report_option_set_choices_on_uuid", using: :btree

  create_table "report_reports", force: :cascade do |t|
    t.string "aggregation_name", limit: 255
    t.string "bar_style", limit: 255, default: "side_by_side"
    t.datetime "created_at"
    t.integer "creator_id"
    t.integer "disagg_qing_id"
    t.string "display_type", limit: 255, default: "table"
    t.text "filter"
    t.integer "form_id"
    t.boolean "group_by_tag", default: false, null: false
    t.integer "mission_id"
    t.string "name", limit: 255
    t.string "percent_type", limit: 255, default: "none"
    t.string "question_labels", limit: 255, default: "title"
    t.string "question_order", limit: 255, default: "number", null: false
    t.string "text_responses", limit: 255, default: "all"
    t.string "type", limit: 255
    t.boolean "unique_rows", default: false
    t.boolean "unreviewed", default: false
    t.datetime "updated_at"
    t.string "uuid", null: false
    t.integer "view_count", default: 0
    t.datetime "viewed_at"
  end

  add_index "report_reports", ["creator_id"], name: "fk_rails_1df9873194", using: :btree
  add_index "report_reports", ["disagg_qing_id"], name: "report_reports_disagg_qing_id_fk", using: :btree
  add_index "report_reports", ["form_id"], name: "report_reports_form_id_fk", using: :btree
  add_index "report_reports", ["mission_id"], name: "report_reports_mission_id_fk", using: :btree
  add_index "report_reports", ["uuid"], name: "index_report_reports_on_uuid", using: :btree
  add_index "report_reports", ["view_count"], name: "index_report_reports_on_view_count", using: :btree

  create_table "responses", force: :cascade do |t|
    t.datetime "checked_out_at"
    t.integer "checked_out_by_id"
    t.datetime "created_at"
    t.integer "form_id"
    t.boolean "incomplete", default: false, null: false
    t.integer "mission_id"
    t.string "odk_hash", limit: 255
    t.boolean "reviewed", default: false
    t.integer "reviewer_id"
    t.text "reviewer_notes"
    t.string "shortcode", limit: 255, null: false
    t.string "source", limit: 255
    t.datetime "updated_at"
    t.integer "user_id"
    t.string "uuid", null: false
  end

  add_index "responses", ["checked_out_at"], name: "index_responses_on_checked_out_at", using: :btree
  add_index "responses", ["checked_out_by_id"], name: "responses_checked_out_by_id_fk", using: :btree
  add_index "responses", ["created_at"], name: "index_responses_on_created_at", using: :btree
  add_index "responses", ["form_id", "odk_hash"], name: "index_responses_on_form_id_and_odk_hash", unique: true, using: :btree
  add_index "responses", ["form_id"], name: "responses_form_id_fk", using: :btree
  add_index "responses", ["mission_id"], name: "responses_mission_id_fk", using: :btree
  add_index "responses", ["reviewed"], name: "index_responses_on_reviewed", using: :btree
  add_index "responses", ["reviewer_id"], name: "index_responses_on_reviewer_id", using: :btree
  add_index "responses", ["shortcode"], name: "index_responses_on_shortcode", unique: true, using: :btree
  add_index "responses", ["updated_at"], name: "index_responses_on_updated_at", using: :btree
  add_index "responses", ["user_id", "form_id"], name: "index_responses_on_user_id_and_form_id", using: :btree
  add_index "responses", ["user_id"], name: "responses_user_id_fk", using: :btree
  add_index "responses", ["uuid"], name: "index_responses_on_uuid", using: :btree

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at"
    t.text "data"
    t.string "session_id", limit: 255, null: false
    t.datetime "updated_at"
  end

  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "settings", force: :cascade do |t|
    t.boolean "allow_unauthenticated_submissions", default: false
    t.datetime "created_at"
    t.string "default_outgoing_sms_adapter", limit: 255
    t.string "frontlinecloud_api_key", limit: 255
    t.text "incoming_sms_numbers"
    t.string "incoming_sms_token", limit: 255
    t.integer "mission_id"
    t.string "override_code", limit: 255
    t.string "preferred_locales", limit: 255
    t.string "timezone", limit: 255
    t.string "twilio_account_sid", limit: 255
    t.string "twilio_auth_token", limit: 255
    t.string "twilio_phone_number", limit: 255
    t.datetime "updated_at"
    t.string "uuid", null: false
  end

  add_index "settings", ["mission_id"], name: "settings_mission_id_fk", using: :btree
  add_index "settings", ["uuid"], name: "index_settings_on_uuid", using: :btree

  create_table "sms_messages", force: :cascade do |t|
    t.string "adapter_name", limit: 255
    t.boolean "auth_failed", default: false, null: false
    t.text "body"
    t.integer "broadcast_id"
    t.datetime "created_at", null: false
    t.string "from", limit: 255
    t.integer "mission_id"
    t.integer "reply_to_id"
    t.datetime "sent_at"
    t.string "to", limit: 255
    t.string "type", limit: 255, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "uuid", null: false
  end

  add_index "sms_messages", ["body"], name: "index_sms_messages_on_body", using: :btree
  add_index "sms_messages", ["broadcast_id"], name: "sms_messages_broadcast_id_fk", using: :btree
  add_index "sms_messages", ["created_at"], name: "index_sms_messages_on_created_at", using: :btree
  add_index "sms_messages", ["from"], name: "index_sms_messages_on_from", using: :btree
  add_index "sms_messages", ["mission_id"], name: "sms_messages_mission_id_fk", using: :btree
  add_index "sms_messages", ["reply_to_id"], name: "sms_messages_reply_to_id_fk", using: :btree
  add_index "sms_messages", ["to"], name: "index_sms_messages_on_to", using: :btree
  add_index "sms_messages", ["type"], name: "index_sms_messages_on_type", using: :btree
  add_index "sms_messages", ["user_id"], name: "sms_messages_user_id_fk", using: :btree
  add_index "sms_messages", ["uuid"], name: "index_sms_messages_on_uuid", using: :btree

  create_table "taggings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "question_id", null: false
    t.integer "tag_id", null: false
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
  end

  add_index "taggings", ["question_id"], name: "index_taggings_on_question_id", using: :btree
  add_index "taggings", ["tag_id"], name: "index_taggings_on_tag_id", using: :btree
  add_index "taggings", ["uuid"], name: "index_taggings_on_uuid", using: :btree

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "mission_id"
    t.string "name", limit: 64, null: false
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
  end

  add_index "tags", ["mission_id"], name: "index_tags_on_mission_id", using: :btree
  add_index "tags", ["name", "mission_id"], name: "index_tags_on_name_and_mission_id", using: :btree
  add_index "tags", ["uuid"], name: "index_tags_on_uuid", using: :btree

  create_table "user_group_assignments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_group_id", null: false
    t.integer "user_id", null: false
    t.string "uuid", null: false
  end

  add_index "user_group_assignments", ["user_group_id"], name: "index_user_group_assignments_on_user_group_id", using: :btree
  add_index "user_group_assignments", ["user_id", "user_group_id"], name: "index_user_group_assignments_on_user_id_and_user_group_id", unique: true, using: :btree
  add_index "user_group_assignments", ["user_id"], name: "index_user_group_assignments_on_user_id", using: :btree
  add_index "user_group_assignments", ["uuid"], name: "index_user_group_assignments_on_uuid", using: :btree

  create_table "user_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "mission_id"
    t.string "name", limit: 255, null: false
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
  end

  add_index "user_groups", ["mission_id"], name: "index_user_groups_on_mission_id", using: :btree
  add_index "user_groups", ["name", "mission_id"], name: "index_user_groups_on_name_and_mission_id", unique: true, using: :btree
  add_index "user_groups", ["uuid"], name: "index_user_groups_on_uuid", using: :btree

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.boolean "admin", default: false, null: false
    t.string "api_key", limit: 255
    t.integer "birth_year"
    t.datetime "created_at", null: false
    t.string "crypted_password", limit: 255
    t.datetime "current_login_at"
    t.string "email", limit: 255
    t.text "experience"
    t.string "gender", limit: 255
    t.string "gender_custom", limit: 255
    t.integer "import_num"
    t.integer "last_mission_id"
    t.datetime "last_request_at"
    t.string "login", limit: 255, null: false
    t.integer "login_count", default: 0
    t.string "name", limit: 255, null: false
    t.string "nationality", limit: 255
    t.text "notes"
    t.string "password_salt", limit: 255
    t.string "perishable_token", limit: 255
    t.string "persistence_token", limit: 255
    t.string "phone", limit: 255
    t.string "phone2", limit: 255
    t.string "pref_lang", limit: 255, null: false
    t.string "sms_auth_code", limit: 255
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["login"], name: "index_users_on_login", unique: true, using: :btree
  add_index "users", ["name"], name: "index_users_on_name", using: :btree
  add_index "users", ["sms_auth_code"], name: "index_users_on_sms_auth_code", unique: true, using: :btree
  add_index "users", ["uuid"], name: "index_users_on_uuid", using: :btree

  create_table "whitelistings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "uuid", null: false
    t.integer "whitelistable_id"
    t.string "whitelistable_type", limit: 255
  end

  add_index "whitelistings", ["uuid"], name: "index_whitelistings_on_uuid", using: :btree

  add_foreign_key "answers", "form_items", column: "questioning_id", name: "answers_questioning_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "answers", "options", name: "answers_option_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "answers", "responses", name: "answers_response_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "assignments", "missions", name: "assignments_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "assignments", "users", name: "assignments_user_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "broadcast_addressings", "broadcasts", name: "broadcast_addressings_broadcast_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "broadcasts", "missions", name: "broadcasts_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "choices", "answers", name: "choices_answer_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "choices", "options", name: "choices_option_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "conditions", "form_items", column: "questioning_id", name: "conditions_questioning_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "conditions", "form_items", column: "ref_qing_id", name: "conditions_ref_qing_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "conditions", "missions", name: "conditions_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "conditions", "option_nodes", name: "conditions_option_node_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "form_forwardings", "forms", name: "form_forwardings_form_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "form_items", "forms", name: "form_items_form_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "form_items", "missions", name: "form_items_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "form_items", "questions", name: "form_items_question_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "form_versions", "forms", name: "form_versions_form_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "forms", "form_versions", column: "current_version_id", name: "forms_current_version_id_fkey", on_update: :restrict, on_delete: :nullify
  add_foreign_key "forms", "forms", column: "original_id", name: "forms_original_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "forms", "forms", column: "original_id", name: "forms_original_id_fkey1", on_update: :restrict, on_delete: :nullify
  add_foreign_key "forms", "missions", name: "forms_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "media_objects", "answers", name: "media_objects_answer_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "operations", "users", column: "creator_id", name: "operations_creator_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "option_nodes", "missions", name: "option_nodes_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "option_nodes", "option_nodes", column: "original_id", name: "option_nodes_original_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "option_nodes", "option_nodes", column: "original_id", name: "option_nodes_original_id_fkey1", on_update: :restrict, on_delete: :nullify
  add_foreign_key "option_nodes", "option_sets", name: "option_nodes_option_set_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "option_nodes", "options", name: "option_nodes_option_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "option_sets", "missions", name: "option_sets_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "option_sets", "option_nodes", column: "root_node_id", name: "option_sets_root_node_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "option_sets", "option_sets", column: "original_id", name: "option_sets_original_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "option_sets", "option_sets", column: "original_id", name: "option_sets_original_id_fkey1", on_update: :restrict, on_delete: :nullify
  add_foreign_key "options", "missions", name: "options_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "questions", "missions", name: "questions_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "questions", "option_sets", name: "questions_option_set_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "questions", "questions", column: "original_id", name: "questions_original_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "questions", "questions", column: "original_id", name: "questions_original_id_fkey1", on_update: :restrict, on_delete: :nullify
  add_foreign_key "report_calculations", "questions", column: "question1_id", name: "report_calculations_question1_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "report_calculations", "report_reports", name: "report_calculations_report_report_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "report_option_set_choices", "option_sets", name: "report_option_set_choices_option_set_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "report_option_set_choices", "report_reports", name: "report_option_set_choices_report_report_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "report_reports", "form_items", column: "disagg_qing_id", name: "report_reports_disagg_qing_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "report_reports", "forms", name: "report_reports_form_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "report_reports", "missions", name: "report_reports_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "report_reports", "users", column: "creator_id", name: "report_reports_creator_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "responses", "forms", name: "responses_form_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "responses", "missions", name: "responses_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "responses", "users", column: "checked_out_by_id", name: "responses_checked_out_by_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "responses", "users", column: "reviewer_id", name: "responses_reviewer_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "responses", "users", name: "responses_user_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "settings", "missions", name: "settings_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "sms_messages", "broadcasts", name: "sms_messages_broadcast_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "sms_messages", "missions", name: "sms_messages_mission_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "sms_messages", "sms_messages", column: "reply_to_id", name: "sms_messages_reply_to_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "sms_messages", "users", name: "sms_messages_user_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "user_group_assignments", "user_groups", name: "user_group_assignments_user_group_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "user_group_assignments", "users", name: "user_group_assignments_user_id_fkey", on_update: :restrict, on_delete: :restrict
  add_foreign_key "user_groups", "missions", name: "user_groups_mission_id_fkey", on_update: :restrict, on_delete: :restrict
end
