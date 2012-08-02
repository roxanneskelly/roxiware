
(function($) {

    $.roxiware = $.roxiware || {version: '@VERSION'};
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
				 color: "#777",
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
})(jQuery);

$(document).bind("ready", function() {
	$(document).bind("ajaxStart", function(event) {
		$.wait();
	    });
	$(document).bind("ajaxStop", function(event) {
		$.resume();
	    });
    });