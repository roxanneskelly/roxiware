class Roxiware::AssetController < ApplicationController
  require 'RMagick'
  require 'uuid'
  require 'open-uri'
  require 'set'
  include Roxiware::ImageHelpers

  skip_after_filter :store_location
  def show
      serve_file_name = Pathname(request.path).basename
      # determine if there's a width and height value
      serve_file_path = Rails.root.join(AppConfig.raw_upload_path, serve_file_name)
      if(!File.exist?(serve_file_path))
	  extension = serve_file_name.extname
	  puts "MIME #{request.format.inspect}"
	  case request.format.to_sym
	  when :jpeg, :gif, :png, :tiff
	      allowed_image_sizes = Set.new(%w(50x50 50x75 300x450 400x400 400x450 200x225 180x180 200x200 100x100 100x150))
	      match = /^(.+)_(\d+)x(\d+)$/.match(serve_file_name.basename(".*"))
	      width =  match[2].to_i if match
	      height = match[3].to_i if match
	      root_name = match[1] if match

	      raise ActiveRecord::RecordNotFound unless (user_signed_in? || allowed_image_sizes.include?("#{width}x#{height}"))
	      # if someone tries to generate an image that's too big, then toss them
	      root_file_path = Rails.root.join(AppConfig.raw_upload_path, root_name+extension)
	      raise ActiveRecord::RecordNotFound if(width > 1600) || (height > 1050)
	      raise ActiveRecord::RecordNotFound unless File.exist?(root_file_path)

	      image = Magick::Image.from_blob(open(root_file_path, "r").read).first
	      image.resize_to_fit!(width, height)
	      image.write(serve_file_path)
	  else
	      raise ActiveRecord::RecordNotFound
          end
      end
      send_file(serve_file_path, :type=>request.format.to_s, :disposition=>"inline") 
  end

  def edit
      respond_to do |format|
          format.html { render :partial =>"roxiware/asset/editform_image", :locals=>{:asset_url=>params[:url], :width=>params[:width], :height=>params[:height]} }
      end
  end
  
  def create
     render :status => 401 unless user_signed_in?
     case params[:asset_type]
       when "image"
          thumbprint = UUID.new.generate :compact
          if(params[:qqfile])
	      extension = File.extname(params[:qqfile])
	      image_file_handle=request.body
	  else
	    image_url = URI(params[:url])
            extension = File.extname(image_url.path)
	    if image_url.host
                image_file_handle = open(image_url.to_s)
            else
	        image_file_handle = open(Rails.root.join(AppConfig.raw_upload_path, Pathname.new(image_url.path).basename))
	    end
	  end
          # read in the image to make sure it's valid
	  image = Magick::Image.from_blob(image_file_handle.read).first

	  upload_path = Rails.root.join(AppConfig.raw_upload_path, thumbprint+extension)
	  Roxiware::ImageHelpers.modify_image(image, upload_path, params)
          render :json => {:success=>"true", :url=>asset_path+"/" +  thumbprint+extension}
        else
          render :status => 404
        end
    end
    
    def update
        render :status => 401 unless (!current_user.nil?)
        thumbprint = UUID.new.generate :compact
	case params[:modify_type]
	    when "image"
	    image_url = URI(params[:url])
            extension = File.extname(image_url.path)
	    if image_url.host
                image_file_handle = open(image_url.to_s)
            else
	        image_file_handle = open(Rails.root.join(AppConfig.raw_upload_path, Pathname.new(image_url.path).basename))
	    end
	    image = Magick::Image.from_blob(image_file_handle.read).first
	    upload_path = Rails.root.join(AppConfig.raw_upload_path, thumbprint+extension)
	    result = Roxiware::ImageHelpers.modify_image(image, upload_path, params)
	    render :json=>result
	else
          render :status => 404
	end
    end
end
