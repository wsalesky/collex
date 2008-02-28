/** 
 *  Copyright 2007 Applied Research in Patacriticism and the University of Virginia
 * 
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 * 
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 **/

SidebarTagCloud = Class.create( {
	
	initialize: function( initialCloudSize ) {
		this.initialCloudSize = initialCloudSize;
		this.initSidebarFilterHandler();			
	},
	
	// initialize keystroke event for sidebar filter field
	initSidebarFilterHandler: function() {
		this.showAllCloudTags = false;
		this.sidebarTouched = false;
		this.updateTagCloud();
		Event.observe('sidebar_search', 'keyup', this.onSidebarFilter.bindAsEventListener(this) );					
	},

	// respond to changes in the sidebar filter field
	onSidebarFilter: function() {
		this.sidebarTouched = true;
		this.updateTagCloud();
	},
		
	// update the display of the tag cloud
	updateTagCloud: function() {
		
		var tagCloud = $('tagcloud');
		if( !tagCloud ) return;
		
		// so that we don't filter on the "filter tags" text.
		var sidebarFilterString = this.sidebarTouched ?	$('sidebar_search').value.toLowerCase() : "";

		// collect all of the <a> tags in the tagcloud <div> 
		var tags = tagCloud.select('a');

		var i = 0;
		var visibleTags = [];

		// hide tags that don't match the filter
		tags.each( function(tag) {
			if( sidebarFilterString.blank() || tag.text.toLowerCase().startsWith( sidebarFilterString ) ) {
				tag.show();
				visibleTags[i++] = tag;
			} 
			else {
				tag.hide();
			}
		});

		// hide excess tags if we are not showing all tags
		if( this.showAllCloudTags == false && visibleTags.length > this.initialCloudSize ) {
			var tagIndex = this.initialCloudSize; 
			while( tagIndex < visibleTags.length ) {
				visibleTags[tagIndex++].hide();
			}		
		}	
	},

	// toggle whether we show all tags or a subset
	toggleShowMoreCloudTags: function() {
		this.showAllCloudTags = !this.showAllCloudTags;
		var toggleButton = $('toggle-show-all-tags');
		if( this.showAllCloudTags ) {
			toggleButton.innerHTML = "hide more";
		} else {
			toggleButton.innerHTML = "show more";		
		}	
		this.updateTagCloud();
	},

	// update the sidebar with new content from the target URL
	updateSidebar: function( targetURL ) {
		new Ajax.Updater('sidebar', targetURL, {
			asynchronous:true, 
			evalScripts:true,
			onComplete: this.initSidebarFilterHandler.bindAsEventListener(this)
		});
	}					
});

