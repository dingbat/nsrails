require 'test_helper'

class ResponsesControllerTest < ActionController::TestCase
  setup do
    @response = responses(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:responses)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create response" do
    assert_difference('Response.count') do
      post :create, :response => @response.attributes
    end

    assert_redirected_to response_path(assigns(:response))
  end

  test "should show response" do
    get :show, :id => @response.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @response.to_param
    assert_response :success
  end

  test "should update response" do
    put :update, :id => @response.to_param, :response => @response.attributes
    assert_redirected_to response_path(assigns(:response))
  end

  test "should destroy response" do
    assert_difference('Response.count', -1) do
      delete :destroy, :id => @response.to_param
    end

    assert_redirected_to responses_path
  end
end
