_                      = require 'lodash'
Datastore              = require 'meshblu-core-datastore'
mongojs                = require 'mongojs'
IotAppConfigurationSaver = require '..'

describe 'IotAppConfigurationSaver', ->
  beforeEach ->
    db = mongojs 'localhost/flow-config-test', ['instances']
    @datastore = new Datastore
      database: db
      collection: 'instances'

  afterEach (done) ->
    db = mongojs 'localhost/flow-config-test', ['instances']
    db.instances.drop done

  beforeEach ->
    @sut = new IotAppConfigurationSaver {@datastore}

  describe '->save', ->
    beforeEach (done) ->
      @flowData =
        router:
          config: {}
          data: {}

      @sut.save appId: 'some-bluprint-uuid', version: '1', flowData: @flowData, done

    it 'should save to mongo', (done) ->
      @datastore.findOne {appId: 'some-bluprint-uuid', version: '1'}, (error, {flowData}) =>
        return done error if error?
        expect(JSON.parse flowData).to.deep.equal @flowData
        done()

  describe '->stop', ->
    describe 'with one instance', ->
      beforeEach (done) ->
        @flowData =
          router:
            config: {}
            data: {}

        @sut.save appId: 'some-bluprint-uuid', version: '1', flowData: @flowData, done

      beforeEach (done) ->
        @sut.stop appId: 'some-bluprint-uuid', version: '1', done

      it 'should remove the configuration', (done) ->
        @datastore.findOne appId: 'some-bluprint-uuid', version: '1', (error, result) =>
          expect(result).not.to.exist
          done error

    describe 'with two instances', ->
      beforeEach (done) ->
        @flowData =
          router:
            config: {}
            data: {}

        @sut.save appId: 'some-bluprint-uuid', version: '1', flowData: @flowData, done

      beforeEach (done) ->
        @flowData = 'other instance'

        @sut.save appId: 'some-bluprint-uuid', version: 'other-instance-id', flowData: @flowData, done

      beforeEach (done) ->
        @sut.stop appId: 'some-bluprint-uuid', version: '1', done

      it 'should remove the stop configuration', (done) ->
        @datastore.findOne {appId: 'some-bluprint-uuid', version: '1'}, (error, result) =>
          return done error if error?
          expect(result).not.to.exist
          done()

  describe '->linkToBluprint', ->
    beforeEach 'insert flow', (done) ->
      @flowData = JSON.stringify {
        node1:
          config: { bees: true }
          data: {}
        node2:
          config: {bee_size: '4000m'}
          data: {}
      }

      @datastore.insert flowId: 'some-flow-id', instanceId: 'some-instance-id', flowData: @flowData, done

    beforeEach 'run linkToBluprint', (done) ->
      options =
        appId: 'some-app-id'
        config: {bee_color: 'blue'},
        configSchema: { type: 'string' }
        flowId: 'some-flow-id'
        instanceId: 'some-instance-id'
        version: '1'

      @sut.linkToBluprint options, done

    beforeEach 'get flow', (done) ->
      @flowData = JSON.stringify {
        node1:
          config: { bees: true }
          data: {}
        node2:
          config: {bee_size: '4000m'}
          data: {}
      }

      @datastore.findOne flowId: 'some-flow-id', instanceId: 'some-instance-id', (error, {flowData, @bluprint}) =>
        @flowData = JSON.parse(flowData)
        done()


    it 'should update the flow data with the bluprint config', ->
      expect(@flowData).to.deep.equal
        node1:
          config: { bees: true }
          data: {}
        node2:
          config: {bee_size: '4000m'}
          data: {}
        bluprint:
          config:
            appId: 'some-app-id'
            config: {bee_color: 'blue'},
            configSchema: { type: 'string' }
            version: '1'


    it 'should write a pointer to the bluprint', ->
      expect(@bluprint).to.deep.equal
        appId: 'some-app-id'
        version: '1'
