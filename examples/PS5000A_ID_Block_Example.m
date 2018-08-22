%% PicoScope 5000 Series (A API) Instrument Driver Oscilloscope Block Data Capture Example 
% This is an example of an instrument control session using a device 
% object. The instrument control session comprises all the steps you 
% are likely to take when communicating with your instrument. 
%
% These steps are:
%    
% # Create a device object   
% # Connect to the instrument 
% # Configure properties 
% # Invoke functions 
% # Disconnect from the instrument 
%  
% To run the instrument control session, type the name of the file,
% PS5000A_ID_Block_Example, at the MATLAB command prompt.
% 
% The file, PS5000A_ID_BLOCK_EXAMPLE.M must be on your MATLAB PATH. For
% additional information on setting your MATLAB PATH, type 'help addpath'
% at the MATLAB command prompt.
%
% *Example:*
%     PS5000A_ID_Block_Example;
%
% *Description:*
%     Demonstrates how to call functions in order to capture a block of
%     data from a PicoScope 5000 Series Oscilloscope
%     using the underlying 'A' API library functions.
%
% *See also:* <matlab:doc('icdevice') |icdevice|> | <matlab:doc('instrument/invoke') |invoke|>
%
% *Copyright:* © 2013-2018 Pico Technology Ltd. See LICENSE file for terms.

%% Suggested input test signals
% This example was published using the following test signals:
%
% * Channel A: 4 Vpp, 1 kHz sine wave
% * Channel B: 2 Vpp, 1 kHz ramp up wave

%% Clear command window and close any figures

clc;
close all;

%% Load configuration information

PS5000aConfig;

%% Device connection

% Check if an Instrument session using the device object |ps5000aDeviceObj|
% is still open, and if so, disconnect if the User chooses 'Yes' when prompted.
if (exist('ps5000aDeviceObj', 'var') && ps5000aDeviceObj.isvalid && strcmp(ps5000aDeviceObj.status, 'open'))
    
    openDevice = questionDialog(['Device object ps5000aDeviceObj has an open connection. ' ...
        'Do you wish to close the connection and continue?'], ...
        'Device Object Connection Open');
    
    if (openDevice == PicoConstants.TRUE)
        
        % Close connection to device.
        disconnect(ps5000aDeviceObj);
        delete(ps5000aDeviceObj);
        
    else

        % Exit script if User selects 'No'.
        return;
        
    end
    
end

% Create a device object. 
ps5000aDeviceObj = icdevice('picotech_ps5000a_generic', ''); 

% Connect device object to hardware.
connect(ps5000aDeviceObj);

%% Set channels
% Default driver settings applied to channels are listed below - use the
% Instrument Driver's |ps5000aSetChannel()| function to turn channels on or
% off and set voltage ranges, coupling, as well as analog offset.

% In this example, data is collected on channels A and B. If it is a
% 4-channel model, channels C and D will be switched off if the power
% supply is connected.

% Channels       : 0 - 1 (ps5000aEnuminfo.enPS5000AChannel.PS5000A_CHANNEL_A & PS5000A_CHANNEL_B)
% Enabled        : 1 (PicoConstants.TRUE)
% Type           : 1 (ps5000aEnuminfo.enPS5000ACoupling.PS5000A_DC)
% Range          : 8 (ps5000aEnuminfo.enPS5000ARange.PS5000A_5V)
% Analog Offset  : 0.0 V

% Channels       : 2 - 3 (ps5000aEnuminfo.enPS5000AChannel.PS5000A_CHANNEL_C & PS5000A_CHANNEL_D)
% Enabled        : 0 (PicoConstants.FALSE)
% Type           : 1 (ps5000aEnuminfo.enPS5000ACoupling.PS5000A_DC)
% Range          : 8 (ps5000aEnuminfo.enPS5000ARange.PS5000A_5V)
% Analog Offset  : 0.0 V

% Find current power source
[status.currentPowerSource] = invoke(ps5000aDeviceObj, 'ps5000aCurrentPowerSource');

if (ps5000aDeviceObj.channelCount == PicoConstants.QUAD_SCOPE && status.currentPowerSource == PicoStatus.PICO_POWER_SUPPLY_CONNECTED)
    
    [status.setChC] = invoke(ps5000aDeviceObj, 'ps5000aSetChannel', 2, 0, 1, 8, 0.0);
    [status.setChD] = invoke(ps5000aDeviceObj, 'ps5000aSetChannel', 3, 0, 1, 8, 0.0);
    
end

%% Set device resolution

% Max. resolution with 2 channels enabled is 15 bits.
[status.setResolution, resolution] = invoke(ps5000aDeviceObj, 'ps5000aSetDeviceResolution', 15);

%% Verify timebase index and maximum number of samples
% Use the |ps5000aGetTimebase2()| function to query the driver as to the
% suitability of using a particular timebase index and the maximum number
% of samples available in the segment selected, then set the |timebase|
% property if required.
%
% To use the fastest sampling interval possible, enable one analog
% channel and turn off all other channels.
%
% Use a while loop to query the function until the status indicates that a
% valid timebase index has been selected. In this example, the timebase
% index of 65 is valid.

% Initial call to ps5000aGetTimebase2() with parameters:
%
% timebase      : 65
% segment index : 0

status.getTimebase2 = PicoStatus.PICO_INVALID_TIMEBASE;
timebaseIndex = 65;

while (status.getTimebase2 == PicoStatus.PICO_INVALID_TIMEBASE)
    
    [status.getTimebase2, timeIntervalNanoseconds, maxSamples] = invoke(ps5000aDeviceObj, ...
                                                                    'ps5000aGetTimebase2', timebaseIndex, 0);
    
    if (status.getTimebase2 == PicoStatus.PICO_OK)
       
        break;
        
    else
        
        timebaseIndex = timebaseIndex + 1;
        
    end    
    
end

fprintf('Timebase index: %d, sampling interval: %d ns\n', timebaseIndex, timeIntervalNanoseconds);

% Configure the device object's |timebase| property value.
set(ps5000aDeviceObj, 'timebase', timebaseIndex);

%% Set simple trigger
% Set a trigger on channel A, with an auto timeout - the default value for
% delay is used.

% Trigger properties and functions are located in the Instrument
% Driver's Trigger group.

triggerGroupObj = get(ps5000aDeviceObj, 'Trigger');
triggerGroupObj = triggerGroupObj(1);

% Set the |autoTriggerMs| property in order to automatically trigger the
% oscilloscope after 1 second if a trigger event has not occurred. Set to 0
% to wait indefinitely for a trigger event.

set(triggerGroupObj, 'autoTriggerMs', 1000);

% Channel     : 0 (ps5000aEnuminfo.enPS5000AChannel.PS5000A_CHANNEL_A)
% Threshold   : 1000 mV
% Direction   : 2 (ps5000aEnuminfo.enPS5000AThresholdDirection.PS5000A_RISING)

[status.setSimpleTrigger] = invoke(triggerGroupObj, 'setSimpleTrigger', 0, 1000, 2);

%% Set block parameters and capture data
% Capture a block of data and retrieve data values for channels A and B.

% Block data acquisition properties and functions are located in the 
% Instrument Driver's Block group.

blockGroupObj = get(ps5000aDeviceObj, 'Block');
blockGroupObj = blockGroupObj(1);

% Set pre-trigger and post-trigger samples as required - the total of this
% should not exceed the value of |maxSamples| returned from the call to
% |ps5000aGetTimebase2()|. The number of pre-trigger samples is set in this
% example but default of 10000 post-trigger samples is used.

% Set pre-trigger samples.
set(ps5000aDeviceObj, 'numPreTriggerSamples', 1024);

%%
% This example uses the |runBlock()| function in order to collect a block of
% data - if other code needs to be executed while waiting for the device to
% indicate that it is ready, use the |ps5000aRunBlock()| function and poll
% the |ps5000aIsReady()| function.

% Capture a block of data:
%
% segment index: 0 (The buffer memory is not segmented in this example)

[status.runBlock] = invoke(blockGroupObj, 'runBlock', 0);

% Retrieve data values:

startIndex              = 0;
segmentIndex            = 0;
downsamplingRatio       = 1;
downsamplingRatioMode   = ps5000aEnuminfo.enPS5000ARatioMode.PS5000A_RATIO_MODE_NONE;

% Provide additional output arguments for other channels e.g. chC for
% channel C if using a 4-channel PicoScope.
[numSamples, overflow, chA, chB] = invoke(blockGroupObj, 'getBlockData', startIndex, segmentIndex, ...
                                            downsamplingRatio, downsamplingRatioMode);
                                        
%% Process data
% In this example the data values returned from the device are displayed in
% plots in a Figure.

figure1 = figure('Name','PicoScope 5000 Series (A API) Example - Block Mode Capture', ...
    'NumberTitle','off');

% Calculate time (nanoseconds) and convert to milliseconds
% Use |timeIntervalNanoseconds| output from the |ps5000aGetTimebase2()|
% function or calculate it using the main Programmer's Guide.
% Take into account the downsampling ratio used.

timeNs = double(timeIntervalNanoseconds) * downsamplingRatio * double(0:numSamples - 1);
timeMs = timeNs / 1e6;

% Channel A
axisHandleChA = subplot(2,1,1); 
plot(timeMs, chA, 'b');
title(axisHandleChA, 'Channel A');
xlabel(axisHandleChA, 'Time (ms)');
ylabel(axisHandleChA, 'Voltage (mV)');
grid(axisHandleChA, 'on');

% Channel B
axisHandleChB = subplot(2,1,2); 
plot(timeMs, chB, 'r');
title(axisHandleChB, 'Channel B');
xlabel(axisHandleChB, 'Time (ms)');
ylabel(axisHandleChB, 'Voltage (mV)');
grid(axisHandleChB, 'on');

%% Stop the device

[status.stop] = invoke(ps5000aDeviceObj, 'ps5000aStop');

%% Disconnect device
% Disconnect device object from hardware.

disconnect(ps5000aDeviceObj);
delete(ps5000aDeviceObj);