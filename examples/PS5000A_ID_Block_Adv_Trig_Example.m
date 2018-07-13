%% PicoScope 5000 Series Instrument Driver Oscilloscope Block Data with Advanced Trigger Capture Example 
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
%   PS5000A_ID_Block_Adv_Trig_Example, at the MATLAB command prompt.
% 
%   The file, PS5000A_ID_BLOCK_ADV_TRIG_EXAMPLE.M must be on your MATLAB PATH. For additional information
%   on setting your MATLAB PATH, type 'help addpath' at the MATLAB command
%   prompt.
%
%   Example:
%       PS5000A_ID_Block_Adv_Trig_Example;
%
%   Description:
%       Demonstrates how to call functions in order to capture a block of
%       data from a PicoScope 5000 Series oscilloscope using an advanced trigger.
%
%   See also ICDEVICE.
%
%   Copyright: © 2017 Pico Technology Ltd. See LICENSE file for terms.
%

%% Suggested Input Test Signal
% This example used the following test signal:
%
% * Channel A: 2 Vpp with ±500 mV offset, 2 kHz sine wave

%% CLEAR COMMAND WINDOW AND CLOSE FIGURES 

clc;
close all;

%% LOAD CONFIGURATION INFORMATION

PS5000aConfig;

%% DEVICE CONNECTION

% Create a device object. 
ps5000aDeviceObj = icdevice('picotech_ps5000a_generic', ''); 

% Connect device object to hardware.
connect(ps5000aDeviceObj);

%% SET CHANNELS

% Default driver settings used - use ps5000aSetChannel to turn channels on
% or off and set voltage ranges, coupling, as well as analogue offset.

%% SET DEVICE RESOLUTION

% Max. resolution with 2 channels enabled is 15 bits.
[status.resolution, resolution] = invoke(ps5000aDeviceObj, 'ps5000aSetDeviceResolution', 15);

%% SET ADVANCED TRIGGER
% Setup a window trigger on channel A. Device should trigger when the input
% signal is exits a ±1 V window.

% Trigger properties and functions are located in the Instrument
% Driver's Trigger group.

triggerGroupObj = get(ps5000aDeviceObj, 'Trigger');
triggerGroupObj = triggerGroupObj(1);

% Trigger channel conditions

triggerConditions = ps5000aStructs.tPS5000ATriggerConditions.members;

triggerConditions.channelA              = ps5000aEnuminfo.enPS5000ATriggerState.PS5000A_CONDITION_TRUE;
triggerConditions.channelB              = ps5000aEnuminfo.enPS5000ATriggerState.PS5000A_CONDITION_DONT_CARE;
triggerConditions.channelC              = ps5000aEnuminfo.enPS5000ATriggerState.PS5000A_CONDITION_DONT_CARE;
triggerConditions.channelD              = ps5000aEnuminfo.enPS5000ATriggerState.PS5000A_CONDITION_DONT_CARE;
triggerConditions.external              = ps5000aEnuminfo.enPS5000ATriggerState.PS5000A_CONDITION_DONT_CARE;
triggerConditions.aux                   = ps5000aEnuminfo.enPS5000ATriggerState.PS5000A_CONDITION_DONT_CARE;
triggerConditions.pulseWidthQualifier   = ps5000aEnuminfo.enPS5000ATriggerState.PS5000A_CONDITION_DONT_CARE;

% Trigger channel directions    
% Define a struct to pass to the Instrument Driver's setAdvTrigger() function

triggerDirections = struct('channelA', ps5000aEnuminfo.enPS5000AThresholdDirection.PS5000A_EXIT, 'channelB', ps5000aEnuminfo.enPS5000AThresholdDirection.PS5000A_NONE, ...
                                    'channelC', ps5000aEnuminfo.enPS5000AThresholdDirection.PS5000A_NONE,'channelD', ps5000aEnuminfo.enPS5000AThresholdDirection.PS5000A_NONE, ...
                                    'external', ps5000aEnuminfo.enPS5000AThresholdDirection.PS5000A_NONE, 'aux' ,ps5000aEnuminfo.enPS5000AThresholdDirection.PS5000A_NONE);                            

% Set trigger properties

autoTrigMs = 0; % Wait indefinitely

channelProperties                           = ps5000aStructs.tPS5000ATriggerChannelProperties.members;
channelProperties.thresholdUpper            = mv2adc(1000, 5000, ps5000aDeviceObj.maxADCValue);
channelProperties.thresholdUpperHysteresis  = mv2adc(10, 5000, ps5000aDeviceObj.maxADCValue);
channelProperties.thresholdLower            = mv2adc(-1000, 5000, ps5000aDeviceObj.maxADCValue);
channelProperties.thresholdLowerHysteresis  = mv2adc(10, 5000, ps5000aDeviceObj.maxADCValue);
channelProperties.thresholdMode             = ps5000aEnuminfo.enPS5000AThresholdMode.PS5000A_WINDOW;
channelProperties.channel                   = ps5000aEnuminfo.enPS5000AChannel.PS5000A_CHANNEL_A;

% Set the |autoTriggerMs| property in order to automatically trigger the
% oscilloscope after 1 second if a trigger event has not occurred. Set to 0
% to wait indefinitely for a trigger event.

set(triggerGroupObj, 'autoTriggerMs', 1000);

% Set trigger delay to 0
set(triggerGroupObj, 'delay', 0);

% Set Advanced trigger
status.advTrigStatus = invoke(triggerGroupObj, 'setAdvancedTrigger', channelProperties, triggerConditions, triggerDirections);

%% GET TIMEBASE

% Driver default timebase index used - use ps5000aGetTimebase or
% ps5000aGetTimebase2 to query the driver as to suitability of using a
% particular timebase index then set the 'timebase' property if required.

% timebase     : 65 (default)
% segment index: 0

[status.getTimebase, timeIntervalNanoSeconds, maxSamples] = invoke(ps5000aDeviceObj, 'ps5000aGetTimebase', 65, 0);

%% SET BLOCK PARAMETERS AND CAPTURE DATA

% Block data acquisition properties and functions are located in the 
% Instrument Driver's Block group.

blockGroupObj = get(ps5000aDeviceObj, 'Block');
blockGroupObj = blockGroupObj(1);

% Set pre-trigger samples.

numPreTriggerSamples = 1024;
set(ps5000aDeviceObj, 'numPreTriggerSamples', numPreTriggerSamples);

% Capture a block of data:
%
% segment index: 0

[status.runBlock] = invoke(ps5000aDeviceObj, 'runBlock', 0);

% Retrieve data values:

startIndex              = 0;
segmentIndex            = 0;
downsamplingRatio       = 1;
downsamplingRatioMode   = ps5000aEnuminfo.enPS5000ARatioMode.PS5000A_RATIO_MODE_NONE;

[numSamples, overflow, chA, chB] = invoke(blockGroupObj, 'getBlockData', startIndex, segmentIndex, ...
                                            downsamplingRatio, downsamplingRatioMode);

% Stop the device
[status.stop] = invoke(ps5000aDeviceObj, 'ps5000aStop');

%% PROCESS DATA

% Plot data values.

figure;

% Calculate time (nanoseconds) and convert to milliseconds
% Use timeIntervalNanoSeconds output from ps5000aGetTimebase or
% ps5000aGetTimebase2 or calculate from Programmer's Guide.

timeNs = double(timeIntervalNanoSeconds) * double(0:numSamples - 1);
timeMs = timeNs / 1e6;

% Obtain trigger point
triggerIndex = get(ps5000aDeviceObj, 'numPreTriggerSamples') + 1;

% Channel A
axisHandleChA = subplot(2,1,1); 
plot(timeMs, chA, 'b');
hold on;
plot(timeMs(triggerIndex), chA(triggerIndex), 'rx'); % Plot the trigger point
plot(timeMs, 1000*ones(length(chA),1), 'k--'); % Show upper window bound
plot(timeMs, -1000*ones(length(chA),1), 'k--'); % Show lower window bound
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

%% DEVICE DISCONNECTION

% Disconnect device object from hardware.
disconnect(ps5000aDeviceObj);
delete(ps5000aDeviceObj);