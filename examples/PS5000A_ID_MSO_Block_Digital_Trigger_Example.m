%% PicoScope 5000 Series (A API) Instrument Driver Mixed Signal Oscilloscope Block Data Capture with Digital Trigger Example 
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
% PS5000A_ID_MSO_Block_Digital_Trigger_Example, at the MATLAB command prompt.
% 
% The file, PS5000A_ID_MSO_BLOCK_DIGITAL_TRIGGER_EXAMPLE.M must be on your MATLAB PATH. For
% additional information on setting your MATLAB PATH, type 'help addpath'
% at the MATLAB command prompt.
%
% *Example:*
%     PS5000A_ID_MSO_Block_Digital_Trigger_Example;
%
% *Description:*
%     Demonstrates how to call functions in order to capture a block of
%     data from a PicoScope 5000 Series Mixed Signal Oscilloscope
%     using the underlying 'A' API library functions.
%
% *See also:* <matlab:doc('icdevice') |icdevice|> | <matlab:doc('instrument/invoke') |invoke|>
%
% *Copyright:* © 2019 Pico Technology Ltd. See LICENSE file for terms.

%% Suggested input test signals
% This example was published using the following test signals:
%
% * Channel A: 4 Vpp, 1 kHz sine wave
% * Channel B: 2 Vpp, 1 kHz ramp up wave
% * PORT0    : 5 kHz bit counter signal from test device (applied to all channels).

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

%% Set analog channels and digital ports
% Default driver settings applied to channels are listed below - use the
% Instrument Driver's |ps5000aSetChannel()| function to turn channels on or
% off and set voltage ranges, coupling, as well as analog offset.

% In this example, data is collected on channels A and B, as well as
% Digital Port 0 channels (D0 - D7). If it is a 4-channel model, channels C
% and D will be switched off if the power supply is connected. Digital Port
% 1 (D8 - D15) is switched off.

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

%% 
% Use the |ps5000aSetDigitalPort()| function to enable/disable digital ports
% and set the logic level threshold. This function is located in the
% Instrument Driver's Digital Group. Enabling a digital port will enable
% all channels on that port, while setting the enabled parameter to 0 will
% turn off all digital channels on that port.

digitalObj = get(ps5000aDeviceObj, 'Digital');

% Digital Port  : 128 (ps5000aEnuminfo.enPS5000AChannel.PS5000A_DIGITAL_PORT0)
% Enabled       : 1 (On - PicoConstants.TRUE)
% Logic Level   : 1.5 V

status.setDPort0 = invoke(digitalObj, 'ps5000aSetDigitalPort', ps5000aEnuminfo.enPS5000AChannel.PS5000A_DIGITAL_PORT0, 1, 1.5);

% Digital Port  : 129 (ps5000aEnuminfo.enPS5000AChannel.PS5000A_DIGITAL_PORT1)
% Enabled       : 0 (Off - PicoConstants.FALSE)
% Logic Level   : 0 V

status.setDPort1 = invoke(digitalObj, 'ps5000aSetDigitalPort', ps5000aEnuminfo.enPS5000AChannel.PS5000A_DIGITAL_PORT1, 0, 0);

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
timebaseIndex = 5;

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

%% Set digital trigger
% Set a trigger on digital channel 0
% Trigger properties and functions are located in the Instrument
% Driver's Trigger group.

triggerGroupObj = get(ps5000aDeviceObj, 'Trigger');
triggerGroupObj = triggerGroupObj(1);

% Trigger channel conditions

channelConditionsV2 = ps5000aStructs.tPS5000ACondition.members;
channelConditionsV2.source = ps5000aEnuminfo.enPS5000AChannel.PS5000A_DIGITAL_PORT0;
channelConditionsV2.condition = ps5000aEnuminfo.enPS5000ATriggerState.PS5000A_CONDITION_TRUE;

digitalDirections = ps5000aStructs.tPS5000ADigitalChannelDirections.members;
digitalDirections.channel = ps5000aEnuminfo.enPS5000ADigitalChannel.PS5000A_DIGITAL_CHANNEL_0;
digitalDirections.direction = ps5000aEnuminfo.enPS5000ADigitalDirection.PS5000A_DIGITAL_DIRECTION_RISING;

info = ps5000aEnuminfo.enPS5000AConditionsInfo.PS5000A_ADD + ps5000aEnuminfo.enPS5000AConditionsInfo.PS5000A_CLEAR;

% Set digital trigger
status.TriggerChannelConditions = invoke(triggerGroupObj, 'ps5000aSetTriggerChannelConditionsV2', channelConditionsV2, info);
status.SetTriggerDigitalPortProperties = invoke(triggerGroupObj, 'ps5000aSetTriggerDigitalPortProperties', digitalDirections);

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
[numSamples, overflow, chA, chB, ~, ~, dPort0, ~] = invoke(blockGroupObj, 'getBlockData', startIndex, segmentIndex, ...
                                                        downsamplingRatio, downsamplingRatioMode);
                                        
%% Process data
% In this example the data values returned from the device are displayed in
% plots in with separate figures for analog and digital data.
%
% Calculate time (nanoseconds) and convert to milliseconds
% Use |timeIntervalNanoseconds| output from the |ps5000aGetTimebase2()|
% function or calculate it using the main Programmer's Guide.
% Take into account the downsampling ratio used.

timeNs = double(timeIntervalNanoseconds) * downsamplingRatio * double(0:numSamples - 1);
timeMs = timeNs / 1e6;

%%
% *Analog data*

scrsz = get(groot,'ScreenSize');

analogFigure = figure('Name','PicoScope 5000 Series (A API) - MSO Block Mode Capture With Digital Trigger', ...
    'NumberTitle', 'off', 'Position', [1 scrsz(4)/4 scrsz(3)/2 scrsz(4)/2]);

movegui(analogFigure, 'west');

analogAxes = axes('Parent', analogFigure);

hold(analogAxes, 'on');

% Channels A and B.
plot(analogAxes, timeMs, chA, timeMs, chB);
title(analogAxes, 'Analog Channel Data');
xlabel(analogAxes, 'Time (ms)');
ylabel(analogAxes, 'Voltage (mV)');
legend(analogAxes, 'Channel A', 'Channel B');
grid(analogAxes, 'on');

hold(analogAxes, 'off');

%% 
% *Digital data*

digitalFigure = figure('Name','PicoScope 5000 Series (A API) Example - MSO Block Mode Capture With Digital Trigger', ...
    'NumberTitle', 'off', 'Position', [scrsz(3)/2 + 1 scrsz(4)/4 scrsz(3)/2 scrsz(4)/2]);

movegui(digitalFigure, 'east');

digitalAxes = axes('Parent', digitalFigure);

disp('Converting digital integer data to binary...');

% Create 2D array to hold binary data values for each channel.
dPort0Binary = zeros(numSamples, 8);

% Retrieve the bit values from the lower 8 bits of the 16-bit values
% returned for dPort0 - each bit corresponds to a digital channel. Channel
% D0 data will be in column 8 and D7 data will be in column 1.
for sample = 1:numSamples

    dPort0Binary(sample, :) = bitget(dPort0(sample), 8:-1:1, 'int16');
    
end

hold on;

% Specify colors to use for the plots - the colour to use will be selected
% according to the digital channel.
digiPlotColours = ['m', 'b', 'r', 'g'];

% Display digital data in a 4 x 2 grid
for i = 1:8
    
    digitalAxes = subplot(4, 2, i); 
    plot(digitalAxes, timeMs, dPort0Binary(:, (8 - (i - 1))), digiPlotColours(rem(i, length(digiPlotColours)) + 1));
    title(digitalAxes, strcat('Digital Channel D', num2str(i - 1)));
    xlabel(digitalAxes, 'Time (ms)');
    ylabel(digitalAxes, 'Logic Level');
    axis(digitalAxes, [-inf, inf, -0.5, 1.5])
    grid(digitalAxes, 'on');
    
end

hold off;

%% Stop the device

[status.stop] = invoke(ps5000aDeviceObj, 'ps5000aStop');

%% Disconnect device
% Disconnect device object from hardware.
disconnect(ps5000aDeviceObj);
delete(ps5000aDeviceObj);