_ = require 'lodash'
helper = require './imdone-helper'
log = require('debug/browser') 'imdone-atom:connector-manager'
{Emitter} = require 'atom'

module.exports =
class ConnectorManager extends Emitter
  products: null
  constructor: (@repo) ->
    super
    @client = require('./imdoneio-client').instance
    @handleEvents()
    # READY:20 Check for updates to products/connectors and update @products with changes

  handleEvents: ->
    @client.on 'product.linked', (product) =>
      @setProduct product, (err, product) =>
        @emit 'product.linked', product unless err

    @client.on 'product.unlinked', (product) =>
      @setProduct product, (err, product) =>
        @emit 'product.unlinked', product unless err

    # @client.on 'connector.enabled', (connector) => @setConnector connector
    #
    # @client.on 'connector.disabled', (connector) => @setConnector connector
    #
    # @client.on 'connector.changed', (connector) => @setConnector connector
    #
    # @client.on 'connector.created', (connector) => @setConnector connector

  projectId: () -> @client.getProjectId @repo

  getProducts: (cb) ->
    cb = (()->) unless cb
    return cb(null, @products) if @products
    @client.getProducts @projectId(), (err, products) =>
      return cb err  if err
      @enhanceProduct product for product in products
      @products = products
      cb null, products

  getProduct: (provider, cb) ->
    @getProducts (err, products) ->
      cb err, _.find products, name: provider

  setProduct: (newProduct, cb) ->
    cb = (()->) unless cb
    @getProduct newProduct.name, (err, product) ->
      return cb err  if err
      _.assign product, newProduct
      product.linked = newProduct.linked
      _.set product, 'connector.enabled', _.get(newProduct, 'connector.enabled')
      cb null, product

  setConnector: (connector, cb) ->
    @getProduct connector.name, (err, product) =>
      return cb err  if err
      product.connector = connector
      @enhanceProduct  product
      cb null, connector

  saveConnector: (connector, cb) ->
    cb = (()->) unless cb
    return @createConnector connector, cb unless connector.id
    @updateConnector connector, cb

  createConnector: (connector, cb) ->
    @client.createConnector @repo, connector, cb

  updateConnector: (connector, cb) ->
    @client.updateConnector @repo, connector, (err, connector) =>
      return cb err if err
      @setConnector connector, cb

  enableConnector: (connector, cb) ->
    @client.enableConnector @repo, connector, (err, connector) =>
      return cb err if err
      @setConnector connector, cb

  disableConnector: (connector, cb) ->
    @client.disableConnector @repo, connector, (err, connector) =>
      return cb err if err
      @setConnector connector, cb

  getGitOrigin: () ->
    repo = helper.repoForPath @repo.getPath()
    return null unless repo
    repo.getOriginURL()

  enhanceProduct: (product) ->
    product.connector.defaultSearch = product.defaultSearch if product.connector
    _.mixin product,
      isLinked: () -> this.linked
      isEnabled: () -> this.linked && this.connector && this.connector.enabled