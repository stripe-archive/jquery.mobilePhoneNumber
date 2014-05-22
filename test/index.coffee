assert = require('assert')
jsdom = require('jsdom').jsdom
global.document = jsdom('')
global.window = document.createWindow()
$ = require('jquery')
global.jQuery = $

require('../src/jquery.mobilePhoneNumber')
require('../vendor/jquery.caret')

type = ($input, digits) ->
  for digit in digits
    do (digit) ->
      e = $.Event('keydown')
      e.which = digit.charCodeAt(0)
      $input.trigger(e)

      e = $.Event('keypress')
      e.which = digit.charCodeAt(0)
      $input.trigger(e)

      e = $.Event('keyup')
      e.which = digit.charCodeAt(0)
      $input.trigger(e)

      # Hack to push the selection to the end
      $input[0].selectionStart = $input[0].selectionEnd = 1000

describe 'jquery.mobilePhoneNumber', ->
  describe 'mobilePhoneNumber', ->
    it 'should correctly format US phone', ->
      $phone = $('<input type=text>').val('').mobilePhoneNumber()

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

    it 'should correctly format US phone with allowPhoneWithoutPrefix +1', ->
      $phone = $('<input type=text>').val('').mobilePhoneNumber({ allowPhoneWithoutPrefix: '+1' })

      type $phone, '415'
      assert.equal $phone.val(), '(415) '

      type $phone, '1234567'
      assert.equal $phone.val(), '(415) 123-4567'

    it 'should correctly format BE phone', ->
      $phone = $('<input type=text>').val('').mobilePhoneNumber()

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

    it 'should correctly format BE phone with allowPhoneWithoutPrefix +1', ->
      $phone = $('<input type=text>').val('').mobilePhoneNumber({ allowPhoneWithoutPrefix: '+1' })

      type $phone, '+32'
      assert.equal $phone.val(), '+32 '

      type $phone, '123456789'
      assert.equal $phone.val(), '+32 123 45 67 89'

  describe 'mobilePhoneNumber("country")', ->
    it 'should correctly find the country', ->
      $phone = $('<input type=text>').mobilePhoneNumber()

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
      $phone = $('<input type=text>').mobilePhoneNumber()

      $phone.val('+1415123')
      assert.equal $phone.mobilePhoneNumber('prefix'), '+1'

      $phone.val('+3212345')
      assert.equal $phone.mobilePhoneNumber('prefix'), '+32'

      $phone.val('+3312345')
      assert.equal $phone.mobilePhoneNumber('prefix'), '+33'

      $phone.val('+1403123')
      assert.equal $phone.mobilePhoneNumber('prefix'), '+1'

  describe 'mobilePhoneNumber("val")', ->
    it 'should correctly returns the val with allowPhoneWithoutPrefix on', ->
      $phone = $('<input type=text>').mobilePhoneNumber({allowPhoneWithoutPrefix: '+1'})

      $phone.val('4151234567')
      assert.equal $phone.mobilePhoneNumber('val'), '+14151234567'

      $phone.val('+32123456789')
      assert.equal $phone.mobilePhoneNumber('val'), '+32123456789'

    it 'should correctly returns the val with allowPhoneWithoutPrefix off', ->
      $phone = $('<input type=text>').mobilePhoneNumber()

      $phone.val('+14151234567')
      assert.equal $phone.mobilePhoneNumber('val'), '+14151234567'

      $phone.val('+32123456789')
      assert.equal $phone.mobilePhoneNumber('val'), '+32123456789'

  describe 'event country.mobilePhoneNumber', ->
    it 'is triggered correctly with US number', (done) ->
      $phone = $('<input type=text>').val('').mobilePhoneNumber()
      $phone.bind('country.mobilePhoneNumber', (e, country) ->
        if country == 'US'
          done()
      )
      type $phone, '+1415'

    it 'is triggered correctly with BE number and then US number', (done) ->
      $phone = $('<input type=text>').val('').mobilePhoneNumber()
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
