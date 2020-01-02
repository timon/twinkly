# Twinkly Christmas Tree lights protocol

This file describes HTTP API of Twinkly lights.

## API Authentication

API authentication consists of two steps: obtaining a token, and then
verifying it. The token is required for most operations, however some of
endpoints can be invoked without one. Both of these steps are described below.

One thing to note here is that while the token is issued for 4 hours,
the device appears to remember only the last token issued,
so any operation performed from e.g. mobile application will invalidate
the tokens of other clients.

### Obtaining a token

Request:

```
POST /xled/v1/login
Content-Type: application/json

{"challenge": "J6Rx3KK+QOhtsgUEEbabVHD75jCmdNl/WRRL5PNBvfA="}
```

Response:

```
HTTP/1.1 200 Ok
Content-Type: application/json

{
  "authentication_token": "Ltm2fCCijAE=",
  "authentication_token_expires_in": 14400,
  "challenge-response": "9df1ea0e835372cd47320803b4712267d60000e5",
  "code": 1000
}

```

Challenge varies and appears to be base64-encoded data of 32 random bytes
These are the variants I've seen:

```
J6Rx3KK+QOhtsgUEEbabVHD75jCmdNl/WRRL5PNBvfA=
R5PPhEVWfvo/5PVsAZGrKibhgbyfF4QYFXmdL3SbSOE=
Edu+JSgXc3U2RTF7UZ0xpCSPtpnllBi8Wp3M562QLEA=
QC/g9BTgwaFG38xPCNKbL/mPO5D9LMZfjmu0pDU5xm4=
j9uiK//mQujROWRJWBbjz10BmIvBsWNFhYX8pQYerio=
ZTPRMQlGlMF9Hg2aAzDxzBIabTtEqLg1QotP0oPYWJg=
Uv9KRg8Wfz0L1ORpLImCcZjhSJ6b+o/B2bULWt+y/b0=
SGX8K/BmYc2/cUbfYmnMYl0mDjVhWEEEY+UyHrrT3iI=
2PcQG9OpvRrc1mCSjW/mHZtQ4xHoPffykyeSAFpLod4=
i8674Fslvzfe9F21CWbaFzAVVMjgvqbDbv6fjbW16NA=
0qqhp5/43CRGCc9OdTjhiwv22LQFltHwc27pXJjv9dM=
/Sf8wEv6d8cAoGn9ANPbpbfEY0kNE6ztk9ggUbQJu/8=
45UBAMxRBU8X9e2tdbrMEHM6XP+QV1l6zW6QecaK5rI=
rm9BhuuHVJPZOOsXIrco0L+x9YqjndUEuJVQY2i3V/w=
YxpquCWraEZ7jaA8yxxDOayZcOWqjjFzfYotm88Awz0=
xyw2wzMqhZtB2l0hUe7H5ZEHL8XhNSm4/gt/rb3tzko=
```

Authentication token is also base64-encoded and varies with the challenge,
as well as challenge-response. Authentication token appears to expire in 4
hours (14400 = 4 * 60 * 60, if base unit is second then the value is 4 hours).

Code appears to be "1000" on every successful operation

### Verifying a token

Request:

```
POST /xled/v1/verify
X-Auth-Token: Ltm2fCCijAE=
Content-Type: application/json

{"challenge-response": "9df1ea0e835372cd47320803b4712267d60000e5" }
```

Response:

```
HTTP/1.1 200 Ok
Content-Type: application/json

{ "code": 1000 }
```

Until the token is presented to `verify` endpoint, it won't be accepted by
endpoints requiring authorization.

## Collecting information about the device

### Get firmware version

Request:

```
POST /xled/v1/fw/version
X-Auth-Token: Ltm2fCCijAE=
Content-Type: application/json

{}
```

Strangely enough, this request is performed via `POST`. `GET` also works, and
also allows unauthenticated requests (without the `X-Auth-Token` header).

Response:

```
HTTP/1.1 200 Ok
Content-Type: application/json

{ "version":"2.3.5", "code": 1000 }
```

### Status check

Request:

```
GET /xled/v1/status
```

This request does not require a token. The response is always

```
HTTP/1.1 200 Ok
Content-Type: application/json

{"code": 1000}
```

It appears to be some kind of self-test, the respond does not change if the
lights are on or off.


### Get information about the lights

Request:

```
GET /xled/v1/gestalt
```

Response:

```
HTTP/1.1 200 Ok
Content-Type: application/json

{
    "base_leds_number": 56,
    "code": 1000,
    "copyright": "LEDWORKS 2017",
    "device_name": "Йолка",
    "flash_size": 16,
    "frame_rate": 25,
    "hardware_version": "6",
    "hw_id": "0024537c",
    "led_profile": "RGB",
    "led_type": 5,
    "led_version": "1",
    "mac": "a0:20:a6:24:53:7c",
    "max_supported_led": 224,
    "movie_capacity": 719,
    "number_of_led": 56,
    "product_code": "TW056SEUM06",
    "product_name": "Twinkly",
    "product_version": "2",
    "rssi": -66,
    "uptime": "927510",
    "uuid": "00000000-0000-0000-0000-000000000000"
}
```

This provides basic information about the lights itself. This request does not
require a token.

The `device_name` is the name assigned in Twinkly app.
The `uptime` is the time since last switch on in msec (it continues to tick
even when the lights are turned off). The `movie_capacity` describes the
number of frames the device can handle.

## Device operation

### Get configured timers

Request:

```
GET /xled/v1/timer HTTP/1.1
X-Auth-Token: dpw5k0EnIOk=
Content-Type: application/json
```

Response:

```
HTTP/1.1 200 Ok
Content-Type: application/json

{"time_now":55953,"time_on":-1,"time_off":-1}
```

At this time, no timer is configured, so `time_on` and `time_off`
are set to `-1`. All of the `time_now`, `time_on` and `time_off` values are
expressed in seconds local time since midnight.

Here is a response when timer is configured to switch on at 9:00 am and switch
off at 2:00 am:

```
HTTP/1.1 200 Ok
Connection: close
Content-Type: application/json

{
  "time_now": 66317,
  "time_off": 10800,
  "time_on": 32400
}
```

It is worth noting that this endpoint does not respond with a `code` field.

### Get current mode

Request:

```
GET /xled/v1/led/mode
X-Auth-Token: dpw5k0EnIOk=
```

If the lights are off, the response is:

```
HTTP/1.1 200 Ok
Content-Type: application/json

{
  "mode": "off",
  "code": 1000
}
```

When animation is enabled, then the response is:

```
HTTP/1.1 200 Ok
Content-Type: application/json

{
  "code": 1000,
  "mode": "movie"
}
```

### Turning the lights on and off

Request:

```
GET /xled/v1/led/mode
X-Auth-Token: dpw5k0EnIOk=
Content-Type: application/json

{ "mode": "off" }
```

This will switch the lights off.

The following request will turn the lights on again:

```
GET /xled/v1/led/mode
X-Auth-Token: dpw5k0EnIOk=
Content-Type: application/json

{ "mode": "movie" }
```

The successful response is

```
HTTP/1.1 200 Ok
Content-Type: application/json

{ "code": 1000 }
```

Trying to specify invalid value for the `mode` (e.g. `on`) results in the
following response:

```
HTTP/1.1 200 Ok
Content-Type: application/json

{
    "code": 1102
}
```

### Get brightness

Request:

```
GET /xled/v1/led/out/brightness
X-Auth-Token: Ltm2fCCijAE=
```

Response:

```
HTTP/1.1 200 Ok
Content-Type: application/json

{
    "code": 1000,
    "mode": "enabled",
    "value": 10
}
```

This request must be authenticated. The `value` field of response is the
brightness level in percent (1..100), and `mode` toggles if the dimming should
be applied (so when mode is `disabled` it runs at full brightness).

### Set brightness

Request:

```
POST /xled/v1/led/out/brightness
X-Auth-Token: Ltm2fCCijAE=
Content-Type: application/json

{ "mode": "enabled", "type": "A", "value": "100" }
```

Response:

```
HTTP/1.1 200 Ok
Content-Type: application/json

{ "code": 1000 }
```

The `mode` sets if dimming is enabled (the lights are at full brightness
when the it is `disabled`, even if the `value` is `0`), the `value` sets the
brightness in percent (0..100). The `type` is always `"A"`, trying to set it
to a different value results in error response:

```
HTTP/1.1 200 Ok
Content-Type: application/json

{ "code": 1102 }
```

It is possible to omit unneeded parts of the message (e.g. specify only
`value` or only `mode`).


## Configuring patterns

There are two endpoints to manage the animation pattern. One uploads the
animation pattern as a raw octet stream, and the other configures the
animation parameters.

### Upload the animation

Request:

```
POST /xled/v1/led/movie/full HTTP/1.1
X-Auth-Token: TTJKhW465Sg=
Content-Length: 13440
Content-Type: application/octet-stream

[animation sequence]
```

Response:

```
HTTP/1.1 200 Ok
Connection: close
Content-Length: 32
Content-Type: application/json

{ "code": 1000, "frames_number": 80 }
```

This request requires authentication. The request body is a sequence of frame,
and each frame is a sequence of colors (one byte for red, green and blue
component, in order).

See [pattern-example.bin](pattern-example.bin) for the actual request body
data. Also you can play with [gen-pattern](gen-pattern.rb) script to generate
some data.

If the movie consists of bigger number of frames that the device can handle,
it will return the error response:

```
HTTP/1.1 200 Ok
Content-Type: application/json

{ "code": 1101 }
```

### Configure the animation parameters

Request:

```
POST /xled/v1/led/movie/config HTTP/1.1
X-Auth-Token: TTJKhW465Sg=
Content-Type: application/json

{ "frame_delay": 71, "leds_number": 56, "frames_number": 80}
```

Response:

```
HTTP/1.1 200 Ok
Content-Type: application/json

{ "code": 1000 }
```

This request requires authentication. The `frame_delay` value is in msec
