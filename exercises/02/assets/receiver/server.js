const cds = require('@sap/cds')
const log = cds.log('receiver')
const eventID = 'Greeting.Received'

cds.once('served', async () => {
  log(`Setting up listener for ${eventID}`)
  const EmitterService = await cds.connect.to('EmitterService')
  EmitterService.on(eventID, (msg) => {
    log('received:', msg.event, msg.data)
  })
})
