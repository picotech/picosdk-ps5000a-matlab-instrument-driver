%% PicoScope 5000 Series Instrument Driver Oscilloscope ETS Block Data Capture Example
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
%   PS5000A_ID_Block_ETS_Example, at the MATLAB command prompt.
% 
%   The file, PS5000A_ID_BLOCK_ETS_EXAMPLE.M must be on your MATLAB PATH. For additional information
%   on setting your MATLAB PATH, type 'help addpath' at the MATLAB command
%   prompt.
%
%   Example:
%       PS5000A_ID_Block_ETS_Example;
%
%   Description:
%       Demonstrates how to call functions in order to capture a block of
%       data from a PicoScope 5000 series oscilloscope.
%
%   See also ICDEVICE.
%
%   Copyright: (c) 2013 - 2017 Pico Technology Ltd. See LICENSE file for terms.
%
%   Author: HSM
%
%   Device used to generated example: PicoScope 5242A

%   Creation time: 05-Jul-2013 13:00:29 

%% LOAD CONFIGURATION INFORMATION

PS5000aConfig;

%% DEVICE CONNECTION

% Create a device object. 
ps5000aDeviceObj = icdevice('picotech_ps5000a_generic.mdd');

% Connect device object to hardware.
connect(ps5000aDeviceObj);

%% SET CHANNELS

% Default driver settings used - use ps5000aSetChannel to turn channels on
% or off and set voltage ranges, coupling, as well as analogue offset.

% Turn off Channel B (as well as C and D if using a 4-channel oscilloscope)

status.chB = invoke(ps5000aDeviceObj, 'ps5000aSetChannel', 1, 0, 1, 8, 0.0);
        
if (ps5000aDeviceObj.channelCount == PicoConstants.QUAD_SCOPE)

    status.currentPowerSource = invoke(ps5000aDeviceObj, 'ps5000aCurrentPowerSource');

    % Check if power supply connected - channels C and D will not be enabled on
    % a 4-channel oscilloscope if it is only USB powered.
    if(status.currentPowerSource == PicoStatus.PICO_POWER_SUPPLY_CONNECTED)
        
        status.chC = invoke(ps5000aDeviceObj, 'ps5000aSetChannel', 2, 0, 1, 8, 0.0);
        status.chD = invoke(ps5000aDeviceObj, 'ps5000aSetChannel', 3, 0, 1, 8, 0.0);
    
    end

end

%% SET ETS MODE PARAMETERS
% Set Equivalent Time Sampling Parameters
% Note: ETS mode is only supported in 8-bit resolution

% Block data acquisition properties and functions are located in the 
% Instrument Driver's Block group.

blockGroupObj = get(ps5000aDeviceObj, 'Block');
blockGroupObj = blockGroupObj(1);

mode            = ps5000aEnuminfo.enPS5000AEtsMode.PS5000A_ETS_SLOW;
etsCycles       = 20;
etsInterleave   = 5;

[status.setEts, sampleTimePicoSeconds] = invoke(blockGroupObj, 'ps5000aSetEts', mode, etsCycles, etsInterleave);

%% SET SIMPLE TRIGGER
% Set a trigger on channel A.

% Trigger properties and functions are located in the Instrument
% Driver's Trigger group.

triggerGroupObj = get(ps5000aDeviceObj, 'Trigger');
triggerGroupObj = triggerGroupObj(1);

% Channel     : 0 (ps5000aEnuminfo.enPS5000AChannel.PS5000A_CHANNEL_A)
% Threshold   : 1000 mV
% Direction   : 2 (ps5000aEnuminfo.enPS5000AThresholdDirection.PS5000A_RISING)

[status.setSimpleTrigger] = invoke(triggerGroupObj, 'setSimpleTrigger', 0, 1000, 2);
%status.setSimpleTrigger = calllib('ps5000a', 'ps5000aSetSimpleTrigger', ps5000aDeviceObj.unitHandle, 1, ps5000aEnuminfo.enPS5000AChannel.PS5000A_CHANNEL_A, 16256, ...
%    ps5000aEnuminfo.enPS5000AThresholdDirection.PS5000A_RISING, 0, 0);

%% SET BLOCK PARAMETERS AND CAPTURE DATA

% Set pre-trigger samples.
set(ps5000aDeviceObj, 'numPreTriggerSamples', 5000);
set(ps5000aDeviceObj, 'numPostTriggerSamples', 5000);

% Capture a block of data:
%
% segment index: 0

[status.runBlock] = invoke(blockGroupObj, 'runBlock', 0);

% Retrieve data values:
%
% start index       : 0
% segment index     : 0
% downsampling ratio: 1
% downsampling mode : 0 (PS5000A_RATIO_MODE_NONE)

[etsTimes, chA, ~, ~, ~, numSamples, overflow] = invoke(blockGroupObj, 'getEtsBlockData', 0, 0, 1, 0);

% Stop the device
[status.stop] = invoke(ps5000aDeviceObj, 'ps5000aStop');

%% PROCESS DATA
% Plot data values.

figure;

% Channel A
plot(etsTimes, chA, 'b');
title('ETS Block Capture - Channel A');
xlabel('Time (fs)');
ylabel('Voltage (mV)');
grid on;

%% DEVICE DISCONNECTION

% Disconnect device object from hardware.
disconnect(ps5000aDeviceObj);
delete(ps5000aDeviceObj);