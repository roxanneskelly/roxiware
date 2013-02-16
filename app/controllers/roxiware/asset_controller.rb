class Roxiware::AssetController < ApplicationController
  require 'RMagick'
  require 'uuid'
  include Roxiware::ImageHelpers
  
  def upload
     render :status => 401 unless (!current_user.nil?)
     case params[:upload_type]
       when "image"
          extension = File.extname(params[:qqfile])
          if params[:unprocessed_raw].present? && params[:unprocessed_raw]
	     path = File.join(Rails.root.join(AppConfig.processed_upload_path, params[:qqfile]))
	     file = File.open(path, "wb") do |f|
	        f.write(request.body.read)
	     end
	     render :json => {:urls=>{:raw=> File.join(AppConfig.upload_url, File.basename(params[:qqfile]))}, :success=>true}
	     return
	  end
	  requested_sizes = params[:imageSizes] || {}
          thumbprint = UUID.new.generate :compact
          # create the file path
          image = Magick::Image.from_blob(request.body.read).first
	  write_image = image.resize_to_fit( Roxiware.upload_image_sizes[:huge][0], Roxiware.upload_image_sizes[:huge][1])
	  image.destroy!
	  upload_path = Rails.root.join(AppConfig.raw_upload_path, thumbprint+extension)
          write_image.write(upload_path)

	  result = Roxiware::ImageHelpers.process_uploaded_image(upload_path, :image=>write_image, :image_sizes=>requested_sizes)
	  if(params[:unprocessed_raw].present? && params[:unprocessed_raw])
	     result[:urls][:raw] = File.join(AppConfig.upload_url, File.basename(upload_path))
	  end
          render :json => result
	  puts "RESULT IS #{result.inspect}"
        else
          render :status => 404
        end
    end
end
