jQuery.mobilePhoneNumber
========================

This plugin allows you to add mobile phone number formatting in any HTML input: [demo here](http://stripe.github.io/jquery.mobilePhoneNumber/example/).

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

Dependencies:
- [jQuery.caret](http://plugins.jquery.com/caret/)
- Tested on jQuery 1.8.3

## API

### $.fn.mobilePhoneNumber([options])
Enable the automatic mobile phone number for an input.
- options (optional): object
  - allowPhoneWithoutPrefix (optional): allows the user to type a phone number without the prefix for this specific prefix.

### $.fn.mobilePhoneNumber('val')
Returns a `String` with the prefixed phone number.

### $.fn.mobilePhoneNumber('validate')
Check if the entered phone number is valid.
Note: this implementation is too naive, it only validates if the phone number entered is longer than the prefix.

### $.fn.mobilePhoneNumber('country')
Returns the country code of the entered phone number.

### $.fn.mobilePhoneNumber('prefix')
Returns the prefix of the entered phone number.

### $.formatMobilePhoneNumber(phone)
Returns the formatted phone number.

## Events

### country.mobilePhoneNumber
Triggered when the country has changed.
