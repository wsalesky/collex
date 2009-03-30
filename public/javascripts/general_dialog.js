//------------------------------------------------------------------------
//    Copyright 2009 Applied Research in Patacriticism and the University of Virginia
//    
//    Licensed under the Apache License, Version 2.0 (the "License");
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at
//  
//        http://www.apache.org/licenses/LICENSE-2.0
//  
//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License.
//----------------------------------------------------------------------------

/*global Class, $, $$, $H, Element */
/*global YAHOO */

var GeneralDialog = Class.create({
	initialize: function (parent_id, this_id, elements, flash_notice) {
		this.class_type = 'GeneralDialog';	// for debugging

		// private variables
		var This = this;

		var handleCancel = function() {
		    this.cancel();
		};
		
		var panel = new YAHOO.widget.Dialog(this_id, {
			constraintoviewport: true,
			modal: true,
			close: true,
			draggable: true,
			underlay: 'shadow',
			buttons: [ { text:"Cancel", handler:handleCancel } ]
		});
		
		var klEsc = new YAHOO.util.KeyListener(document, { keys:27 },  							
			{ fn:handleCancel,
				scope:panel,
				correctScope:true }, "keyup" ); // keyup is used here because Safari won't recognize the ESC keydown event, which would normally be used by default
		panel.cfg.queueProperty("keylisteners", klEsc);

		// Create all the html for the dialog
		var listenerArray = [];
		var body = new Element('div');
		body.appendChild(new Element('div', { id: this_id + 'flash', 'class': 'flash_notice' }).update(flash_notice));
		elements.each(function (el){
			var elClass = el.page;
			el.elements.each(function (subel) {
				if (subel.item_type === 'instructions')
					body.appendChild(new Element('div', { 'class': elClass + " switchable_element login-explanation hidden" }).update(subel.data));
				else if (subel.item_type === 'group')
				{
					if (subel.data.title.length > 0)
						body.appendChild(new Element('div', { 'class': elClass + " switchable_element login-option hidden" }).update(subel.data.title));
					var form = new Element('form');
					body.appendChild(form);
					subel.data.fields.each(function (fld) {
						var row = new Element('div', { 'class': elClass + " switchable_element hidden" });
						form.appendChild(row);

						if (fld.label !== undefined) {
							row.appendChild(new Element('span', { 'class': "login-row"}).update(fld.label));
						}
						if (fld.fixed !== undefined) {
							row.appendChild(new Element('span', { id: (fld.id !== undefined) ? fld.id : '' }).update(fld.fixed));
						}
						if (fld.text !== undefined) {
							var el1 = new Element('input', { 'class': elClass + " switchable_element hidden", 'type': 'text', size: fld.text });
							if (fld.id !== undefined)
								el1.writeAttribute({id: fld.id });
							if (fld.value !== undefined)
								el1.writeAttribute({value: fld.value });
							row.appendChild(new Element('span').appendChild(new Element('div').appendChild(el1)));
						}
						if (fld.password !== undefined) {
							row.appendChild(new Element('span').appendChild(new Element('input', { 'type': 'password', size: fld.text, id: (fld.id !== undefined) ? fld.id : '' })));
						}
						if (fld.submit !== undefined) {
							var span = new Element('span', { 'class': "login-row"});
							var input = new Element('input', { id: 'btn' + listenerArray.length, 'type': 'button', value: fld.submit });
							span.appendChild(input);
							row.appendChild(span);
							listenerArray.push({ id: 'btn' + listenerArray.length, callback: fld.callback, param: [ fld.submit_url, this_id + 'flash' ] });
						}
						if (fld.page_link !== undefined) {
							var span = new Element('span', { 'class': "login-row"});
							var a = new Element('a', { id: 'a' + listenerArray.length, href: '#', 'class': 'nav_link' }).update(fld.page_link);
							span.appendChild(a);
							row.appendChild(span);
							listenerArray.push({ id: 'a' + listenerArray.length, callback: fld.callback, param: [ fld.new_page, this ] });
						}
					}, this);

//					if (subel.data.title.length > 0)
//						body.appendChild(new Element('div', { 'class': elClass + " switchable_element login-option hidden" }).update(subel.data.title));
//					var table = new Element('table', { 'class': elClass + ' switchable_element hidden ' + subel.data.cls });
//					var tbody = new Element('tbody');
//					var form = new Element('form');
//					table.appendChild(tbody);
//					form.appendChild(table);
//					body.appendChild(form);
//					subel.data.fields.each(function (fld) {
//						var tr = new Element('tr', { 'class': elClass + " switchable_element hidden" });
//						tbody.appendChild(tr);
//
//						if (fld.label !== undefined) {
//							tr.appendChild(new Element('td').update(fld.label));
//						}
//						if (fld.fixed !== undefined) {
//							tr.appendChild(new Element('td', { colspan: 2, id: (fld.id !== undefined) ? fld.id : '' }).update(fld.fixed));
//						}
//						if (fld.text !== undefined) {
//							var el1 = new Element('input', { 'class': elClass + " switchable_element hidden", 'type': 'text', size: fld.text });
//							if (fld.id !== undefined)
//								el1.writeAttribute({id: fld.id });
//							if (fld.value !== undefined)
//								el1.writeAttribute({value: fld.value });
//							tr.appendChild(new Element('td', { colspan: 2}).appendChild(new Element('div').appendChild(el1)));
//						}
//						if (fld.password !== undefined) {
//							tr.appendChild(new Element('td', { colspan: 2}).appendChild(new Element('input', { 'type': 'password', size: fld.text, id: (fld.id !== undefined) ? fld.id : '' })));
//						}
//						if (fld.submit !== undefined) {
//							tr.appendChild(new Element('td', { colspan: 2}).appendChild(new Element('input', { id: 'btn' + listenerArray.length, 'type': 'button', value: fld.submit })));
//							listenerArray.push({ id: 'btn' + listenerArray.length, callback: fld.callback, param: [ fld.submit_url, this_id + 'flash' ] });
//						}
//						if (fld.page_link !== undefined) {
//							tr.appendChild(new Element('td', { colspan: 2}).appendChild(new Element('a', { id: 'a' + listenerArray.length, href: '#', 'class': 'nav_link' }).update(fld.page_link)));
//							listenerArray.push({ id: 'a' + listenerArray.length, callback: fld.callback, param: [ fld.new_page, this ] });
//						}
//					}, this);
				}
				else if (subel.item_type === 'button') {
					var but = [ { text: subel.data.name, handler: { fn: subel.data.callback, obj: [ subel.data.submit_url, this_id + 'flash'], scope: elClass } },
					 { text:"Cancel", handler:handleCancel } ];
					panel.cfg.queueProperty("buttons", but);
				}
			}, this);
		}, this);

		panel.setBody(body);
		panel.render(parent_id);
		
		listenerArray.each(function (listen, i) {
			YAHOO.util.Event.addListener(listen.id, "click", listen.callback, listen.param); 
		});
		
		this.setTitle = function(title) {
			panel.setHeader(title); 
		};
		
		this.center = function() {
			var dlg = $(this_id);
			var w = parseInt(dlg.getStyle('width'), 10);
			var h = parseInt(dlg.getStyle('height'), 10);
			var vw = YAHOO.util.Dom.getViewportWidth();
			var vh = YAHOO.util.Dom.getViewportHeight();
			var x = (vw - w) / 2;
			var y = (vh - h) / 2;
			if (x < 0) x = 0;
			if (y < 0) y = 0;
			var el = dlg.up();
			el.setStyle({ left: x + 'px', top: y + 'px'});
		};
	}
});

