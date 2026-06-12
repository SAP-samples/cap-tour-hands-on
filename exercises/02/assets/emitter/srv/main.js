const cds = require('@sap/cds')
const log = cds.log('emitter')

module.exports = cds.service.impl(async function() {
  this.on('greet', async (req) => {
    const emitter = await cds.connect.to('codejam.emitter.EmitterService')
    log(`emitting Greeting.Received (${req.data.greeting})`)
    await emitter.emit('Greeting.Received', { info: req.data.greeting })
    return 'OK'
  })
})
