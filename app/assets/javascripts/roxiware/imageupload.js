


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
	    uploadParams: {},
	    uploadImageUrlTarget: null,
	    uploadImageThumbnailTarget: null,
	    uploadImagePreview: null

	}
    };
    function ImageUpload(uploadTarget, conf) {
	$.extend(uploadTarget,
		 {
		     submit: function () {
		     }
		 });

	new AjaxUpload(uploadTarget, {
		action: conf.uploadPath + "/" + conf.uploadType,
		    autoSubmit: conf.autoSubmit,
		    name: "upload_asset",
		    responseType: "json",
		    onSubmit : function(file, ext) {
                        var upload_wait_icon = $("<img src='/assets/wait30trans.gif'/>");
                         $("body").append(upload_wait_icon);
			 upload_wait_icon.addClass("wait_icon");


		        if (! (ext && /^(jpg|png|jpeg|gif)$/i.test(ext))){
                            // extension is not allowed
			    alert('Error: invalid file extension');
			    // cancel upload
			    return false;
			}
			// set up the security token so we can authenticate
			var csrf_token = $('meta[name="csrf-token"]').attr('content');
			var csrf_param = $('meta[name="csrf-param"]').attr('content');
			var upload_params = conf.uploadParams;
			if (csrf_param !== undefined && csrf_token !== undefined) {
			    upload_params[csrf_param] = csrf_token;
			}
		        if (conf.width != undefined && conf.height != undefined) {
			    upload_params["width"] = conf.width;
			    upload_params["height"] = conf.height;
			}
		        if (conf.uploadImageThumbnailTarget != undefined && conf.thumbnail_width != undefined && conf.height != undefined) {
			    upload_params["thumbnail_width"] = conf.thumbnail_width;
			    upload_params["thumbnail_height"] = conf.thumbnail_height;
			}
			this.setData(upload_params);
		    },

		    onComplete: function(file, json_data) {
		    $(".wait_icon").remove();
			$(conf.uploadImagePreview).attr("src", json_data.image_url);
			$(conf.uploadImageUrlTarget).val(json_data.image_url);
			$(conf.uploadImageUrlTarget).change();
			$(conf.uploadImageThumbnailTarget).val(json_data.thumbnail_url);
			$(conf.uploadImageThumbnailTarget).change();
		    }
	});
    };
    $.fn.image_upload = function(conf) {
	var iu_api = this.data("image_upload");
	if (iu_api) { return iu_api; }

	conf = $.extend(true, {}, $.roxiware.image_upload.conf, conf);

	this.each(function() {
		iu_api = new ImageUpload($(this), conf);
		$(this).data("image_upload", iu_api);
	    });
	return conf.api ? iu_api: this;
    };
})(jQuery);
