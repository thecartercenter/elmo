class ELMO.Views.UserGroupsModalView extends Backbone.View
  el: '#user-groups-modal'

  events:
    "ajax:success": "process_response"
    "click a.action_link_update": "update_name"

  initialize: (params) ->
    @params = params
    @set_body(params.html)

  set_body: (html) ->
    @$('.modal-body').html(html)

  show: ->
    $(@el).modal('show')

  update_name: (e) ->
    e.preventDefault();
    target_url = $(e.currentTarget).attr("href")
    target_value = $(e.currentTarget).closest("tr").find("input").val()
    $.ajax
      url: target_url
      method: "patch"
      data: { name: target_value }
      success: (data) =>
        @$(e.currentTarget).closest("tr").find(".name_col").html("<div>" + data.name + "</div>")


  process_response: (e, data, status, xhr) ->
    event_target = e.target
    if @$(event_target).hasClass("action_link_destroy")
      target_row = $(event_target).closest("tr")
      @$(target_row).remove()
      @$(".header.link_set").html(data.page_entries_info)
    else if @$(event_target).hasClass("action_link_edit")
      target_field = $(event_target).closest("tr").find(".name_col")
      @$(target_field).html(data)
