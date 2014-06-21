module Roxiware
    module ImageHelpers
        require 'RMagick'


        def self.modify_image(image, upload_path, options)
            if(options.include?(:crop))
                image.crop!(options[:crop][:x].to_i, options[:crop][:y].to_i, options[:crop][:width].to_i, options[:crop][:height].to_i)
            end
            if(options.include?(:width) && options.include?(:height))
                image.resize_to_fit!(options[:width].to_i, options[:height].to_i)
            end
            image.write(upload_path)
        end

        def self.process_uploaded_image(filename, options={})
            extension = File.extname(filename)
            base_filename = File.basename(filename, extension)
            result = {:basename => base_filename, :urls=>{}}
            requested_sizes = options[:image_sizes] || {"raw"=>{}}
            processed_image_root = File.join(Rails.root.join(AppConfig.processed_upload_path), base_filename)

            image = options[:image] || Magick::Image::read(filename).first
            requested_sizes.each do |name, size|
                sizes = requested_sizes[name]
                if name != "raw"
                    image_watermark = nil
                    if(sizes["width"].to_i > 200)
                        image_watermark = options[:watermark]
                        if options[:watermark_person].present?
                            image_watermark = "\xa9" + DateTime.now.year.to_s + " " + options[:watermark_person].full_name;
                        end
                    end

                    resize_image = image.resize_to_fit(sizes["width"].to_i, sizes["height"].to_i)
                    if image_watermark.present?
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
                    result[:success] = true;
                end
            end
            image.destroy! if options[:image].blank?
            result
        end
    end
end
