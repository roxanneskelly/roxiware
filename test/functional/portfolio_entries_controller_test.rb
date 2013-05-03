require 'test_helper'

class PortfolioEntriesControllerTest < ActionController::TestCase
  setup do
    @portfolio_entry = portfolio_entries(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:portfolio_entries)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create portfolio_entry" do
    assert_difference('PortfolioEntry.count') do
      post :create, :portfolio_entry => @portfolio_entry.attributes
    end

    assert_redirected_to portfolio_entry_path(assigns(:portfolio_entry))
  end

  test "should show portfolio_entry" do
    get :show, :id => @portfolio_entry.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @portfolio_entry.to_param
    assert_response :success
  end

  test "should update portfolio_entry" do
    put :update, :id => @portfolio_entry.to_param, :portfolio_entry => @portfolio_entry.attributes
    assert_redirected_to portfolio_entry_path(assigns(:portfolio_entry))
  end

  test "should destroy portfolio_entry" do
    assert_difference('PortfolioEntry.count', -1) do
      delete :destroy, :id => @portfolio_entry.to_param
    end

    assert_redirected_to portfolio_entries_path
  end
end
