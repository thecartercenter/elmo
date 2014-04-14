module ApplicationHelper

  FONT_AWESOME_ICON_MAPPINGS = {
    :clone => "copy",
    :destroy => "trash-o",
    :edit => "pencil",
    :map => "globe",
    :print => "print",
    :publish => "arrow-up",
    :remove => "times",
    :sms => "comment",
    :unpublish => "arrow-down",
    :submit => "share-square-o",
    :response => "check-circle-o",
    :report_report => "bar-chart-o",
    :report => "bar-chart-o",
    :form => "file-text-o",
    :question => "question-circle",
    :option_set => "list-ul",
    :optionset => 'list-ul',
    :user => "users",
    :broadcast => "bullhorn",
    :setting => "gear",
    :mission => "briefcase"
  }

  ERROR_MESSAGE_KEYS_TO_HIDE = {
    :'optionings.option.base' => true,
    :'condition.base' => true
  }

  # pairs flash errors with bootstrap styling
  def bootstrap_flash_class(level)
    case level
      when :notice then "alert alert-info"
      when :success then "alert alert-success"
      when :error then "alert alert-danger"
      when :alert then "alert alert-warning"
      else nil
    end
  end

  # returns the html for an action icon using font awesome and the mappings defined above
  def action_link(action, href, html_options = {})
    # join passed html class (if any) with the default class
    html_options[:class] = [html_options[:class], "action_link", "action_link_#{action}"].compact.join(" ")

    link_to(content_tag(:i, "", :class => "fa fa-" + FONT_AWESOME_ICON_MAPPINGS[action.to_sym]), href, html_options)
  end

  # assembles links for the basic actions in an index table (edit and destroy)
  def action_links(obj, options)
    route_key = obj.class.model_name.singular_route_key

    options[:exclude] = Array.wrap(options[:exclude])

    # always exclude edit and destroy if we are in show mode
    options[:exclude] += [:edit, :destroy] if controller.action_name == 'show'

    # build links
    %w(edit destroy).map do |action|

      # skip to next action if action is excluded
      next if options[:exclude].include?(action.to_sym)

      case action
      when "edit"
        # check permissions
        next unless can?(:update, obj)

        # build link
        action_link(action, send("edit_#{route_key}_path", obj), :title => t("common.edit"))

      when "destroy"
        # check permissions
        next unless can?(:destroy, obj)

        # build a delete warning
        obj_description = options[:obj_name] ? "#{obj.class.model_name.human} '#{options[:obj_name]}'" : options[:obj_description]
        warning = t("layout.delete_warning", :obj_description => obj_description)

        # build link
        action_link(action, send("#{route_key}_path", obj), :method => :delete, :confirm => warning, :title => t("common.delete"))
      end

    end.join('').html_safe
  end

  # creates a link to a batch operation
  def batch_op_link(options)
    link_to(options[:name], "#",
      :onclick => "batch_submit({path: '#{options[:path]}', confirm: '#{options[:confirm]}'}); return false;",
      :class => "batch_op_link")
  end

  # creates a link to select all the checkboxes in an index table
  def select_all_link
    link_to(t("layout.select_all"), '#', :onclick => "batch_select_all(); return false", :id => 'select_all_link')
  end

  # renders an index table for the given class and list of objects
  # options[:within_form] - Whether the table is contained within a form tag. Affects whether a form tag is generated
  #   to contain the batch op checkboxes.
  def index_table(klass, objects, options = {})
    links = []

    unless options[:table_only]
      # get links from class' helper
      links = send("#{klass.model_name.route_key}_index_links", objects).compact

      # if there are any batch links, insert the 'select all' link
      batch_ops = !links.reject{|l| !l.match(/class="batch_op_link"/)}.empty?
      links.insert(0, select_all_link) if batch_ops
    end

    # render, getting fields and checking if there are no objects at all
    render("layouts/index_table",
      :klass => klass,
      :objects => objects,
      :options => options,
      :paginated => objects.respond_to?(:total_entries),
      :links => links.flatten.join.html_safe,
      :fields => send("#{klass.model_name.route_key}_index_fields"),
      :batch_ops => batch_ops
    )
  end

  # renders a loading indicator image wrapped in a wrapper
  def loading_indicator(options = {})
    content_tag("div", :class => "loading_indicator loading_indicator#{options[:floating] ? '_floating' : '_inline'}", :id => options[:id]) do
      image_tag("load-ind-small#{options[:header] ? '-header' : ''}.gif", :style => "display: none", :id => "loading_indicator" +
        (options[:id] ? "_#{options[:id]}" : ""))
    end
  end

  # returns a set of [name, id] pairs for the given objects
  # defaults to using .name and .id, but other methods can be specified, including Procs
  # if :tags is set, returns the <option> tags instead of just the array
  def sel_opts_from_objs(objs, options = {})
    # set default method names
    id_m = options[:id_method] ||= "id"
    name_m = options[:name_method] ||= "name"

    # get array of arrays
    arr = objs.collect do |o|
      # get id and name array
      id = id_m.is_a?(Proc) ? id_m.call(o) : o.send(id_m)
      name = name_m.is_a?(Proc) ? name_m.call(o) : o.send(name_m)
      [name, id]
    end

    # wrap in tags if requested
    options[:tags] ? options_for_select(arr) : arr
  end

  # finds the english name of the language with the given code (e.g. 'French' for 'fr')
  # tries to use the translated locale name if it exists, otherwise use english language name from the iso639 gem
  # returns code itself if code not found
  def language_name(code)
    if configatron.full_locales.include?(code)
      t(:locale_name, :locale => code)
    else
      (entry = ISO_639.find(code.to_s)) ? entry.english_name : code.to_s
    end
  end

  # wraps the given content in a js tag and a jquery ready handler
  def javascript_doc_ready(&block)
    content = capture(&block)
    javascript_tag("$(document).ready(function(){#{content}});")
  end

  # takes an array of keys and a scope and builds an options array (e.g. [["Option 1", "opt1"], ["Option 2", "opt2"], ...])
  def translate_options(keys, scope)
    keys.map{|k| [t(k, :scope => scope), k]}
  end

  # generates a link like "Create New Option Set" given a klass
  # options[:js] - if true, the link just points to # with expectation that js will bind to it
  def create_link(klass, options = {})
    # get the link target path. honor the js option.
    href = options[:js] ? "#" : send("new_#{klass.model_name.singular_route_key}_path")

    link_to(t("#{klass.model_name.i18n_key}.create_link"), href, :class => "create_#{klass.model_name.param_key}")
  end

  # translates a boolean value
  def tbool(b)
    t(b ? "common._yes" : "common._no")
  end

  # if the given array is not paginated, apply an infinite pagination so the will_paginate methods will still work
  def prepare_for_index(objs)
    objs = if !objs.respond_to?(:total_entries) && objs.respond_to?(:paginate)
      objs.paginate(:page => 1, :per_page => 1000000)
    else
      objs
    end

    # ensure .all gets called so that a bunch of extra queries don't get triggered
    objs = objs.all if objs.respond_to?(:all)

    objs
  end

  def translate_model(model)
    pluralize_model(model, :count => 1)
  end

  # gets or constructs the page title from the translation file or from an explicitly set @title
  # returns empty string if no translation found and no explicit title set
  # looks for special :standard option in @title_args, shows seal if set
  # options[:text_only] - don't return any images or html
  def title(options = {})
    # use explicit title if given
    return @title unless @title.nil?

    @title_args ||= {}

    # if action specified outright, use that
    action = if @title_action
      @title_action
    else
      # use 'new' and 'edit' for 'update' and 'create', respectively
      case action_name
      when "update" then "edit"
      when "create" then "new"
      else action_name
      end
    end

    ttl = ''
    model_name = controller_name.classify.downcase

    # add icon where appropriate
   if !options[:text_only] && (icon_name = FONT_AWESOME_ICON_MAPPINGS[model_name.to_sym])
      ttl += content_tag(:i, "", :class => "fa fa-" + icon_name)
    end

    # add text
    ttl += t(action, {:scope => "page_titles.#{controller_name}", :default => [:all, ""]}.merge(@title_args || {}))



    ttl.html_safe
  end

  # pluralizes an activerecord model name
  # assumes 2 if count not given in options
  def pluralize_model(klass, options = {})
    klass = klass.constantize if klass.is_a?(String)
    t("activerecord.models.#{klass.model_name.i18n_key}", :count => options[:count] || 2)
  end

  # translates and interprets markdown markup
  def tmd(*args)
    html = BlueCloth.new(t(*args)).to_html

    if html[0,3] == '<p>' && html[-4,4] == '</p>'
      html = html[3..-5]
    end

    html.html_safe
  end

  # makes sure error messages look right
  def format_validation_error_messages(obj, options = {})
    messages = obj.errors.map do |attrib, message|
      # if error message key is in special list, don't show full message
      ERROR_MESSAGE_KEYS_TO_HIDE[attrib] ? message : obj.errors.full_message(attrib, message)
    end

    # join all messages into one string
    message = messages.join(', ')

    # add a custom prefix if given
    if options[:prefix]
      # remove the inital cap also
      message = options[:prefix] + ' ' + message.gsub(/^([A-Z])/){$1.downcase}
    end

    # add Error: unless in compact mode
    unless options[:compact]
      message = t("common.error", :count => obj.errors.size) + ": " + message
    end

    message
  end

  # returns img tag for standard icon if obj is standard, '' otherwise
  def std_icon(obj)
    if obj.respond_to?(:standardized?) && obj.standardized?
      content_tag(:i, "", :class => "fa fa-certificate")
    else
      ''
    end
  end

  # makes a set of <li> wrapped links to the index actions of the given classes
  def nav_links(*klasses)
    l = []
    klasses.each do |k|
      if can?(:index, k)
        path = send("#{k.model_name.route_key}_path")
        active = current_page?(path)
        l << content_tag(:li, :class => active ? 'active' : '') do
          link_to(path) do
            content_tag('i', '', :class => 'fa fa-' + FONT_AWESOME_ICON_MAPPINGS[k.model_name.param_key.to_sym]) +
            pluralize_model(k)
          end
        end
      end
    end
    l.join.html_safe
  end

  # tries to get a path for the given object, returns nil if object doesn't have route
  # preserves the search param in the current query string, if any
  def path_for_with_search(obj)
    begin
      polymorphic_path(obj, :search => params[:search])
    rescue
      nil
    end
  end
end
