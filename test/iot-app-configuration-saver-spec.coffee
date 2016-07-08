_                      = require 'lodash'
Datastore              = require 'meshblu-core-datastore'
mongojs                = require 'mongojs'
IotAppConfigurationSaver = require '..'

describe 'IotAppConfigurationSaver', ->
  beforeEach (done) ->
    db = mongojs 'localhost/flow-config-test', ['instances']
    @datastore = new Datastore
      database: db
      collection: 'instances'
    db.instances.remove done

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
        @flowData = 'stop'

        @sut.save appId: 'some-bluprint-uuid-stop', version: '1', flowData: @flowData, done

      beforeEach (done) ->
        @sut.stop appId: 'some-bluprint-uuid', version: '1', done

      it 'should remove the stop configuration', (done) ->
        @datastore.findOne {appId: 'some-bluprint-uuid-stop', version: '1'}, (error, result) =>
          return done error if error?
          expect(result).not.to.exist
          done()

      describe 'after the config is removed', ->
        it 'should replace the configuration with the stop configuration', (done) ->
          @datastore.findOne {appId: 'some-bluprint-uuid', version: '1'}, (error, {flowData}) =>
            return done error if error?
            expect(JSON.parse flowData).to.equal 'stop'
            done()

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
        @flowData = 'stop'

        @sut.save appId: 'some-bluprint-uuid-stop', version: '1', flowData: @flowData, done

      beforeEach (done) ->
        @flowData = 'stop'

        @sut.save appId: 'some-bluprint-uuid-stop', version: 'other-instance-id', flowData: @flowData, done

      beforeEach (done) ->
        @sut.stop appId: 'some-bluprint-uuid', version: '1', done

      it 'should remove the stop configuration', (done) ->
        @datastore.findOne {appId: 'some-bluprint-uuid-stop', version: '1'}, (error, result) =>
          return done error if error?
          expect(result).not.to.exist
          done()

      describe 'after the config is removed', ->
        it 'should replace the configuration with the stop configuration', (done) ->
          @datastore.findOne {appId: 'some-bluprint-uuid', version: '1'}, (error, {flowData}) =>
            return done error if error?
            expect(JSON.parse flowData).to.equal 'stop'
            done()

        it 'should change the other instance', (done) ->
          @datastore.findOne {appId: 'some-bluprint-uuid', version: 'other-instance-id'}, (error, {flowData}) =>
            return done error if error?
            expect(JSON.parse flowData).to.equal 'stop'
            done()
