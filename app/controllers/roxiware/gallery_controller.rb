class Roxiware::GalleryController < ApplicationController
  include Roxiware::GalleryHelper

  application_name "gallery"


  load_and_authorize_resource :except=>[:show_seo, :new], :class=>"Roxiware::Gallery"

  before_filter do
    redirect_to("/") unless @enable_gallery
    @application_name = "gallery"
    @role = "guest"
    @role = current_user.role unless current_user.nil?
  end

  # GET - Show a listing of galleries
  def index
    # find the galleries in batches so we can render in groups
    @title = @title + " : Galleries"
    @meta_description = @meta_description +" : Galleries"
    @galleries = @galleries.collect {|x| x}
    if can? :create, Roxiware::Gallery
      @galleries << Roxiware::Gallery.new({:name=>"Create New Gallery"}, :as=>@role) 
    end    
  end

  # GET - Show the contents of a single gallery
  def show
    @robots="noindex,nofollow"
    @title = @title + " : Gallery : " + @gallery.name
    @meta_description = @meta_description +" : Gallery : " + @gallery.name

    if can? :create, Roxiware::GalleryItem
       @gallery.gallery_items.create({:name=>"Upload New Picture", :person_id=>current_user.id}, :as=>@role) 
    end    
    respond_to do |format|
      format.html { render }
      format.json { render :json => @gallery.ajax_attrs(@role) }
    end
  end

  # GET - Show the contents of a single gallery
  def show_seo
    @robots="noindex,nofollow"
    @gallery = Roxiware::Gallery.where(:seo_index=>params[:gallery_seo_index]).first
    @title = @title + " : Gallery : " + @gallery.name
    @meta_description = @meta_description +" : Gallery : " + @gallery.name

    raise ActiveRecord::RecordNotFound if @gallery.nil?
    authorize! :read, @gallery
    
    if can? :create, Roxiware::GalleryItem
       logger.debug("adding new gallery item");
       @gallery.gallery_items.build({:name=>"Upload New Picture", :person_id=>current_user.id}, :as=>@role) 
    end    
   logger.debug("items" + @gallery.gallery_items.to_json);
    respond_to do |format|
      format.html { render :show }
      format.json { render :json => @gallery.ajax_attrs(@role) }
    end
  end

  # GET - Get contents to edit a gallery
  def edit
    respond_to do |format|
      format.html { render }
      format.json { render :json => @gallery.ajax_attrs(@role) }
    end
  end

  # GET - Get default contents for a new gallery
  def new
     @robots="noindex,nofollow"
     authorize! :create, Roxiware::Gallery
     @gallery = Roxiware::Gallery.new({:name=>"Gallery Name", :description=>"Description", :thumbnail=>""}, :as=>@role)
     respond_to do |format|
         format.html
         format.json { render :json => @gallery.ajax_attrs(@role) }
     end
  end

  def create
     @robots="noindex,nofollow"
     respond_to do |format|
       if !@gallery.update_attributes(params, :as=>@role)
         format.json { render :json=>report_error(@gallery) }
       else
         format.json { render :json=> @gallery.ajax_attrs(@role) }
       end
     end
  end

  def update
     @robots="noindex,nofollow"
     respond_to do |format|
       if !@gallery.update_attributes(params, :as=>@role)
         run_layout_setup
         format.json { render :json=>report_error(@gallery)}
       else
         format.json { render :json=> @gallery.ajax_attrs(@role) }
       end
     end
  end

  def destroy
    @robots="noindex,nofollow"
    respond_to do |format|
      if !@gallery.destroy
         run_layout_setup
        format.json { render :json=>report_error(@gallery)}
      else
        format.json { render :json=>{}}
      end
    end
  end
end
