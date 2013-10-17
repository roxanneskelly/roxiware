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

		var params = {};
		settingsForm("/asset/edit?"+jQuery.param(params), "Choose Image", {
		    success: function(image_url) {
	                Wysiwyg.insertHtml("<img src='" + image_url+"'/>");
			$(Wysiwyg.editorDoc).trigger("editorRefresh.wysiwyg");
		    }
		});
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
		dialog: '<div class="image_attribute_dialog settings_dialog" style="display:none;position:absolute;">' +
                            '<div id="float_label">Image Float</div>' +
		            '<div id="float"><a id="left">left</a> <a id="none">none</a> <a id="right">right</a></div>' +
		        '</div>',
		closeTimeout: 30000,
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
			     // bring up dialog over center of image
			     self.dialog = $(conf.dialog).clone();

			     var set_dialog_position = function() {
				 var doc_x = image.parents("body").scrollLeft();
				 var doc_y = image.parents("body").scrollTop();
				 var image_horz_center = Math.max(0, Math.min(image.offset().left + image.width()/2 - doc_x, iframe.width()));
				 var dialog_bottom = Math.max(0, Math.min(image.offset().top + image.height()/2 - doc_y, iframe.height()));
			     
				 self.dialog.css("top", dialog_bottom+"px");
				 self.dialog.css("left", (image_horz_center-(self.dialog.width()/2))+"px");
			     };
			     var url_regex_string = new RegExp("^\/assets/uploads/[0-9a-f]{32}_"+size_regex_string+".(png|jpg|gif|jpeg)$");
			     var match = url_regex_string.exec(image.attr("src"));
			     
                             var iframe_id = image.parents("body").attr("id");
			     var iframe = $(window.document).find("iframe#"+iframe_id+"-wysiwyg-iframe");
                             // find the iframe pertaining to this image
                             iframe.after(self.dialog);
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
				     self.cleanup();
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
			 }
		     }
	     );
	    console.log(image);
	    $(image).load(function() {
		    // wrap image in a div with same style
		    //var resize_wrapper = $(this).wrap("<div class='wysiwyg_image_wrapper'></div>");
		    //resize_wrapper.css("display",$(this).css("inline"));
		    $(this).css("position", "relative");
		    $(this).resizable({handles:"all", zIndex:2004});
		});
	    console.log("set resize");
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
