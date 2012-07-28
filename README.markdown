megabuffer
--------------

A syphon-based video buffer, with manual and OSC controls. 

OSC messages
--------------
    /syInApplicationName	set the Syphon input application name
    /syInServerName	set the Syphon input server name

    /bufferSize		set the size of the buffer (in frames)
    /fps	set the sampling rate
    /addMarker	add a marker (in development)
    /addMarkerWithLabel	add a marker with a label (in development)

    /scrubber/autoScrubDuration
    /scrubber/autoScrubToDelay
    /scrubber/delay
    /scrubber/gotoDelay
    /scrubber/gotoMarkerWithLabel
    /scrubber/gotoNextMarker
    /scrubber/gotoPrevMarker
    /scrubber/rate
    /scrubber/scrubMode



Installing
----------

Clone a copy of the repository:

      git://github.com/andreacremaschi/Megabuffer.git

Then, update the framework dependencies using [CocoaPods](https://github.com/CocoaPods/CocoaPods/):

      pod install

