%% PicoScope 5000 Series (A API) Instrument Driver Oscilloscope Block Data with Advanced Trigger Capture Example 
%  
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
% PS5000A_ID_Block_Adv_Trig_Example, at the MATLAB command prompt.
% 
% The file, PS5000A_ID_BLOCK_ADV_TRIG_EXAMPLE.M must be on your MATLAB
% PATH. For additional information on setting your MATLAB PATH, type 'help
% addpath' at the MATLAB command prompt.
%
% *Example:*
%     PS5000A_ID_Block_Adv_Trig_Example;
%
% *Description:*
%     Demonstrates how to call functions in order to capture a block of
%     data from a PicoScope 5000 Series oscilloscope using an advanced trigger.
%
% *See also:* <matlab:doc('icdevice') |icdevice|> | <matlab:doc('instrument/invoke') |invoke|>
%
% *Copyright:* © 2017-2019 Pico Technology Ltd. See LICENSE file for terms.

%% Suggested input test signals
% This example used the following test signals:
%
% * Channel A: 2 V p-p with ±500 mV offset, 2 kHz sine wave
% * Channel B: 4 V p-p, 1 kHz square wave

%% Clear command window and close any figures

clc;
close all;

%% Load configuration information
% Setup paths and also load struct and enumeration information. Structs and
% enumeration values are required for certain function calls.

[ps5000aStructs, ps5000aEnuminfo] = ps5000aSetConfig(); % DO NOT EDIT THIS LINE.

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
%
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
[status.resolution, resolution] = invoke(ps5000aDeviceObj, 'ps5000aSetDeviceResolution', 15);

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

%% Setup trigger using advanced functions
% Set up the device to trigger if the trigger condition on channel A OR the
% trigger condition on channel B is met. Use an auto-timeout of 5 seconds
% if the trigger condition is not met in that time.

% Trigger properties and functions are located in the Instrument
% Driver's Trigger group.

triggerGroupObj = get(ps5000aDeviceObj, 'Trigger');
triggerGroupObj = triggerGroupObj(1);

%%
% *Trigger conditions*
%
% Specify which channels to trigger on.
%
% Create a MATLAB structure corresponding to the |tPS5000ACondition| struct
% defined in |ps5000aStructs| in order to define the trigger conditions for
% each channel.

TriggerConditions(1).source = ps5000aEnuminfo.enPS5000AChannel.PS5000A_CHANNEL_A;
TriggerConditions(1).condition = ps5000aEnuminfo.enPS5000ATriggerState.PS5000A_CONDITION_TRUE;
TriggerConditions(2).source = ps5000aEnuminfo.enPS5000AChannel.PS5000A_PULSE_WIDTH_SOURCE;
TriggerConditions(2).condition = ps5000aEnuminfo.enPS5000ATriggerState.PS5000A_CONDITION_TRUE;

% Clear any pre-existing trigger configurations that may have been set.
info = ps5000aEnuminfo.enPS5000AConditionsInfo.PS5000A_CLEAR + ps5000aEnuminfo.enPS5000AConditionsInfo.PS5000A_ADD;

% Set the condition for channel A
[status.ps5000aSetTriggerChannelConditionsV2ChA] = invoke(triggerGroupObj, 'ps5000aSetTriggerChannelConditionsV2', TriggerConditions, info);

%%
% *Trigger directions*
%
% Set the direction on which to trigger for each channel.
%
% Create an array of MATLAB structures corresponding to the
% |tPS5000ADirection| structure in |ps5000aStructs|. Each structure in the
% array defines the direction on which to trigger and also if it is a level
% (edge) or window trigger.

TriggerDirections(1).source = ps5000aEnuminfo.enPS5000AChannel.PS5000A_CHANNEL_A;
TriggerDirections(1).direction = ps5000aEnuminfo.enPS5000AThresholdDirection.PS5000A_RISING;
TriggerDirections(1).mode = ps5000aEnuminfo.enPS5000AThresholdMode.PS5000A_LEVEL;

[status.setTriggerChannelDirectionsV2] = invoke(triggerGroupObj, 'ps5000aSetTriggerChannelDirectionsV2', TriggerDirections);

%%
% *Trigger properties*
%
% Set up the trigger thresholds for each channel.
%
% Specify the threshold values to use in millivolts. As the
% |PS5000A_RISING| and |PS5000A_FALLING| enumerations have been specified
% for the trigger directions, the upper threshold values will be used.

TriggerChannelChannelProperties(1).thresholdUpper = 1000;
TriggerChannelChannelProperties(1).thresholdUpperHysteresis = 50;
TriggerChannelChannelProperties(1).thresholdLower = 1000;
TriggerChannelChannelProperties(1).thresholdLowerHysteresis = 50;
TriggerChannelChannelProperties(1).channel = ps5000aEnuminfo.enPS5000AChannel.PS5000A_CHANNEL_A;

[status.setTriggerChannelPropertiesV2] = invoke(triggerGroupObj, 'ps5000aSetTriggerChannelPropertiesV2', TriggerChannelChannelProperties);

%%
% set pulse width trigger

pwqConditions(1).source = ps5000aEnuminfo.enPS5000AChannel.PS5000A_CHANNEL_A;
pwqConditions(1).condition = ps5000aEnuminfo.enPS5000ATriggerState.PS5000A_CONDITION_TRUE;
nConditions = length(pwqConditions);
pwqDirection.source = ps5000aEnuminfo.enPS5000AChannel.PS5000A_CHANNEL_A;
pwqDirection.direction = ps5000aEnuminfo.enPS5000AThresholdDirection.PS5000A_OUTSIDE;
pwqDirection.mode = ps5000aEnuminfo.enPS5000AThresholdMode.PS5000A_WINDOW;
nDirections = length(pwqDirection);
pwqTime = ceil(1e6 / timeIntervalNanoseconds); %1 ms
pwqLower = pwqTime; 
pwqUpper = 10 * pwqTime; 
pwqType = ps5000aEnuminfo.enPS5000APulseWidthType.PS5000A_PW_TYPE_GREATER_THAN;

%%
% *Set auto trigger*
%
% The device will automatically trigger if the trigger condition has not
% been met within 5 seconds.

[status.autoTriggerUs] = invoke(triggerGroupObj, 'ps5000aSetAutoTriggerMicroSeconds', 5e6);

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

numPreTriggerSamples = 1024;
set(ps5000aDeviceObj, 'numPreTriggerSamples', numPreTriggerSamples);

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

figure1 = figure('Name','PicoScope 5000 Series (A API) Example - Block Mode Capture with Advanced Trigger', ...
    'NumberTitle', 'off', 'Position', [500, 500, 640, 480]);

movegui(figure1, 'center');

% Calculate time (nanoseconds) and convert to milliseconds.
% Use |timeIntervalNanoseconds| output from the |ps5000aGetTimebase2()|
% function or calculate it using the main Programmer's Guide.
% Take into account the downsampling ratio used.

timeNs = double(timeIntervalNanoseconds) * double(0:numSamples - 1);
timeMs = timeNs / 1e6;

% Obtain trigger point
triggerIndex = get(ps5000aDeviceObj, 'numPreTriggerSamples') + 1;

% Channel A
axisHandleChA = subplot(2,1,1); 
plot(timeMs, chA, 'b');
hold on;
title('Channel A');
xlabel(axisHandleChA, 'Time (ms)');
ylabel(axisHandleChA, 'Voltage (mV)');
grid on;
hold off;

% Channel B

axisHandleChB = subplot(2,1,2); 
plot(timeMs, chB, 'r');
title('Channel B');
xlabel(axisHandleChB, 'Time (ms)');
ylabel(axisHandleChB, 'Voltage (mV)');
grid on;
hold off;

%% Stop the device

[status.stop] = invoke(ps5000aDeviceObj, 'ps5000aStop');

%% Disconnect device
% Disconnect device object from hardware.

disconnect(ps5000aDeviceObj);
delete(ps5000aDeviceObj);