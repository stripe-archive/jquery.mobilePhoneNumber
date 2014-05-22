$ = jQuery

formatForPhone_ = (phone, allowsPhoneWithoutPrefix = null) ->
  if phone.indexOf('+') != 0 and allowsPhoneWithoutPrefix
    phone = allowsPhoneWithoutPrefix + phone.replace(/[^0-9]/g, '')
  else
    phone = '+' + phone.replace(/[^0-9]/g, '')
  bestFormat = null
  precision = 0
  for prefix, format of formats
    if phone.length >= prefix.length && phone.substring(0, prefix.length) == prefix && prefix.length > precision
      bestFormat = format
      bestFormat.prefix = prefix
      precision = prefix.length
  bestFormat

prefixesAreSubsets_ = (prefixA, prefixB) ->
  return true if prefixA == prefixB
  if prefixA.length < prefixB.length
    return prefixB.substring(0, prefixA.length) == prefixA
  return prefixA.substring(0, prefixB.length) == prefixB

formattedPhoneNumber_ = (phone, lastChar, allowsPhoneWithoutPrefix = null) ->
  if phone.length != 0 and (phone.substring(0, 1) == "+" or allowsPhoneWithoutPrefix)
    format = formatForPhone_(phone, allowsPhoneWithoutPrefix)
    if format && format.format
      phoneFormat = format.format
      phonePrefix = format.prefix

      if allowsPhoneWithoutPrefix
        if (allowsPhoneWithoutPrefix == phonePrefix or prefixesAreSubsets_(phonePrefix, allowsPhoneWithoutPrefix)) and (phone.indexOf('+') != 0 or phone.length == 0)
          phoneFormat = phoneFormat.substring(Math.min(phonePrefix.length, allowsPhoneWithoutPrefix.length) + 1)

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
  value = value.substring(0, @caret().start) +
          String.fromCharCode(e.which) +
          value.substring(@caret().end, value.length)
  charDiff = value.length - @val().length
  selection = [ @caret().start, @caret().end ]
  selectionAtEnd = selection[1] == @val().length
  format_.call(@, value, e)
  if !selectionAtEnd
    s = selection[1] + charDiff
    @[0].selectionStart = s
    @[0].selectionEnd = s

formatUp_ = (e) ->
  checkForCountryChange_.call(@)
  value = @val()
  return if e.keyCode == 8 && (@caret().end == @caret().start && @caret().end == value.length)
  format_.call(@, value, e)

formatBack_ = (e) ->
  return if !e
  return if e.meta
  value = @val()
  return if value.length == 0
  return if !(@caret().end == @caret().start && @caret().end == value.length)
  return if e.keyCode != 8

  value = value.substring(0, value.length - 1)
  e.preventDefault()
  phone = formattedPhone_.call(@, value, false)
  if @val() != phone
    @val(phone)

format_ = (value, e) ->
  phone = formattedPhone_.call(@, value, true)
  if phone != @val()
    selection = [ @caret().start, @caret().end ]
    selectionAtEnd = selection[1] == @val().length
    e.preventDefault()
    @val(phone)
    if !selectionAtEnd
      @[0].selectionStart = selection[1]
      @[0].selectionEnd = selection[1]

formattedPhone_ = (phone, lastChar) ->
  if phone.indexOf('+') != 0 && @data('allowsPhoneWithoutPrefix')
    phone = phone.replace(/[^0-9]/g, '')
  else
    phone = '+' + phone.replace(/[^0-9]/g, '')
  formattedPhoneNumber_(phone, lastChar, @data('allowsPhoneWithoutPrefix'))

checkForCountryChange_ = ->
  phone = @val()
  format = formatForPhone_(phone, @data('allowsPhoneWithoutPrefix'))
  country = null
  country = format.country if format
  if @mobilePhoneCountry != country
    @mobilePhoneCountry = country
    @trigger('country.mobilePhoneNumber', country)

mobilePhoneNumber = {}
mobilePhoneNumber.init = ->
  @bind('keypress', restrictEventAndFormat_.bind($(@)))
  @bind('keyup', formatUp_.bind($(@)))
  @bind('keydown', formatBack_.bind($(@)))
  @data('allowsPhoneWithoutPrefix', null)

mobilePhoneNumber.allowsPhoneWithoutPrefix = (prefix) ->
  @data('allowsPhoneWithoutPrefix', prefix)

mobilePhoneNumber.val = ->
  val = @val().replace(/[^0-9]/g, '')
  format = formatForPhone_(val, @data('allowsPhoneWithoutPrefix'))
  if @val().indexOf('+') == 0 or !@data('allowsPhoneWithoutPrefix')?
    '+' + val
  else
    @data('allowsPhoneWithoutPrefix') + val

mobilePhoneNumber.validate = ->
  val = @mobilePhoneNumber('val')
  format = formatForPhone_(val, @data('allowsPhoneWithoutPrefix'))
  return true unless format
  return val.length > format.prefix.length

mobilePhoneNumber.country = ->
  format = formatForPhone_(@mobilePhoneNumber('val'))
  format.country if format

mobilePhoneNumber.prefix = ->
  countryCode = @mobilePhoneNumber('country')
  return "" if !countryCode?
  $.mobilePhoneNumberPrefixFromCountryCode(countryCode)

$.fn.mobilePhoneNumber = (method, args...) ->
  method = 'init' unless method?
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
  '+1473' :
    country : 'GD',
  '+1671' :
    country : 'GU',
  '+1876' :
    country : 'JM',
  '+1664' :
    country : 'MS',
  '+1767' :
    country : 'DM',
  '+1849' :
    country : 'DO',
  '+1441' :
    country : 'BM',
  '+1246' :
    country : 'BB',
  '+1242' :
    country : 'BS',
  '+1684' :
    country : 'AS',
  '+1264' :
    country : 'AI',
  '+1268' :
    country : 'AG',
  '+1670' :
    country : 'MP',
  '+1939' :
    country : 'PR',
  '+1868' :
    country : 'TT',
  '+1649' :
    country : 'TC',
  '+1869' :
    country : 'KN',
  '+1758' :
    country : 'LC',
  '+1784' :
    country : 'VC',
  '+1284' :
    country : 'VG',
  '+1340' :
    country : 'VI',
  '+1' :
    country : 'US',
  '+972' :
    country : 'IL',
  '+93' :
    country : 'AF',
  '+355' :
    country : 'AL',
  '+213' :
    country : 'DZ',
  '+376' :
    country : 'AD',
  '+244' :
    country : 'AO',
  '+54' :
    country : 'AR',
  '+374' :
    country : 'AM',
  '+297' :
    country : 'AW',
  '+61' :
    country : 'AU',
    format : '+.. ... ... ...',
  '+43' :
    country : 'AT',
  '+994' :
    country : 'AZ',
  '+973' :
    country : 'BH',
  '+880' :
    country : 'BD',
  '+375' :
    country : 'BY',
  '+32' :
    country : 'BE',
    format : '+.. ... .. .. ..'
  '+501' :
    country : 'BZ',
  '+229' :
    country : 'BJ',
  '+975' :
    country : 'BT',
  '+387' :
    country : 'BA',
  '+267' :
    country : 'BW',
  '+55' :
    country : 'BR',
  '+246' :
    country : 'IO',
  '+359' :
    country : 'BG',
  '+226' :
    country : 'BF',
  '+257' :
    country : 'BI',
  '+855' :
    country : 'KH',
  '+237' :
    country : 'CM',
  '+238' :
    country : 'CV',
  '+345' :
    country : 'KY',
  '+236' :
    country : 'CF',
  '+235' :
    country : 'TD',
  '+56' :
    country : 'CL',
  '+86' :
    country : 'CN',
    format : '+.. ..-........',
  '+57' :
    country : 'CO',
  '+269' :
    country : 'KM',
  '+242' :
    country : 'CG',
  '+682' :
    country : 'CK',
  '+506' :
    country : 'CR',
    format : '+... ....-....',
  '+385' :
    country : 'HR',
  '+53' :
    country : 'CU',
  '+537' :
    country : 'CY',
  '+420' :
    country : 'CZ',
  '+45' :
    country : 'DK',
    format : '+.. .. .. .. ..',
  '+253' :
    country : 'DJ',
  '+593' :
    country : 'EC',
  '+20' :
    country : 'EG',
  '+503' :
    country : 'SV',
    format : '+... ....-....',
  '+240' :
    country : 'GQ',
  '+291' :
    country : 'ER',
  '+372' :
    country : 'EE',
  '+251' :
    country : 'ET',
  '+298' :
    country : 'FO',
  '+679' :
    country : 'FJ',
  '+358' :
    country : 'FI',
    format : '+... .. ... .. ..',
  '+33' :
    country : 'FR',
    format : '+.. . .. .. .. ..',
  '+594' :
    country : 'GF',
  '+689' :
    country : 'PF',
  '+241' :
    country : 'GA',
  '+220' :
    country : 'GM',
  '+995' :
    country : 'GE',
  '+49' :
    country : 'DE',
    format : '+.. ... .......',
  '+233' :
    country : 'GH',
  '+350' :
    country : 'GI',
  '+30' :
    country : 'GR',
  '+299' :
    country : 'GL',
  '+590' :
    country : 'GP',
  '+502' :
    country : 'GT',
    format : '+... ....-....',
  '+224' :
    country : 'GN',
  '+245' :
    country : 'GW',
  '+595' :
    country : 'GY',
  '+509' :
    country : 'HT',
    format : '+... ....-....',
  '+504' :
    country : 'HN',
  '+36' :
    country : 'HU',
  '+354' :
    country : 'IS',
    format : '+... ... ....',
  '+91' :
    country : 'IN',
    format : '+.. .....-.....',
  '+62' :
    country : 'ID',
  '+964' :
    country : 'IQ',
  '+353' :
    country : 'IE',
    format : '+... .. .......',
  '+972' :
    country : 'IL',
  '+39' :
    country : 'IT',
    format : '+.. ... ......',
  '+81' :
    country : 'JP',
    format : '+.. ... .. ....',
  '+962' :
    country : 'JO',
  '+77' :
    country : 'KZ',
  '+254' :
    country : 'KE',
  '+686' :
    country : 'KI',
  '+965' :
    country : 'KW',
  '+996' :
    country : 'KG',
  '+371' :
    country : 'LV',
  '+961' :
    country : 'LB',
  '+266' :
    country : 'LS',
  '+231' :
    country : 'LR',
  '+423' :
    country : 'LI',
  '+370' :
    country : 'LT',
  '+352' :
    country : 'LU',
  '+261' :
    country : 'MG',
  '+265' :
    country : 'MW',
  '+60' :
    country : 'MY',
    format : '+.. ..-....-....',
  '+960' :
    country : 'MV',
  '+223' :
    country : 'ML',
  '+356' :
    country : 'MT',
  '+692' :
    country : 'MH',
  '+596' :
    country : 'MQ',
  '+222' :
    country : 'MR',
  '+230' :
    country : 'MU',
  '+262' :
    country : 'YT',
  '+52' :
    country : 'MX',
  '+377' :
    country : 'MC',
  '+976' :
    country : 'MN',
  '+382' :
    country : 'ME',
  '+212' :
    country : 'MA',
  '+95' :
    country : 'MM',
  '+264' :
    country : 'NA',
  '+674' :
    country : 'NR',
  '+977' :
    country : 'NP',
  '+31' :
    country : 'NL',
    format : '+.. .. ........',
  '+599' :
    country : 'AN',
  '+687' :
    country : 'NC',
  '+64' :
    country : 'NZ',
    format: '+.. ...-...-....',
  '+505' :
    country : 'NI',
  '+227' :
    country : 'NE',
  '+234' :
    country : 'NG',
  '+683' :
    country : 'NU',
  '+672' :
    country : 'NF',
  '+47' :
    country : 'NO',
  '+968' :
    country : 'OM',
  '+92' :
    country : 'PK',
    format : '+.. ...-.......',
  '+680' :
    country : 'PW',
  '+507' :
    country : 'PA',
  '+675' :
    country : 'PG',
  '+595' :
    country : 'PY',
  '+51' :
    country : 'PE',
  '+63' :
    country : 'PH',
    format : '+.. ... ....',
  '+48' :
    country : 'PL',
    format : '+.. ...-...-...',
  '+351' :
    country : 'PT',
  '+974' :
    country : 'QA',
  '+40' :
    country : 'RO',
  '+250' :
    country : 'RW',
  '+685' :
    country : 'WS',
  '+378' :
    country : 'SM',
  '+966' :
    country : 'SA',
  '+221' :
    country : 'SN',
  '+381' :
    country : 'RS',
  '+248' :
    country : 'SC',
  '+232' :
    country : 'SL',
  '+65' :
    country : 'SG',
    format : '+.. ....-....',
  '+421' :
    country : 'SK',
  '+386' :
    country : 'SI',
  '+677' :
    country : 'SB',
  '+27' :
    country : 'ZA',
  '+500' :
    country : 'GS',
  '+34' :
    country : 'ES',
    format : '+.. ... ... ...',
  '+94' :
    country : 'LK',
  '+249' :
    country : 'SD',
  '+597' :
    country : 'SR',
  '+268' :
    country : 'SZ',
  '+46' :
    country : 'SE',
  '+41' :
    country : 'CH',
    format : '+.. .. ... .. ..',
  '+992' :
    country : 'TJ',
  '+66' :
    country : 'TH',
  '+228' :
    country : 'TG',
  '+690' :
    country : 'TK',
  '+676' :
    country : 'TO',
  '+216' :
    country : 'TN',
  '+90' :
    country : 'TR',
    format : '+.. ... ... .. ..',
  '+993' :
    country : 'TM',
  '+688' :
    country : 'TV',
  '+256' :
    country : 'UG',
  '+380' :
    country : 'UA',
  '+971' :
    country : 'AE',
  '+44' :
    country : 'GB',
    format : '+.. .... ......',
  '+598' :
    country : 'UY',
  '+998' :
    country : 'UZ',
  '+678' :
    country : 'VU',
  '+681' :
    country : 'WF',
  '+967' :
    country : 'YE',
  '+260' :
    country : 'ZM',
  '+263' :
    country : 'ZW',
  '+591' :
    country : 'BO',
  '+673' :
    country : 'BN',
  '+243' :
    country : 'CD',
  '+225' :
    country : 'CI',
  '+500' :
    country : 'FK',
  '+379' :
    country : 'VA',
  '+852' :
    country : 'HK',
    format : '+... .... ....',
  '+98' :
    country : 'IR',
  '+850' :
    country : 'KP',
  '+82' :
    country : 'KR',
  '+856' :
    country : 'LA',
  '+218' :
    country : 'LY',
  '+853' :
    country : 'MO',
  '+389' :
    country : 'MK',
  '+691' :
    country : 'FM',
  '+373' :
    country : 'MD',
  '+258' :
    country : 'MZ',
  '+970' :
    country : 'PS',
  '+872' :
    country : 'PN',
  '+262' :
    country : 'RE',
  '+7' :
    country : 'RU',
    format : '+. ... ...-..-..',
  '+590' :
    country : 'BL',
  '+290' :
    country : 'SH',
  '+590' :
    country : 'MF',
  '+508' :
    country : 'PM',
  '+239' :
    country : 'ST',
  '+252' :
    country : 'SO',
  '+47' :
    country : 'SJ',
    format : '+.. ... .. ...',
  '+963' :
    country : 'SY',
  '+886' :
    country : 'TW',
  '+255' :
    country : 'TZ',
  '+670' :
    country : 'TL',
  '+58' :
    country : 'VE',
  '+84' :
    country : 'VN',

do (formats) ->
  # Canada
  canadaPrefixes = [403, 587, 780, 250, 604, 778, 204, 506, 709, 902, 226, 249, 289, 343, 416, 519, 613, 647, 705, 807, 905, 418, 438, 450, 514, 579, 581, 819, 873, 306, 867]
  for prefix in canadaPrefixes
    formats['+1' + prefix] = { country: 'CA' }

  for prefix, format of formats
    if prefix.substring(0, 2) == "+1"
      format.format = '+. (...) ...-....'
