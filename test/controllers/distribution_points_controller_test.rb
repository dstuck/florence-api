require 'test_helper'

class DistributionPointsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  fixtures :all

  setup do
    @distribution_point = distribution_points(:nrg)
  end

  test 'should get index' do
    get distribution_points_url
    assert_response :success
  end

  test 'should get new' do
    get new_distribution_point_url
    assert_response :success
  end

  test 'creates new and accepted draft if admin user creates a distribution point' do
    expected_pods = DistributionPoint.count + 1
    expected_drafts = Draft.count + 1
    name = @distribution_point.facility_name
    sign_in users(:admin)
    post distribution_points_url, params: { distribution_point: { active: true, address: @distribution_point.address, city: @distribution_point.city, county: @distribution_point.county, facility_name: name, state: @distribution_point.state, phone: @distribution_point.phone } }
    draft = Draft.last
    assert_response :redirect
    assert_equal expected_pods, DistributionPoint.count
    assert_equal expected_drafts, Draft.count
    assert_equal name, Draft.last.info['facility_name']
    assert_equal users(:admin), draft.accepted_by
    assert_nil draft.denied_by
  end

  test 'creates new distribution point if user is admin' do
    expected_count = DistributionPoint.count + 1
    name = @distribution_point.facility_name
    sign_in users(:admin)
    post distribution_points_url, params: { distribution_point: { active: @distribution_point.active, address: @distribution_point.address, city: @distribution_point.city, county: @distribution_point.county, facility_name: name, state: @distribution_point.state, phone: @distribution_point.phone } }
    assert_response :redirect
    assert_equal expected_count, DistributionPoint.count
    assert_equal name, DistributionPoint.last.facility_name
  end

  test 'creates new draft if guest user creates a distribution point' do
    expected_pods = DistributionPoint.count
    expected_drafts = Draft.count + 1
    name = @distribution_point.facility_name
    sign_in users(:guest)
    post distribution_points_url, params: { distribution_point: { active: true, address: @distribution_point.address, city: @distribution_point.city, county: @distribution_point.county, facility_name: name, state: @distribution_point.state, phone: @distribution_point.phone } }
    draft = Draft.last
    assert_response :redirect
    assert_equal expected_pods, DistributionPoint.count
    assert_equal expected_drafts, Draft.count
    assert_equal name, draft.info['facility_name']
    assert_nil draft.accepted_by
    assert_nil draft.denied_by
  end

  test 'should show distribution_point' do
    get distribution_point_url(@distribution_point)
    assert_response :success
  end

  test 'should get edit' do
    get edit_distribution_point_url(@distribution_point)
    assert_response :success
  end

  test 'creates new and accepted draft if admin user updates a distribution point' do
    pod = distribution_points(:nrg)
    expected_pods = DistributionPoint.count
    expected_drafts = Draft.count + 1
    name = 'Some random name you should never name a distribution point'
    sign_in users(:admin)
    patch distribution_point_url(pod), params: { distribution_point: { facility_name: name } }
    pod.reload
    draft = pod.drafts.last
    assert_response :redirect
    assert_equal expected_pods, DistributionPoint.count
    assert_equal expected_drafts, Draft.count
    assert_equal name, pod.facility_name
    assert_equal name, draft.info['facility_name']
    assert_equal users(:admin), draft.accepted_by
    assert_nil draft.denied_by
  end

  test 'should update distribution point if admin' do
    pod = distribution_points(:nrg)
    name = 'Some random name you should never name a distribution point'
    expected_pods = DistributionPoint.count
    expected_drafts = Draft.count + 1
    sign_in users(:admin)
    patch distribution_point_url(pod), params: { distribution_point: { facility_name: name } }
    pod.reload
    assert_response :redirect
    assert_equal expected_pods, DistributionPoint.count
    assert_equal expected_drafts, Draft.count
    assert_equal name, pod.facility_name
  end

  test 'creates new draft if guest user updates a distribution point' do
    pod = distribution_points(:nrg)
    pod_name = pod.facility_name
    expected_pods = DistributionPoint.count
    expected_drafts = Draft.count + 1
    name = 'Some random name you should never name a distribution point'
    sign_in users(:guest)
    patch distribution_point_url(pod), params: { distribution_point: { facility_name: name } }
    pod.reload
    draft = pod.drafts.last
    assert_response :redirect
    assert_equal expected_pods, DistributionPoint.count
    assert_equal expected_drafts, Draft.count
    assert_equal pod_name, pod.facility_name
    assert_equal name, draft.info['facility_name']
    assert_nil draft.accepted_by
    assert_nil draft.denied_by
  end

  test 'archives if admin user' do
    pod = distribution_points(:nrg)
    expected_count = DistributionPoint.count - 1
    sign_in users(:admin)
    post archive_distribution_point_path(pod)
    assert_response :redirect
    assert_equal expected_count, DistributionPoint.count
  end

  test 'guests may not archive' do
    pod = distribution_points(:nrg)
    expected_count = DistributionPoint.count
    sign_in users(:guest)
    post archive_distribution_point_path(pod)
    assert_response :redirect
    assert_equal expected_count, DistributionPoint.count
  end

  test 'reactivates if user admin' do
    pod = distribution_points(:test)
    expected_count = DistributionPoint.count + 1
    sign_in users(:admin)
    delete unarchive_distribution_point_path(pod)
    assert_response :redirect
    assert_equal expected_count, DistributionPoint.count
  end

  test 'guests may not reactivate' do
    pod = distribution_points(:test)
    expected_count = DistributionPoint.count
    sign_in users(:guest)
    delete unarchive_distribution_point_path(pod)
    assert_response :redirect
    assert_equal expected_count, DistributionPoint.count
  end

  test 'should get archived index' do
    get archived_distribution_points_url
    assert_response :success
  end

  test 'loads drafts' do
    get drafts_distribution_points_path
    assert_response :success
  end

  test 'viewers cannot mark current' do
    pod = distribution_points(:nrg)
    oldtimestamp = pod.updated_at
    sleep 0.1
    post mark_current_distribution_point_path(pod)
    assert_response :redirect
    assert_redirected_to root_path
    pod.reload
    assert_equal oldtimestamp, pod.updated_at
  end

  test 'users can mark current' do
    pod = distribution_points(:nrg)
    oldtimestamp = pod.updated_at
    sleep 0.1
    sign_in users(:guest)
    post mark_current_distribution_point_path(pod)
    assert_response :redirect
    assert_redirected_to outdated_distribution_points_path
    pod.reload
    refute_equal oldtimestamp, pod.updated_at
  end

  test 'admins can mark current' do
    pod = distribution_points(:nrg)
    oldtimestamp = pod.updated_at
    sleep 0.1
    sign_in users(:admin)
    post mark_current_distribution_point_path(pod)
    assert_response :redirect
    assert_redirected_to outdated_distribution_points_path
    pod.reload
    refute_equal oldtimestamp, pod.updated_at
  end

  test 'guests may not delete' do
    pod = distribution_points(:nrg)
    sign_in users(:guest)
    delete distribution_point_path(pod)
    assert_response :redirect
    assert_redirected_to root_path
  end

  test 'admins can delete' do
    pod = distribution_points(:nrg)
    sign_in users(:admin)
    delete distribution_point_path(pod)
    assert_response :redirect
    assert_redirected_to distribution_points_path
  end

  test 'deleted items get moved to trash' do
    pod = distribution_points(:nrg)
    expected_pods = DistributionPoint.count - 1
    expected_trash = Trash.count + 1
    sign_in users(:admin)
    delete distribution_point_path(pod)
    assert_response :redirect
    assert_equal expected_pods, DistributionPoint.count
    assert_equal expected_trash, Trash.count
  end
end
