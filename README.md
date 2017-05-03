# PicoScope 5000 Series - MATLAB Generic Instrument Driver

This MATLAB® Generic Instrument Driver allows you to acquire data from the PicoScope® 5000 Series Flexible Resolution Oscilloscopes 
and control in-built signal generator functionality. The data could be processed in MATLAB using functions from Toolboxes such 
as [Signal Processing Toolbox](https://www.mathworks.com/products/signal.html). 

The driver has been created using Instrument Control Toolbox v3.2. 

This Instrument Driver package includes the following: 

* The MATLAB Generic Instrument Driver 
* Example scripts that demonstrate how to call functions in order to capture data in various collection modes, as well as using the signal generator.

* The driver can be used with the Test and Measurement Tool to carry out the following: 

  * Acquire data in Block mode 
  * Acquire data in Rapid Block mode 
  * Use the Built-in Function/Arbitrary Waveform Generator (model-dependent)

## Supported Models

The driver will work with the following PicoScope models:

* PicoScope 5242A/B & 5442A/B 
* PicoScope 5243A/B & 5443A/B  
* PicoScope 5244A/B & 5444A/B

Please note that the driver will not work with the [PicoScope 5203 and 5204](https://uk.mathworks.com/matlabcentral/fileexchange/59657-picoscope-5203-and-5204-examples) devices.

## Getting started

### Prerequisites

* [MATLAB](https://uk.mathworks.com/products/matlab.html) for Microsoft Windows (32- or 64-bit) or Linux operating systems (64-bit).
* The [PicoScope Support Toolbox](http://uk.mathworks.com/matlabcentral/fileexchange/53681-picoscope-support-toolbox)

**Notes:**

* MATLAB 2015b is recommended for 32-bit versions of MATLAB on Microsoft Windows operating systems.
* Support for MATLAB on Mac OS X is limited. Please contact our [Technical Support Team](https://github.com/picotech/picosdk-ps5000a-matlab-instrument-driver#obtaining-support) for further information.

### Installing drivers

Drivers are available for the following platforms. Refer to the subsections below for further information.

#### Windows

* Download the PicoSDK (32-bit or 64-bit) driver package installer from our [Downloads page](https://www.picotech.com/downloads).

#### Linux

* Follow the instructions from our [Linux Software & Drivers for Oscilloscopes and Data Loggers](https://www.picotech.com/downloads/linux) to install the required `libps5000a` and `libpswrappers` driver packages.

#### Mac OS X

* Visit our [Downloads page](https://www.picotech.com/downloads) and download the PicoScope Beta for Mac OS X application. Contact our [Technical Support Team](https://github.com/picotech/picosdk-ps6000-matlab-instrument-driver#obtaining-support) for further information.

### Programmer's Guides

You can download the [Programmer's Guide](https://www.picotech.com/download/manuals/PicoScope5000SeriesAApiMatlabInstrumentDriverGuide.pdf) providing a description of the functions provided by this Instrument Driver.

**Notes:**

The example files have been renamed - please refer to the scripts in the examples directory for further information.

## Obtaining support

Please visit our [Support page](https://www.picotech.com/tech-support) to contact us directly or visit our [Test and Measurement Forum](https://www.picotech.com/support/forum71.html) to post questions.

Please leave a comment and rating for this submission on our [MATLAB Central File Exchange page](https://uk.mathworks.com/matlabcentral/fileexchange/42820-picoscope-5000-series-matlab-generic-instrument-driver).

## Copyright and licensing

picosdk-ps5000a-matlab-instrument-driver is Copyright (C) 2013 - 2017 Pico Technology Ltd. All rights reserved. See [LICENSE.md](LICENSE.md) for license terms. 

*PicoScope* is a registered trademark of Pico Technology Ltd. 

*MATLAB* is a registered trademark of The Mathworks, Inc. *Signal Processing Toolbox*
is a trademark of The Mathworks, Inc.

*Windows* is a registered trademark of Microsoft Corporation. 

*Mac* and *OS X* are registered trademarks of Apple, Inc. 

*Linux* is the registered trademark of Linus Torvalds in the U.S. and other countries.

## Contributing

Contributions to examples are welcome. Please refer to our [guidelines for contributing](.github/CONTRIBUTING.md) for further information.

