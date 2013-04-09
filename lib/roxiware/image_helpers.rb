module Roxiware
  module ImageHelpers
    require 'RMagick'
    def self.process_uploaded_image(filename, options={})
      extension = File.extname(filename)
      base_filename = File.basename(filename, extension)
      result = {:basename => base_filename, :urls=>{}}
      requested_sizes = options[:image_sizes] || Roxiware.upload_image_sizes
      processed_image_root = File.join(Rails.root.join(AppConfig.processed_upload_path), base_filename)

      image = options[:image] || Magick::Image::read(filename).first
      requested_sizes.each do |name, size|
         sizes = requested_sizes[name]
	 if name != "raw"
	    image_watermark = nil
	    if(sizes["width"].to_i > 200)
	       image_watermark = options[:watermark]
	       if options[:watermark_person].present?
		  image_watermark = "©" + DateTime.now.year.to_s + " " + options[:watermark_person].full_name;
	       end
	    end
	    
	    resize_image = image.resize_to_fit(sizes["width"].to_i, sizes["height"].to_i)
	    if image_watermark.present?
	        print "WATERMARKING WITH " + image_watermark + " to " + resize_image.columns.to_s, resize_image.rows.to_s + "\n\n"
		mark = Magick::Image.new(resize_image.columns, resize_image.rows) do
		  self.background_color = 'none'
		end
		gc = Magick::Draw.new
		gc.text_antialias = true
		gc.gravity = Magick::SouthEastGravity
		gc.stroke  = "none"
		gc.fill = "white"
		gc.pointsize = 16
		gc.font_weight = 900
		gc.opacity(0.5)
		gc.text(10,10,image_watermark)
		gc.draw(resize_image)
	    end

	    resize_image.write( processed_image_root + "_#{name}#{extension}")
	    resize_image.destroy!
	    result[:urls][name] = File.join(AppConfig.upload_url, base_filename + "_#{name}"+extension)
	    result[:success] = true;
	 else
	    image.write( processed_image_root + extension)
	    result[:urls][name] = File.join(AppConfig.upload_url, base_filename + extension)
	 end
      end
      result
    end
  end
end