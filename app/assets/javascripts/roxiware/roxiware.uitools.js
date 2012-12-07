/* roxiware.uitools.js 
   Various UI tools, including an alert popup dialog,
   a wait spinner,
   and a progress bar control.

   requires jquerytools

   Copyright (c) 2012 Roxiware
*/
(function($) {

    $.roxiware = $.roxiware || {version: '@VERSION'};
    $.roxiware.jstree_param = {
	conf: {
	    description_guid:"",  /* description of the primary param */
	    max_depth:-1,
	    max_children:-1,
	    valid_children:"all",
	    objects: {
		/* objects that can be in this jstree */
		/*
		  "description_guid": {
		     valid_children:"all",
		     max_children:-1,
		     max_depth:-1,
		     children_guid: "bleah",
		     title: "bleah",  'string indicates name of parameter, function generates title, given input of params'
		     icon: "bleah",
		     drop_finish: function(data) {},
		     init_params: {
		        foo:"",
			bar:""
		     }
		  }
		 */
		
	    }
        }
    };

    $.roxiware.alert = {
	conf: {
            alertTemplate: "<div class='overlay alert_popup'></div>",
            alertLineTemplate: "<div class='alert_line'></div>",
	    alertPopupNoticeClass: "alert_popup_notice",
	    alertPopupAlertClass: "alert_popup_alert",
	    alertPopupErrorClass: "alert_popup_error"
	    
	}, 
	popup: null
    }
    $.extend({
	    notice: function(alert_string) {
		if(!$.roxiware.alert.popup) {
		    $.roxiware.alert.popup = new AlertPopup($.roxiware.alert.conf);
		}
		$.roxiware.alert.popup.append(alert_string, $.roxiware.alert.conf.alertPopupNoticeClass);
	    },
	    alert: function(alert_string) {
		if(!$.roxiware.alert.popup) {
		    $.roxiware.alert.popup = new AlertPopup($.roxiware.alert.conf);
		}
		$.roxiware.alert.popup.append(alert_string, $.roxiware.alert.conf.alertPopupAlertClass);
	    },
	    error: function(alert_string) {
		if(!$.roxiware.alert.popup) {
		    $.roxiware.alert.popup = new AlertPopup($.roxiware.alert.conf);
		}
		$.roxiware.alert.popup.append(alert_string, $.roxiware.alert.conf.alertPopupErrorClass);
	    },
	    alertHtml: function(alert_html) {
		if(!$.roxiware.alert.popup) {
		    $.roxiware.alert.popup = new AlertPopup($.roxiware.alert.conf);
		}
		$.roxiware.alert.popup.appendHtml(alert_string);
		
	    }
	}
     );

    // Display an overlay popup for alert/error/notice content.
    function AlertPopup(confStr) {
	var conf = confStr;
	this.alertDialog = $(conf.alertTemplate);
	$("body").append(this.alertDialog);
	this.alertDialog.overlay({
		top: "center",
			      oneInstance: false,
			      load: true,
			      zIndex: 99999,
                              closeOnClick: false,
			      mask: {
			      zIndex: 99998,
				 color: "#222",
				 loadSpeed: 200,
				 opacity: 0.6
			      },
		              onClose: function (event) {
		                  $.roxiware.alert.popup = null;
		                  delete this;
		              }
        });
	this.append = function(alert_string, alert_class) {
	    var alertString = $(conf.alertLineTemplate);
	    alertString.append(alert_string);
	    alertString.addClass(alert_class);
	    this.alertDialog.append(alertString);
	}

	this.appendHtml = function(alertHtml) {
	    this.alertDialog.append(alertHtmlstring);
	}
    };



    $.roxiware.wait = {
	waitInstance: null,
	conf: {
            waitContent: "<div id='wait_content'>&nbsp;</div>",
	    mask: {
		closeOnClick:false,
		closeOnEsc:false,
		color:null,
		maskId: "wait_mask",
		zIndex:99999,
		opacity:0.8
	    }
	}
	
    }

    // Bring up a wait spinner and mask out the rest of the screen

    function Wait(conf) {
	this.waitElement = $(conf.waitContent);
	this.waitElement.css("position", "absolute");
	this.waitElement.css("top", ( $(window).height() - this.waitElement.height() ) / 2+$(window).scrollTop() + "px");
	this.waitElement.css("left", ( $(window).width() - this.waitElement.width() ) / 2+$(window).scrollLeft() + "px");

	$("body").append(this.waitElement);
	this.close = function() {
	    this.waitElement.remove();
	}
    }
    $.extend({
	wait: function() {
		if(!$.roxiware.wait.waitInstance) {
		    $.roxiware.wait.waitInstance = new Wait($.roxiware.wait.conf);
		}
	    },
	resume: function() {
		if($.roxiware.wait.waitInstance) {
		    $.roxiware.wait.waitInstance.close();
		    $.roxiware.wait.waitInstance = null;
		}
	    }});




    $.roxiware.progressbar = {
	instance: null,
	conf: {
            mainContent: "<div id='progress_bar_dialog' class='overlay'><h1>Upload Progress</h1></div>",
            instanceContent: "<div class='progress_bar_instance'><div class='progress_bar'><div class='progress_status'>uploading</div><div class='instance_progress'></div></div><span class='progress_bar_title'></span></div>",
	    mask: {
		closeOnClick:false,
		closeOnEsc:false,
		color:null,
		maskId: "progress_mask",
		zIndex:99999,
		opacity:0.8
	    },
	    progressRemoveTimeout: 2000
	}
	
    }


    // Bring up a wait spinner and mask out the rest of the screen

    function ProgressBar(conf) {
	this.progressBarDialog = $(conf.mainContent);
	this.progressBarDialog.css("position", "absolute");
	$("body").append(this.progressBarDialog);

	this.progressBarDialog.overlay({
		oneInstance:false,
		    top: "10%",
		    load: true,
		    zIndex: 99999,
                    closeOnClick: false,
	            mask: conf.mask
	    });

	this.progressBarDialog.css("top", ( $(window).height() - this.progressBarDialog.height() ) / 2+$(window).scrollTop() + "px");
	this.progressBarDialog.css("left", ( $(window).width() - this.progressBarDialog.width() ) / 2+$(window).scrollLeft() + "px");


	this.updateProgress = function(id, title, progress, status) {
	    var progress_bar_instance = this.progressBarDialog.find("div#progress_bar_"+id);
	    if(progress_bar_instance.length == 0) {
		progress_bar_instance = $(conf.instanceContent);
		progress_bar_instance.attr("id", "progress_bar_"+id);
		this.progressBarDialog.append(progress_bar_instance);
	    }
	    progress_bar_instance.find("span.progress_bar_title").text(title);
	    if(status) {
		progress_bar_instance.find("div.progress_status").text(status);
	    }
	    progress_bar_instance.find("div.instance_progress").css("width", progress+"%");
	    if(progress == 100) {
		setTimeout(function(event) {
			progress_bar_instance.slideUp();
		    }, conf.progressRemoveTimeout);
	    }
	}

	this.finished = function(id) {
	    this.progressBarDialog.find("div#progress_bar_"+id).remove();
	}
	
	this.close = function() {
	    this.progressBarDialog.find("a.close").click();
	}
    }
    $.extend({
	progressbar: function() {
		if(!$.roxiware.progressbar.instance) {
		    $.roxiware.progressbar.instance = new ProgressBar($.roxiware.progressbar.conf);
		}
	        return $.roxiware.progressbar.instance;
	    }
	});

    $.roxiware.context_menu = {
	conf: {
	    onConfig: function(menu_obj) { }
	}
    }

    function ContextMenu(target, menu, conf) {
	var self = this;
	   $.extend(self,
		    {
			context_menu: "",
                        instance_menu: "",
			addInstanceMenus: function(menu_items) {
			    self.instance_menu = self.instance_menu + menu_items;
			},
			buildMenu: function(trigger) {
			    // get the parent menu
			    var parent = $(trigger).parents(".context_menu_client").first();
			    var menu = null;
			    if(parent.context_menu()) {
				menu = parent.context_menu().buildMenu(parent);
				menu.prepend("<hr/>");
			        $(self.context_menu).find("li").clone().prependTo(menu);
			    }
			    else {
				menu = $(self.context_menu).clone();
			    }
			    menu.prepend(self.instance_menu);
			    return menu;
			},
			setMenu: function(menu) {
			    // get the parent menu
			    self.context_menu = menu;
			    conf.onConfig(self);
			},
			onConfig: function(func) {self.onConfig = func;}
		    });
	   if(menu) self.setMenu(menu);
	   target.addClass("context_menu_client");
	   target.bind("contextmenu", function(e) {
	     e.preventDefault();
	     $(".live_context_menu").remove();
	     var current_menu = self.buildMenu($(this));
	     current_menu.addClass("live_context_menu");
	     $("body").append(current_menu);
	     current_menu.css("position", "fixed").css("display", "block").offset({left:e.clientX-5, top:e.clientY-5});
	     current_menu.find("li a").click(function(event) {
		var menu_item = $(this).attr("menu_item");
		target.trigger("context_menu", [menu_item, e]);
	      });
	     
	     $(document).on("click.contextMenu keyup.contextMenu contextmenu.contextMenu", function(event) {
		if (event.type == "keyup" && (event.which != 27)) return;
		if (current_menu) {
		    current_menu.remove();
		    current_menu = null;
		    $("document").off("click.contextMenu keyup.contextMenu contextmenu.contextMenu");
		}
		 });
	     return false;
	   });
    }
    $.fn.context_menu = function(menu, conf) {
	      conf = $.extend(true, {}, $.roxiware.context_menu.conf, conf);
	      var cm_api = null;
	      this.each(function() {
		      cm_api = $(this).data("context_menu");
		      if(!cm_api) {
		         cm_api = new ContextMenu($(this), menu, conf);
		         $(this).data("context_menu", cm_api);
		      }
		      else {
			  if(menu) {
			      cm_api.setMenu(menu);
			  }
		      }
			  
		  });
	      return  cm_api;
    };

    $.fn.autoGrowInput = function(o) {

        o = $.extend({
		maxWidth: 1000,
		minWidth: 30,
		comfortZone: 30
	    }, o);

        this.filter('input:text').each(function(){

		var minWidth = o.minWidth || $(this).width(),
		    val = '',
		    input = $(this),
		    testSubject = $('<tester/>').css({
			    position: 'absolute',
			    top: -9999,
			    left: -9999,
			    width: 'auto',
			    fontSize: input.css('fontSize'),
			    fontFamily: input.css('fontFamily'),
			    fontWeight: input.css('fontWeight'),
			    letterSpacing: input.css('letterSpacing'),
			    whiteSpace: 'nowrap'
			}),
		    check = function() {

                    if (val === (val = input.val())) {return;}

                    // Enter new content into testSubject
                    var escaped = val.replace(/&/g, '&amp;').replace(/\s/g,'&nbsp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
                    testSubject.html(escaped);

                    // Calculate new width + whether to change
                    var testerWidth = testSubject.width(),
		    newWidth = (testerWidth + o.comfortZone) >= minWidth ? testerWidth + o.comfortZone : minWidth,
		    currentWidth = input.width(),
		    isValidWidthChange = (newWidth < currentWidth && newWidth >= minWidth)
		    || (newWidth > minWidth && newWidth < o.maxWidth);

                    // Animate width
                    if (isValidWidthChange) {
                        input.width(newWidth);
                    }

                };

		testSubject.insertAfter(input);

		$(this).bind('keyup keydown blur update', check);

	    });

        return this;

    };


    function JSTreeParam(jstree, init_data, conf) {
	var self = this;
	$.extend(self, {
		new_node: function(obj_type, target, position, params) {
		    if (!position) {
			position="after";
		    }
		    var currently_selected = target;
			if(!currently_selected) {
			    currently_selected = $(jstree).jstree("get_selected");
			}
			if(!currently_selected) {
			    currently_selected = -1;
			}
			var title = "";
			var init_object = conf.objects[obj_type];
			var init_params = init_object.init_params;
			$.extend(init_params, params);
			if($.isFunction(init_object.title)) {
			    title = init_object.title(init_params);
			}
			else {
			    title = init_params[init_object.title].value;
			}
			// jstree 'types' create_node doesn't set the icon based on type automatically, so we need to pass it in
			var js_init_params = {icon:init_object.icon, data:{title:title}};
			$(jstree).jstree("create_node", currently_selected, position, js_init_params, function(new_node) {
				new_node.attr("rel", obj_type);
				new_node.data().params = init_params;
				$(jstree).jstree("deselect_all");
				$(jstree).jstree("select_node", new_node);
                                if($.isFunction(init_object.onNew)) {
				    init_object.onNew(new_node);
				}
				new_node.bind("data_changed.jstree_param", function() {
				    var object_info = conf.objects[$(this).attr("rel")];
				    if($.isFunction(object_info.title)) {
					title = object_info.title($(this).data());
				    }
				    else {
					title = $(this).data().params[object_info.title].value;
				    }
				    $(jstree).jstree("set_text", $(this), title);
				    });
			    });
		    },
		    export_xml: function(param_name) {
			var export_jstree_node = function(node_name, node) {
			    var export_params = function(params) {
				var xml_result = ""
				for(var param_name in params) {
				    xml_result = xml_result + "<param class='local' name='"+param_name+"'>" +
				       "<param_description guid='"+params[param_name].guid+"'/>" +
				       "<value>" + params[param_name].value+"</value>" +
				       "</param>";
				}
				return xml_result;
			    }
			    var object_info = conf.objects[node.attr("rel")];

			    var xml_result = "<param class='local' name='" + node_name + "'>" +
			    "<param_description guid='"+node.attr("rel")+"'/>" + 
				     "<value>" +
					  export_params(node.data().params);
			    var children = node.find("> ul > li");

			    if (object_info.children_guid && (children.length > 0)) {
				xml_result = xml_result + "<param class='local' name='children'>" +
				    "<param_description guid='"+object_info.children_guid+"'/><value>";
				children.each(function(index, child_node){
					xml_result = xml_result + export_jstree_node(node_name+"_"+index, $(child_node));
				    });
				xml_result = xml_result + "</value></param>";
			    }
			    xml_result = xml_result +  "</value></param>";
			    return xml_result;
			};


			var xml_result = "<param name='"+param_name+"' class='local'>" +
			    "<param_description guid='"+conf.description_guid+"'/>" + 
			    "<value>";
			$(jstree).find("> ul > li").each(function(index, node) {
				xml_result = xml_result + export_jstree_node("child_"+index, $(node), $(jstree));
			    });
			xml_result = xml_result + "</value></param>";
			return xml_result;
		    }
		});
	    /* scrub through init data, preparing it for jstree */
	    var scrubInitData = function(jstree_data) {
	       var result = [];
	       var scrub_init_data_item = function(jstree_data) {
		   var init_object = conf.objects[jstree_data["description_guid"]];
		   var result = { "data": { }};
		   if($.isFunction(init_object.title)) {
		       result["data"]["title"] = init_object.title(jstree_data.params);
		   }
		   else {
		       result["data"]["title"] = jstree_data.params[init_object.title].value;
		   }
		   if(init_object.icon) {
		       result["data"]["icon"] = init_object.icon;
		   }
		   result["metadata"] = {"params" : jstree_data.params}
		   result["attr"] = {"rel":jstree_data["description_guid"]};
		   if(jstree_data.children) {
		       result["children"] = [];
		       for (var child_index in jstree_data.children) {
			   result["children"].push(scrub_init_data_item(jstree_data.children[child_index]));
		       }
		   }
		   return result;
	       }
	       for (var child_index in init_data) {
		   result.push(scrub_init_data_item(init_data[child_index]));
	       }
	       return result;

	    }
	    var valid_objs = {
	    default: {
		    valid_children : "none"
	    }
	    };
	    for (obj_type in conf.objects) {
		valid_objs[obj_type] = {
		    valid_children : conf.objects[obj_type].valid_children,
		    max_children : conf.objects[obj_type].max_children,
		    max_depth : conf.objects[obj_type].max_depth,
		    icon : conf.objects[obj_type].icon
		};
	    }

     var can_drop = function(dragee, target) {
	  var valid_children = "none";
	  var drop_target_obj = conf.objects[target.attr("rel")];
	  if ($(jstree).is(target)) {
	     valid_children = conf.valid_children;
	  } else if(drop_target_obj) {
	     valid_children = drop_target_obj.valid_children;
	  }
	  return ((valid_children == "all") || 
		  ($.isArray(valid_children) && ($.inArray(dragee.attr("rel"), valid_children) >= 0)));
      }
      $(jstree).jstree({
          "core" : {"html_titles" : true, "animation":200},
	  "types" : { 
		      "max_depth":conf.max_depth, 
		      "valid_children":conf.valid_children, 
		      "max_children":conf.max_depth,
		      "types":conf.objects
		     },
	  "json_data" : { "data" : scrubInitData(init_data) },
          "dnd" : {
		  "drag_check" : function(data) {
		      if (!$(data.o).attr("rel")) {
			  
			  return {after:false, before:false, inside:false};
		      }
		      var parent = jQuery.jstree._reference($(jstree))._get_parent($(data.r));
		      if((!parent) || (parent == -1)) {
			  parent = $(jstree);
		      }
		      var next_to = can_drop($(data.o), parent);
		      return { after:next_to, before:next_to, inside:can_drop($(data.o), $(data.r))}
		  },
		  "drag_finish" : function(data) {
		      var parent = jQuery.jstree._reference($(jstree))._get_parent($(data.r));
		      if((!parent) || (parent == -1)) {
			  parent = $(jstree);
		      }
		      if(can_drop($(data.o), parent)) {
			  var drop_target_obj = conf.objects[$(data.o).attr("rel")];
			  if(drop_target_obj && drop_target_obj.drop) {
			      return drop_target_obj.drop(data);
			  }
		      }
		      return false;
		  }
	  },
          "themes" : {"no_load" : true, url:"/assets/themes/apple/style.css", theme:"apple", "icons":true, "dots":true},
          "ui" : { "initially_select":$(jstree).find("li:first").attr("id")},
          "hotkeys" : { "backspace" : function(e) {
                           e.preventDefault(); 
                           this.remove();
                          }, 
                        "down" : function(e) {
                                var o = this.data.ui.last_selected || -1;
                                var n = this._get_next(o);
                                if (n.length > 0) {
				   this.deselect_all();
				   this.select_node(n);
                                }
                                return false; 
                        },
                        "up" : function(e) {
                                var o = this.data.ui.last_selected || -1;
                                var n = this._get_prev(o);
                                if (n.length > 0) {
                                   this.deselect_all();
                                   this.select_node(n);
                                }
                                return false; 
                         },
                        "space" : false, "ctrl+up" : false, "ctrl+down" : false, "shift+up" : false, "shift+down" : false,
                        "shift-space" : false, "ctrl+space" : false, "f2" : false, "del" : false,
                        "left" : function(e) {
                                var o = this.data.ui.last_selected;
                                if(o) {
                                   if(!o.hasClass("jstree-open")) { 
                                      var n = this._get_prev(o);
                                      if (n.length > 0) {
                                        this.deselect_all();
                                        this.select_node(n); 
                                      }
                                   }
                                }
                                return false; 
                           },
                        "right" : function(e) {
                                var o = this.data.ui.last_selected;
                                if(o && o.length) {
                                        if(o.hasClass("jstree-closed")) { this.open_node(o); }
                                        else if(o.hasClass("jstree-open")){ 
                                          var n = this._get_next(o);
                                          if (n.length > 0) {
                                             this.deselect_all();
                                             this.select_node(n); 
                                          }
                                        }
                                }
                                return false; 
                           },
                        "ctrl+left" : false, "ctrl+right" : false, "shift+left" : false, "shift+right" : false
          },
	      "plugins" : ["themes", "json_data", "ui", "dnd","crrm","hotkeys","types"]
      });
      $(jstree).bind("loaded.jstree", function(event, data) {
	      $(jstree).jstree("open_all");
	      $(jstree).jstree("select_node","li:first");
	      $(jstree).find("li").bind("data_changed.jstree_param", function() {
		    var object_info = conf.objects[$(this).attr("rel")];
		    if($.isFunction(object_info.title)) {
			title = object_info.title($(this).data());
		    }
		    else {
			title = $(this).data().params[object_info.title].value;
		    }
		    $(jstree).jstree("set_text", $(this), title);
		  });
	  });

    }

    $.fn.jstree_param =  function(init_data, conf) {
	conf = $.extend(true, {}, $.roxiware.jstree_param.conf, conf);
	var jtp_api = null;
	this.each(function() {
		jtp_api = $(this).data("jstree_param");
		if(!jtp_api) {
		    jtp_api = new JSTreeParam($(this), init_data, conf);
		    $(this).data("jstree_param", jtp_api);
		}
	    });
	return  jtp_api;
    }

})(jQuery);

function settingsForm(url)
{
   var overlay = $("<div id='edit_overlay' class='settings overlay'><div class='contentWrap'> </div></div>");
   $("body").append(overlay);
   overlay.find(".contentWrap").load(url, function(responseText, textStatus, xhr) {
      if(xhr.status != 200) {
	  $.error(xhr.statusText);
	  return;
      }
      overlay.overlay({
		top: "center",
                oneInstance: false,
		load: true,
		zIndex: 2000,
                closeOnClick: false,
		mask: {
		     zIndex: 1999,
		     color: "#222",
	             loadSpeed: 200,
		     opacity: 0.6
		      },
		 onClose: function (event) {
		         $.roxiware.alert.popup = null;
		         overlay.remove();
	         }
	  });
      overlay.find(".contentWrap [title]").tooltip({
	  predelay:1000,
	  effect:'fade',
	  position: "top right",
	  offset: [10, -20]
	});
   });
}


function colorToHex(color) {
    if (color.substr(0, 1) === '#') {
	   return color;
    }
    var digits = /(.*?)rgb\((\d+), (\d+), (\d+)\)/.exec(color);
    
    var red = parseInt(digits[2]);
    var green = parseInt(digits[3]);
    var blue = parseInt(digits[4]);
    
    var rgb = blue | (green << 8) | (red << 16);
    return digits[1] + '#' + rgb.toString(16);
};



function imageDialog(conf)
{
    var default_options = {
	raw_upload: false
    };
   var options = $.extend(true, {}, default_options, conf);
   
   var overlay_dialog = $('<div class="overlay" id="wysiwyg_add_image_overlay">' +
		      '<form class="wysiwyg">' +
		      '<div id="upload_target" class="upload_target">' +
		       '</div>' + 
			 '<input id="image_source_upload" name="image_source" type="radio" value="upload" checked>Upload Image</input>' +
			 '<br style="clear:both"/>' +
			 '<input id="image_source_url" name="image_source" type="radio" value="url">URL</input>' +
			   '<input name="image_text_url" type="text" disabled/>' +
			 '<br/><br/><input type="submit" class="button" value="Save" disabled/>' +
		      '</form>' +
			  '</div>');

   $("body").append(overlay_dialog);
   overlay_dialog.find("input:radio[name=image_source]").change(function() {
      var new_image_url;
      var image_type = overlay_dialog.find("input:radio[name=image_source]:checked").val();
      if(image_type == "url") {
	    // set the preview image to the image specified in the image_url input
	    new_image_url = overlay_dialog.find("input[name=image_text_url]").val();
	    self.old_image = overlay_dialog.find("div#upload_target").image_upload().getImage();
	    self.old_thumbprint = overlay_dialog.find("div#upload_target").image_upload().getThumbprint();
	    overlay_dialog.find("div#upload_target").image_upload().setImage(new_image_url);
	    overlay_dialog.find("div#upload_target").image_upload().setThumbprint(null);
	    overlay_dialog.find("div#upload_target").image_upload().disable();
	    overlay_dialog.find("input[name=image_text_url]").removeAttr("disabled");
      }
      else if (image_type == "upload") {
	  new_image_url = self.old_image;
	  overlay_dialog.find("div#upload_target").image_upload().setImage(self.old_image);
	  overlay_dialog.find("div#upload_target").image_upload().setThumbprint(self.old_thumbprint);
	  overlay_dialog.find("div#upload_target").image_upload().enable();
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
	 opacity: 0.6,
	    zIndex:2999
	 },
	 closeOnClick: true,
	 load:true,
	 onClose: function() {
	    overlay_dialog.remove();
	 },
	 onBeforeLoad: function () {
	    overlay_dialog.find("form").submit(function (e) {
	       e.preventDefault();
	       var image_type = overlay_dialog.find("input:radio[name=image_source]:checked").val();
	       if(image_type == "url") {
		   options.onSuccess(overlay_dialog.find("input[name=image_text_url]").val(), image_type, null);
	       }
               else if (image_type == "upload") {
		   
		   options.onSuccess(overlay_dialog.find("div#upload_target").image_upload().getImage(), image_type, null);
	       }
	       overlay_dialog.overlay().close();
	       return false;
	     });
	    
	    var default_upload_params = {
		  uploadImagePreviewSize: "raw",
		  complete: function(urls) {
			  overlay_dialog.find("input:submit").removeAttr("disabled");
		      }
	    };
	    
	    var image_upload_conf = $.extend(true, {}, default_upload_params, options.uploadConf);
	    if(options.raw_upload) {
		image_upload_conf = $.extend(true, {}, image_upload_conf, {uploadImageParams: { unprocessed_raw:true}});
	    }

	    $("div#wysiwyg_add_image_overlay div#upload_target").image_upload(image_upload_conf);
	   }
       }
   );
}


$(document).bind("ready", function() {
	$(document).bind("ajaxStart", function(event) {
		$.wait();
	    });
	$(document).bind("ajaxStop", function(event) {
		$.resume();
	    });
    });