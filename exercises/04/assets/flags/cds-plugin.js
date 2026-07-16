const cds = require('@sap/cds')
const flags = require('./flags')
const log = cds.log('flags')
log.debug('Starting up ...')
log.debug(`Flags available for ${Object.keys(flags).length} countries`)

const isAppService = x => x.kind == 'app-service'
const isAnnotatedWith = a => x => x[a]
const isFlagified = isAnnotatedWith('@flagify')

cds.once('served', _ => {

  const services = [...cds.services].filter(isAppService)

  services.forEach(s => {
    [...s.entities].forEach(en => {
      if ([...en.elements].some(isFlagified)) {
        s.after('READ', en.name, (records, req) => {
          const flagified = [...req.target.elements].filter(isFlagified)
          records.forEach(r =>
            flagified.forEach(el => r[el.name] = flags[r[el.name]] || r[el.name])
          )
        })
      }
    })
  })

})
