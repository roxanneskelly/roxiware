class Roxiware::AssetController < ApplicationController
  require 'RMagick'
  require 'uuid'
  include Roxiware::ImageHelpers
  
  def upload
     render :status => 401 unless (!current_user.nil?)
     case params[:upload_type]
       when "image"
          extension = File.extname(params[:qqfile])
	  requested_sizes = params[:imageSizes] || {}
          thumbprint = UUID.new.generate :compact

          # create the file path
          image = Magick::Image.from_blob(request.body.read).first
	  if requested_sizes.has_key?(:raw)
	      # limit by the maximum image size allowed, and save it
	      write_image = image.resize_to_fit( Roxiware.upload_image_sizes[:huge][0], Roxiware.upload_image_sizes[:huge][1])
	      image.destroy!
          else
	      write_image = image
          end
	  upload_path = Rails.root.join(AppConfig.raw_upload_path, thumbprint+extension)
	  puts "SAVING TO " + upload_path
          write_image.write(upload_path)
	  result = Roxiware::ImageHelpers.process_uploaded_image(upload_path, :image=>write_image, :image_sizes=>requested_sizes)
          render :json => result
	  puts "RESULT IS #{result.inspect}"
        else
          render :status => 404
        end
    end
end
