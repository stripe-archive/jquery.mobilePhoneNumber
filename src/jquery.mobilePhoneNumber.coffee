$ = jQuery

supportSelectionEnd = 'selectionEnd' of document.createElement('input')

formatForPhone_ = (phone, defaultPrefix = null) ->
  if phone.indexOf('+') != 0 and defaultPrefix
    phone = defaultPrefix + phone.replace(/[^0-9]/g, '')
  else
    phone = '+' + phone.replace(/[^0-9]/g, '')
  bestFormat = null
  precision = 0
  for prefix, format of formats
    if phone.length >= prefix.length && phone.substring(0, prefix.length) == prefix && prefix.length > precision
      bestFormat = {}
      for k, v of format
        bestFormat[k] = v
      bestFormat.prefix = prefix
      precision = prefix.length
  bestFormat

prefixesAreSubsets_ = (prefixA, prefixB) ->
  return true if prefixA == prefixB
  if prefixA.length < prefixB.length
    return prefixB.substring(0, prefixA.length) == prefixA
  return prefixA.substring(0, prefixB.length) == prefixB

formattedPhoneNumber_ = (phone, lastChar, defaultPrefix = null) ->
  if phone.length != 0 and (phone.substring(0, 1) == "+" or defaultPrefix)
    format = formatForPhone_(phone, defaultPrefix)
    if format && format.format
      phoneFormat = format.format
      phonePrefix = format.prefix

      if defaultPrefix
        if (defaultPrefix == phonePrefix or prefixesAreSubsets_(phonePrefix, defaultPrefix)) and (phone.indexOf('+') != 0 or phone.length == 0)
          phoneFormat = phoneFormat.substring(Math.min(phonePrefix.length, defaultPrefix.length) + 1)
          if format.nationalPrefix?
            prefixPhoneFormat = ""
            for i in [0...format.nationalPrefix.length]
              prefixPhoneFormat += "."
            phoneFormat = prefixPhoneFormat + phoneFormat

      if phone.substring(0, 1) == "+"
        phoneDigits = phone.substring(1)
      else
        phoneDigits = phone
      formatDigitCount = phoneFormat.match(/\./g).length

      formattedPhone = ""
      for formatChar in phoneFormat
        if formatChar == "."
          if phoneDigits.length == 0
            break
          formattedPhone += phoneDigits.substring(0, 1)
          phoneDigits = phoneDigits.substring(1)
        else if lastChar || phoneDigits.length > 0
          formattedPhone += formatChar
      phone = formattedPhone + phoneDigits
  phone

isEventAllowed_ = (e) ->
  # Key event is for a browser shortcut
  return true if e.metaKey
  # If keycode is a space
  return false if e.which is 32
  # If keycode is a special char (WebKit)
  return true if e.which is 0
  # If char is a special char (Firefox)
  return true if e.which < 33
  isEventAllowedChar_(e)

isEventAllowedChar_ = (e) ->
  char = String.fromCharCode(e.which)
  # Char is a number or a space or a +
  !!/[\d\s+]/.test(char)

restrictEventAndFormat_ = (e) ->
  if !isEventAllowed_(e)
    return e.preventDefault()

  return if !isEventAllowedChar_(e)
  value = @val()
  caretEnd = if supportSelectionEnd then @get(0).selectionEnd else @caret()
  value = value.substring(0, @caret()) +
          String.fromCharCode(e.which) +
          value.substring(caretEnd, value.length)
  selection = @caret()
  selectionAtEnd = selection == @val().length
  format_.call(@, value, e)
  if !selectionAtEnd
    @caret(@val().length)

formatUp_ = (e) ->
  checkForCountryChange_.call(@)
  value = @val()
  return if e.keyCode == 8 && @caret() == value.length
  format_.call(@, value, e)

formatBack_ = (e) ->
  return if !e
  return if e.meta
  value = @val()
  return if value.length == 0
  return if !(@caret() == value.length)
  return if e.keyCode != 8

  value = value.substring(0, value.length - 1)
  e.preventDefault()
  phone = formattedPhone_.call(@, value, false)
  if @val() != phone
    @val(phone)

format_ = (value, e) ->
  phone = formattedPhone_.call(@, value, true)
  if phone != @val()
    selection = @caret()
    selectionAtEnd = selection == @val().length
    e.preventDefault()
    @val(phone)
    if !selectionAtEnd
      @caret(selection)

formattedPhone_ = (phone, lastChar) ->
  if phone.indexOf('+') != 0 && @data('defaultPrefix')
    phone = phone.replace(/[^0-9]/g, '')
  else
    phone = '+' + phone.replace(/[^0-9]/g, '')
  formattedPhoneNumber_(phone, lastChar, @data('defaultPrefix'))

checkForCountryChange_ = ->
  phone = @val()
  format = formatForPhone_(phone, @data('defaultPrefix'))
  country = null
  country = format.country if format
  if @data('mobilePhoneCountry') != country
    @data('mobilePhoneCountry', country)
    @trigger('country.mobilePhoneNumber', country)

mobilePhoneNumber = {}
mobilePhoneNumber.init = (options = {}) ->
  unless @data('mobilePhoneNumberInited')
    @data('mobilePhoneNumberInited', true)
    @bind 'keypress', =>
      restrictEventAndFormat_.apply($(@), arguments)
    @bind 'keyup', =>
      formatUp_.apply($(@), arguments)
    @bind 'keydown', =>
      formatBack_.apply($(@), arguments)

  @data('defaultPrefix', options.allowPhoneWithoutPrefix ? options.defaultPrefix)

mobilePhoneNumber.val = ->
  val = @val().replace(/[^0-9]/g, '')
  format = formatForPhone_(val, @data('defaultPrefix'))
  if @val().indexOf('+') == 0 or !@data('defaultPrefix')?
    '+' + val
  else
    @data('defaultPrefix') + val

mobilePhoneNumber.validate = ->
  val = @mobilePhoneNumber('val')
  format = formatForPhone_(val, @data('defaultPrefix'))
  return true unless format
  return (val.length > format.prefix.length) && (!format.min_length || val.length >= format.min_length) && (!format.max_length || val.length <= format.max_length) && (!format.pattern || format.pattern.test(val))

mobilePhoneNumber.country = ->
  format = formatForPhone_(@mobilePhoneNumber('val'))
  format.country if format

mobilePhoneNumber.prefix = ->
  countryCode = @mobilePhoneNumber('country')
  return "" if !countryCode?
  $.mobilePhoneNumberPrefixFromCountryCode(countryCode)

$.fn.mobilePhoneNumber = (method, args...) ->
  if !method? or !(typeof(method) == 'string')
    args = [ method ] if method?
    method = 'init'
  mobilePhoneNumber[method].apply(this, args)

$.formatMobilePhoneNumber = (phone) ->
  phone = '+' + phone.replace(/[^0-9\*]/g, '')
  formattedPhoneNumber_(phone, true)

$.mobilePhoneNumberPrefixFromCountryCode = (countryCode) ->
  for prefix, format of formats
    if format.country.toLowerCase() == countryCode.toLowerCase()
      if prefix.length == 5 and prefix[1] == '1'
        return '+1'
      return prefix
  return null

formats =
  '+247' :
    country : 'AC',
  '+376' :
    country : 'AD',
    format : '+... ... ...',
  '+971' :
    country : 'AE',
    format : '+... .. ... ....',
  '+93' :
    country : 'AF',
    format : '+.. .. ... ....',
  '+1268' :
    country : 'AG',
  '+1264' :
    country : 'AI',
  '+355' :
    country : 'AL',
    format : '+... .. ... ....',
  '+374' :
    country : 'AM',
    format : '+... .. ......',
  '+244' :
    country : 'AO',
    format : '+... ... ... ...',
  '+54' :
    country : 'AR',
    format : '+.. .. ..-....-....',
  '+1684' :
    country : 'AS',
  '+43' :
    country : 'AT',
    format : '+.. ... ......',
  '+61' :
    country : 'AU',
    format : '+.. ... ... ...',
  '+297' :
    country : 'AW',
    format : '+... ... ....',
  '+994' :
    country : 'AZ',
    format : '+... .. ... .. ..',
  '+387' :
    country : 'BA',
    format : '+... .. ...-...',
  '+1246' :
    country : 'BB',
  '+880' :
    country : 'BD',
    format : '+... ....-......',
  '+32' :
    country : 'BE',
    format : '+.. ... .. .. ..',
  '+226' :
    country : 'BF',
    format : '+... .. .. .. ..',
  '+359' :
    country : 'BG',
    format : '+... ... ... ..',
  '+973' :
    country : 'BH',
    format : '+... .... ....',
  '+257' :
    country : 'BI',
    format : '+... .. .. .. ..',
  '+229' :
    country : 'BJ',
    format : '+... .. .. .. ..',
  '+1441' :
    country : 'BM',
  '+673' :
    country : 'BN',
    format : '+... ... ....',
  '+591' :
    country : 'BO',
    format : '+... ........',
  '+55' :
    country : 'BR',
    format : '+.. .. .....-....',
  '+1242' :
    country : 'BS',
  '+975' :
    country : 'BT',
    format : '+... .. .. .. ..',
  '+267' :
    country : 'BW',
    format : '+... .. ... ...',
  '+375' :
    country : 'BY',
    format : '+... .. ...-..-..',
  '+501' :
    country : 'BZ',
    format : '+... ...-....',
  '+243' :
    country : 'CD',
    format : '+... ... ... ...',
  '+236' :
    country : 'CF',
    format : '+... .. .. .. ..',
  '+242' :
    country : 'CG',
    format : '+... .. ... ....',
  '+41' :
    country : 'CH',
    format : '+.. .. ... .. ..',
  '+225' :
    country : 'CI',
    format : '+... .. .. .. ..',
  '+682' :
    country : 'CK',
    format : '+... .. ...',
  '+56' :
    country : 'CL',
    format : '+.. . .... ....',
  '+237' :
    country : 'CM',
    format : '+... .. .. .. ..',
  '+86' :
    country : 'CN',
    format : '+.. ... .... ....',
  '+57' :
    country : 'CO',
    format : '+.. ... .......',
  '+506' :
    country : 'CR',
    format : '+... .... ....',
  '+53' :
    country : 'CU',
    format : '+.. . .......',
  '+238' :
    country : 'CV',
    format : '+... ... .. ..',
  '+599' :
    country : 'CW',
    format : '+... . ... ....',
  '+537' :
    country : 'CY',
  '+357' :
    country : 'CY',
    format : '+... .. ......',
  '+420' :
    country : 'CZ',
    format : '+... ... ... ...',
  '+49' :
    country : 'DE',
    format : '+.. .... .......',
  '+253' :
    country : 'DJ',
    format : '+... .. .. .. ..',
  '+45' :
    country : 'DK',
    format : '+.. .. .. .. ..',
  '+1767' :
    country : 'DM',
  '+1849' :
    country : 'DO',
  '+213' :
    country : 'DZ',
    format : '+... ... .. .. ..',
  '+593' :
    country : 'EC',
    format : '+... .. ... ....',
  '+372' :
    country : 'EE',
    format : '+... .... ....',
  '+20' :
    country : 'EG',
    format : '+.. ... ... ....',
  '+291' :
    country : 'ER',
    format : '+... . ... ...',
  '+34' :
    country : 'ES',
    format : '+.. ... .. .. ..',
  '+251' :
    country : 'ET',
    format : '+... .. ... ....',
  '+358' :
    country : 'FI',
    format : '+... .. ... .. ..',
  '+679' :
    country : 'FJ',
    format : '+... ... ....',
  '+500' :
    country : 'FK',
  '+691' :
    country : 'FM',
    format : '+... ... ....',
  '+298' :
    country : 'FO',
    format : '+... ......',
  '+33' :
    country : 'FR',
    format : '+.. . .. .. .. ..',
  '+241' :
    country : 'GA',
    format : '+... .. .. .. ..',
  '+44' :
    country : 'GB',
    format : '+.. .... ......',
  '+1473' :
    country : 'GD',
  '+995' :
    country : 'GE',
    format : '+... ... .. .. ..',
  '+594' :
    country : 'GF',
    format : '+... ... .. .. ..',
  '+233' :
    country : 'GH',
    format : '+... .. ... ....',
  '+350' :
    country : 'GI',
    format : '+... ... .....',
  '+299' :
    country : 'GL',
    format : '+... .. .. ..',
  '+220' :
    country : 'GM',
    format : '+... ... ....',
  '+224' :
    country : 'GN',
    format : '+... ... .. .. ..',
  '+240' :
    country : 'GQ',
    format : '+... ... ... ...',
  '+30' :
    country : 'GR',
    format : '+.. ... ... ....',
  '+502' :
    country : 'GT',
    format : '+... .... ....',
  '+1671' :
    country : 'GU',
  '+245' :
    country : 'GW',
    format : '+... ... ....',
  '+592' :
    country : 'GY',
    format : '+... ... ....',
  '+852' :
    country : 'HK',
    format : '+... .... ....',
  '+504' :
    country : 'HN',
    format : '+... ....-....',
  '+385' :
    country : 'HR',
    format : '+... .. ... ....',
  '+509' :
    country : 'HT',
    format : '+... .. .. ....',
  '+36' :
    country : 'HU',
    format : '+.. .. ... ....',
  '+62' :
    country : 'ID',
    format : '+.. ...-...-...',
  '+353' :
    country : 'IE',
    format : '+... .. ... ....',
  '+972' :
    country : 'IL',
    format : '+... ..-...-....',
  '+91' :
    country : 'IN',
    format : '+.. .. .. ......',
  '+246' :
    country : 'IO',
    format : '+... ... ....',
  '+964' :
    country : 'IQ',
    format : '+... ... ... ....',
  '+98' :
    country : 'IR',
    format : '+.. ... ... ....',
  '+354' :
    country : 'IS',
    format : '+... ... ....',
  '+39' :
    country : 'IT',
    format : '+.. .. .... ....',
  '+1876' :
    country : 'JM',
  '+962' :
    country : 'JO',
    format : '+... . .... ....',
  '+81' :
    country : 'JP',
    format : '+.. ...-...-....',
    nationalPrefix: '0',
  '+254' :
    country : 'KE',
    format : '+... .. .......',
  '+996' :
    country : 'KG',
    format : '+... ... ... ...',
  '+855' :
    country: "KH",
    format: "+... .. ... ...",
    min_length: 12,
    max_length: 13,
    pattern: /^\+855[1-9]\d{7,8}$/,
  '+8550' :
    country: "KH",
    format: "+... (.) .. ... ...",
    min_length: 13,
    max_length: 14,
    pattern: /^\+8550[1-9]\d{7,8}$/,
  '+686' :
    country : 'KI',
  '+269' :
    country : 'KM',
    format : '+... ... .. ..',
  '+1869' :
    country : 'KN',
  '+850' :
    country : 'KP',
    format : '+... ... ... ....',
  '+82' :
    country : 'KR',
    format : '+.. ..-....-....',
  '+965' :
    country : 'KW',
    format : '+... ... .....',
  '+345' :
    country : 'KY',
  '+77' :
    country : 'KZ',
  '+856' :
    country : 'LA',
    format : '+... .. .. ... ...',
  '+961' :
    country : 'LB',
    format : '+... .. ... ...',
  '+1758' :
    country : 'LC',
  '+423' :
    country : 'LI',
    format : '+... ... ... ...',
  '+94' :
    country : 'LK',
    format : '+.. .. . ......',
  '+231' :
    country : 'LR',
    format : '+... ... ... ...',
  '+266' :
    country : 'LS',
    format : '+... .... ....',
  '+370' :
    country : 'LT',
    format : '+... ... .....',
  '+352' :
    country : 'LU',
    format : '+... .. .. .. ...',
  '+371' :
    country : 'LV',
    format : '+... .. ... ...',
  '+218' :
    country : 'LY',
    format : '+... ..-.......',
  '+212' :
    country : 'MA',
    format : '+... ...-......',
  '+377' :
    country : 'MC',
    format : '+... . .. .. .. ..',
  '+373' :
    country : 'MD',
    format : '+... ... .. ...',
  '+382' :
    country : 'ME',
    format : '+... .. ... ...',
  '+590' :
    country : 'MF',
  '+261' :
    country : 'MG',
    format : '+... .. .. ... ..',
  '+692' :
    country : 'MH',
    format : '+... ...-....',
  '+389' :
    country : 'MK',
    format : '+... .. ... ...',
  '+223' :
    country : 'ML',
    format : '+... .. .. .. ..',
  '+95' :
    country : 'MM',
    format : '+.. . ... ....',
  '+976' :
    country : 'MN',
    format : '+... .... ....',
  '+853' :
    country : 'MO',
    format : '+... .... ....',
  '+1670' :
    country : 'MP',
  '+596' :
    country : 'MQ',
    format : '+... ... .. .. ..',
  '+222' :
    country : 'MR',
    format : '+... .. .. .. ..',
  '+1664' :
    country : 'MS',
  '+356' :
    country : 'MT',
    format : '+... .... ....',
  '+230' :
    country : 'MU',
    format : '+... .... ....',
  '+960' :
    country : 'MV',
    format : '+... ...-....',
  '+265' :
    country : 'MW',
    format : '+... ... .. .. ..',
  '+52' :
    country : 'MX',
    format : '+.. ... ... ... ....',
  '+60' :
    country : 'MY',
    format : '+.. ..-... ....',
  '+258' :
    country : 'MZ',
    format : '+... .. ... ....',
  '+264' :
    country : 'NA',
    format : '+... .. ... ....',
  '+687' :
    country : 'NC',
    format : '+... ........',
  '+227' :
    country : 'NE',
    format : '+... .. .. .. ..',
  '+672' :
    country : 'NF',
    format : '+... .. ....',
  '+234' :
    country : 'NG',
    format : '+... ... ... ....',
  '+505' :
    country : 'NI',
    format : '+... .... ....',
  '+31' :
    country : 'NL',
    format : '+.. . ........',
  '+47' :
    country : 'NO',
    format : '+.. ... .. ...',
  '+977' :
    country : 'NP',
    format : '+... ...-.......',
  '+674' :
    country : 'NR',
    format : '+... ... ....',
  '+683' :
    country : 'NU',
  '+64' :
    country : 'NZ',
    format : '+.. .. ... ....',
  '+968' :
    country : 'OM',
    format : '+... .... ....',
  '+507' :
    country : 'PA',
    format : '+... ....-....',
  '+51' :
    country : 'PE',
    format : '+.. ... ... ...',
  '+689' :
    country : 'PF',
    format : '+... .. .. ..',
  '+675' :
    country : 'PG',
    format : '+... ... ....',
  '+63' :
    country : 'PH',
    format : '+.. .... ......',
  '+92' :
    country : 'PK',
    format : '+.. ... .......',
  '+48' :
    country : 'PL',
    format : '+.. .. ... .. ..',
  '+508' :
    country : 'PM',
    format : '+... .. .. ..',
  '+872' :
    country : 'PN',
  '+1939' :
    country : 'PR',
  '+970' :
    country : 'PS',
    format : '+... ... ... ...',
  '+351' :
    country : 'PT',
    format : '+... ... ... ...',
  '+680' :
    country : 'PW',
    format : '+... ... ....',
  '+595' :
    country : 'PY',
    format : '+... .. .......',
  '+974' :
    country : 'QA',
    format : '+... .... ....',
  '+262' :
    country : 'RE',
  '+40' :
    country : 'RO',
    format : '+.. .. ... ....',
  '+381' :
    country : 'RS',
    format : '+... .. .......',
  '+7' :
    country : 'RU',
    format : '+. ... ...-..-..',
  '+250' :
    country : 'RW',
    format : '+... ... ... ...',
  '+966' :
    country : 'SA',
    format : '+... .. ... ....',
  '+677' :
    country : 'SB',
    format : '+... ... ....',
  '+248' :
    country : 'SC',
    format : '+... . ... ...',
  '+249' :
    country : 'SD',
    format : '+... .. ... ....',
  '+46' :
    country : 'SE',
    format : '+.. ..-... .. ..',
  '+65' :
    country : 'SG',
    format : '+.. .... ....',
  '+290' :
    country : 'SH',
  '+386' :
    country : 'SI',
    format : '+... .. ... ...',
  '+421' :
    country : 'SK',
    format : '+... ... ... ...',
  '+232' :
    country : 'SL',
    format : '+... .. ......',
  '+378' :
    country : 'SM',
    format : '+... .. .. .. ..',
  '+221' :
    country : 'SN',
    format : '+... .. ... .. ..',
  '+252' :
    country : 'SO',
    format : '+... .. .......',
  '+597' :
    country : 'SR',
    format : '+... ...-....',
  '+211' :
    country : 'SS',
    format : '+... ... ... ...',
  '+239' :
    country : 'ST',
    format : '+... ... ....',
  '+503' :
    country : 'SV',
    format : '+... .... ....',
  '+963' :
    country : 'SY',
    format : '+... ... ... ...',
  '+268' :
    country : 'SZ',
    format : '+... .... ....',
  '+1649' :
    country : 'TC',
  '+235' :
    country : 'TD',
    format : '+... .. .. .. ..',
  '+228' :
    country : 'TG',
    format : '+... .. .. .. ..',
  '+66' :
    country : 'TH',
    format : '+.. .. ... ....',
  '+992' :
    country : 'TJ',
    format : '+... ... .. ....',
  '+690' :
    country : 'TK',
  '+670' :
    country : 'TL',
    format : '+... .... ....',
  '+993' :
    country : 'TM',
    format : '+... .. ..-..-..',
  '+216' :
    country : 'TN',
    format : '+... .. ... ...',
  '+676' :
    country : 'TO',
    format : '+... ... ....',
  '+90' :
    country : 'TR',
    format : '+.. ... ... ....',
  '+1868' :
    country : 'TT',
  '+688' :
    country : 'TV',
  '+886' :
    country : 'TW',
    format : '+... ... ... ...',
  '+255' :
    country : 'TZ',
    format : '+... ... ... ...',
  '+380' :
    country : 'UA',
    format : '+... .. ... ....',
  '+256' :
    country : 'UG',
    format : '+... ... ......',
  '+1' :
    country : 'US',
  '+598' :
    country : 'UY',
    format : '+... .... ....',
  '+998' :
    country : 'UZ',
    format : '+... .. ... .. ..',
  '+379' :
    country : 'VA',
  '+1784' :
    country : 'VC',
  '+58' :
    country : 'VE',
    format : '+.. ...-.......',
  '+1284' :
    country : 'VG',
  '+1340' :
    country : 'VI',
  '+84' :
    country : 'VN',
    format : '+.. .. ... .. ..',
  '+678' :
    country : 'VU',
    format : '+... ... ....',
  '+681' :
    country : 'WF',
    format : '+... .. .. ..',
  '+685' :
    country : 'WS',
  '+967' :
    country : 'YE',
    format : '+... ... ... ...',
  '+27' :
    country : 'ZA',
    format : '+.. .. ... ....',
  '+260' :
    country : 'ZM',
    format : '+... .. .......',
  '+263' :
    country : 'ZW',
    format : '+... .. ... ....',

do (formats) ->
  # Canada
  canadaPrefixes = [403, 587, 780, 250, 604, 778, 204, 506, 709, 902, 226, 249, 289, 343, 416, 519, 613, 647, 705, 807, 905, 418, 438, 450, 514, 579, 581, 819, 873, 306, 867]
  for prefix in canadaPrefixes
    formats['+1' + prefix] = { country: 'CA' }

  for prefix, format of formats
    if prefix.substring(0, 2) == "+1"
      format.format = '+. (...) ...-....'
