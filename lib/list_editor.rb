require "list_editor/version"

module ListEditor
  VIEW_PATH = File.join(File.dirname(__FILE__), 'views')
  ActionController::Base.append_view_path(VIEW_PATH) unless ActionController::Base.view_paths.include?(VIEW_PATH)

  require 'list_editor/list_editor_core'
  require 'list_editor/list_editor_helper'

  ActionView::Base.send(:include, ListEditorHelper)
  ActionController::Base.send(:include, ListEditor)
end
