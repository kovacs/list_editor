module ListEditorHelper
  # Creates a <ul> with the given objects that's intended to provide AJAX CRUD operations
  # Unless specified options are taken from the list_editor controller declaration in the
  # corresponding controller providing the actions for the declared list_editor
  #
  # example usage:
  #
  #      class FooController < ApplicationController
  #        list_editor Foo, 'foos/foo_form', :display_property => 'name'
  #      end
  #
  #      ---------------
  #      Foos index.html.erb page
  #      <% create_list_editor @foos %>
  #      ---------------
  #
  # option parameters:
  #
  # controller - Explicitly declare the controller that is used to edit the items in the list. The
  #              default is the current controller whose context this helper is being invoked within.
  #              If you call this helper from a page called from FoosController that's the controller
  #              that's assumed to provide the options and operations for this list_editor. Sometimes this is
  #              not that case.
  #
  #              For example if you wanted to provide a list_editor for the line items in an order and
  #              the page displaying the order is the orders_controller and the list_editor is declared in
  #              the line_items_controller you'd specify:
  #
  #     class LineItemsController < ApplicationController
  #       list_editor LineItem, 'shared/order', :display_partial => 'line_items/item',
  #                                             :show_edit => Proc.new {false},
  #                                             :show_add => Proc.new {false},
  #                                             :show_delete => Proc.new {|i| i.order.pending?}
  #     end
  #
  #     ----------------
  #     Order show page
  #     ...
  #
  #     <% create_list_editor order.line_items, :controller => 'LineItemsController' %>
  #
  #     End of order show page
  #     ----------------
  #
  #     View callbacks
  #     If you wish to perform additional UI changes on top of the ones made by default in the list editor you can define
  #     callbacks for the action you'd like to hook into. Simply define a helper method for one or more of the following callbacks:
  #
  #     post_create_callback
  #     post_edit_callback
  #     post_delete_callback
  #
  #     You callback will be called from the create, update, or destroy action's RJS template after all the list editor updates
  #     have been performed.
  #
  def create_list_editor(objects, options={})
    # sometimes the controller that's declaring the list_editor isn't the current controller.. need to get the right one
    controller = options[:controller]
    link_text = options[:link_text]
    link_class = options[:class]

    if controller.blank?
      controller = self.controller
    else
      controller = controller.constantize.new
    end

    options = controller.list_editor_options
    link_text ||= "Add a new #{options[:description]}"
    title_text ||= "Add #{options[:description].capitalize}"
    link_class ||= ''

    concat("<ul id='#{options[:list_id]}'>")
    objects.each do |o|
      concat(create_list_entry(o, options, controller))
    end
    concat("</ul>")
    if options[:show_add].call
      concat(link_to(link_text, build_url('new', controller.klass, nil, controller),
                          :class => "lbOn #{link_class}", :rel => options[:size], :title => title_text))
    end
  end

  OP_PREFIXES = {'new' => 'new_',
                'create' => '',
                'edit' => 'edit_',
                'update' => '',
                'delete' => ''}

  OP_POSTFIXES = {'new' => '_path',
                         'create' => 's_path',
                         'edit' => '_path',
                         'update' => '_path',
                         'delete' => '_path'}

  # this method requires a @resource_parents variable to be set if you wish
  # to CRUD elements as a nested resource. The @resource_parents variable needs
  # to be set in any controller where the create_list_editor helper method is invoked
  #
  # Example:
  #
  # If for example you are going to edit "Children" objects from a page on your Parent controller
  # you would do the following:
  #
  # class ParentController < ApplicationController
  #   before_filter :setup_resource
  #
  #   def setup_resource
  #     @resource_parents = [@parent]
  #   end
  # end
  #
  # class ChildrenController < ApplicationController
  #   before_filter :find_parent
  #   before_filter :setup_resource
  #   list_editor Child, 'children/child_form', :display_property => 'name', :create => "find_parent.children.create(params['child'])"
  #
  #   def find_object
  #     @object = @parent.children.find(params[:id])
  #   end
  #
  #   def setup_resource
  #     @resource_parents = [@parent]
  #   end
  # end
  #
  # Then in show.erb for ParentController you'd have
  #      <% create_list_editor(@parent.children, :controller => 'ChildrenController') %>
  #
  def build_url(operation, klass, object=nil, controller=nil)
    if controller.nil?
      controller = self
    end
    if controller.list_editor_options[:urls] && controller.list_editor_options[:urls][operation]
      path = controller.list_editor_options[:urls][operation]
      custom_path = true
    else
      path = OP_PREFIXES[operation]
    end
    if @resource_parents
      if !custom_path
        @resource_parents.each do |res|
          path += "#{res.class.to_s.underscore}_"
        end
        path += "#{klass.to_s.underscore}#{OP_POSTFIXES[operation]}"
      end
      resources = Array.new @resource_parents
      if object
        resources << object
      end
      @url = send(path, *resources)
    else
      if !custom_path
        path += "#{klass.to_s.underscore}#{OP_POSTFIXES[operation]}"
      end
      if object
        @url = send(path, object)
      else
        @url = send(path)
      end
    end
    return @url
  end

  def create_list_entry(object, options={}, controller=self.controller)
    opts = controller.list_editor_options.merge(options)
    if opts[:show_edit].call(object)
      opts[:edit_action] = build_url('edit', controller.klass, object, controller)
    end
    if opts[:show_delete].call(object)
      opts[:delete_action] =  build_url('delete', controller.klass, object, controller)
    end
    render(:partial => 'list_editor/list_entry', :object => object, :locals => opts)
  end

  def entry_display(entry, display_prop)
    auto_link_new(h(entry.send(display_prop.to_s).to_s))
  end

  def busy_icon(display=false, el_id='busy')
    style = 'height: 16px; width: 16px;'
    if !display
      style += ' display: none;'
    end
    image_tag('list_editor/indicator.gif', :id => el_id, :style => style)
  end

  def better_simple_format(text)
    result = simple_format(text)
    result = text.gsub("\r\n", '<br/>')
    result = result.gsub("\r\n\r\n", '<br/><br/>')
    result = '<p>' + result + '</p>'
  end

  def auto_link_new(text)
    auto_link(text, :all, :target => '_blank')
  end

  # FIXME/REVIEW 3/17/07 look at changing this to a more flexible impl: http://snippets.dzone.com/posts/show/3623
  def build_container_start(title=nil, ui_class='pm_display_table')
    result = '<table class="' + ui_class + '" cellpadding="0" cellspacing="0">'
  end

  def close_container
    '</table>'
  end

  def required_icon
    '<span class="required_label">*</span>'
  end

  def build_id(name)
    no_spaces = name.delete(' ')
    id = no_spaces+'_view'
  end

  def build_name_value_row(name, value, required_image=nil, tooltip=false, wrap=false, row_id=nil, display=true)
    name = h(name)
    no_spaces = name.delete(' ')
    id = build_id(name)
    required_image = required_image.nil? ? '' : required_image
    if tooltip
      tooltip_id = build_tt(name)
      tt = ' ' + build_tt_image(tooltip_id)
    else
      tt = ''
    end

    if row_id
      row_params = {:id => row_id}
      if !display # display flag will only ever be used in conjunction with id
        row_params[:style] = 'display: none;'
      end
    else
      row_params = {}
    end
    label_params = {:class => 'label', :nowrap => 'nowrap'}
    value_params = {:class => 'value', :id => id}
    if !wrap
      value_params[:nowrap] = 'nowrap'
    end
    result = content_tag('tr',
      content_tag('td', required_image +
          content_tag('label', name, :for => id) + ':', label_params) +
        content_tag('td', value + tt, value_params), row_params)
    return result

  end

  def build_name_value(name, value, required=true, tooltip=false, wrap=false, row_id=nil, display=true)
    if required
      required_image = required_icon
    end
    build_name_value_row(name, value, required_image, tooltip, wrap, row_id, display)
  end
end
