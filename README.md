jQuery.mobilePhoneNumber
========================

This plugin allows you to add mobile phone number formatting in any HTML input: [demo here](todo).

Example:
``` javascript
$('input').mobilePhoneNumber();
```

You can also listen to country change when the user edits the phone number:
``` javascript
$('input').bind('country.mobilePhoneNumber', function(e, country) {
  console.log('The new country code', country);
})
```

## API

### $.fn.mobilePhoneNumber()

Enable the automatic mobile phone number for an input.
Returns a `MobilePhoneNumberInput` object

### $.formatMobilePhoneNumber(phone)

Returns the formatted phone number.

### MobilePhoneNumberInput

#### setAllowsPhoneWithoutPrefix(prefix)
Allows the user to type a phone number without the prefix for this specific prefix.
- `prefix`: `String`, example: "+1"

#### val()
Returns a `String` as a formatted phone number.

#### validate()
Check if the entered phone number is valid.
Note: this implementation is too naive, it only validates if the phone number entered is longer than the prefix.

#### country()
Returns the country code of the entered phone number.

#### prefix()
Returns the prefix of the entered phone number.

### Events

#### country.mobilePhoneNumber
Triggered when the country has changed.
