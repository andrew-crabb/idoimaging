Papaya 
======

Papaya is a pure JavaScript medical research image viewer, compatible across a range of popular web browsers, 
including mobile devices.  The orthogonal viewer supports NIFTI (.nii or .nii.gz) files, overlays and atlas labels.  See 
the [user guide](http://ric.uthscsa.edu/mango/papaya_userguide.html) for a full list of features.

[![ScreenShot](https://raw.github.com/rii-mango/Papaya/master/README-img.png)](http://ric.uthscsa.edu/mango/papaya/)

**Last Release:** http://ric.uthscsa.edu/mango/papaya/

**Current Beta:** http://ric.uthscsa.edu/mango/papayabeta/

**Requirements:** Firefox (7), Chrome (7), Safari (6), MobileSafari (iOS 6), IE (10)

**User Guide:** http://ric.uthscsa.edu/mango/papaya_userguide.html

**Developer Guide:** http://ric.uthscsa.edu/mango/papaya_devguide.html

Quickstart Guide
------

###Development
Load `tests/debug.html` in your [favorite](http://www.jetbrains.com/webstorm/) JavaScript debugger.


###Building
Run `papaya-builder.sh` to create the build files.  A typical usage might be `papaya-builder.sh -sample -atlas`

```shell
usage: papaya-builder [options]
 -atlas <file>     add atlas
 -help             print this message
 -images <files>   images to include
 -local            build for local usage
 -root <dir>       papaya project directory
 -sample           include sample image
```

###Usage
See the [developer guide](http://ric.uthscsa.edu/mango/papaya_devguide.html) for a full list of configurable parameters.  

####Basic usage (loads a blank viewer)
```html
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
    <head>
        <link rel="stylesheet" type="text/css" href="papaya.css" />
        <script type="text/javascript" src="papaya.js"></script>
        <title>Papaya Viewer</title>
    </head>

    <body>
        <div class="papaya"></div>
    </body>
</html>
```

####To automatically load images and specify other options
```html
<head>
    ...
    <script type="text/javascript">
        var params = [];
        params["worldSpace"] = true;
        params["images"] = ["data/myBaseImage.nii.gz", "data/myOverlayImage.nii.gz"];
        params["myOverlayImage.nii.gz"] = {"min": 4, "max": 10};
        // for more options, see http://ric.uthscsa.edu/mango/papaya_devguide.html
    </script>
<head>

...

<div class="papaya" data-params="params"></div>

```



