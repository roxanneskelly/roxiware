/*
 * jQuery UI Font Selector Widget
 *
 * Copyright 2012, Olav Andreas Lindekleiv (http://lindekleiv.com/)
 * Available under the BSD License
 * See the LICENSE file or http://opensource.org/licenses/BSD-3-Clause
 *
 * Changed by Steve Scheidecker (http://stevezilla.com) to allow multiple font selectors on a single page.
 * Available on BitBucket at
 * https://bitbucket.org/sscheidecker/jquery-ui-fontselector-multiples
 */

$.widget('oal.fontSelector', {
  options: {
    inSpeed: 500,
    outSpeed: 250,
    bold: false,
    italic: false,
    underline: false,
    closeOnSelect: true,
	styleToggles: ['Bold','Italic','Underline','Strike','Blink']
  },
  _create: function() {
    var font, fontEl, fontLabel, fontName, fonts, label, _i, _j, _len, _len2, _ref, _ref2,
      _this = this;
    this.element.hide();
    fonts = [];
    _ref = this.element.children();
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      font = _ref[_i];
      fontLabel = $(font).text();
      fontName = $(font).attr('value');
      if ($(font).attr('selected')) this.selected = fontName;
      fonts.push([fontName, fontLabel]);
    }
    if (!this.selected) this.selected = fonts[0][0];
    this.dropdown = $('<div class="fontSelector ui-widget"><span class="handle">&#9660;</span></div>');
    if(this.options.styleToggles) {
	this.styleToggles = $('<div class="styleToggles"></div>');
	for(i in this.options.styleToggles){
	    this.styleToggles.append('<div class="styleToggle" styleType="' + this.options.styleToggles[i].toLowerCase() + '"><a href="#">' + this.options.styleToggles[i] + '</a></div>');
	}
    }
    this.list = $('<ul class="fonts" style="z-index:2"></ul>');
    for (_j = 0, _len2 = fonts.length; _j < _len2; _j++) {
      font = fonts[_j];
      _ref2 = font, font = _ref2[0], label = _ref2[1];
      this.element.before("<link rel='stylesheet' type='text/css' href='http://fonts.googleapis.com/css?family=" + font + ":400,700,400italic,700italic'></link>");
      fontEl = $("<li style=\"font-family: " + font + "\">" + label + "</li>");
      fontEl.data('font', font);
      if (font === this.selected) {
        fontEl.addClass('selected');
        this.dropdown.prepend($("<h4 style=\"font-family: " + font + "\" class='selected handle'>" + label + "</h4>"));
      }
      this.list.append(fontEl);
    }
    this.dropdown.append(this.list);
    this.element.after(this.dropdown);
    if(this.options.styleToggels) {
	this.dropdown.after(this.styleToggles);
    
	$(this.styleToggles).find('.styleToggle').click(function(){
		if($(this).hasClass('styleToggle')){
			targetEl = $(this).find('a');
			wrapEl = $(this);
		}
		else {
			targetEl = $(this);
			wrapEl = $(this).parent();
		}
		
		if(targetEl.attr("value") != true){
			targetEl.attr("value",true);
			wrapEl.addClass('selected');
		} else {
			targetEl.attr("value",false);
			wrapEl.removeClass('selected');
		}
		return _this._styleToggle(targetEl.html(),targetEl.attr("value"));
		
	    });
    }

      return $(this.dropdown).find(".handle").click(function() {
      return _this._toggleOpen();
	  });


  },
  _styleToggle: function(styleType,value){
	return this._setOption(styleType.toLowerCase(),value);
 },
  _toggleOpen: function() {
    var _this = this;
    if (this.list.is(':visible')) {
      this.dropdown.find('span.handle').html('&#9660;');
      return this.list.slideUp(this.options.outSpeed);
    } else {
      this.dropdown.find('span.handle').html('&#9650;');
      this.list.slideDown(this.options.inSpeed);
	  return $(this.dropdown).find('ul.fonts li').click(function(e) {
		if(_this.options.closeOnSelect){
			_this.dropdown.find('span.handle').html('&#9660;');
			_this.list.slideUp(_this.options.outSpeed);
		}
		
        var font, fontLi, fontName, fontOption, label, oldFont, _i, _j, _len, _len2, _ref, _ref2, _results;
        font = $(e.target).data('font');
        label = $(e.target).text();
        oldFont = _this.selected;
        if (font === oldFont) return false;
        _this._trigger('fontChange', null, {
          font: font,
          oldFont: oldFont
        });
        _this.selected = font;
        
		$(_this.element).find("option").attr("selected",false);
		$(_this.element).find('option[value="' + font + '"]').attr("selected","true");

		$(_this.dropdown).find('h4.selected').text(label).css({
          fontFamily: font
        });

        _ref = _this.list.children();
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          fontLi = _ref[_i];
          if ($(fontLi).data('font') === font) {
            $(fontLi).addClass('selected');
          } else if ($(fontLi).data('font') === oldFont) {
            $(fontLi).removeClass('selected');
          }
        }
        _ref2 = _this.element.children();
        _results = [];
        for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
          fontOption = _ref2[_j];
          fontName = $(fontOption).val();
          if (fontName === font) {
            _results.push($(fontOption).attr('selected', 'selected'));
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      });
    }
  },
  _setOption: function(key, value) {
	var td_options = ['strike','blink','underline'];
	this.element.attr('option_'+key,value);
    if (key === 'bold' && (value === true || value === false)) {
      this.options.bold = value;
      if (value === true) {
        this.dropdown.find('h4.selected').css({
          fontWeight: 'bold'
        });
        this.list.css({
          fontWeight: 'bold'
        });
      } else {
        this.dropdown.find('h4.selected').css({
          fontWeight: 'normal'
        });
        this.list.css({
          fontWeight: 'normal'
        });
      }
    } else if (key === 'italic' && (value === true || value === false)) {
      this.options.italic = value;
      if (value === true) {
        this.dropdown.find('h4.selected').css({
          fontStyle: 'italic'
        });
        this.list.css({
          fontStyle: 'italic'
        });
      } else {
        this.dropdown.find('h4.selected').css({
          fontStyle: 'normal'
        });
        this.list.css({
          fontStyle: 'normal'
        });
      }
    } else if ((key === 'underline' || key === 'strike' || key === 'blink') && (value === true || value === false)) {
	  setKey = key;
	  if(key === 'strike') setKey = 'line-through';
      this.options[key] = value;
      if (value === true) {
        this.dropdown.find('h4.selected').css({
          textDecoration: setKey
        });
        this.list.css({
          textDecoration: setKey
        });

		for(i in td_options){
			option = td_options[i];
			if(option != key){
				this.options[option] = false;
				this.element.attr('option_'+option,false);
				this.styleToggles.find('[styleType='+option+']').removeClass("selected");
				this.styleToggles.find('[styleType='+option+'] a').attr("value",false);
			}
		}

      } else {
        this.dropdown.find('h4.selected').css({
          textDecoration: 'none'
        });
        this.list.css({
          textDecoration: 'none'
        });
      }
    } 

    if ((key === 'bold' || key === 'italic' || key === 'underline' || key === 'strike' || key === 'blink') && (value === true || value === false)) {
      return this._trigger('styleChange', null, {
        style: key,
        value: value
      });
    }
  },
  getProperties: function(){
	fontWeight = 'normal';
	fontStyle = 'normal';
	fontTD = 'none';
	if(this.options.bold === true) fontWeight = 'bold';
	if(this.options.italic === true) fontStyle = 'italic';
	if(this.options.strike === true) fontTD = 'line-through';
	if(this.options.underline === true) fontTD = 'underline';
	if(this.options.blink === true) fontTD = 'blink';
	
	return {"fontFamily":this.selected,"fontWeight":fontWeight,"fontStyle":fontStyle,"textDecoration":fontTD};
  },
  destroy: function() {
    return Widget.prototype.destroy.call(this);
  }
});