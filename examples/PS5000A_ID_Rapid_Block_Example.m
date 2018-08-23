%% PicoScope 5000 Series (A API) Instrument Driver Oscilloscope Rapid Block Data Capture Example
% This is an example of an instrument control session using a device
% object. The instrument control session comprises all the steps you are
% likely to take when communicating with your instrument.
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
% PS5000A_ID_Rapid_Block_Example, at the MATLAB command prompt.
% 
% The file, PS5000A_ID_RAPID_BLOCK_EXAMPLE.M must be on your MATLAB PATH.
% For additional information on setting your MATLAB PATH, type 'help
% addpath' at the MATLAB command prompt.
%
% *Example:*
%    PS5000A_ID_Rapid_Block_Example;
%
% *Description:*
%     Demonstrates how to call functions in order to capture a series of
%     waveforms using rapid block mode on a PicoScope 5000 Series
%     Oscilloscope using the underlying 'A' API library functions.
%   
% *See also:* <matlab:doc('icdevice') |icdevice|> | <matlab:doc('instrument/invoke') |invoke|>
%
% *Copyright:* © 2013-2017 Pico Technology Ltd. See LICENSE file for terms.

%% Suggested input test signal
% This example was published using the following test signal:
%
% * Channel A: 4 Vpp Swept sine wave (Start: 10 kHz, Stop: 100 kHz, Sweep type: Up, Increment Time: 1 ms, Increment type: Linear, Mode: Continous)
% * Channel B: 2 Vpp Swept square wave (Start: 10 kHz, Stop: 50 kHz, Sweep type: Up, Increment: 5 kHz, Increment Time: 1 ms)

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

% resolution : 12bits

[status.setDeviceResolution, resolution] = invoke(ps5000aDeviceObj, 'ps5000aSetDeviceResolution', 12);

%% Set memory segments
% Configure the number of memory segments and query |ps5000aMemorySegments()|
% to find the maximum number of samples for each segment.

% nSegments : 64

nSegments = 64;
[status.memorySegments, nMaxSamples] = invoke(ps5000aDeviceObj, 'ps5000aMemorySegments', nSegments);

% Set number of samples to collect pre- and post-trigger. Ensure that the
% total does not exceeed nMaxSamples above.

set(ps5000aDeviceObj, 'numPreTriggerSamples', 2048);
set(ps5000aDeviceObj, 'numPostTriggerSamples', 2048);

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
% index of 4 is valid.

% Initial call to ps5000aGetTimebase2() with parameters:
%
% timebase      : 4
% segment index : 0

status.getTimebase2 = PicoStatus.PICO_INVALID_TIMEBASE;
timebaseIndex = 4;

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
% delay is used. The device will wait for a rising edge through
% the specified threshold unless the timeout occurs first.

% Trigger properties and functions are located in the Instrument
% Driver's Trigger group.

triggerGroupObj = get(ps5000aDeviceObj, 'Trigger');
triggerGroupObj = triggerGroupObj(1);

% Set the |autoTriggerMs| property in order to automatically trigger the
% oscilloscope after 1 second if a trigger event has not occurred. Set to 0
% to wait indefinitely for a trigger event.

set(triggerGroupObj, 'autoTriggerMs', 1000);

% Channel     : 0 (ps5000aEnuminfo.enPS5000AChannel.PS5000A_CHANNEL_A)
% Threshold   : 500 mV
% Direction   : 2 (ps5000aEnuminfo.enPS5000AThresholdDirection.PS5000A_RISING)

[status.setSimpleTrigger] = invoke(triggerGroupObj, 'setSimpleTrigger', 0, 500, 2);

%% Set rapid block parameters and capture data
% Capture a number of waveof and retrieve data values for channels A and B.

% Rapid Block specific properties and functions are located in the
% Instrument Driver's Rapidblock group.

rapidBlockGroupObj = get(ps5000aDeviceObj, 'Rapidblock');
rapidBlockGroupObj = rapidBlockGroupObj(1);

% Block specific properties and functions are located in the Instrument
% Driver's Block group.

blockGroupObj = get(ps5000aDeviceObj, 'Block');
blockGroupObj = blockGroupObj(1);

% Set number of captures - can be less than or equal to the number of
% segments.

numCaptures = 8;
[status.setNoOfCaptures] = invoke(rapidBlockGroupObj, 'ps5000aSetNoOfCaptures', numCaptures);

%% 
% This example uses the |runBlock()| function in order to collect a block of
% data - if other code needs to be executed while waiting for the device to
% indicate that it is ready, use the |ps5000aRunBlock()| function and poll
% the |ps5000aIsReady()| function until the device indicates that it has
% data available for retrieval.

% Capture the blocks of data:

% segmentIndex : 0 

[status.runBlock, timeIndisposedMs] = invoke(blockGroupObj, 'runBlock', 0);

% Retrieve rapid block data values:

downsamplingRatio       = 1;
downsamplingRatioMode   = ps5000aEnuminfo.enPS5000ARatioMode.PS5000A_RATIO_MODE_NONE;

% Provide additional output arguments for the remaining channels e.g. chC
% for Channel C
[numSamples, overflow, chA, chB] = invoke(rapidBlockGroupObj, 'getRapidBlockData', numCaptures, ...
                                    downsamplingRatio, downsamplingRatioMode);

%% Obtain the number of captures

[status.GetNoOfCaptures, numCaptures] = invoke(rapidBlockGroupObj, 'ps5000aGetNoOfCaptures');

%% Process data
% Plot data values.
%
% Calculate the time period over which samples were taken for each waveform.
% Use the |timeIntNs| output from the |ps5000aGetTimebase2()| function or
% calculate the sampling interval using the main Programmer's Guide.
% Take into account the downsampling ratio used.

timeNs = double(timeIntervalNanoseconds) * downsamplingRatio * double(0:numSamples - 1);

% Channel A
figure1 = figure('Name','PicoScope 5000 Series (A API) Example - Rapid Block Mode Capture', ...
    'NumberTitle', 'off');

plot(timeNs, chA);
title('Channel A');
xlabel('Time (ns)');
ylabel('Voltage (mV)');
grid on;
movegui(figure1, 'west');

% Channel B
figure2  = figure('Name','PicoScope 5000 Series (A API) Example - Rapid Block Mode Capture', ...
    'NumberTitle', 'off');

plot(timeNs, chB);
title('Channel B - Rapid Block Capture');
xlabel('Time (ns)');
ylabel('Voltage (mV)')
grid on;
movegui(figure2, 'east');

%% Stop the device

[status.stop] = invoke(ps5000aDeviceObj, 'ps5000aStop');

%% Disconnect device
% Disconnect device object from hardware.

disconnect(ps5000aDeviceObj);
delete(ps5000aDeviceObj);

