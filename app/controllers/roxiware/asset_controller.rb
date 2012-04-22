# -*- coding: utf-8 -*-
class AssetController < ApplicationController
  require 'RMagick'
  def upload
     render :status => 401 unless (!current_user.nil?)
     case params[:upload_type]
       when "image"
          upload_image_thumbprint = UUID.new.generate :compact
          # create the file path
          path = File.join(AppConfig.upload_path, upload_image_thumbprint + ".png")
          # resize
          image = Magick::Image.from_blob(params[:upload_asset].read).first
          width = (params.has_key?(:width))?(params[:width].to_i):(image.columns)
	  height = (params.has_key?(:height))? (params[:height].to_i):(image.rows)
	  if ((width != image.columns) && (height != image.rows))
             image.resize_to_fit!(width, height)
             logger.debug "resizing to "+width.to_s+" "+height.to_s
          end
          # center image
	  image = image.colorize(0.20, 0.20, 0.20, 0.20, '#cc9953')
          image.background_color = 'none';
          logger.warn "height " + height.to_s
          if params.has_key?(:pad_image) && (params[:pad_image])
	     width_offset = (width-image.columns)/2
             height_offset = (height-image.rows)/2

              mversion = Magick::Magick_version
              ( v_version , v_commit ) = mversion.split(' ')[1].split('-')
              ( v_version_1 , v_version_2 , v_version_3 ) = v_version.split('.')
              if Integer(v_version_1) >= 6 and Integer(v_version_2) >= 6 and Integer(v_version_3) >= 4 and Integer(v_commit) >= 2
              	 width_offset = - width_offset
              	 height_offset = - height_offset
              end
	      image = image.extent(width, 
              	                   height, 
                                   width_offset,
		                   height_offset)
          end
    	  logger.debug "thumbprint"+upload_image_thumbprint
          image.write(path)
	  result = {:image_url=>File.join(AppConfig.upload_url, upload_image_thumbprint + ".png") }
          if params.has_key?(:thumbnail_width) && params.has_key?(:thumbnail_height)
	      thumbnail_image = Magick::Image.read(path)
              image.resize_to_fit!(params[:thumnail_width], params[:thumbnail_height])
              thumbnail_path = File.join(AppConfig.upload_path, upload_image_thumbprint + "_thumbnail.png")
	      image.write(thumbnail_path)
	      result[:thumbnail_url] = File.join(AppConfig.upload_url, upload_image_thumbprint + "_thumbnail.png")
          end
          render :json => result
        else
          logger.debug "general create"
          render :status => 404
        end
    end
end
