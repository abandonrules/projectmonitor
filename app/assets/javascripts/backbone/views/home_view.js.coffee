ProjectMonitor.Views ||= {}

class ProjectMonitor.Views.HomeView extends Backbone.View
  tagName: "ol"
  className: "projects"
  template: JST["backbone/templates/home"]

  initialize: (options) ->
    @_addTileView(tile) for tile in @collection.models

    @collection.on 'reset', =>
      for cid,view of @subViews
        view.tearDown()
      for model in @collection.models
        @_addTileView(model)
      @render()

    @collection.on 'add', (model) =>
      unless model.id in (view.model.id for cid,view of @subViews)
        @_addTileView(model)
        @render()

    @collection.on 'remove', (model) =>
      viewsToDelete = (view for cid,view of @subViews when view.model.id == model.id)
      for view in viewsToDelete
        view.tearDown()

  _addTileView: (model) ->
    if model.get("aggregate")
      view = new ProjectMonitor.Views.AggregateProjectView(model: model)
    else
      view = new ProjectMonitor.Views.ProjectView(model: model)
    @registerSubView(view)
    

  render: ->
    @$el.empty()
    @$el.append(subview.render().$el) for cid,subview of @subViews
    @
