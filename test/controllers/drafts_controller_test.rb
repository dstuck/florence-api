require 'test_helper'

class DraftsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def drafts
    Draft.where('record_type is not null').all
  end

  test 'loads show for all types' do
    drafts.each do |draft|
      get draft_path(draft)
      assert_response :success
    end
  end

  test 'accepts drafts for all types' do
    drafts.each do |draft|
      sign_in(users(:admin))
      post accept_draft_path(draft)
      assert_response :redirect
      draft = draft.reload
      record = draft.record
      assert_equal(users(:admin), draft.accepted_by)
      # Assert the info on the draft matches the corresponding fields on the record
      draft.info.keys.each do |key|
        # We use record type to create the record for the draft if it is a new record
        # This field does not exist on the record, only in the draft
        # You cannot set a polymorphic type without also setting the id (as far as I know)
        next if key == 'record_type'

        assert_equal(record.send(key), draft.info[key], "Error for #{key} on #{draft}")
      end
    end
  end

  test 'denies drafts for all types' do
    drafts.each do |draft|
      sign_in(users(:admin))
      delete draft_path(draft)
      assert_response :redirect
      draft = draft.reload
      assert_equal(users(:admin), draft.denied_by)
    end
  end
end
