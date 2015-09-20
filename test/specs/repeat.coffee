{stream, prop, send, activate, deactivate, Kefir} = require('../test-helpers.coffee')

describe 'repeat', ->

  it 'should return stream', ->
    expect(Kefir.repeat()).toBeStream()

  it 'should work correctly (with .constant)', ->
    a = Kefir.repeat (i) ->
      Kefir[if i == 2 then 'constantError' else 'constant'](i)
    expect(a.take(3)).toEmit [
      {current: 0},
      {current: 1},
      {currentError: 2},
      {current: 3},
      '<end:current>'
    ]


  it 'should work correctly (with .later)', ->
    a = Kefir.repeat (i) -> Kefir.later(100, i)
    expect(a.take(3)).toEmitInTime [
      [100, 0],
      [200, 1],
      [300, 2],
      [300, '<end>']
    ]

  it 'should work correctly (with .sequentially)', ->
    a = Kefir.repeat (i) -> Kefir.sequentially(100, [1, 2, 3])
    expect(a.take(5)).toEmitInTime [
      [100, 1],
      [200, 2],
      [300, 3],
      [400, 1],
      [500, 2],
      [500, '<end>']
    ]

  it 'should not cause stack overflow', ->
    sum = (a, b) -> a + b
    genConstant = -> Kefir.constant(1)

    a = Kefir.repeat(genConstant).take(3000).scan(sum, 0).last()
    expect(a).toEmit [{current: 3000}, '<end:current>']


  it 'should get new source only if previous one ended', ->
    a = stream()

    callsCount = 0
    b = Kefir.repeat ->
      callsCount++
      if !a._alive
        a = stream()
      a

    expect(callsCount).toBe(0)
    activate(b)
    expect(callsCount).toBe(1)
    deactivate(b)
    activate(b)
    expect(callsCount).toBe(1)
    send(a, ['<end>'])
    expect(callsCount).toBe(2)



  it 'should unsubscribe from source', ->
    a = stream()
    b = Kefir.repeat -> a
    expect(b).toActivate(a)



  it 'should end when falsy value returned from generator', ->
    a = Kefir.repeat (i) ->
      if i < 3
        Kefir.constant(i)
      else
        false
    expect(a).toEmit [
      {current: 0},
      {current: 1},
      {current: 2},
      '<end:current>'
    ]

