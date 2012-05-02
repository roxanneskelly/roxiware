
(function($) {

    $.roxiware = $.roxiware || {version: '@VERSION'};
    $.roxiware.popup_form = {
	conf: {
            imageUploadPath: '/assets/upload',
	    uploadImageTarget: ".upload_target",
	    imagePath: "/assets/uploads/",
	    method: "PUT",
	    canEdit: false,
	    complete: function(XMLHttpRequest, textStatus) { },
	    error: function (XMLHttpRequest, textStatus, errorThrown) 
	    {
		conf.alertPopup([["general", textStatus]]); 
	    },
	    success: function (data, textStatus, XMLHttpRequest) {},
	    uploadImagePreview: null,
	    uploadImageThumbnailTarget: null,
	    uploadImageUrlTarget: null,
            dataId: "user",
	    fieldErrorClass: "popup_form_error_field",
	    errorPopupGenerator: function(data) {
		result = "<div class='popup_form_alert'><table>";
	        $.each(data, function(key, value) {
			result +="<tr><td>"+value[0]+"</td><td>"+value[1]+"</td></tr>";
		    });
                result += "</table></div>";
		console.log(result);
		return $(result);

            },
	    alertPopup: function (data) {
                }
        }
    };

    function PopupForm(form, url, conf) {
	var self = form,
	    endpoint = url;
	if (!conf.uploadImagePreview) {
	    conf.uploadImagePreview = conf.uploadImageTarget + " img";
	}

	if (!conf.uploadUrlTarget) {
	    conf.uploadImageUrlTarget = conf.uploadImageTarget + " input[name=image_url]";
	}

	if (!conf.uploadImageThumbnailTarget) {
	    conf.uploadImageThumbnailTarget = conf.uploadImageTarget + " input[name=thumbnail_url]";
	}
	$.extend(self, 
		 {
		clear: function() {
			 // hide buttons
			 self.find(".button").css("visibility", "hidden");
			 self.find(".button").off("click");
		 
			 // disable inputs 
			 self.find("input").attr("readonly","").removeClass(conf.fieldErrorClass);
			 self.find("input[type=text]").val("").removeClass(conf.fieldErrorClass);
			 self.find("textarea").attr("readonly","").removeClass(conf.fieldErrorClass);
			 self.find("textarea").text("").removeClass(conf.fieldErrorClass);
			 self.find("select").attr("disabled", "").removeClass(conf.fieldErrorClass);
		    
			 self.find("textarea.popup_wysiwyg").wysiwyg('destroy');
			 // clear images for all popup form uploadable images
			 self.find(conf.uploadImagePreview).removeAttr("src");
			 self.find(conf.uploadImageUrlTarget).removeAttr("value");
			 self.find(conf.uploadImageThumbnailTarget).removeAttr("value");
		     },

		 edit: function(edit_fields) {
			 console.log("setting edit fields");
			 $.each(edit_fields, function(index,key) {
				      console.log("setting to edit " + key);
			           self.find("input[name="+key+"]").removeAttr("readonly");
			           self.find("textarea[name="+key+"]").removeAttr("readonly");
			           self.find("select[name="+key+"]").removeAttr("disabled");
				   self.find("textarea.popup_wysiwyg[name="+key+"]").wysiwyg({
				       controls: {
				          undo: { visible: false },
					  redo: { visible: false},
					  insertHorizontalRule: { visible: true},
					  html: { visible: true},
					  insertTable: {visible: true},
					  'fileManager': {
					      visible: true,
					      tooltip: "File Manager"
						  }
					   }
				       });
                                       self.find("select[name="+key+"]").removeAttr("disabled");
                                       self.find("textarea[name="+key+"]").removeAttr("readonly");
				  });

			 var image_upload_params = {
			     width: self.find(conf.uploadImageUrlTarget).width(),
			     height: self.find(conf.uploadImageUrlTarget).height(),
			     thumbnail_width: self.find(conf.uploadImageThumbnailTarget).width(),
			     thumbnail_height: self.find(conf.uploadImageThumbnailTarget).height(),
			     uploadImagePreview: conf.uploadImagePreview,
			     uploadImageUrlTarget: conf.uploadImageUrlTarget,
			     uploadImageThumbnailTarget: conf.uploadImageThumbnailTarget
			 };

			 if (conf.watermark) {
			     image_upload_params["watermark"] = conf.watermark;
			 };
			 self.find(conf.uploadImageTarget).image_upload(image_upload_params);
			 self.find("div.edit_button").css("visibility", "hidden").off("click");
			 self.find("div.save_button").css("visibility", "visible").click(function(){
				 self.save();
			     });
			 self.find("div.delete_button").css("visibility", "visible").click(function(){
				 self.delete();  
			     });
		     },
		 save: function() {
			 $.ajax({
				 url: endpoint +".json",
				     type: conf.method,
				     processData: false,
				     data: jQuery.param(self.find("form").serializeArray()),
				     complete: conf.complete,
				     error: function (jqXHR, textStatus, errorThrown) {
				     self.alert([["Server Error", errorThrown]]);
				     },
				     success: function (data, textStatus, jqXHR) 
				     {
				       if ("error" in data) {
					   self.alert(data["error"]);
				       }
                                       else {
				         conf.success(data, textStatus, jqXHR);
                                       }
				 }
				  });
		     },
             alert: function(data) {
			 
		   $.each(data, function(key, value) {
			   self.find("input[name="+value[0]+"]").addClass(conf.fieldErrorClass);
		      });
		      result =conf.errorPopupGenerator(data);
		      self.before(result);
		      result.overlay({
			      top: 260,
				  oneInstance: false,
				  load: true,
				  zIndex: 99999,
				  mask: {
				  zIndex: 99998,
				      color: "#000000",
				      loadSpeed: 200,
				      opacity: 0.6
				      },
                                  onClose: function() { 
			          result.remove();
			      }});
		     },
             delete: function() {
			 $.ajax({
				 url: endpoint + ".json",
				     type: "DELETE",
				     processData: false,
				     complete: conf.complete,
				     error: conf.error,
				     success: conf.success
				     });
		     }
		 });
	self.clear();

	var get_endpoint = endpoint;
	if (conf.method == "POST") {
	    get_endpoint += "/new";
	}	
	get_endpoint += ".json"
	$.getJSON(get_endpoint,
		  function(json_data) {
		      $.each(json_data, function(key, value) {
			      self.find("input[name="+key+"]").val(value);
			      self.find("hidden[name="+key+"]").val(value);
			      self.find("textarea[name="+key+"]").text(value);
			      self.find("img[name="+key+"]").attr("src", value);
			      self.find("select[name="+key+"]").val(value);
			  });
		      if (json_data.can_edit) {
			  if(conf.canEdit) {
			      self.edit(json_data.can_edit);
			  }
			  else {
			      self.find("div.edit_button").css("visibility", "visible").click(function() {
				  self.edit(json_data.can_edit);
			      });
			  }
			  self.find("div.delete").css("visibility", "visible").click(function() {
			      });
		      }
		      else
		      {
			  self.find("div.edit_button").css("visibility", "hidden").click();
		      }
		  });
		  
    }

    $.fn.popup_form = function(url, conf){
        // extend the configuration by passed in values
        conf = $.extend(true, {}, $.roxiware.popup_form.conf, conf);

        // add the ajax edit form code to each entry in the jQuery object
        this.each(function() {
		pf_api = new PopupForm($(this), url, conf);
		$(this).data("popup_form", pf_api);
	    });
	return conf.api ? pf_api: this;
    };
})(jQuery);