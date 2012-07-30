
function toTitleCase(str)
{
   return str.replace(/_/g, " ").replace(/\w\S*/g, function(txt){return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();});
}

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
	    uploadImageThumbprint: null,
	    uploadImageSizes: ["medium"],
            dataId: "user",
	    fieldErrorClass: "popup_form_error_field",
	    errorPopupGenerator: function(data) {
		result = "<div class='overlay popup_form_alert'><table>";
	        $.each(data, function(key, value) {
			if (value[0]) {
                            result +="<tr><td>"+toTitleCase(value[0])+"</td><td>"+value[1]+"</td></tr>";
                        }
                        else {
                          result +="<tr><td>System Error</td><td>"+value[1]+"</td></tr>";
			}
		       
		    });
                result += "</table></div>";
		return $(result);

            },
	    alertPopup: function (data) {
                }
        }
    };

    function PopupForm(form, url, conf) {
	var self = form,
	    endpoint = url;

        var image_upload_params = {
           uploadImageSizes: conf.uploadImageSizes,
	};
        if (conf.watermark) {
	     image_upload_params["watermark"] = conf.watermark;
	 };
	self.find(conf.uploadImageTarget).image_upload({uploadParams:image_upload_params,
	   complete: function(urls, thumbprint)
           {
	        self.find(conf.uploadImageThumbprint).val(thumbprint);
	   }
        });

	if (!conf.uploadImageThumbprint) {
	    conf.uploadImageThumbprint = "input[name=image_thumbprint]";
	}

	$.extend(self, 
		 {
		clear: function() {
			 // hide buttons
			 self.find(".button").css("visibility", "hidden");
			 self.find(".button").off("click");
		 
			 // disable inputs 
			 self.find("input").attr("readonly","").removeClass(conf.fieldErrorClass);
			 self.find("input[type=text]").val("");
			 self.find("input:checkbox").attr("disabled", "").removeAttr("checked").val("false");
			 self.find("textarea").attr("readonly","").removeClass(conf.fieldErrorClass);
			 self.find("textarea").text("").removeClass(conf.fieldErrorClass);
			 self.find("select").attr("disabled", "").removeClass(conf.fieldErrorClass);
			 self.find("select").selectBox("disable");
		    
			 self.find("textarea.popup_wysiwyg").wysiwyg('destroy');
			 // clear images for all popup form uploadable images
			 self.find(conf.uploadImageTarget).each(function(index, item) {
				 $(item).image_upload().clear();
			     });
			 self.find("button#save_button").css("visibility", "hidden").off("click");
			 self.find("button#edit_button").css("visibility", "hidden").off("click");
		     },

		 edit: function(edit_fields) {
			 $.each(edit_fields, function(index,key) {
			           self.find("input[name='"+key+"']").removeAttr("readonly");
			           self.find("textarea[name='"+key+"']").removeAttr("readonly");
			           self.find("select[name='"+key+"']").selectBox("enable");
				   self.find("input:checkbox").removeAttr("disabled");
				   self.find("input.jquerytools_date").dateinput({
					   format: 'mm/dd/yyyy',
					       trigger: true,
					       min: -1
				       });
				   var wysiwyg_params = {
                                       css: conf.wysiwyg_css,
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
				   }
				   self.find("textarea.popup_wysiwyg[name='"+key+"']").wysiwyg(wysiwyg_params)
				       self.find("select[name='"+key+"']").selectBox("enable");
                                   self.find("textarea[name='"+key+"']").removeAttr("readonly");
			     });

			 self.find("button#edit_button").css("visibility", "hidden").off("click");
			 self.find("button#save_button").css("visibility", "visible").click(function(){
				 self.save();
			     });
			 self.find("div.delete_button").css("visibility", "visible").click(function(){
				 self.delete();  
			     });
		     },
		 save: function() {
			 // unchecked checkboxes won't be included, so we need
			 // to add them.
			 var form_data = self.find("form").serializeArray();
			 self.find("input:checkbox[checked!=checked]").each(function(index, element) {
				 form_data.push({
					 name: $(element).attr("name"),
					     value:"false"});
			     });
			 var wait_icon = $("<img src='/assets/wait30trans.gif'/>");
                         self.prepend(wait_icon);
			 wait_icon.addClass("wait_icon");

			 $.ajax({
				 url: endpoint +".json",
				     type: conf.method,
				     processData: false,
				     dataType: "json",
				     data: jQuery.param(form_data),
				     complete: function() { wait_icon.remove(); conf.complete },
				     error: function (jqXHR, textStatus, errorThrown) {
				     self.alert([[null, errorThrown]], false);
				     },
				     success: function (data, textStatus, jqXHR) 
				     {
				       if ("error" in data) {
					   self.alert(data["error"], false);
				       }
                                       else {
				         conf.success(data, textStatus, jqXHR);
                                       }
				 }
				  });
		     },
          	 alert: function(data, closeOverlay) {
		   $.each(data, function(key, value) {
			   if(value[0]) { 
                              self.find("input[name="+value[0]+"]").addClass(conf.fieldErrorClass);
                           }
		      });
		      result =conf.errorPopupGenerator(data);
		      self.before(result);
		      result.overlay({
			      top: 260,
				  oneInstance: false,
				  load: true,
				  zIndex: 99999,
                                  closeOnClick: false,
				  mask: {
				  zIndex: 99998,
				      color: "#777",
				      loadSpeed: 200,
				      opacity: 0.6
				      },
                                  onClose: function() {
				     result.remove();
				     if(closeOverlay) {
                                        self.find(".close").click();
				     }
			      }});
		     },
             delete: function() {
			 $.ajax({
				 url: endpoint + ".json",
				     type: "DELETE",
				     processData: false,
				     complete: conf.complete,
				     error: function (jqXHR, textStatus, errorThrown) {
                                        self.alert([[null, errorThrown]], false);
				     },
				     success: conf.success
				     });
		     }
		 });
	self.clear();

	var get_endpoint = endpoint;
	if (conf.method == "POST") {
	    get_endpoint += "/new";
	}
        self.find("button").button();

	var wait_icon = $("<img src='/assets/wait30trans.gif'/>");
	self.prepend(wait_icon);
	wait_icon.addClass("wait_icon");
	get_endpoint += ".json"
	    $.ajax({
		    url:get_endpoint,
			dataType:'json',
			
                        error: function (jqXHR, textStatus, errorThrown) {
			self.alert([[null, errorThrown]], true);
			},
                        complete: function() { wait_icon.remove(); conf.complete },
		        success:function(json_data) {
                            if ("error" in json_data) {
				self.alert(json_data["error"], true);
			    }
			    else {
		               $.each(json_data, function(key, value) {
			           self.find("input[name='"+key+"']:hidden").val(value);
			           self.find("input[name='"+key+"']:text").val(value);
			           self.find("input[name='"+key+"']:password").val(value);
			           self.find("input:checkbox[name='"+key+"']").val("true").each(function(index, elem) {
					   if (value) {
					       $(elem).attr("checked", "checked");
					   }
					   else {
					       $(elem).removeAttr("checked");
					   }});
			           self.find("hidden[name='"+key+"']").val(value);
			           self.find("textarea[name='"+key+"']").text(value);
				   if(key == "medium_image_url") {
				       self.find(conf.uploadImageTarget).each(function(index, item) { $(item).image_upload().setImage(value);
					   });
				   }
			           self.find("select[name='"+key+"']").find("option[value="+"admin"+"]").attr("selected", "selected");
			           self.find("select[name='"+key+"']").selectBox("value", value);
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
		              else {
			        self.find("div.edit_button").css("visibility", "hidden").click();
    		              }
			    }
		    }});
		  
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