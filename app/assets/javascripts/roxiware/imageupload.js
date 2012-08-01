


// set up an div surrounding an image as an upload target.
// when the image within the div is clicked, an upload dialog will come up
// when the image is selected, it will be uploaded, optionally
// watermarked, and a thumbprint will be returned
// data is a generic list passed to the server side
// common values inclued
//   - width
//   - height
(function($) {

    $.roxiware = $.roxiware || {version: '@VERSION'};
    $.roxiware.image_upload = {
	conf: {
	    uploadPath: '/asset',
	    uploadType: 'image',
	    autoSubmit: true,
	    uploadImageParams: {
		image_sizes: []     // create images in the given sizes
	    },
	    uploadImagePreview: "img#preview_image",           // img element for previewing image
	    uploadImagePreviewSize: "medium",   // size of preview image
	    hoverClass: "upload_target_hover",
	    focusClass: "upload_target_focus",
	    complete: function(urls, thumbprint) {},
	    success: function() {},
	    failure: function() {},
	    uploadTargetContent:'<span id="upload_help" class="popup_help_text upload-button">Click to upload.</span><br/>' +
	                         '<img name="image_url" id="preview_image"/>' 

	}
    };
    function ImageUpload(uploadTarget, conf) {

	// set up the security token so we can authenticate                                                                                                                               
	var self = this;
	self.uploadTarget = $(uploadTarget);
	self.uploadTarget.html(conf.uploadTargetContent);

        this.file_upload = new qq.FileUploaderBasic({
		action: conf.uploadPath + "/" + conf.uploadType,
		element: uploadTarget,
		params: conf.uploadImageParams,
		debug: true,
		button: uploadTarget,
		multiple:false,
                allowed_extensions: ["jpg", "png", "jpeg", "gif"],
		onSubmit: function(id, filename) {
		},
		onProgress: function(id, filename, current, total) {
		   $.wait();
		},
		onComplete: function(id, filename, json_data) {
		    $.resume();
		    self.setImage(json_data.urls[conf.uploadImagePreviewSize]);
		    self.setThumbprint(json_data.thumbprint);
                    conf.complete(json_data.urls, json_data.thumbprint);

		}
	    });
	this.setImage = function(image_url) {
	    if(image_url) {
		this.uploadTarget.find(conf.uploadImagePreview).attr("src", image_url);
		this.uploadTarget.find(conf.uploadImagePreview).css("display", "inline");
	    }
	    else {
		this.uploadTarget.find(conf.uploadImagePreview).removeAttr("src");
		this.uploadTarget.find(conf.uploadImagePreview).css("display", "none");
	    }
	   this.uploadTarget.image_url = image_url;
	   return this;
       }
       this.setThumbprint = function(image_thumbprint) {
	   this.uploadTarget.image_thumbprint = image_thumbprint;
       }
	this.getImage = function() {
	    return self.uploadTarget.image_url;
       }

       this.getThumbprint = function(image_url) {
	   return self.uploadTarget.image_thumbprint;
       }


       this.enable = function() {
            self.uploadTarget.find("span#upload_help").css("visibility", "visible");
  	    self.uploadTarget.find("input[type=file]").removeAttr("disabled");
	   return self;
       }

	this.disable = function() {
            self.uploadTarget.find("span#upload_help").css("visibility", "hidden");
            self.uploadTarget.find("input[type=file]").attr("disabled", "disabled");
	   return self;
	}
	this.clear = function() {
	    self.setImage(null);
	    self.setThumbprint(null);
	}
	this.setParams = function(upload_params) {
	    console.log("set params ");
	    console.log(upload_params);
	    if(this.file_upload) {
	       this.file_upload.setParams(upload_params);
	    }
	   return self;
	};
    };
    $.fn.image_upload = function(conf) {

	var iu_api = this.data("image_upload");
	if (iu_api) { 
	    return iu_api; 
	}

	console.log("image upload conf");
	console.log(conf);
	conf = $.extend(true, {}, $.roxiware.image_upload.conf, conf);
	var csrf_token = $('meta[name="csrf-token"]').attr('content');
	var csrf_param = $('meta[name="csrf-param"]').attr('content');
	var upload_params = conf.uploadImageParams
	if (csrf_param !== undefined && csrf_token !== undefined) {
	    upload_params[csrf_param] = csrf_token;
	};
	this.each(function() {
		iu_api = new ImageUpload(this, conf);
		iu_api.setParams(upload_params);
		$(this).data("image_upload", iu_api);
	    });
	return conf.api ? iu_api: this;
    };
})(jQuery);
