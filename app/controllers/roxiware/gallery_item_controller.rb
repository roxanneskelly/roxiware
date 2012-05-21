class Roxiware::GalleryItemController < ApplicationController
  include Roxiware::GalleryHelper
  load_and_authorize_resource :except=>[:new, :create]

  before_filter do
    @role = current_user.role unless current_user.nil?
  end

  def index
    respond_to do |format|
      format.html { redirect_to :action=>'show', :controller=>'gallery', :seo_index=>@gallery_item.gallery_id }
      format.json { render :status=>401 }
    end
  end

  # GET - Show the contents of a single gallery item
  def show
    respond_to do |format|
      format.html { render }
      format.json { render :json => @gallery_item.ajax_attrs(@role) }
    end
  end

  # GET - Get contents to edit a gallery
  def edit
    respond_to do |format|
      format.html { render }
      format.json { render :json => @gallery_item.ajax_attrs(@role) }
    end
  end

  # GET - Get default contents for a new gallery
  def new
     @robots="noindex,nofollow"
     authorize! :create, Roxiware::GalleryItem
     person_id = current_user.person.id
     @gallery_item = Roxiware::GalleryItem.new({:name=>"New Item", :person_id=>current_user.person.id, :description=>"Description", :image_url=>"foo", :thumbnail_url=>"bar"}, :as=>@role) 
     respond_to do |format|
         format.html
         format.json { render :json => @gallery_item.ajax_attrs(@role) }
     end
  end

  def create
     @robots="noindex,nofollow"
     authorize! :create, Roxiware::GalleryItem
     @gallery = Roxiware::Gallery.find(params[:gallery_id])
     @gallery_item = @gallery.gallery_items.build
     if cannot? :edit, @gallery_item
       @gallery_item.person_id = current_user.person.id
     end
     respond_to do |format|
       if !@gallery_item.update_attributes(params, :as=>@role)
         format.json { render :json=>report_error(@gallery_item) }
       else
         format.json { render :json=> @gallery_item.ajax_attrs(@role) }
       end
     end
  end

  def update
     @robots="noindex,nofollow"
     respond_to do |format|
       if !@gallery_item.update_attributes(params, :as=>@role)
         format.json { render :json=>report_error(@gallery_item)}
       else
         format.json { render :json=> @gallery_item.ajax_attrs(@role) }
       end
     end
  end

  def destroy
    @robots="noindex,nofollow"
    respond_to do |format|
      if !@gallery_item.delete
        format.json { render :json=>report_error(@gallery)}
      else
        format.json { render :json=>{}}
      end
    end
  end
end
