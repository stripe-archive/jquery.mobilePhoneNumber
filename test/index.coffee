assert = require('assert')
jsdom = require('jsdom').jsdom
global.document = jsdom('')
global.window = document.createWindow()
$ = require('jquery')
global.jQuery = $

# jsdom doesn't support selection, so we just hack it into document.createElement
createElement = document.createElement
document.createElement = ->
  el = createElement.apply(document, arguments)
  if arguments[0] == 'input'
    el.selectionStart = el.selectionEnd = 0
  el

require('../src/jquery.mobilePhoneNumber')
require('../vendor/jquery.caret')

createInput = ->
  $input = $('<input type=text>')
  # jsdom doesn't support selection, so we just define it
  $input[0].selectionStart = $input[0].selectionEnd = 0
  $input

triggerKey = ($input, which) ->
  for type in ['keydown', 'keypress', 'keyup']
    $input.trigger(
      type: type
      which: which
    )

type = ($input, digits) ->
  for digit in digits
    do (digit) ->
      triggerKey($input, digit.charCodeAt(0))

      # jsdom doesn't support selection
      # hack to push the selection to the end
      $input[0].selectionStart = $input[0].selectionEnd = 1000

describe 'jquery.mobilePhoneNumber', ->
  describe 'mobilePhoneNumber', ->
    it 'should correctly format US phone', ->
      $phone = createInput().val('').mobilePhoneNumber()

      type $phone, '1'
      assert.equal $phone.val(), '+1 ('

      type $phone, '4'
      assert.equal $phone.val(), '+1 (4'

      type $phone, '15'
      assert.equal $phone.val(), '+1 (415) '

      type $phone, '12'
      assert.equal $phone.val(), '+1 (415) 12'

      type $phone, '3'
      assert.equal $phone.val(), '+1 (415) 123-'

      type $phone, '4567'
      assert.equal $phone.val(), '+1 (415) 123-4567'

    it 'should correctly format US phone with defaultPrefix +1', ->
      $phone = createInput().val('').mobilePhoneNumber({ defaultPrefix: '+1' })

      type $phone, '415'
      assert.equal $phone.val(), '(415) '

      type $phone, '1234567'
      assert.equal $phone.val(), '(415) 123-4567'

    it 'should correctly format JP phone with defaultPrefix +81', ->
      $phone = createInput().val('').mobilePhoneNumber({ defaultPrefix: '+81' })

      type $phone, '08043691337'
      assert.equal $phone.val(), '0804-369-1337'

    it 'should correctly format BE phone', ->
      $phone = createInput().val('').mobilePhoneNumber()

      type $phone, '+32'
      assert.equal $phone.val(), '+32 '

      type $phone, '49'
      assert.equal $phone.val(), '+32 49'

      type $phone, '5'
      assert.equal $phone.val(), '+32 495 '

      type $phone, '1'
      assert.equal $phone.val(), '+32 495 1'

      type $phone, '2'
      assert.equal $phone.val(), '+32 495 12 '

      type $phone, '3456'
      assert.equal $phone.val(), '+32 495 12 34 56'

    it 'should correctly format BE phone with defaultPrefix +1', ->
      $phone = createInput().val('').mobilePhoneNumber({ defaultPrefix: '+1' })

      type $phone, '+32'
      assert.equal $phone.val(), '+32 '

      type $phone, '123456789'
      assert.equal $phone.val(), '+32 123 45 67 89'

    it 'should correctly format KH phone', ->
      $phone = createInput().val('').mobilePhoneNumber()
      type $phone, '855'
      assert.equal $phone.val(), '+855 '

      type $phone, '089481812'
      assert.equal $phone.val(), '+855 (0) 89 481 812'

      $phone.val('')
      type $phone, "85589481812"
      assert.equal $phone.val(), '+855 89 481 812'

    it 'should correctly replace when select all + type', ->
      $phone = createInput().val('123456789').mobilePhoneNumber()

      $phone.get(0).selectionStart = 0
      $phone.get(0).selectionEnd = 10

      type $phone, '0'

      assert.equal $phone.val(), '+0'

  describe 'mobilePhoneNumber("country")', ->
    it 'should correctly find the country', ->
      $phone = createInput().mobilePhoneNumber()

      $phone.val('+1415123')
      assert.equal $phone.mobilePhoneNumber('country'), 'US'

      $phone.val('+3212345')
      assert.equal $phone.mobilePhoneNumber('country'), 'BE'

      $phone.val('+3312345')
      assert.equal $phone.mobilePhoneNumber('country'), 'FR'

      $phone.val('+1403123')
      assert.equal $phone.mobilePhoneNumber('country'), 'CA'

  describe 'mobilePhoneNumber("prefix")', ->
    it 'should correctly find the prefix', ->
      $phone = createInput().mobilePhoneNumber()

      $phone.val('+1415123')
      assert.equal $phone.mobilePhoneNumber('prefix'), '+1'

      $phone.val('+3212345')
      assert.equal $phone.mobilePhoneNumber('prefix'), '+32'

      $phone.val('+3312345')
      assert.equal $phone.mobilePhoneNumber('prefix'), '+33'

      $phone.val('+1403123')
      assert.equal $phone.mobilePhoneNumber('prefix'), '+1'

  describe 'mobilePhoneNumber("val")', ->
    it 'should correctly returns the val with defaultPrefix on', ->
      $phone = createInput().mobilePhoneNumber({defaultPrefix: '+1'})

      $phone.val('4151234567')
      assert.equal $phone.mobilePhoneNumber('val'), '+14151234567'

      $phone.val('+32123456789')
      assert.equal $phone.mobilePhoneNumber('val'), '+32123456789'

    it 'should correctly returns the val with defaultPrefix off', ->
      $phone = createInput().mobilePhoneNumber()

      $phone.val('+14151234567')
      assert.equal $phone.mobilePhoneNumber('val'), '+14151234567'

      $phone.val('+32123456789')
      assert.equal $phone.mobilePhoneNumber('val'), '+32123456789'

  describe 'event country.mobilePhoneNumber', ->
    it 'is triggered correctly with US number', (done) ->
      $phone = createInput().val('').mobilePhoneNumber()
      $phone.bind('country.mobilePhoneNumber', (e, country) ->
        if country == 'US'
          done()
      )
      type $phone, '+1415'

    it 'is triggered correctly with BE number and then US number', (done) ->
      $phone = createInput().val('').mobilePhoneNumber()
      isFirst = true
      $phone.bind('country.mobilePhoneNumber', (e, country) ->
        if isFirst
          if country == 'BE'
            isFirst = false
        else
          if country == 'US'
            done()
      )
      type $phone, '+32495'
      $phone.val('')
      type $phone, '+1415'

  describe 'mobilePhoneNumber.validate', ->
    it 'should correctly validate KH the phone numbers', ->
      $phone = createInput().val('').mobilePhoneNumber()
      $phone.val("85589481812") # valid KH number
      assert.equal $phone.mobilePhoneNumber('validate'), true
      $phone.val("855894818121") # valid long KH number
      assert.equal $phone.mobilePhoneNumber('validate'), true
      $phone.val("8558948181211") # invalid KH number (too long)
      assert.equal $phone.mobilePhoneNumber('validate'), false
      $phone.val("8558948181") # invalid KH number (too short)
      assert.equal $phone.mobilePhoneNumber('validate'), false
      $phone.val("855089481812") # valid KH number (starts with 0)
      assert.equal $phone.mobilePhoneNumber('validate'), true
      $phone.val("8550089481812") # invalid KH number (starts with 00)
      assert.equal $phone.mobilePhoneNumber('validate'), false
