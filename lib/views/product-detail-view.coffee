{$, $$, $$$, View} = require 'atom-space-pen-views'
util = require 'util'

module.exports =
class ProductDetailView extends View
  handleEvents: (@emitter)->
    if @initialized || !@emitter then return else @initialized = true
    @on 'click', '#create-tasks', =>
      @emitter.emit 'tasks.create', @product.name

  @content: (params) ->
    @div outlet:'$detail', class: 'product-detail-view-content'

  setProduct: (@product)->
    @draw()

  draw: ->
    return unless @product && @product.name
    @html @getDetail(@product)

  getDetail: (product) ->
    $$ ->
      @h1 "#{product.name}"
      # TODO:30 This will have to be upadted on an event sent with pusher
      @div class:'block', =>
        if product.enabled
          @a href:product.logout, class:'btn icon icon-log-out inline-block-tight', "unlink your #{product.name} account"
          @button id:'create-tasks', class:'btn icon icon icon-cloud-upload inline-block-tight', "create #{product.entity}s on #{product.name}"
        else
          @a href:product.login, class:'btn icon icon-log-in inline-block-tight', "link your #{product.name} account"