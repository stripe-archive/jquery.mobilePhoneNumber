# jQuery.mobilePhoneNumber [![Build Status](https://travis-ci.org/stripe/jquery.mobilePhoneNumber.svg?branch=master)](https://travis-ci.org/stripe/jquery.mobilePhoneNumber)

A general purpose library for validating and formatting mobile phone numbers.

``` javascript
$('input.phone-num').mobilePhoneNumber();
```

Your can bind to an event when the user changes the country of the phone number:

``` javascript
$('input.phone-num').bind('country.mobilePhoneNumber', function(e, country) {
  console.log('The new country code:', country);
})
```

You can find a [demo here](http://stripe.github.io/jquery.mobilePhoneNumber/example).

Dependencies:

* [jQuery.caret](http://plugins.jquery.com/caret)
* Tested on jQuery 1.8.3 and 1.11.1

## API

### $.fn.mobilePhoneNumber([options])

Enables phone number formatting.

Options:

* `allowPhoneWithoutPrefix`: allows the user to type a phone number without the prefix for this specific value.

Example:

``` javascript
$('input.phone-num').mobilePhoneNumber({
  allowPhoneWithoutPrefix: '+1'
});
```

### $.fn.mobilePhoneNumber('val')

Returns the phone number value with prefix, but without other formatting.

Example:

``` javascript
$('input.phone-num').val(); //=> '+1 (415) 123-5554'
$('input.phone-num').mobilePhoneNumber('val'); //=> '+14151235554'
```

### $.fn.mobilePhoneNumber('validate')

Returns whether the phone number is valid.

*Note:* this implementation is very naive; it only validates that the phone number is longer than its prefix.

Example:

``` javascript
$('input.phone-num').val(); //=> '+1 (415) 123-5554'
$('input.phone-num').mobilePhoneNumber('validate'); //=> true

$('input.phone-num').val(); //=> '+43'
$('input.phone-num').mobilePhoneNumber('validate'); //=> false
```

### $.fn.mobilePhoneNumber('country')

Returns the two-letter country code of the phone number.

Example:

``` javascript
$('input.phone-num').val(); //=> '+32 495 12 34 56'
$('input.phone-num').mobilePhoneNumber('country'); //=> 'BE'
```

### $.fn.mobilePhoneNumber('prefix')

Returns the prefix of the phone number.

Example:

``` javascript
$('input.phone-num').val(); //=> '+32 495 12 34 56'
$('input.phone-num').mobilePhoneNumber('prefix'); //=> '+32'
```

### $.formatMobilePhoneNumber(phone)

Returns the formatted phone number.

Example:

``` javascript
$.formatMobilePhoneNumber('14151235554'); //=> '+1 (415) 123-5554'
```

## Events

### country.mobilePhoneNumber

Triggered when the country has changed.

Example:

``` javascript
$('input.phone-num').bind('country.mobilePhoneNumber', function(e, country) {
  console.log('The new country code:', country);
})

// Simulate user input
$('input.phone-num').val('+32495123456').keyup();
//=> The new country code: BE
```

## Building

Run `cake build`

## Running tests

Run `cake test`

## Mobile recommendations

We recommend you set the `pattern`, `type`, and `x-autocompletetype` attributes, which will trigger autocompletion and a numeric keypad to display on touch devices:

``` html
<input class="phone-num" type="tel" pattern="\d*" x-autocompletetype="tel">
```

You may have to turn off HTML5 validation (using the `novalidate` form attribute) when using this `pattern`, since it won't permit spaces and other characters that appear in the formatted version of the phone number.
