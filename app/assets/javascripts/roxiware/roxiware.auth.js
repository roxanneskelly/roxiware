/* roxiware.auth.js
   Authentication including login and oauth
   requires jquerytools, roxiware.uitools.js

   Copyright (c) 2012 Roxiware
*/

var login_form_template = '<form accept-charset="UTF-8" action="/account/login" method="post">' +
                              '<div id="login_status"></div>' +
                              '<div id="username_entry">' +
                              '<label for="user_username">Username</label>' +
                              '<input id="user_username" name="user[username]" size="255" type="text" watermark="username" /></div>' +
                              '<div id="password_entry"><label for="user_password">Password</label><input id="user_password" name="user[password]" size="30" type="password" watermark="password" /></div>' +
                              '<div id="remember_me_check" class="labeled-checkbox">' +
                              '<input name="user[remember_me]" type="hidden" value="0" />' +
                              '<input id="user_remember_me" name="user[remember_me]" type="checkbox" value="1" /><span class="control-icon checkbox-icon"></span><label for="user_remember_me">Remember me</label></div>' +
                              '<button disabled="disabled" id="login_button" name="button" type="submit" require_fields="input#user_username,input#user_password">login</button>' +
                              '<a id="forgot_password">Forgot your password?</a>' +
                              '<div id="social_networks_login"><a id="facebook_login" provider="facebook" class="oauth_login"></a>'+
                              '<a id="twitter_login" provider="twitter" class="oauth_login"></a></div>' +
                              '</form>';


var forgot_password_template = '<div class="small_form" id="forgot_password_form"><form accept-charset="UTF-8" action="/account/password" method="POST">' +
                              "<div class='wizard_text'>We'll send you an email containing information on how to reset your password.</div><br/><br/>" +
                              '<div id="email_entry">' +
                              '<label for="user_email">Email</label>' +
                              '<input id="user_email" name="user[email]" size="255" type="email" watermark="my@email.com" /></div>' +
                              '<div><button disabled="disabled" id="forgot_password_button" name="commit" type="submit" require_fields="input#user_email">Submit</button></div>' +
                              "<div class='wizard_text'>Check your email.  We've sent you password reset instructions.</div><br/><br/>" +
                              '</form></div>';


$.fn.require_fields = function(fields) {
    var button = $(this);
    var checkFields = function() {
        var button_enable = "enable";
	$(fields).each(function(index, value) {
	    if ($(this).is(".watermark") || ($(this).val().length == 0)) {
	        button_enable = "disable";
	    }
	});
        button.button(button_enable);
    }
    checkFields();
    $(fields).bind("input blur propertychange onchange", function() {
        checkFields();
    });
}


$.roxiware.oauth_login = {
    conf: {
        check_login_state:false,
        proxy:true,
	onSuccess:function(response) {

        },
        params: {}
    }
}

// assign an element to be an oauth login button.
// on click, it'll do the appropriate login stuff, then
// perform the callback
$.fn.oauthLogin = function(provider, conf) {
    var conf = $.extend(true, {}, $.roxiware.oauth_login.conf, conf);
    conf.params.provider = provider;
    $(this).click(function() {
        do_login(conf);
    });
}


// retrieve the local auth info if it exists
var _get_auth_info = function(callback) {
    var auth_info = null;

    if (document.cookie.indexOf("ext_oauth_token") < 0) {
        localStorage.removeItem("roxiwareAuthInfo");
    }

    if(!window.fbApiInit) {
        setTimeout(function() {_get_auth_info(callback);}, 50);
        return;
    }
    if (localStorage.roxiwareAuthInfo) {
        try{
            auth_info = JSON.parse(localStorage.roxiwareAuthInfo);
        }
        catch(e) {
            localStorage.removeItem("roxiwareAuthInfo");
        }
    }
    if (!auth_info) {
        return callback(null);
    }
    if((auth_info.expires == undefined ) || (new Date(auth_info.expires*1000) < new Date())) {
        localStorage.removeItem("roxiwareAuthInfo");
        return callback(null);
    }

    callback(auth_info);
    /*
    Should do a verification that facebook is currently logged in, but FBapi
    changed and verifies the domain via the request url domain, which
    won't work as we've authenticated against scribaroo */
    /*
    if (auth_info.auth_kind == "facebook") {
        FB.getLoginStatus(function(response) {
	    if (response.status != 'connected') {
                localStorage.removeItem("roxiwareAuthInfo");
	        callback(null);
	    }
            callback(auth_info);
	});
	callback(null);
    }
    else {
    }
    */
}


$.extend({
    // register for notifications of authentication
    //onOAuthLogin:function(conf) {
    //    var conf = $.extend(true, {}, $.roxiware.oauth_login.conf, conf);
    //    conf.params.provider = provider;
    //}

    oAuthLogIn:function(provider, oauth_state) {
            do_login({
                onSuccess: function(auth_info) {
                        $("body").trigger("oauth_login", auth_info);
                    },
                params: {
                        provider:provider,
                        oauth_state:oauth_state
                }});
    },

    // check oauth login status
    oAuthCheckLoggedIn:function() {
        _get_auth_info(function(auth_info) {
            $("body").trigger("oauth_login", auth_info);
        });
    },
    oAuthResetLogin:function() {
        localStorage.removeItem("roxiwareAuthInfo");
        document.cookie = "ext_oauth_token=;Path=/;Expires=Thu, 01-Jan-1970 00:00:01 GMT;";
        $("body").trigger("oauth_login", null);
    }
});


function do_login(data) {
    if(data.resetLogin) {
        reset_login();
    }
    _get_auth_info(function(auth_info) {
        var handleSuccess = function(auth_info, data) {
            var date = new Date();
            date.setDate(date.getDate()+7);
            document.cookie = "ext_oauth_token="+escape(auth_info.auth_token) + ";Path=/;Expires="+date.toUTCString();
            data.onSuccess(auth_info);
        }

        if(auth_info && auth_info.auth_kind) {
            handleSuccess(auth_info, data);
            return;
        }
        if(data.check_login_state) {
            return;
        }

        // we need to bring up the oauth providers login window
        var login_url = "/account/auth/authproxy?"+$.param(data.params);
        var width=500;
        var height=300;
        var left = $(window).width()/2-width/2;
        var top=$(window).height()/2-height/2;
        var login_popup = window.open(login_url, "loginProxyPopup", "height="+height+",width="+width+",left="+left+",top="+top+",resizable=no,scrollbars=no,toolbar=no,menubar=no,location=no,directories=no,status=no");
        // poll until the login window closes.  When it closes, it'll set local storage auth info 
        // to the appropriate value
        var timer = setInterval(function() {
            if(login_popup.closed) {
                if(localStorage.roxiwareAuthInfo) {
                    try {
                        var auth_info = JSON.parse(localStorage.roxiwareAuthInfo);
                        handleSuccess(auth_info, data);
                    }
                    catch(e) {
                    }
                }
                clearInterval(timer);
            }
        }, 250);
    });
};

function reset_login() {
    localStorage.removeItem("roxiwareAuthInfo");
}

function get_login_form_template(options) {
    var template = $(login_form_template);
    template.find("a#forgot_password").click(function() {
        forgotPassword();
        });

    template.find("a.oauth_login").click(function() {
        var data = {
                 proxy:false,
                 resetLogin:true,
                 params:{
                     provider:$(this).attr("provider"), 
                     oauth_state:options[$(this).attr("provider")+"_oauth_state"]
                 },
                 onSuccess:function() { 
                     window.location.reload()
            }
        };
        // do a direct facebook login to gather the auth token
        do_login($.extend(data, options));
    });

    if(localStorage.roxiwareLoginUsername) {
        template.find("input#user_username").val(localStorage.roxiwareLoginUsername);
        template.find("input#user_remember_me").attr("checked", true);
    }
    template.submit(function(e) {
        e.preventDefault();
        if(template.find("input#user_remember_me:").attr("checked")) {
            localStorage.roxiwareLoginUsername = template.find("input#user_username").val();
        }
        else {
            localStorage.removeItem("roxiwareLoginUsername");
        }
        $.ajax({
            type:"POST",
            url: "/account/auth/roxiware/callback",
            processData: true,
            data: template.serializeArray(),
            error: function(xhr, textStatus, errorThrown) {
                       template.find("input").removeClass("field-error");
                       if(xhr.status == 401) {
                           template.find("#login_status").text("Invalid username or password, please try again.");
                           template.find("input#user_username, input#user_password").addClass("field-error");
                       }
                       else if (xhr.status == 0) {
                           $.error("The server is not available.  Please try again.");
                       }
                       else {
                           $.error(errorThrown);
                       }
                },
            complete: function() {
            },
            success: function(data) {
                window.location.reload();
            }
        });
        return false;
    });
    return template;
}

function loginForm(options) {
    settingsForm($("<div class='small_form' id='login_form'/>").append(get_login_form_template(options)), "Sign In");
}

function forgotPassword() {
    var template = $(forgot_password_template);
    template.submit(function(e) {
	e.preventDefault();
        $.ajaxSetParamsJSON("/account/reset_password.json", template.find("form").serializeArray(),
	    {method:"POST",
		success: function() {
		    $.notice("Password reset instructions have been sent to your email address",
			     {
				 onClose: function() {
				     window.location.reload();
				 }
			     })
		}
	    })
        });
    settingsForm(template, "Forgot Password");
}
