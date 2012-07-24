module Roxiware
  module ImageHelpers
    require 'RMagick'
    def self.process_uploaded_image(thumbprint, options={})

      result = {:thumbprint=>thumbprint, :urls=>{}}
      requested_sizes = options[:image_sizes] ||= Roxiware.upload_image_sizes.keys
      base_image = File.join(Rails.root.join(AppConfig.raw_upload_path), thumbprint+Roxiware.upload_image_file_type)
      processed_image_root = File.join(Rails.root.join(AppConfig.processed_upload_path), thumbprint)

      image = options[:image] || Magick::Image::read(base_image).first
      requested_sizes.each do |name|
	 sizes = Roxiware.upload_image_sizes[name.to_sym]
	 if sizes
	    image_watermark = nil
	    if(sizes[0] > 200)
	       image_watermark = options[:watermark]
	       if options[:watermark_person].present?
		  image_watermark = "©" + DateTime.now.year.to_s + " " + options[:watermark_person].full_name;
	       end
	    end
	    
	    print "RESIZING TO " + sizes.to_json + "\n\n"
	    resize_image = image.resize_to_fit(sizes[0], sizes[1])
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

	    resize_image.write( processed_image_root + "_#{name}"+Roxiware.upload_image_file_type)
	    result[:urls][name] = File.join(AppConfig.upload_url, thumbprint + "_#{name}"+Roxiware.upload_image_file_type)
	 end
      end
      result
    end
  end
end