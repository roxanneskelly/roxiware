/* roxiware.uitools.js
   Various UI tools, including an alert popup dialog,
   a wait spinner,
   and a progress bar control.

   requires jquerytools

   Copyright (c) 2012 Roxiware
*/
(function($) {
    $.roxiware = $.roxiware || {version: '@VERSION'};
    $.roxiware.main_css = "/assets/application.css";
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

    $.roxiware.ajaxSetParamsXML = {
	conf: {
	    method:"PUT",
	    success:function() {},
	       error:function() {}
	}
    }
    $.roxiware.ajaxSetParamsJSON = {
	conf: {
	       method:"PUT",
	       fieldPrefix:"",
	       success:function() {},
	       error:function() {}
	}
    }


    $.extend({
	    ajaxSetParamsXML: function(url, data, conf_params) {
		var conf = $.extend({}, $.roxiware.ajaxSetParamsXML.conf, conf_params);
		var endpoint = url;
		if (conf.additionalData) {
		    endpoint = endpoint + "?" + jQuery.param(conf.additionalData);
		}
		if(conf.form) {
		    conf.form.find("input").removeClass("field-error");
                }

		$.ajax({
			type:conf.method,
			url: endpoint,
			processData: false,
			dataType: "xml",
		        contentType: "application/xml",
			data: data,
			error: function(xhr, textStatus, errorThrown) {
			    if(xhr.status == 0) {
    			        $.error("The server is not available.  Please try again.");
			    }
			    else {
				$.error(errorThrown);
			    }
			    conf.error(errorThrown);
			},
			complete: function() {
			},
			success: function(data) {
			    if($(data).find("error").length > 0) {
				    $(data).find("error").each(function(index, value) {
					    $.error($(value).find("parameter").text()+": "+$(value).find("message").text());
					if(conf.form) {
					    conf.form.find("input#"+$(value).find("parameter").text()).css("background", "#ffcccc");
					}
				    });
				    conf.error(data.error);
			    }
			    else {
				if(conf.success) {
				    conf.success();
				}
			    }
			}
		    });
	    },
	    ajaxSetParamsJSON: function(url, data, conf_params) {
                console.log(url);
		var conf = $.extend({}, $.roxiware.ajaxSetParamsJSON.conf, conf_params);
		if(conf.form) {
		    conf.form.find("input").removeClass("field-error");
                }
		$.ajax({
			type:conf.method,
			url: url,
			processData: true,
			data: data,
			error: function(xhr, textStatus, errorThrown) {
			    if(xhr.status == 0) {
    			        $.error("The server is not available.  Please try again.");
			    }
			    else {
				$.error(errorThrown);
			    }
			    conf.error(errorThrown);
			},
			complete: function() {
			},
			success: function(data) {
			    if(data["error"]) {
				$(data["error"]).each(function(index, value) {
				    $.error(value[1]);
				    if(conf.form) {
				        conf.form.find("input#"+conf.fieldPrefix+value[0]).addClass("field-error");
				    }
				});
				conf.error(data.error, data);
			    }
			    else {
				conf.success(data);
			    }
			}
		    });
	    }
    });
    $.roxiware.alert = {
	conf: {
            alertTemplate: "<div class='settings settings_dialog settings_alert'><a class='close icon-cancel-circle'></a><div class='settings_title'>&nbsp;</div><div class='alert_content'></div><div class='alert_buttons'><button id='alert_yes' style='display:none'>Yes</button><button id='alert_no' style='display:none'>No</button><button id='alert_cancel' style='display:none'>Cancel</button></div></div>",
	    alertPopupNoticeClass: "alert_notice",
	    alertPopupAlertClass: "alert_alert",
	    alertPopupErrorClass: "alert_error",
            alertPopupWaitClass: "alert_wait"
	},
	popup: null
    }
    $.extend({
        notice: function(alert_string, conf) {
            if(!$.roxiware.alert.popup) {
                $.roxiware.alert.popup = new AlertPopup("Notice", $.extend(true, {iconClass:"icon-info"}, $.roxiware.alert.conf, conf));
            }
            $.roxiware.alert.popup.append(alert_string, $.roxiware.alert.conf.alertPopupNoticeClass);
        },
        alert: function(alert_string, conf) {
            if(!$.roxiware.alert.popup) {
                $.roxiware.alert.popup = new AlertPopup("Alert", $.extend(true, {iconClass:"icon-notification"}, $.roxiware.alert.conf, conf));
            }
            $.roxiware.alert.popup.append(alert_string, $.roxiware.alert.conf.alertPopupAlertClass);
        },
        error: function(alert_string, conf) {
            if(!$.roxiware.alert.popup) {
                $.roxiware.alert.popup = new AlertPopup("Error", $.extend(true, {iconClass:"icon-warning"}, $.roxiware.alert.conf, conf));
            }
            $.roxiware.alert.popup.append(alert_string, $.roxiware.alert.conf.alertPopupErrorClass);
        },
        alertWait: function(alert_string, conf) {
            if(!$.roxiware.alert.popup) {
                $.roxiware.alert.popup = new AlertPopup("Please Wait", $.extend(true, {iconClass:"icon-spinner-2"}, $.roxiware.alert.conf, conf));
            }
            $.roxiware.alert.popup.append(alert_string, $.roxiware.alert.conf.alertPopupWaitClass);
        },
        alertResume: function() {
            if($.roxiware.alert.popup) {
                $.roxiware.alert.popup.close();
            }
        },
        alertHtml: function(alert_html, conf) {
            if(!$.roxiware.alert.popup) {
                $.roxiware.alert.popup = new AlertPopup("", $.extend(true, {}, $.roxiware.alert.conf, conf));
            }
            $.roxiware.alert.popup.appendHtml(alert_string);
        }
        });

    // Display an overlay popup for alert/error/notice content.
    function AlertPopup(alert_type, conf) {
	this.alertDialog = $(conf.alertTemplate);
        var alert_popup = this.alertDialog;
	this.alertDialog.find("button").button();
	$("body").append(this.alertDialog);
	this.alertDialog.find("div.settings_title").html("<div class='alert-icon " + conf.iconClass + "'></div>&nbsp;" + alert_type);
	if(conf.onYes) {
	    this.alertDialog.find("button#alert_yes").css("display","inline-block").click(function() {
		alert_popup.find(".close").click();
	        conf.onYes();
	    });
        }
	if(conf.onNo) {
	    this.alertDialog.find("button#alert_no").css("display","inline-block").click(function() {
		alert_popup.find(".close").click();
	        conf.onNo();
	    });
        }
	if(conf.onCancel) {
	    this.alertDialog.find("button#alert_cancel").css("display","inline-block").click(function() {
		alert_popup.find(".close").click();
	        conf.onCancel();
	    });
        }
	$.resume();
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
		if(conf.onClose) {
		    conf.onClose();
                }
	    }
        });
	this.append = function(alert_string, alert_class) {
	    this.alertDialog.find(".alert_content").append("<div class='"+alert_class+"'>"+alert_string+'</div>');
	}

	this.appendHtml = function(alertHtml) {
	    this.alertDialog.find(".alert_content").append(alertHtmlstring);
	}
	this.close = function() {
	    this.alertDialog.data("overlay").close();
	}
    };



    $.roxiware.wait = {
	waitInstance: null,
	conf: {
            waitContent: "<div class='wait-icon spinner-icon'></div>",
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
	    wait: function(conf) {
		if((!$.roxiware.wait.waitInstance) && (!$.roxiware.alert.popup)) {
		    $.roxiware.wait.waitInstance = new Wait($.extend({}, $.roxiware.wait.conf, conf));
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
            mainContent: "<div id='progress_bar_dialog' class='overlay'><a class='close icon-cancel-circle'></a><div class='settings_title'>Upload Progress</div></div>",
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
	    this.progressBarDialog.find("div#progressbar_"+id).remove();
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


    $.roxiware.selectable_table = {
        conf: {
	    multi:false,
	    selectClass:"table_select",
	    onSelect:function(selected_items) {
	    }
        }
    }
    function SelectableTable(target, conf) {
	var self=this;

	$.extend(self, {
		anchor:null,
		select:function(row) {
		    $(row).addClass(conf.selectClass);
		    conf.onSelect(self.getSelected());
		},
                deselect: function(row) {
		    $(row).removeClass(conf.selectClass);
		    conf.onSelect(self.getSelected());
		},
                toggle: function(row) {
		    $(row).toggleClass(conf.selectClass);
		    conf.onSelect(self.getSelected());
		},
	        clearAll: function() {
		    $(target).find("tr").removeClass(conf.selectClass);
		    conf.onSelect(self.getSelected());
                },
	        selectAll: function() {
		    $(target).find("tr").addClass(conf.selectClass);
		    conf.onSelect(self.getSelected());
                },
		setAnchor: function(row) {
		    self.anchor = row;
		},
		clearAnchor: function() {
		    self.anchor = null;
		},
		getAnchor: function() {
		    return self.anchor;
		},
	        getSelected: function() {
		    return $(target).find("."+conf.selectClass);
		}
	    }
	    );

	$(target).find("tr").click(function(event) {
	    if(event.shiftKey && conf.multi && self.anchor) {
		// select all between current and anchor
		self.deselect(self.getSelected().not($(this)));
		var first = self.anchor;
		var last = $(this);
	        if (first.index() > last.index()) {
		    first = $(this);
		    last = self.anchor;
		}
		self.select(first.nextUntil(last).andSelf().add(last));
	    }
	    else if (event.metaKey && conf.multi) {
		self.setAnchor($(this));
		self.toggle($(this));
	    }
	    else if (!event.ctrlKey){
		self.getSelected().not($(this)).removeClass(conf.selectClass);
		self.toggle($(this));
		if (conf.multi) {
		    self.setAnchor($(this));
		}
	    }
	});
    }

    $.fn.selectable_table = function(tab_conf) {
	var cm_api = null;
	this.each(function() {
		cm_api = $(this).data("selectable_table");
		if(!cm_api) {
		    var conf = $.extend(true, {}, $.roxiware.selectable_table.conf, tab_conf);
		    cm_api = new SelectableTable($(this), conf);
		    $(this).data("selectable_table", cm_api);
		}
	    });
      return  cm_api;
    };


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
			instance_menu: $("<ul></ul>"),
			addInstanceMenus: function(menu_items) {
			    self.instance_menu.append($(menu_items));
			},
			removeInstanceMenus: function(menu_items) {
			    self.instance_menu.find(menu_items).remove();
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
			    menu.prepend(self.instance_menu.html());
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
    $.fn.context_menu = function(menu_or_api, conf_or_data) {
	      var cm_api = null;
	      this.each(function() {
		      cm_api = $(this).data("context_menu");
		      if(!cm_api) {
	                 var conf = $.extend(true, {}, $.roxiware.context_menu.conf, conf_or_data);
		         cm_api = new ContextMenu($(this), menu_or_api, conf);
		         $(this).data("context_menu", cm_api);
		      }
		      else {
			  if(menu_or_api == "add_instance_menus") {
			      cm_api.addInstanceMenus(conf_or_data);
		          }
			  else if(menu_or_api == "remove_instance_menus") {
			       cm_api.removeInstanceMenus(conf_or_data);
		          }
			  else if (menu_or_api != null) {
			      cm_api.setMenu(menu_or_api);
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
                reload: function(data) {
		    jQuery.jstree._reference($(jstree)).delete_node($(jstree).find("> ul > li"));

		    var update_tree = function(node, data) {
			$.each(data, function(index, value) {
			    self.new_node(value.description_guid,
					  node, "inside", value.params,
					  function(new_node) {
					      if(value.children) {
						  update_tree(new_node, value.children);
					      }
					  });
			    });
		    }
		    update_tree(-1, data);
	     },
	    new_node: function(obj_type, target, position, params, callback) {
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
			var init_params = {};

			$.extend(init_params, init_object.init_params, params);
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
                                if($.isFunction(init_object.onNew)) {
				    init_object.onNew(new_node);
				}
				if(callback) {
				    callback(new_node);
				}
				$(jstree).jstree("select_node", new_node);
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

				var params_xml_result = ""
				for(var param_name in params) {
				    params_xml_result = params_xml_result + "<param class='local' name='"+param_name+"' description='"+params[param_name].guid+"'>" +
				    xmlEscape(params[param_name].value)+"</param>";
				}
				return params_xml_result;
			    }
			    var object_info = conf.objects[node.attr("rel")];

			    var node_xml_result = "<param class='local' name='" + node_name + "' description='"+node.attr("rel")+"'>" +
			    export_params(node.data().params);
			    var children = node.find("> ul > li");

			    if (object_info.children_guid && (children.length > 0)) {
				node_xml_result = node_xml_result + "<param class='local' name='children' description='"+object_info.children_guid+"'>";
				children.each(function(index, child_node){
					node_xml_result = node_xml_result + export_jstree_node(node_name+"_"+index, $(child_node));
				    });
				node_xml_result = node_xml_result + "</param>";
			    }
			    node_xml_result = node_xml_result + "</param>";
			    return node_xml_result;
			};


			var xml_result = "<param name='"+param_name+"' class='local' description='"+conf.description_guid+"'>";
			$(jstree).find("> ul > li").each(function(index, node) {
				xml_result = xml_result + export_jstree_node("child_"+index, $(node), $(jstree));
			    });
			xml_result = xml_result + "</param>";
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
	       for (var child_index in jstree_data) {
		   result.push(scrub_init_data_item(jstree_data[child_index]));
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
	      "plugins" : ["themes", "json_data", "ui", "dnd","crrm","types"]
      });
      $(jstree).bind("loaded.jstree", function(event, data) {
	      $(jstree).jstree("open_all");
	      $(jstree).jstree("select_node","li:first");
	      $(jstree).bind("select_node.jstree", function(event, data) {
		      $(jstree).focus();
		  });
	      $(jstree).jstree("disable_hotkeys");
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
      $(jstree).focus(function() {
	      $(jstree).parent().css("outline", "dotted 1px #777");
	      $(jstree).jstree("enable_hotkeys");
	  });
      $(jstree).blur(function() {
	      $(jstree).parent().css("outline", "none");
	      $(jstree).jstree("disable_hotkeys");
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

    $.fn.watermark =  function() {
	this.each(function() {
		if(($(this).val() == "") || ($(this).val() == $(this).attr("watermark"))) {
                $(this).val($(this).attr("watermark"));
                $(this).addClass("watermark");
             }

	     $(this).blur(function(){
		if ($(this).val().length == 0)
		    $(this).val($(this).attr("watermark")).addClass("watermark");
	      }).focus(function() {
		if ($(this).hasClass("watermark")) {
		   $(this).val('').removeClass("watermark");
		}
	      }).change(function() {
		      if(!$(this).is(":focus")) {
			  if($(this).val().length > 0) {
			      if($(this).hasClass("watermark")) {
				  $(this).removeClass("watermark");
			      }
			  }
			  else {
			      $(this).addClass("watermark").val($(this).attr("watermark"));
			  }
                      }
	      });
	});

	var self = this;
	$("form").submit(function() {
	    self.each(function() {if($(this).hasClass("watermark")) {$(this).val(""); }});
	});
    }
})(jQuery);

function settingsForm(source, title, options) {
    var conf = $.extend({}, options);
    title = typeof title  != 'undefined' ? title : "&nbsp;";
    var overlay = $("<div id='edit_overlay' class='settings settings_dialog settings_form' style='z-index:2000'><a class='close icon-cancel-circle'></a>");


    if(title.length > 0) {
        overlay.append("<div class='settings_title'>"+title+"</div>");
    }
    overlay.append("<div class='contentWrap'> </div></div>");
    if(title.length == 0) {
        overlay.find(".contentWrap").css("top", "2em");
    }

    var instantiateOverlay = function() {
        var top = "5%";
        var fixed=true;
        var source = overlay.find(".contentWrap > div");
        source.data("settings_form", conf);
        if(source.is(".huge_form")) { 
            top="0%";
            overlay.addClass("huge_settings_form"); 
        }
        if(source.is(".large_form")) { overlay.addClass("large_settings_form"); }
        if(source.is(".medium_form")) { overlay.addClass("medium_settings_form"); }
        if(source.is(".small_form")) { overlay.addClass("small_settings_form"); }
        if(source.is(".tiny_form")) { overlay.addClass("tiny_settings_form"); }

        if(overlay.innerWidth() >= window.innerWidth) {
            top="0%";
            fixed=false;
        }
        overlay.overlay({
            top: top,
            left: "center",
            oneInstance: false,
            load: true,
            zIndex: 2000,
            closeOnClick: false,
            fixed:fixed,
            mask: {
                zIndex: 1999,
                color: "#222",
                loadSpeed: 200,
                opacity: 0.6
            },
            onClose: function (event) {
                overlay.find("div.settings_wysiwyg textarea").tinymce().remove();
                overlay.find("div.inline_settings_wysiwyg").tinymce().remove();
                $.roxiware.alert.popup = null;
                if(conf.onClose) {
                    conf.onClose(overlay);
                }
                overlay.remove();
                $("body").css("overflow", "");
            },
            onLoad: function(event) {
                 $("body").css("overflow", "hidden");
                 overlay.find("button").button();
                 overlay.find("input[alt_type=color]").colorpicker();
                 overlay.find(".param-field-image").bind("click", function() {
                     var param_field = $(this);
                     var params = {};
                     params = {url:encodeURI($(this).find("img").attr("src"))};
                     if(param_field.find("input").attr("width") && param_field.find("input").attr("height")) {
                         params.width = param_field.find("input").attr("width");
                         params.height = param_field.find("input").attr("height");
                     }
                     settingsForm("/asset/edit?"+jQuery.param(params), "Choose Image", {
                         success: function(image_url) {
                             param_field.find("img").attr("src", image_url);
                             param_field.find("input").val(image_url);
                         }
                     });
                 });
                 overlay.find("input[watermark]").watermark();
                 overlay.find(".param-field-select select").selectBox();
                 overlay.find("button[require_fields]").each(function(index, button) {
                     $(button).require_fields($(button).attr("require_fields"));
                 });
                 var toolbar = "styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent | link image media | code";
                 if(overlay.find("div.settings_wysiwyg").attr("toolbar") != undefined) {
                     toolbar = overlay.find("div.settings_wysiwyg").attr("toolbar");
                 }

                 // make sure you match this against the ruby sanitizer in lib/roxiware/sanitizer.rb
                 overlay.find("div.settings_wysiwyg textarea").tinymce({
                     script_url:"http://cdn.roxiware.com/tools/tinymce/tinymce.min.js",
                     theme: "modern",
                     skin: "light",
                     menubar: false,
                     browser_spellcheck:true,
                     relative_urls: false,
                     verify_html:false,
                     remove_script_host:true,
                     document_base_url: window.location.protocol+'//'+window.location.hostname+(window.location.port ? ':'+window.location.port: ''),
                     plugins: [
                         "autolink lists link image charmap anchor",
                         "visualblocks code",
                         "media table contextmenu paste"
                     ],
                     height: "100%",
                     init_instance_callback : function(ed) {
                         var timer=setInterval(function() {
                             var panel_height = $(ed.getContainer()).find(".mce-toolbar").height();
                             if(panel_height > 0) {
                                 $(ed.getContentAreaContainer()).css("top", panel_height+"px");
                                 clearInterval(timer);
                             }
                         }, 100);
                     },
                     statusbar:false,
                     resize:false,
                     schema: "html5",
                     toolbar: toolbar,
                 });
            }
        });
        overlay.find("div.inline_settings_wysiwyg").tinymce({
               script_url:"http://cdn.roxiware.com/tools/tinymce/tinymce.min.js",
               theme: "modern",
               inline:true,
               skin: "light",
               menubar: false,
               browser_spellcheck:true,
               relative_urls: false,
               verify_html:false,
               remove_script_host:true,
               document_base_url: window.location.protocol+'//'+window.location.hostname+(window.location.port ? ':'+window.location.port: ''),
               plugins: [
                   "autolink lists link image charmap anchor",
                   "visualblocks code media",
                   "table contextmenu paste autoresize"
               ],
               height: $("div.settings_wysiwyg").height() - 30,
               autoresize_min_height:140,
               statusbar:false,
               schema: "html5",
               toolbar: "styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist | link image media | code",
               setup: function(ed){ed.on('LoadContent', function() {
                            tinymce.ui.FloatPanel.zIndex = overlay.css("z-index")+1;  // Normally, the float panel defaults to 65535, but that'll overlay other dialogs
               })}
        });

        overlay.find(".contentWrap [title]").tooltip({
            predelay:1000,
            effect:'fade',
            position: "top right",
            offset: [10, -20]
        });
    };
    $("body").append(overlay);
    if(source instanceof jQuery) {
        overlay.find(".contentWrap").append(source.css("display","block"));
        instantiateOverlay();
    }
    else {
        overlay.find(".contentWrap").load(source, function(responseText, textStatus, xhr) {
            if(xhr.status != 200) {
                if(xhr.status == 0) {
                    $.error("The server is not available.  Please try again.");
                }
                else {
                    $.error(xhr.statusText);
                }
                return;
            }
            instantiateOverlay();
        });
    }
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

function xmlEscape(value) {
   return value.replace(/&/g, '&amp;')
		.replace(/</g, '&lt;')
		.replace(/>/g, '&gt;')
		.replace(/\"/g, '&quot;');
}


/* Generate a UUID.  We should probably move this to a web service on a centralized server */
/* Taken from http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript */
function genUUID() {
    var nbr, randStr = "";
    do {
        randStr += (nbr = Math.random()).toString(16).substr(2);
    } while (randStr.length < 30);
    return [
	    randStr.substr(0, 8), "-",
	    randStr.substr(8, 4), "-4",
	    randStr.substr(12, 3), "-",
	    ((nbr*4|0)+8).toString(16), // [89ab]
	    randStr.substr(15, 3), "-",
	    randStr.substr(18, 12)
	    ].join("");
}

function getNextUniqueName(name, name_list) {
    var index = 1;
    while($.inArray(name + "("+index+")", name_list) > -1) {
        index++;
    }
    return name + "("+index+")";
}

$(document).bind("ajaxStart", function(event) {
		$.wait();
	    });
$(document).bind("ajaxStop", function(event) {
		$.resume();
	    });


function inIframe () {
    try {
        return window.self !== window.top;
    } catch (e) {
        return true;
    }
}

jQuery.loadScript = function (url, arg1, arg2) {
    var cache = false, callback = null;
    //arg1 and arg2 can be interchangable
    if ($.isFunction(arg1)){
        callback = arg1;
        cache = arg2 || cache;
    } else {
        cache = arg1 || cache;
        callback = arg2 || callback;
    }
               
    var load = true;
    //check all existing script tags in the page for the url
    jQuery('script[type="text/javascript"]')
    .each(function () { 
            return load = (url != $(this).attr('src')); 
        });
    if (load){
        //didn't find it in the page, so load it
        jQuery.ajax({
                type: 'GET',
                    url: url,
                    success: callback,
                    dataType: 'script',
                    cache: cache
                    });
    } else {
        //already loaded so just call the callback
        if (jQuery.isFunction(callback)) {
            callback.call(this);
        };
    };
};
jQuery.loadScripts = function(urls, arg1, arg2) {
    var cache = false, callback = null;
    //arg1 and arg2 can be interchangable
    if ($.isFunction(arg1)){
        callback = arg1;
        cache = arg2 || cache;
    } else {
        cache = arg1 || cache;
        callback = arg2 || callback;
    }
    var new_urls = urls;
    var url = new_urls.shift();
    console.log("loading url :"+url);
    if(url) {
        $.loadScript(url, cache, function() {
            $.loadScripts(urls, cache, callback);
        });
    }
    else {
        callback();
    }
}

$.roxiware.cycle_background = {
    conf: {
        ordered:false,
        firstLoad:function() {},
        lastLoad:function() {},
        cycleParams: {
            fit:true,
            width:"100%",
            height:"100%"
        }
    }
}    


// Add a bunch of divs with backgrounds set to the images parameter.
// The images are loaded in parallel, but are added to the base object
// in order.  On addition of second image, cycle is started
$.fn.cycle_background = function(images, conf_params) {
    var conf = $.extend({}, $.roxiware.cycle_background.conf, conf_params);
    var self = $(this);
    var loadedImages = [];
    var currentAdded = 0;
    var cycle_params = $.extend({}, $.roxiware.cycle_background.conf.cycleParams, conf.cycleParams);
    $.each(images, function(index, image_path) {
        var currentIndex = index;
        var loadingImage = $(new Image());
        loadingImage.bind("load error", function(e) {
            if(!conf.ordered) {
                currentIndex = currentAdded;
            }
            // save off the loaded image into an ordered array, with 
            if(e.type == "load") {
                loadedImages[currentIndex] = $("<div></div>").css({display:"none",
                                                                   position:"absolute", 
                                                                   left:0,
                                                                   right:0,
                                                                   top:0,
                                                                   bottom:0,
                                                                   width:"100%",
                                                                   height:"100%",
                                                                   "background-image":"url('"+$(this).attr('src')+"')"});
            }
            else {
                loadedImages[currentIndex] = $("");
            }
            while((currentAdded < images.length) && loadedImages[currentAdded]) {
                // add this image and any subsequent images that were waiting on this one to be added,
                // if this is the one that we're currently waiting on.
                self.append(loadedImages[currentAdded]);
                
                currentAdded++;
                if(currentAdded == 1) {
                    loadedImages[currentIndex].fadeIn(100, function() {
                        conf.firstLoad();
                    });
                }
                if(currentAdded == images.length) {
                    conf.lastLoad();
                }
            }
            if(currentAdded > 2) {
                // only cycle if there are more than one images added
                self.cycle("destroy");
                self.cycle(cycle_params);
            }
        });
        loadingImage.attr("src", image_path);
    });
}
