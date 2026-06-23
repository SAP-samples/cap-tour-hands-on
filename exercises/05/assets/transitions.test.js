const cds = require('@sap/cds')
const { GET, POST, expect, defaults } = cds.test('.')
defaults.auth = { username: 'alice' }
defaults.path = '/odata/v4/morse'
// defaults.validateStatus = status => status <= 999

describe('Initial controls', () => {

  it('initially returns an empty list', async () => {
    const { data } = await GET('Controls')
    expect(data.value).to.deep.equal([])
  })

  it('allows the creation of new controls', async () => {
    const { status } = await POST('Controls', { ID: 1 })
    expect(status).to.equal(201)
  })

  it('gives new controls a Neutral default position', async () => {
    const { data } = await POST('Controls', { ID: 2 })
    expect(data.position).to.equal('Neutral')
  })

  it('prevents positions being specified on creation', async () => {
    const { data } = await POST('Controls', { ID: 3, position: "Random" })
    expect(data.position).to.equal('Neutral')
  })

})

describe('Transitions', () => {

  it('allows moving from Neutral to Forward', async () => {
    const { status } = await POST('Controls/1/engageForward')
    expect(status).to.equal(204)
  })

  it('tracks the position after engagement', async () => {
    const { data } = await GET('Controls/1')
    expect(data.position).to.equal('Forward')
  })

  it('prevents moving from Forward directly to Reverse', async () => {
    const { data, status } = await POST('Controls/1/engageReverse', null, { validateStatus: status => status == 409 })
    expect(data.error.code).to.equal('INVALID_FLOW_TRANSITION_SINGLE')
  })

  it('allows moving from Forward to Neutral', async () => {
    const { status } = await POST('Controls/1/engageNeutral')
    expect(status).to.equal(204)
  })

  it('allows moving from Neutral to Reverse', async () => {
    const { status } = await POST('Controls/1/engageReverse')
    expect(status).to.equal(204)
  })

})
