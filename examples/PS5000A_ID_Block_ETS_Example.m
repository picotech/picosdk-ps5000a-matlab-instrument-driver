%% PicoScope 5000 Series (A API) Instrument Driver Oscilloscope ETS Block Data Capture Example
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
% PS5000A_ID_Block_ETS_Example, at the MATLAB command prompt.
% 
% The file, PS5000A_ID_BLOCK_ETS_EXAMPLE.M must be on your MATLAB PATH. For
% additional information on setting your MATLAB PATH, type 'help addpath'
% at the MATLAB command prompt.
%
% *Example:*
%     PS5000A_ID_Block_ETS_Example;
%
% *Description:*
%     Demonstrates how to set properties and call functions in order to
%     capture a block of data using Equivalent Time Sampling from a
%     PicoScope 5000 Series Oscilloscope using the underlying 'A' API
%     library functions.
%
% *See also:* <matlab:doc('icdevice') |icdevice|> | <matlab:doc('instrument/invoke') |invoke|>
% 
% *Copyright:* © 2013-2018 Pico Technology Ltd. See LICENSE file for terms.

%% Suggested input test signal
% This example was published using the following test signals:
%
% * Channel A: 4 Vpp, 1 MHz sine wave

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

% In this example, data is collected on channel with channel B switched
% off. If it is a 4-channel model, channels C and D will also be switched
% off if the power supply is connected. If the PicoScope also has digital
% input channels these will also be switched off.

% Channels       : 0 (ps5000aEnuminfo.enPS5000AChannel.PS5000A_CHANNEL_A)
% Enabled        : 1 (PicoConstants.TRUE)
% Type           : 1 (ps5000aEnuminfo.enPS5000ACoupling.PS5000A_DC)
% Range          : 8 (ps5000aEnuminfo.enPS5000ARange.PS5000A_5V)
% Analog Offset  : 0.0 V

% Channels       : 1 - 3 (ps5000aEnuminfo.enPS5000AChannel.PS5000A_CHANNEL_B, PS5000A_CHANNEL_C & PS5000A_CHANNEL_D)
% Enabled        : 0 (PicoConstants.FALSE)
% Type           : 1 (ps5000aEnuminfo.enPS5000ACoupling.PS5000A_DC)
% Range          : 8 (ps5000aEnuminfo.enPS5000ARange.PS5000A_5V)
% Analog Offset  : 0.0 V

% Find current power source
[status.currentPowerSource] = invoke(ps5000aDeviceObj, 'ps5000aCurrentPowerSource');

status.chB = invoke(ps5000aDeviceObj, 'ps5000aSetChannel', 1, 0, 1, 8, 0.0);

if (ps5000aDeviceObj.channelCount == PicoConstants.QUAD_SCOPE && status.currentPowerSource == PicoStatus.PICO_POWER_SUPPLY_CONNECTED)
    
    [status.setChC] = invoke(ps5000aDeviceObj, 'ps5000aSetChannel', 2, 0, 1, 8, 0.0);
    [status.setChD] = invoke(ps5000aDeviceObj, 'ps5000aSetChannel', 3, 0, 1, 8, 0.0);
    
end

%% 
% Turn off digital ports (if the device is an MSO model)
%
% Use the |ps5000aSetDigitalPort()| function to disable digital ports. This
% function is located in the Instrument Driver's Digital Group. Setting the
% enabled parameter to 0 will turn off all digital channels on that port.

if (ps5000aDeviceObj.digitalPorts > 0)
   
    digitalObj = get(ps5000aDeviceObj, 'Digital');

    % Digital Port  : 128 (ps5000aEnuminfo.enPS5000AChannel.PS5000A_DIGITAL_PORT0)
    % Enabled       : 0 (On - PicoConstants.FALSE)
    % Logic Level   : 1.5 V

    status.setDPort0 = invoke(digitalObj, 'ps5000aSetDigitalPort', ps5000aEnuminfo.enPS5000AChannel.PS5000A_DIGITAL_PORT0, 0, 0);

    % Digital Port  : 129 (ps5000aEnuminfo.enPS5000AChannel.PS5000A_DIGITAL_PORT1)
    % Enabled       : 0 (Off - PicoConstants.FALSE)
    % Logic Level   : 0 V

    status.setDPort1 = invoke(digitalObj, 'ps5000aSetDigitalPort', ps5000aEnuminfo.enPS5000AChannel.PS5000A_DIGITAL_PORT1, 0, 0);
    
end

%% Set ETS mode parameters
% Set Equivalent Time Sampling Parameters.
% The underlying driver will return the sampling interval to be used (in
% picoseconds).
%
% *Note:* ETS mode is only supported in 8-bit resolution.

% Block data acquisition properties and functions are located in the 
% Instrument Driver's Block group.

blockGroupObj = get(ps5000aDeviceObj, 'Block');
blockGroupObj = blockGroupObj(1);

mode            = ps5000aEnuminfo.enPS5000AEtsMode.PS5000A_ETS_SLOW;
etsCycles       = 20;
etsInterleave   = 5;

[status.setEts, sampleTimePicoSeconds] = invoke(blockGroupObj, 'ps5000aSetEts', mode, etsCycles, etsInterleave);

fprintf('ETS sampling interval: %d picoseconds.\n\n', sampleTimePicoSeconds);

%% Verify timebase index and maximum number of samples
% Use the |ps5000aGetTimebase2()| function to query the driver as to the
% the maximum number of samples available in the segment selected.
%
% To use the fastest sampling interval possible, enable one analog
% channel and turn off all other channels.

timebaseIndex = get(ps5000aDeviceObj, 'timebase');

[status.getTimebase2, ~, maxSamples] = invoke(ps5000aDeviceObj, ...
                                        'ps5000aGetTimebase2', timebaseIndex, 0);

%% Set simple trigger
% Set a trigger on channel A.

% Trigger properties and functions are located in the Instrument
% Driver's Trigger group.

triggerGroupObj = get(ps5000aDeviceObj, 'Trigger');
triggerGroupObj = triggerGroupObj(1);

%%
% Set the |autoTriggerMs| property in order to automatically trigger the
% oscilloscope after 1 second if a trigger event has not occurred. Set to 0
% to wait indefinitely for a trigger event.

set(triggerGroupObj, 'autoTriggerMs', 1000);

% Channel     : 0 (ps5000aEnuminfo.enPS5000AChannel.PS5000A_CHANNEL_A)
% Threshold   : 1000 mV
% Direction   : 2 (ps5000aEnuminfo.enPS5000AThresholdDirection.PS5000A_RISING)

[status.setSimpleTrigger] = invoke(triggerGroupObj, 'setSimpleTrigger', 0, 1000, 2);

%% Set block parameters and capture data
% Capture a block of data using Equivalent Time Sampling and retrieve data
% values for channel A.

% Block data acquisition properties and functions are located in the 
% Instrument Driver's Block group.

% Set pre-trigger and post-trigger samples as required - the total of this
% should not exceed the value of |maxSamples| returned from the call to
% |ps5000aGetTimebase2()|.

set(ps5000aDeviceObj, 'numPreTriggerSamples', 5000);
set(ps5000aDeviceObj, 'numPostTriggerSamples', 5000);

%%
% This example uses the |runBlock()| function in order to collect a block of
% data - if other code needs to be executed while waiting for the device to
% indicate that it is ready, use the |ps5000aRunBlock()| function and poll
% the |ps5000aIsReady()| function.

% Capture a block of data:
%
% segment index: 0

[status.runBlock] = invoke(blockGroupObj, 'runBlock', 0);

% Retrieve data values:

startIndex              = 0;
segmentIndex            = 0;
downsamplingRatio       = 1;
downsamplingRatioMode   = ps5000aEnuminfo.enPS5000ARatioMode.PS5000A_RATIO_MODE_NONE;

[numSamples, overflow, etsTimes, chA, ~, ~, ~] = invoke(blockGroupObj, 'getEtsBlockData', startIndex, segmentIndex, ...
                                            downsamplingRatio, downsamplingRatioMode);

%% Process data
% In this example the data values returned from the device are displayed in
% plots in a Figure.

figure1 = figure('Name','PicoScope 5000 Series (A API) Example - ETS Block Mode Capture', ...
    'NumberTitle', 'off');

% Channel A
plot(etsTimes, chA, 'b');
title('Channel A');
xlabel('Time (fs)');
ylabel('Voltage (mV)');
grid on;

%%  Stop the device
[status.stop] = invoke(ps5000aDeviceObj, 'ps5000aStop');

%% Turn off ETS mode
% If another operation is required that does not require Equivalent Time
% Sampling of data, turn ETS mode off.

mode            = ps5000aEnuminfo.enPS5000AEtsMode.PS5000A_ETS_OFF;
etsCycles       = 20;
etsInterleave   = 4;

[status.setEts, sampleTimePicoSeconds] = invoke(blockGroupObj, 'ps5000aSetEts', mode, etsCycles, etsInterleave);

%% Disconnect device
% Disconnect device object from hardware.

disconnect(ps5000aDeviceObj);
delete(ps5000aDeviceObj);