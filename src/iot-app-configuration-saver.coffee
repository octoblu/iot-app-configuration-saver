async = require 'async'

class IotAppConfigurationSaver
  constructor: ({@datastore}) ->
    throw new Error 'IotAppConfigurationSaver requires datastore' unless @datastore?

  stop: (options, callback) =>
    {appId, version} = options
    stopappId = "#{appId}-stop"
    @datastore.find {appId: stopappId}, (error, records) =>
      return callback error if error?
      async.each records, async.apply(@_replaceConfig, appId), callback

  _replaceConfig: (appId, record, callback) =>
    {version, flowData} = record
    stopappId = record.appId
    # remove old config
    @datastore.remove {appId, version}, (error) =>
      return callback error if error?
      # replace it with stop config
      @datastore.insert {appId, version, flowData}, (error) =>
        return callback error if error?
        # remove stop config
        @datastore.remove {appId: stopappId, version}, callback

  save: ({appId, version, flowData}, callback) =>
    flowData = JSON.stringify flowData  
    @datastore.insert {appId, version, flowData}, callback


module.exports = IotAppConfigurationSaver
