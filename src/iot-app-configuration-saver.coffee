async = require 'async'
crypto = require 'crypto'

class IotAppConfigurationSaver
  constructor: ({@datastore}) ->
    throw new Error 'IotAppConfigurationSaver requires datastore' unless @datastore?

  stop: ({appId, version}, callback) =>
    @datastore.remove {appId, version}, callback

  save: ({appId, version, flowData}, callback) =>
    flowData = JSON.stringify flowData
    hash = @hash flowData
    @datastore.insert {appId, version, flowData, hash}, callback

  linkToBluprint: ({appId, config, configSchema, flowId, instanceId, version}, callback) =>
    @datastore.findOne {flowId, instanceId}, (error, {flowData}) =>
      return callback error if error?
      flowData = JSON.parse flowData
      flowData.bluprint =
        config: {
          appId
          config
          configSchema
          version
        }
      flowData = JSON.stringify flowData
      @datastore.update {flowId, instanceId}, {$set: {flowData, bluprint: {appId, version}}}, callback

  hash: (flowData) =>
    crypto.createHash('sha256').update(flowData).digest 'hex'

module.exports = IotAppConfigurationSaver
