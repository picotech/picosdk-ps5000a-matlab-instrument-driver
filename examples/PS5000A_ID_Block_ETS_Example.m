%PS5000A_IC_GENERIC_DRIVER_BLOCK_ETS Code for communicating with an instrument. 
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
%   PS5000A_IC_Generic_Driver_Block, at the MATLAB command prompt.
% 
%   The file, PS5000A_IC_GENERIC_DRIVER_BLOCK_ETS.M must be on your MATLAB PATH. For additional information
%   on setting your MATLAB PATH, type 'help addpath' at the MATLAB command
%   prompt.
%
%   Example:
%       PS5000A_IC_Generic_Driver_Block_ETS;
%
%   Description:
%       Demonstrates how to call functions in order to capture a block of
%       data from a PicoScope 5000 series oscilloscope.
%
%   See also ICDEVICE.
%
%   Copyright:  Pico Technology Limited 2013
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
        
if(ps5000aDeviceObj.channelCount == PicoConstants.QUAD_SCOPE)

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

mode            = ps5000aEnuminfo.enPS5000AEtsMode.PS5000A_ETS_SLOW;
etsCycles       = 50;
etsInterleave   = 10;

[status.setEts, sampleTimePicoSeconds] = invoke(ps5000aDeviceObj, 'ps5000aSetEts', mode, etsCycles, etsInterleave);

%% SET SIMPLE TRIGGER

% Channel     : 0 (PS5000A_CHANNEL_A)
% Threshold   : 1000 (mV)
% Direction   : 2 (Rising)
% Delay       : 0
% Auto trigger: 0 (wait indefinitely)

[status.setSimpleTrigger] = invoke(ps5000aDeviceObj, 'setSimpleTrigger', 0, 1000, 2, 0, 0);

%% GET TIMEBASE

% Driver default timebase index used - use ps5000aGetTimebase or
% ps5000aGetTimebase2 to query the driver as to suitability of using a
% particular timebase index then set the 'timebase' property if required.

% timebase     : 4
% segment index: 0

timebase = 4;

[status.getTimebase, timeIntervalNanoSeconds, maxSamples] = invoke(ps5000aDeviceObj, 'ps5000aGetTimebase', timebase, 0);
set(ps5000aDeviceObj, 'timebase', timebase);

%% SET BLOCK PARAMETERS AND CAPTURE DATA

% Set pre-trigger samples.
set(ps5000aDeviceObj, 'numPreTriggerSamples', 5000);
set(ps5000aDeviceObj, 'numPostTriggerSamples', 5000);

% Capture a block of data:
%
% segment index: 0

[status.runBlock] = invoke(ps5000aDeviceObj, 'runBlock', 0);

% Retrieve data values:
%
% start index       : 0
% segment index     : 0
% downsampling ratio: 1
% downsampling mode : 0 (PS5000A_RATIO_MODE_NONE)

[etsTimes, chA, ~, ~, ~, numSamples, overflow] = invoke(ps5000aDeviceObj, 'getEtsBlockData', 0, 0, 1, 0);

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