/**
  Controls: Image plugin
 
  Depends on jWYSIWYG
  Image upload plugin for wysiwyg editor 
    https://github.com/akzhan/jwysiwyg Juan M Martinez, Akzhan Abdulin, and contributors
    Modified from the wysiwyg.image.js plugin supplied with the wysiwyg editor

   includes:
   * tooltip style dialog to change the float/size properties of an image
   * simplified upload dialog with just upload or URL specification
   
   requires: wysiwyg, jquery, roxiware.uitools.js, imageupload.js 

   Copyright (c) 2012 Roxiware

    Dual licensed under the MIT and GPL licenses:   
      http://www.opensource.org/licenses/mit-license.php
      http://www.gnu.org/licenses/gpl.html 
 */
(function ($) {
	"use strict";

	if (undefined === $.wysiwyg) {
		throw "wysiwyg.image.js depends on $.wysiwyg";
	}

	if (!$.wysiwyg.controls) {
		$.wysiwyg.controls = {};
	}

	/*
	 * Wysiwyg namespace: public properties and methods
	 */
	$.wysiwyg.controls.image = {
		groupIndex: 6,
		visible: true,
		exec: function () {
			$.wysiwyg.controls.image.init(this);
		},
		tags: ["img"],
		tooltip: "Insert image",
		init: function (Wysiwyg) {
		var self = this, elements, adialog, dialog, formImageHtml, regexp, dialogReplacements, key, translation;

			dialogReplacements = {
				legend	: "Insert Image",
				preview : "Preview",
				url     : "URL",
			        upload  : "Upload a file from your computer",
				upload_help : "Click to upload.",
				submit  : "Insert Image",
				reset   : "Cancel"
			};
			var formImageHtml = '<div class="overlay" id="wysiwyg_add_image_overlay">' +
                                           '<form class="wysiwyg">' +
	                                   '<div id="upload_target" class="upload_target">' +
	                                    '</div>' + 
                                              '<input id="image_source_upload" name="image_source" type="radio" value="upload" checked>{upload}</input>' +
			                      '<br style="clear:both"/>' +
                                              '<input id="image_source_url" name="image_source" type="radio" value="url">{url}</input>' +
			                        '<input name="image_text_url" type="text" disabled/>' +
			                      '<br/><br/><input type="submit" class="button" value="{submit}" disabled/>' +
			                      '<input type="reset" class="button" value="{reset}"/>' +
			                   '</form>' +
                                         '</div>';

			for (key in dialogReplacements) {
				if ($.wysiwyg.i18n) {
					translation = $.wysiwyg.i18n.t(dialogReplacements[key], "dialogs.image");

					if (translation === dialogReplacements[key]) { // if not translated search in dialogs 
						translation = $.wysiwyg.i18n.t(dialogReplacements[key], "dialogs");
					}

					dialogReplacements[key] = translation;
				}

				regexp = new RegExp("{" + key + "}", "g");
				formImageHtml = formImageHtml.replace(regexp, dialogReplacements[key]);
			}

			var overlay_dialog = $(formImageHtml);
			$("body").append(overlay_dialog);

			overlay_dialog.find("input[name=image_source]:radio").change(function() {
			  var new_image_url;
			  if($(this).val() == "url") {
				// set the preview image to the image specified in the image_url input
				new_image_url = overlay_dialog.find("input[name=image_text_url]").val();
				self.old_image = overlay_dialog.find("div#upload_target").image_upload().getImage();
				self.old_thumbprint = overlay_dialog.find("div#upload_target").image_upload().getThumbprint();
				overlay_dialog.find("div#upload_target").image_upload().setImage(new_image_url).setThumbprint(null).disable();
				overlay_dialog.find("input[name=image_text_url]").removeAttr("disabled");
				
			    }
			  else if ($(this).val() == "upload") {
			      new_image_url = self.old_image;
			      overlay_dialog.find("div#upload_target").image_upload().setImage(self.old_image).setThumbprint(self.old_thumbprint).enable();
			      overlay_dialog.find("input[name=image_text_url]").attr("disabled", "disabled");
			  }

			   if((new_image_url != null) && (new_image_url != "")) {
			      overlay_dialog.find("input:submit").removeAttr("disabled");
			    }
			    else {
				overlay_dialog.find("input:submit").attr("disabled", "disabled");
			    }

			});
                        overlay_dialog.find("input[name=image_text_url]").change(function(e) {
			   var new_image_url = overlay_dialog.find("input[name=image_text_url]").val();
			   overlay_dialog.find("div#upload_target").image_upload().setImage(new_image_url).setThumbprint(null);
			   if((new_image_url != null) && (new_image_url != "")) {
			      overlay_dialog.find("input:submit").removeAttr("disabled");
			    }
			    else {
				overlay_dialog.find("input:submit").attr("disabled", "disabled");
			    }
			    
			});
			overlay_dialog.overlay({
				oneInstance:false,
				top: "center",
				// some mask tweaks suitable for facebox-looking dialogs
				mask: {
				    color: '#222',
				    loadSpeed: 200,
					opacity: 0.5,
					zIndex:2999
				},
				closeOnClick: false,
                                load:true,
			        onClose: function() {
				    overlay_dialog.remove();
				},
				onBeforeLoad: function () {
                                  overlay_dialog.find("form").submit(function (e) {
				      e.preventDefault();
				      self.processInsert(overlay_dialog, Wysiwyg);
                                      overlay_dialog.find("a.close").click();
				      return false;
				   });
			       
                                   $("div#wysiwyg_add_image_overlay div#upload_target").image_upload({
					uploadImagePreviewSize: "medium",
				       complete: function(urls, thumbprint) {
					       overlay_dialog.find("input:submit").removeAttr("disabled");
					   }
				       });
                                    overlay_dialog.find("input:reset").click(function (e) {
                                        overlay_dialog.find("a.close").click();
				    });

				    $(Wysiwyg.editorDoc).trigger("editorRefresh.wysiwyg");
				}
		    });
			
	    },
            processInsert: function (context, Wysiwyg) {
               var url = context.find("div#upload_target").image_upload().getImage();
	       var image_html = "<img src='" + url + "'/>";
	       Wysiwyg.insertHtml(image_html);
	    }
	}



        $.wysiwyg.insertImage = function (object, url, attributes) {
		return object.each(function () {
			var Wysiwyg = $(this).data("wysiwyg"),
				image,
				attribute;

			if (!Wysiwyg) {
				return this;
			}

			if (!url || url.length === 0) {
				return this;
			}

			if ($.browser.msie) {
				Wysiwyg.ui.focus();
			}

			if (attributes) {
				Wysiwyg.editorDoc.execCommand("insertImage", false, "#jwysiwyg#");
				image = Wysiwyg.getElementByAttributeValue("img", "src", "#jwysiwyg#");

				if (image) {
					image.src = url;

					for (attribute in attributes) {
						if (attributes.hasOwnProperty(attribute)) {
							image.setAttribute(attribute, attributes[attribute]);
						}
					}
				}
			} else {
				Wysiwyg.editorDoc.execCommand("insertImage", false, url);
			}

			Wysiwyg.saveContent();

			$(Wysiwyg.editorDoc).trigger("editorRefresh.wysiwyg");

			return this;
		});
	};


	$.roxiware.image_attributes_edit = {

	    conf: {
	        onExit: function () { },
		dialog: '<div class="image_attribute_dialog" style="display:none;position:absolute;">' +
                            '<div id="float_label">Image Float</div>' +
		            '<div id="float"><a id="left">left</a> <a id="none">none</a> <a id="right">right</a></div>' +
		        '</div>',
		sizes: ['xsmall','small','medium','large','xlarge','huge'],
		closeTimeout: 300,
		hoverDelay: 700
		
	    }
	};

        function ImageAttributesEdit(image, wysiwyg, conf)
	{
	    var self=$(this);
	    var Wysiwyg = wysiwyg;
	    $.extend(self,
		     {
			 dialog: null,
			 launch_dialog: function (image) {
			     // bring up dialog over center/bottom of image
			     self.dialog = $(conf.dialog).clone();
			     var size_regex_string = "("+conf.sizes.join("|")+")";

			     var url_regex_string = new RegExp("^\/.*\/[0-9a-f]{32}_"+size_regex_string+".(png|jpg|gif)$");
			     var match = url_regex_string.exec(image.attr("src"));
			     if(match) {
				 var size_div = $("<div id='size'></div>");
				 conf.sizes.forEach(function(size) {
                                     var size_specifier = $("<a id='"+size+"'>"+size+"</a>");
				     size_specifier.click(function(event) {
					     var regexp = new RegExp(size_regex_string);
					     var img_src = image.attr("src").replace(regexp, size);
					     image.attr("src", img_src);
					     self.dialog.find("div#size a").removeAttr("disabled");
					     self.dialog.find("div#size a#"+size).attr("disabled","disabled");
					     Wysiwyg.saveContent();
					     
					 });
				     size_div.append(size_specifier);
				 });
				 self.dialog.append('<div id="size_label">Image Size</div>');
				 self.dialog.append(size_div);
			     }
			     
                             var iframe_id = image.parents("body").attr("id");
			     var iframe = $(window.document).find("iframe#"+iframe_id+"-wysiwyg-iframe");
                             // find the iframe pertaining to this image
                             iframe.after(self.dialog);
			     var set_dialog_position = function() {
				 var doc_x = image.parents("body").scrollLeft();
				 var doc_y = image.parents("body").scrollTop();
				 var image_center = Math.max(0, Math.min(image.offset().left + image.width()/2 - doc_x, iframe.width()));
				 var dialog_bottom = Math.max(0, Math.min(image.offset().top + image.height() - doc_y, iframe.height()));
			     
				 self.dialog.css("top", dialog_bottom+"px");
				 self.dialog.css("left", (image_center-(self.dialog.width()/2))+"px");
			     };
			     set_dialog_position();
			     image.parents("html").parent().scroll(function(e) {
				     set_dialog_position();
				 });

			     self.dialog.find("a#"+image.css("float")).attr("disabled", "disabled");
			     self.dialog.find("a#left, a#none, a#right").click(function() {
				     self.dialog.find("a#"+image.css("float")).removeAttr("disabled");
				     image.css("float", $(this).attr("id"));
			             self.dialog.find("a#"+image.css("float")).attr("disabled", "disabled");
                                     Wysiwyg.saveContent();
				 });
			     if(match) {
				 self.dialog.find("div#size a#"+match[1]).attr("disabled","disabled");
			     }
			     self.dialog.fadeIn();
			     $(image).mouseleave(
				     function(event) {
					// dialog has been launched, so don't close it unless we mouseexit the image or dialog
					// for a period of time
                                        self.imageAttrDialogTimeout = setTimeout( function() {
						self.dialog.fadeOut(function() { self.cleanup(); });
					    },
					    conf.closeTimeout)}).mouseenter(
				     function(event) {
					 clearTimeout(self.imageAttrDialogTimeout);
			             });
			         $(self.dialog).mouseleave(
				     function(event) {
					// dialog has been launched, so don't close it unless we mouseexit the image or dialog
					// for a period of time
                                        self.imageAttrDialogTimeout = setTimeout( function() {
						self.dialog.fadeOut(function() { self.cleanup(); });
					    },
					    conf.closeTimeout)}).mouseenter(
				     function(event) {
					 clearTimeout(self.imageAttrDialogTimeout);
			             });
		         },
			 cleanup: function() {
			     if(self.dialog) {
				 self.dialog.remove();
				 self.dialog = null;
  			     }
			     if(self.imageAttrDialogTimeout) {
				 clearTimeout(self.imageAttrDialogTimeout); 
			     }
			     if(self.imageAttrHoverTimeout) {
				 clearTimeout(self.imageAttrHoverTimeout);
			     }
			     image.parents("html").parent().unbind("scroll");
			     image.unbind("mouseenter");
			     image.unbind("mouseleave");
			     image.mouseenter(function(event) {
				 // on entry into the image, set up a timer to detect
				 // a hover operation.
				 self.imageAttrHoverTimeout =  setTimeout(function() {
				     // if we've hovered long enough, launch the dialog
				     self.launch_dialog(image);
				     // close the timeout
				     if(self.imageAttrHoverTimeout) {
					 clearTimeout(self.imageAttrHoverTimeout);
					 self.imageAttrHoverTimeout = null;
				     }
				 },
			         conf.hoverDelay);
			     }).mouseleave(
	                         function(event) {
				 if(self.imageAttrHoverTimeout) {
				     clearTimeout(self.imageAttrHoverTimeout);
				     self.imageAttrHoverTimeout = null;
				 }
			     });
			 }
		     }
	     );
	    self.cleanup();

	}

        $.fn.image_attributes_edit = function(wysiwyg, conf) {
	    var iae_api = this.data("image_attributes_edit");
	    if(iae_api) { return iae_api; }

	    conf = $.extend(true, {}, $.roxiware.image_attributes_edit.conf, conf);
	    this.each(function () {
		    iae_api = new ImageAttributesEdit($(this), wysiwyg, conf);
		    $(this).data("image_attributes_edit", iae_api);
		});
	    return conf.api?iae_api:this;
	}

})(jQuery);
