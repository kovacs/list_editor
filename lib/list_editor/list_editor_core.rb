module ListEditor
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    # Class method to inject AJAX CRUD actions for an AJAX list editor
    #
    # usage: list_editor Class, <form partial>, options
    #
    # example:
    #
    # class WidgetsController < ActionController::Base
    #   list_editor Widget, 'widgets/widget_form',
    #                       :display_property => 'name',
    #                       :view_properties => ['created_at', 'size']
    #
    # available options:
    # display_property - The object attribute used as the display label for the object in the list
    # display_partial - The path to a partial used as the display for the object in the list instead of a property
    #                   For example: 'line_items/item'
    #                                This might contain the name of the product and the price
    #
    # view_properties - Optional properties to display for a given object in the UI in a collapsable box under the list entry
    #
    # edit_image - Icon displayed for the 'edit' action
    # delete_image - Icon displayed for the 'delete' action
    #
    # show_edit - A Proc to determine whether or not an edit link should be displayed - true by default
    # show_delete - A Proc to determine whether or not a delete link should be displayed - true by default
    # show_add - A Proc to determine whether or not an add link should be displayed - true by default
    #
    # The "Show" parameters
    #
    # The three "show" parameters are used to control what actions show be available on the list and list items.
    # A Proc object is used so that you can determine dynamically what actions you'd like to show.
    #
    # The show_add Proc object is called by list_editor with no params passed.
    # The show_edit and show_delete Proc objects are called by list_editor and passed the individual object
    # for you to determine whether or not edit or delete should be shown for that particular object.
    # For example:
    #
    #    {:show_edit => Proc.new {|user| user.admin?}} - Do we allow editing of admin users in a list?
    #    {:show_edit => Proc.new {current_user.admin?} - Only allow admins to edit these list items
    #    {:show_delete => Proc.new {|line_item| line_item.order.pending?}} - Only allow deletion of line items from a pending order
    #
    # If you'd like to simply disable any of the "show" parameters simply return false from a Proc like so:
    #   {:show_edit => Proc.new {false}}
    #
    # list_id - The id of the <ul> that's generated. Default is 'classname'_list
    # description - The description used when you mouseover add/edit/delete links
    #
    def list_editor(class_to_edit, form_partial, options={})
      before_filter :find_object, :only => [:edit, :update, :destroy, :show]

      @@list_editor_options ||= HashWithIndifferentAccess.new

      options = {:display_property => 'to_s',
                               :view_properties => [],
                               :edit_image => 'list_editor/pencil.png',
                               :delete_image => 'list_editor/cross.png',
                               :show_edit => Proc.new {true},
                               :show_delete => Proc.new {true},
                               :show_add => Proc.new {true},
                               :list_id => "#{class_to_edit.to_s.underscore}_list",
                               :hide => false,
                               :description => class_to_edit.to_s.demodulize,
                               :size => ''}.merge(options)
      @@list_editor_options[controller_name] = {'form' => form_partial,
                                                'class' => class_to_edit,
                                                'options' => options}


      module_eval do
        # install CRUD methods that are generic and dynamic
        include ListEditor::InstanceMethods
        include ListEditorHelper

        # attributes used when dynamically CRUDing
        def klass
          @@list_editor_options[controller_name]['class']
        end

        def list_editor_form
          @@list_editor_options[controller_name]['form']
        end

        def list_editor_options
          @@list_editor_options[controller_name]['options']
        end
      end

    end

  end

  module InstanceMethods

    # filter used to fetch the object. Override in your controller for different behavior
    protected
    def find_object
      @object = klass.find(params[:id])
    end

    public
    def new
      @object = klass.new
      @title = list_editor_options[:add_title].blank? ? "Add a new #{klass.to_s} to your list" : list_editor_options[:add_title]
      render :partial => 'list_editor/dialog',
        :locals => {:edit_object => @object,
        :url => build_url('create', klass), # REVIEW allow for overrides
        :form_partial => list_editor_form,
        :title => @title}
    end

    def create
      # optional lambda/proc to create a new object for when it needs to be nested
      if list_editor_options[:create]
        @object = eval list_editor_options[:create]
      else
        @object = klass.create(params[klass.to_s.underscore])
      end
      setup_update
      render :template => 'list_editor/add_entry', :layout => false
    end

    def edit
      @title = "Edit #{klass.to_s}"

      render :partial => 'list_editor/dialog',
        :locals => {:edit_object => @object,
        :url => build_url('update', klass, @object),
        :form_partial => list_editor_form,
        :title => @title}
    end

    def update
      @object.update_attributes(params[klass.to_s.underscore])
      setup_update
      render :template => 'list_editor/edit_entry', :layout => false
    end

    def destroy
      @object.destroy
      setup_update
      render :template => 'list_editor/delete_entry', :layout => false
    end

    private

    def setup_update
      @entry = @object
      @successful = @entry && @entry.valid?
      @show_edit = list_editor_options[:show_edit]
      @show_delete = list_editor_options[:show_delete]
      if list_editor_options[:display_partial]
        @display_partial = list_editor_options[:display_partial]
      else
        @display_prop = list_editor_options[:display_property]
      end
      @view_properties = list_editor_options[:view_properties]
      @edit_image = list_editor_options[:edit_image]
      @delete_image = list_editor_options[:delete_image]
      @list_id = list_editor_options[:list_id]
      @form = list_editor_form
      @size = list_editor_options[:size]
    end

  end
end
