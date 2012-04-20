Velvet is a UI bridging framework for Mac OS X, built to allow AppKit to interoperate with layer-based UIs. In particular, Velvet allows the use of normal Cocoa views and functionality in conjunction with frameworks like [TwUI](http://github.com/bitswift/twui) and [Chameleon](http://github.com/BigZaphod/Chameleon).

# Features

 - Defines a modern API for layer-backed views (`VELView`), and provides some basic view classes, including:
   - `VELControl`, a control class supporting block-based actions
   - `VELImageView`, a simple image view with an easy-to-use API for stretchable images
   - `VELLabel`, a text label supporting formatting and sub-pixel antialiasing
 - Support for creating an AppKit view hierarchy within any Velvet hierarchy, using `VELNSView`
 - Automatic alignment of Velvet views to integral pixels (with an option to disable it), avoiding blurriness from landing on half-pixels
 - Slo-mo animation mode for debugging (similar to the iOS Simulator)
 - Automatic HiDPI support
 - A view controller class usable with any `VELView` instance, including `VELNSView`
 - Event recognizers (similar to `UIGestureRecognizer`) that work with _any_ bridged view class
 - Improvements to some AppKit view and control classes to make bindings more useful
 - Miscellaneous conveniences for bridging Core Animation and Core Graphics functionality with that of AppKit

Additionally, most of the above features are unit tested, to validate the typical use cases and detect any future breakage.

See also [our fork of TwUI](http://github.com/bitswift/twui), which integrates Velvet and adds view classes to bridge into and out of TwUI.

# License

Velvet is released under the 3-clause BSD license. See the LICENSE file for more information.
