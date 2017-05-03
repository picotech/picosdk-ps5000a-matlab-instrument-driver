%%PS5000A_ID_BLOCK_2_SCOPE_EXAMPLE Code for communicating with an instrument. 
%  
%   This is a modified version of the machine generated representation of 
%   an instrument control session using a device object. The instrument 
%   control session comprises all the steps you are likely to take when 
%   communicating with your instrument. These steps are:
%       
%       1. Create a device object   
%       2. Connect to the instrument 
%       3. Configure properties 
%       4. Invoke functions 
%       5. Disconnect from the instrument 
%  
%   To run the instrument control session, type the name of the file,
%   PS5000A_ID_Block_2_Scope_Example, at the MATLAB command prompt.
% 
%   The file, PS5000A_ID_BLOCK_2_SCOPE_EXAMPLE.M must be on your MATLAB PATH. For additional information
%   on setting your MATLAB PATH, type 'help addpath' at the MATLAB command
%   prompt.
%
%   Example:
%       PS5000A_ID_Block_2_Scope_Example;
%
%   Description:
%       Demonstrates how to call functions in order to capture a block of
%       data from two PicoScope 5000 Series oscilloscopes.
%
%   See also ICDEVICE.
%
%   Copyright (C) 2016 - 2017 Pico Technology Ltd. All rights reserved.

%% CLEAR COMMAND WINDOW AND CLOSE ANY FIGURES

clc;
close all;

%% LOAD CONFIGURATION INFORMATION

PS5000aConfig;

%% DEVICE CONNECTION

% Create a device object - provide the serial number as a second argument if required. 
ps5000aDeviceObj1 = icdevice('picotech_ps5000a_generic.mdd', '');
ps5000aDeviceObj2 = icdevice('picotech_ps5000a_generic.mdd', '');

% Connect device object to hardware.
connect(ps5000aDeviceObj1);
connect(ps5000aDeviceObj2);

%% SET CHANNELS

% Default driver settings used - use ps5000aSetChannel to turn channels on
% or off and set voltage ranges, coupling, as well as analogue offset.

%% SET DEVICE RESOLUTION

% Max. resolution with 2 channels enabled is 15 bits.
[status1.setResolution, scope1.resolution] = invoke(ps5000aDeviceObj1, 'ps5000aSetDeviceResolution', 15);
[status2.setResolution2, scope2.resolution] = invoke(ps5000aDeviceObj2, 'ps5000aSetDeviceResolution', 8);

%% SET SIMPLE TRIGGER

% Channel     : 0 (PS5000A_CHANNEL_A)
% Threshold   : 1000 (mV) on device 1, 500 (mV) on device 2
% Direction   : 2 (Rising)
% Delay       : 0
% Auto trigger: 2000 ms

[status1.setSimpleTrigger] = invoke(ps5000aDeviceObj1, 'setSimpleTrigger', 0, 1000, 2, 0, 2000);
[status2.setSimpleTrigger] = invoke(ps5000aDeviceObj2, 'setSimpleTrigger', 0, 500, 2, 0, 2000);

%% GET TIMEBASE

% Driver default timebase index used - use ps5000aGetTimebase or
% ps5000aGetTimebase2 to query the driver as to suitability of using a
% particular timebase index then set the 'timebase' property if required.

% timebase     : 65 (default)
% segment index: 0

scope1.timebaseIndex = 65;

status1.getTimebase = PicoStatus.PICO_INVALID_TIMEBASE;

while (status1.getTimebase == PicoStatus.PICO_INVALID_TIMEBASE)
    
    [status1.getTimebase, scope1.timeIntervalNanoSeconds, scope1.maxSamples] = invoke(ps5000aDeviceObj1, 'ps5000aGetTimebase', scope1.timebaseIndex, 0);
    
    if (status1.getTimebase == PicoStatus.PICO_OK)
       
        break;
        
    else
        
        scope1.timebaseIndex = scope1.timebaseIndex + 1;
        
    end    
    
end

set(ps5000aDeviceObj1, 'timebase', scope1.timebaseIndex);

% Repeat for second device

scope2.timebaseIndex = 65;

status2.getTimebase = PicoStatus.PICO_INVALID_TIMEBASE;

while (status2.getTimebase == PicoStatus.PICO_INVALID_TIMEBASE)
    
    [status2.getTimebase, scope2.timeIntervalNanoSeconds, scope2.maxSamples] = invoke(ps5000aDeviceObj2, 'ps5000aGetTimebase', scope2.timebaseIndex, 0);
    
    if (status2.getTimebase == PicoStatus.PICO_OK)
       
        break;
        
    else
        
        scope2.timebaseIndex = scope2.timebaseIndex + 1;
        
    end    
    
end

set(ps5000aDeviceObj2, 'timebase', scope2.timebaseIndex);

%% SET BLOCK PARAMETERS AND CAPTURE DATA

% Set pre-trigger and post-trigger samples.
set(ps5000aDeviceObj1, 'numPreTriggerSamples', 1024);
set(ps5000aDeviceObj1, 'numPostTriggerSamples', 2048);

set(ps5000aDeviceObj2, 'numPreTriggerSamples', 2048);
set(ps5000aDeviceObj2, 'numPostTriggerSamples', 4096);


% Start the devices collecting data

% Capture a block of data:
%
% segment index: 0

status1.ps5000aRunBlock = invoke(ps5000aDeviceObj1, 'ps5000aRunBlock', 0);
status2.ps5000aRunBlock = invoke(ps5000aDeviceObj2, 'ps5000aRunBlock', 0);

% Poll the device driver to see if data is available

scope1.ready = PicoConstants.FALSE;
scope2.ready = PicoConstants.FALSE;

while (scope1.ready == PicoConstants.FALSE || scope2.ready == PicoConstants.FALSE)
    
    [status1.ready, scope1.ready] = invoke(ps5000aDeviceObj1, 'ps5000aIsReady');
    [status2.ready, scope2.ready] = invoke(ps5000aDeviceObj2, 'ps5000aIsReady');
    
    pause(0.01);
    
end


% Retrieve data values:
%
% start index       : 0
% segment index     : 0
% downsampling ratio: 1
% downsampling mode : 0 (PS5000A_RATIO_MODE_NONE)

[scope1.chA, scope1.chB, scope1.chC, scope1.chD, scope1.numSamples, scope1.overflow] = invoke(ps5000aDeviceObj1, 'getBlockData', 0, 0, 1, 0);

[scope2.chA, scope2.chB, scope2.chC, scope2.chD, scope2.numSamples, scope2.overflow] = invoke(ps5000aDeviceObj2, 'getBlockData', 0, 0, 1, 0);


%% PROCESS DATA

% Plot data values.

scope1.figureName = ['PicoScope ', ps5000aDeviceObj1.InstrumentModel, ' (', get(ps5000aDeviceObj1, 'unitSerial'), ') Block Capture'];
scope1.figure = figure('Name', scope1.figureName, ...
    'NumberTitle','off');

% Calculate time (nanoseconds) and convert to milliseconds
% Use timeIntervalNanoSeconds output from ps5000aGetTimebase or
% ps5000aGetTimebase2 or calculate from Programmer's Guide.

scope1.timeNs = double(scope1.timeIntervalNanoSeconds) * double(0:scope1.numSamples - 1);
scope1.timeMs = scope1.timeNs / 1e6;

% Channel A 
plot(scope1.timeMs, scope1.chA, 'b');
title('Channel A');
xlabel('Time (ms)');
ylabel('Voltage (mV)');
grid on;

movegui(scope1.figure, 'west');

scope2.figureName = ['PicoScope ', ps5000aDeviceObj2.InstrumentModel, ' (', get(ps5000aDeviceObj2, 'unitSerial'), ') Block Capture'];
scope2.figure = figure('Name', scope2.figureName, ...
    'NumberTitle','off');

% Calculate time (nanoseconds) and convert to milliseconds
% Use timeIntervalNanoSeconds output from ps5000aGetTimebase or
% ps5000aGetTimebase2 or calculate from Programmer's Guide.

scope2.timeNs = double(scope2.timeIntervalNanoSeconds) * double(0:scope2.numSamples - 1);
scope2.timeMs = scope2.timeNs / 1e6;

% Channel A 
plot(scope2.timeMs, scope2.chA, 'b');
title('Channel A');
xlabel('Time (ms)');
ylabel('Voltage (mV)');
grid on;

movegui(scope2.figure, 'east');

%% STOP DEVICES
% Stop the device
[status1.stop] = invoke(ps5000aDeviceObj1, 'ps5000aStop');
[status2.stop] = invoke(ps5000aDeviceObj2, 'ps5000aStop');

%% DEVICE DISCONNECTION

% Disconnect device object from hardware.
disconnect(ps5000aDeviceObj1);
delete(ps5000aDeviceObj1);

disconnect(ps5000aDeviceObj2);
delete(ps5000aDeviceObj2);