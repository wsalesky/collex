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

class GroupsController < ApplicationController
  layout 'nines'
  before_filter :init_view_options

  private
  def init_view_options
    @use_tabs = true
    @use_signin= true
    @site_section = :exhibits
    @uses_yui = true
    return true
  end
  public

	def pending_requests
		items = params[:group]
		group_id = params[:id]
		items.each { |key, val|
			if val == 'accept'
				GroupsUser.accept_request(key)
			elsif val == 'deny'
				GroupsUser.decline_request(key)
			end
		}
		render :partial => 'group_details', :locals => { :group => Group.find(group_id), :user_id => get_curr_user_id() }
	end

	# The following 4 calls can come from either the web or the email link. We have to go to
	# different pages in the two cases. The way to tell is the email link is GET and the web is POST.
	def accept_request
		from_web = request.request_method == :post

		success = GroupsUser.accept_request(params[:id])
		if !success
			redirect_to :action => 'stale_request'
		else
			group_id = GroupsUser.get_group_from_obfuscated_id(params[:id])
			if from_web
				render :partial => 'group_details', :locals => { :group => Group.find(group_id), :user_id => get_curr_user_id() }
			else
				redirect_to :action => 'acknowledge_notification', :type => 'accept_request', :success => success, :group_id => group_id
			end
		end
	end

	def decline_request
		from_web = request.request_method == :post

		group_id = GroupsUser.get_group_from_obfuscated_id(params[:id])
		success = GroupsUser.decline_request(params[:id])
		if !success
			redirect_to :action => 'stale_request'
		else
			if from_web
				render :partial => 'group_details', :locals => { :group => Group.find(group_id), :user_id => get_curr_user_id() }
			else
				redirect_to :action => 'acknowledge_notification', :type => 'decline_request', :success => success, :group_id => group_id
			end
		end
	end

	def accept_invitation
		from_web = request.request_method == :post
		from_web = false if params[:from_create]	# we can also be redirected here from the create user id page.

		begin
			has_login = GroupsUser.has_login(params[:id])
		rescue
			redirect_to :action => 'stale_request'
			return
		end
			if has_login
				success = GroupsUser.join_group(params[:id])
				group_id = GroupsUser.get_group_from_obfuscated_id(params[:id])
				user_id = User.find(GroupsUser.find(Group.id_retriever(params[:id])).user_id)
				user = User.find(user_id)
				session[:user] = { :email => user.email, :fullname => user.fullname, :username => user.username, :role_names => user.role_names }
				if from_web
					render :partial => 'group_details', :locals => { :group => Group.find(group_id), :user_id => get_curr_user_id() }
				else
					redirect_to :action => 'acknowledge_notification', :type => 'join_group', :success => success, :group_id => group_id
				end
			else
				redirect_to :action => 'create_login', :id => Group.id_retriever(params[:id]), :message => ''
			end
	end

	def decline_invitation
		from_web = request.request_method == :post

		group_id = GroupsUser.get_group_from_obfuscated_id(params[:id])
		begin
			success = GroupsUser.decline_group(params[:id])
		rescue
			redirect_to :action => 'stale_request'
			return
		end
		if from_web
			render :partial => 'group_details', :locals => { :group => Group.find(group_id), :user_id => get_curr_user_id() }
		else
			redirect_to :action => 'acknowledge_notification', :type => 'decline_group', :success => success, :group_id => group_id
		end
	end

	def create_login_create
		gu_id = params[:id]
		user_name = params[:user_name]
		gu = GroupsUser.find(gu_id)
		email = gu.email
		password = params[:password]
		password2 = params[:password2]
		if user_name.length == 0
			redirect_to :action => 'create_login', :id => params[:id], :message => 'Please enter a user name.'
			return
		end
		user = User.find_by_username(user_name)
		if user != nil # there is a user with that name
			redirect_to :action => 'create_login', :id => params[:id], :message => 'There is already a user with that name. Please try another.'
			return
		end
		if password.length == 0 && password.strip.length == 0
			redirect_to :action => 'create_login', :id => params[:id], :message => 'Please enter a password.'
			return
		end
		if password != password2
			redirect_to :action => 'create_login', :id => params[:id], :message => 'Your passwords didn\'t match. Please try again.'
			return
		end

		session[:user] = COLLEX_MANAGER.create_user(user_name, password.strip, email)
		params[:id] = Group.id_obfuscator(gu_id)
		params[:from_create] = true
		accept_invitation()
	end

	 def leave_group
		 group_id = params[:group_id]
		 user_id = params[:user_id]
		 GroupsUser.leave_group(group_id, user_id)
		 redirect_to :back
	 end

	 def request_join
		 group_id = params[:group_id]
		 user_id = params[:user_id]
		 GroupsUser.request_join(group_id, user_id)
		 render :partial => 'group_details', :locals => { :group => Group.find(group_id), :user_id => user_id }
	 end

	 def accept_as_peer_reviewed
		 exhibit_id = params[:exhibit_id]
		 exhibit = Exhibit.find(exhibit_id)
		 exhibit.update_attributes(params[:exhibit])
		 #cluster = exhibit.cluster_id == nil ? nil : Cluster.find(exhibit.cluster_id)
		 render :partial => 'group_exhibits_list', :locals => { :group => Group.find(exhibit.group_id), :cluster => nil, :user_id => get_curr_user_id() }
	 end

	def unpublish_exhibit
		 exhibit_id = params[:exhibit_id]
		 exhibit = Exhibit.find(exhibit_id)
		 exhibit.is_published = 0
		 exhibit.save!
		 cluster = exhibit.cluster_id == nil ? nil : Cluster.find(exhibit.cluster_id)
		 render :partial => 'group_exhibits_list', :locals => { :group => Group.find(exhibit.group_id), :cluster => cluster, :user_id => get_curr_user_id() }
	end

	# Note: This is the same as unpublish_exhibit. Perhaps it should be the same call, even if it is semantically different.
	 def reject_as_peer_reviewed
		 exhibit_id = params[:exhibit_id]
		 exhibit = Exhibit.find(exhibit_id)
		 exhibit.is_published = 0
		 exhibit.save!
		 cluster = exhibit.cluster_id == nil ? nil : Cluster.find(exhibit.cluster_id)
		 render :partial => 'group_exhibits_list', :locals => { :group => Group.find(exhibit.group_id), :cluster => cluster, :user_id => get_curr_user_id() }
	 end

	def edit_membership
		show_membership = params[:show_membership]
		group = params[:group]
		group_id = nil
		group.each {|id,value|
			gu = GroupsUser.find(id)
			group_id = gu.group_id
			if value['delete'] == 'true'
				gu.destroy
			else
				role = value['editor'] == 'true' ? 'editor' : 'member'
				if gu.role != role
					gu.role = role
					gu.save!
				end
			end
		}
		group = Group.find(group_id)
		group.show_membership = show_membership == 'Yes'
		group.save!

		render :partial => 'group_details', :locals => { :group => Group.find(group_id), :user_id => get_curr_user_id() }
	end

	def render_license
		@group = Group.find(params[:id])
		render :partial => 'group_license', :locals => { :group => @group, :user_id => get_curr_user_id() }
	end
	
	def remove_profile_picture
		id = params[:id]
    group = Group.find(id)
		group.image = nil
		group.save
    redirect_to :back
	end

	def edit_thumbnail
		group_id = params[:id]
		group = Group.find(group_id)
		image = params['image']
		if image && image
			image = Image.new({ :uploaded_data => image })
#			if image	# If there were an error in uploading the image, don't go further.
#				begin
#					user.image.save!
#					user.save
#				rescue
#					flash = "ERROR: The image you have uploaded is too large or of the wrong type.<br />The file name must end in .jpg, .png or .gif, and cannot exceed 1MB in size."
#				end
		end
		begin
			group.image = image
			if group.save
				group.image.save! if group.image
				flash = "OK:Thumbnail updated"
			else
				flash = "Error updating thumbnail"
			end
		rescue
			flash = "ERROR: The image you have uploaded is too large or of the wrong type.<br />The file name must end in .jpg, .png or .gif, and cannot exceed 1MB in size."
		end
    render :text => "<script type='text/javascript'>window.top.window.stopEditGroupThumbnailUpload('#{flash}');</script>"  # This is loaded in the iframe and tells the dialog that the upload is complete.
	end

  # GET /groups
  # GET /groups.xml
#  def index
#    @groups = Group.all
#
#    respond_to do |format|
#      format.html # index.html.erb
#      format.xml  { render :xml => @groups }
#    end
#  end

  # GET /groups/1
  # GET /groups/1.xml
  def show
		if params[:id] == 'verify_group_title'
			title = params[:name]
			group = Group.find_by_name(title)
			if group == nil
				render :text => "ok"
			else
				render :text => "There is already a group with this title.", :status => :bad_request
			end
		else
			@group = Group.find(params[:id])

			respond_to do |format|
				format.html # show.html.erb
				format.xml  { render :xml => @group }
			end
		end
  end

  # GET /groups/new
  # GET /groups/new.xml
#  def new
#    @group = Group.new
#
#    respond_to do |format|
#      format.html # new.html.erb
#      format.xml  { render :xml => @group }
#    end
#  end

  # GET /groups/1/edit
#  def edit
#    @group = Group.find(params[:id])
#  end

#	def show_cluster
#			@cluster = Cluster.find(params[:id])
#			@group = Group.find(@cluster.group_id)
#
#	end

	def create_cluster
		begin
			if params['image'] && params['image'].length > 0
				image = Image.new({ :uploaded_data => params['image'] })
			end
			cluster = Cluster.new(params[:cluster])
			cluster.image = image
			err = false
			if cluster.save
				begin
					cluster.image.save! if cluster.image
				rescue
					err = true
					cluster.delete
					flash = "ERROR: The image you have uploaded is too large or of the wrong type.<br />The file name must end in .jpg, .png or .gif, and cannot exceed 1MB in size."
				end
				if err == false
					flash = "OK:#{cluster.group_id}"
				end
			else
				flash = "Error creating cluster"
			end
		rescue
			flash = "Server error when creating cluster."
		end
    render :text => "<script type='text/javascript'>window.top.window.stopNewClusterUpload('#{flash}');</script>"  # This is loaded in the iframe and tells the dialog that the upload is complete.
	end

	def group_exhibits_list
		if params[:cluster_id]
			cluster = Cluster.find(params[:cluster_id])
			render :partial => '/groups/group_exhibits_list', :locals => { :group => Group.find(cluster.group_id), :cluster => cluster, :user_id => get_curr_user_id() }
		else
			render :partial => '/groups/group_exhibits_list', :locals => { :group => Group.find(params[:id]), :user_id => get_curr_user_id() }
		end
	end

  # POST /groups
  # POST /groups.xml
  def create
		begin
			if params['image'] && params['image'].length > 0
				image = Image.new({ :uploaded_data => params['image'] })
	#			if image	# If there were an error in uploading the image, don't go further.
	#				begin
	#					user.image.save!
	#					user.save
	#				rescue
	#					flash = "ERROR: The image you have uploaded is too large or of the wrong type.<br />The file name must end in .jpg, .png or .gif, and cannot exceed 1MB in size."
	#				end
				end
			params[:group][:show_membership] = true if params[:group][:show_membership] == 'Yes'
			params[:group][:show_membership] = false if params[:group][:show_membership] == 'No'
			@group = Group.new(params[:group])
			@group.header_font_name = 'Arial'
			@group.header_font_size = '24'
			@group.text_font_name = 'Times New Roman'
			@group.text_font_size = '18'
			@group.illustration_font_name = 'Trebuchet MS'
			@group.illustration_font_size = '14'
			@group.caption1_font_name = 'Trebuchet MS'
			@group.caption1_font_size = '14'
			@group.caption2_font_name = 'Trebuchet MS'
			@group.caption2_font_size = '14'
			@group.endnotes_font_name = 'Times New Roman'
			@group.endnotes_font_size = '16'
			@group.footnote_font_name = 'Times New Roman'
			@group.footnote_font_size = '16'
			@group.use_styles = 0
			@group.image = image
			err = false
			if @group.save
				begin
					@group.image.save! if @group.image
				rescue
					err = true
					@group.delete
					flash = "ERROR: The image you have uploaded is too large or of the wrong type.<br />The file name must end in .jpg, .png or .gif, and cannot exceed 1MB in size."
				end
				if err == false
					flash = "OK:#{@group.id}"
					invitor = get_curr_user()
					@group.invite_members(invitor.fullname, invitor.email, params[:emails])
				end
			else
				flash = "Error creating group"
			end
		rescue
			flash = "Server error when creating group."
		end
    render :text => "<script type='text/javascript'>window.top.window.stopNewGroupUpload('#{flash}');</script>"  # This is loaded in the iframe and tells the dialog that the upload is complete.

#    respond_to do |format|
#      if @group.save
#        flash[:notice] = 'Group was successfully created.'
#        format.html { redirect_to(@group) }
#        format.html { redirect_to(@group) }
#        format.xml  { render :xml => @group, :status => :created, :location => @group }
#      else
#        format.html { render :action => "new" }
#        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
#      end
#    end
  end

  # PUT /groups/1
  # PUT /groups/1.xml
  def update
    @group = Group.find(params[:id])
		if params[:group]
			params[:group][:show_membership] = true if params[:group][:show_membership] == 'Yes'
			params[:group][:show_membership] = false if params[:group][:show_membership] == 'No'
			@group.update_attributes(params[:group])
		end

		err_msg = nil
		if params[:emails]
			invitor = get_curr_user()
			err_msg = @group.invite_members(invitor.fullname, invitor.email, params[:emails])
		end
#    respond_to do |format|
#      if @group.update_attributes(params[:group])
#        flash[:notice] = 'Group was successfully updated.'
#        format.html { redirect_to(@group) }
#        format.xml  { head :ok }
#      else
#        format.html { render :action => "edit" }
#        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
#      end
#    end
		curr_user = session[:user] == nil ? nil : User.find_by_username(session[:user][:username])
		if err_msg == nil
			render :partial => 'group_details', :locals => { :group => @group, :user_id => curr_user.id }
		else
			render :text => err_msg, :status => :bad_request
		end
  end

  # DELETE /groups/1
  # DELETE /groups/1.xml
  def destroy
    @group = Group.find(params[:id])
    @group.destroy

		# Also remove the exhibits and discussions from being in the group.
		exhibits = Exhibit.find_all_by_group_id(params[:id])
		exhibits.each { |exhibit|
			exhibit.group_id = nil
			exhibit.save!
		}
		threads = DiscussionThread.find_all_by_group_id(params[:id])
		threads.each { |thread|
			thread.group_id = nil
			thread.save!
		}
		groupsusers = GroupsUser.find_all_by_group_id(params[:id])
		groupsusers.each { |gu|
			gu.destroy
		}
		redirect_to :controller => 'exhibits', :action => "index"
#    respond_to do |format|
#      format.html { redirect_to(groups_url) }
#      format.xml  { head :ok }
#    end
  end
end
