require 'test_helper'

class SecretPagesControllerTest < ActionController::TestCase
  setup do
    @secret_page = secret_pages(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:secret_pages)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create secret_page" do
    assert_difference('SecretPage.count') do
      post :create, :secret_page => @secret_page.attributes
    end

    assert_redirected_to secret_page_path(assigns(:secret_page))
  end

  test "should show secret_page" do
    get :show, :id => @secret_page.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @secret_page.to_param
    assert_response :success
  end

  test "should update secret_page" do
    put :update, :id => @secret_page.to_param, :secret_page => @secret_page.attributes
    assert_redirected_to secret_page_path(assigns(:secret_page))
  end

  test "should destroy secret_page" do
    assert_difference('SecretPage.count', -1) do
      delete :destroy, :id => @secret_page.to_param
    end

    assert_redirected_to secret_pages_path
  end
end
