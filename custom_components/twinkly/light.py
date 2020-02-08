"""Platform for light integration."""
import logging

import voluptuous as vol
import xled

from homeassistant.components.light import (
    ATTR_BRIGHTNESS,
    ATTR_BRIGHTNESS_PCT,
    PLATFORM_SCHEMA,
    SUPPORT_BRIGHTNESS,
    Light,
)
from homeassistant.const import CONF_HOST
import homeassistant.helpers.config_validation as cv

_LOGGER = logging.getLogger(__name__)

# Validation of the user's configuration
PLATFORM_SCHEMA = PLATFORM_SCHEMA.extend({vol.Required(CONF_HOST): cv.string})

TWINKLY_SUPPORT_FLAGS = SUPPORT_BRIGHTNESS


def setup_platform(hass, config, add_entities, discovery_info=None):
    """Set up the Twinkly Light platform."""
    host = config[CONF_HOST]

    # Add devices
    add_entities([TwinklyLight(host)])


class TwinklyLight(Light):
    """Representation of a Twinkly Light."""

    def __init__(self, host, hwaddr=None):
        """Initialize a Twinkly light."""
        self._control = xled.control.HighControlInterface(host, hwaddr)
        self._name = self._control.get_device_name().data["name"]
        self._state = None
        self._brightness = None

    @property
    def name(self):
        """Return the display name of this light."""
        return self._name

    @property
    def brightness(self):
        """Return the brightness of the light."""
        brightness = self._brightness
        if brightness is None:
            return brightness

        # Convert percent values to 0..255 range
        return int(round(brightness * 255 / 100.0))

    @property
    def is_on(self):
        """Return true if light is on."""
        return self._state

    @property
    def supported_features(self):
        """Flag supported features."""
        return TWINKLY_SUPPORT_FLAGS

    def turn_on(self, **kwargs):
        """Instruct the light to turn on."""

        brightness_pct = kwargs.get(ATTR_BRIGHTNESS_PCT)
        if brightness_pct is None:
            brightness = kwargs.get(ATTR_BRIGHTNESS)
            if brightness is not None:
                brightness_pct = int(round(brightness * 100.0 / 255))

        if brightness_pct is not None:
            self._control.set_brightness(brightness_pct)

        self._control.turn_on()

    def turn_off(self, **kwargs):
        """Instruct the light to turn off."""
        self._control.turn_off()

    def update(self):
        """Fetch new state data for this light."""
        self._state = self._control.is_on()

        brightness_data = self._control.get_brightness().data
        if brightness_data["mode"] == "enabled":
            self._brightness = brightness_data["value"]
        else:
            self._brightness = 100
