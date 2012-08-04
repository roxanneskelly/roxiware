class Roxiware::GalleryItemController < ApplicationController
  include Roxiware::GalleryHelper
  load_and_authorize_resource :except=>[:new, :create], :class=>"Roxiware::GalleryItem"

  before_filter do
    @role = "guest"
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
    render_attrs = @gallery_item.ajax_attrs(@role)
    gallery_item_ids = @gallery_item.gallery.gallery_item_ids
    gallery_item_ids.unshift(nil)
    gallery_item_ids.push(nil)
    (0..gallery_item_ids.size).each do |index|
      if(gallery_item_ids[index+1] == @gallery_item.id)
         render_attrs[:next_id] = gallery_item_ids[index+2]
         render_attrs[:prev_id] = gallery_item_ids[index]
      end
    end
    respond_to do |format|
      format.html { render }
      format.json { render :json => render_attrs }
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
     @gallery_item = Roxiware::GalleryItem.new({:name=>"New Item", :person_id=>current_user.person.id, :description=>"Description", :image_url=>"/foo", :thumbnail_url=>"/bar"}, :as=>@role) 
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
     if cannot?(:edit, @gallery_item) || @gallery_item.person_id.nil?
       @gallery_item.person_id = current_user.person.id
     end
     respond_to do |format|
       if !@gallery_item.update_attributes(params, :as=>@role)
         format.json { render :json=>report_error(@gallery_item) }
       else
         Roxiware::ImageHelpers.process_uploaded_image(@gallery_item.image_thumbprint, :watermark_person=>@gallery_item.person, :image_sizes=>params[:image_sizes])
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
         Roxiware::ImageHelpers.process_uploaded_image(@gallery_item.image_thumbprint, :watermark_person=>@gallery_item.person, :image_sizes=>params[:image_sizes])
         format.json { render :json=> @gallery_item.ajax_attrs(@role) }
       end
     end
  end

  def destroy
    @robots="noindex,nofollow"
    respond_to do |format|
      if !@gallery_item.destroy
        format.json { render :json=>report_error(@gallery)}
      else
        format.json { render :json=>{}}
      end
    end
  end
end
