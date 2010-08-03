##########################################################################
# Copyright 2009 Applied Research in Patacriticism and the University of Virginia
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################################################

class DiscussionThread < ActiveRecord::Base
  belongs_to :discussion_topic
	belongs_to :group
	belongs_to :cluster
  has_many :discussion_comments, :order => :position
	has_and_belongs_to_many :users
  
  def get_title
    if title && title.length > 0
      return title
    end
    
    ty = discussion_comments[0].get_type()
    case ty
      when "comment":
        return title
      when "nines_object":
        hit = CachedResource.get_hit_from_resource_id(discussion_comments[0].cached_resource_id)
        return CGI.escapeHTML(CachedResource.fix_char_set(hit["title"][0])) if hit != nil && hit["title"]
        return "object" # If the object isn't found in the cache or is somehow not complete.
      when "nines_exhibit":
        exhibit = Exhibit.find(discussion_comments[0].exhibit_id)
        return CGI.escapeHTML(exhibit.title)
      when "inet_object":
        return discussion_comments[0].link_url
    end
  end

	def get_most_recent_comment_time
		return 0 if discussion_comments.length == 0
		return discussion_comments[discussion_comments.length-1].updated_at
	end
end
