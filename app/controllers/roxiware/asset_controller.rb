class Roxiware::AssetController < ApplicationController
  require 'RMagick'
  require 'uuid'
  include Roxiware::ImageHelpers
  
  def upload
     render :status => 401 unless (!current_user.nil?)
     case params[:upload_type]
       when "image"
          if params[:image_sizes].present?
	     requested_sizes ||= []
	     params[:image_sizes].each do |key, value|
	        requested_sizes << value
	     end
	  end
          thumbprint = UUID.new.generate :compact
          # create the file path
          raw_image_base_path = File.join(Rails.root.join(AppConfig.raw_upload_path), thumbprint)
          image = Magick::Image.from_blob(request.body.read).first
	  write_image = image.resize_to_fit( Roxiware.upload_image_sizes[:huge][0], Roxiware.upload_image_sizes[:huge][1])
	  image.destroy!
          write_image.write(Rails.root.join(AppConfig.raw_upload_path, thumbprint+Roxiware.upload_image_file_type))

	  result = Roxiware::ImageHelpers.process_uploaded_image(thumbprint, :image=>write_image, :image_sizes=>requested_sizes)
          render(:json => result)
        else
          render :status => 404
        end
    end
end
