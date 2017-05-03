%PS5000A_IC_GENERIC_DRIVER_SIG_GEN Code for communicating with an instrument. 
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
%   PS5000A_IC_Generic_Driver_Sig_Gen, at the MATLAB command prompt.
% 
%   The file, PS5000A_IC_GENERIC_DRIVER_SIG_GEN.M must be on your MATLAB PATH. For additional information
%   on setting your MATLAB PATH, type 'help addpath' at the MATLAB command
%   prompt.
%
%   Example:
%       PS5000A_IC_Generic_Driver_Sig_Gen;
%
%   Description:
%       Demonstrates how to call functions to operate the
%       Function/Arbitrary Waveform Generator.
%
%   See also ICDEVICE.
%
%   Copyright:  Pico Technology Limited 2013
%
%   Author: HSM

%   Creation time: 28-Jun-2013 14:41:21 

%% LOAD CONFIGURATION INFORMATION

PS5000aConfig;

%% DEVICE CONNECTION

% Create a device object. 
ps5000aDeviceObj = icdevice('picotech_ps5000a_generic.mdd');

% Connect device object to hardware.
connect(ps5000aDeviceObj);

%% FUNCTION GENERATOR - SIMPLE
% Output a Sine wave, 2000mVpp, 0mV offset (uses preset frequency)

invoke(ps5000aDeviceObj, 'setSigGenBuiltInSimple', 0, 2000, 0);

%% FUNCTION GENERATOR - SWEEP FREQUENCY
% Output a Square wave 2000mVpp, 500mV offset, sweep down from 500 to 50Hz

% Define parameters

set(ps5000aDeviceObj, 'startFrequency', 50);
set(ps5000aDeviceObj, 'stopFrequency', 500);

offsetMv = 500;
pkToPkMv = 2400;
waveType = ps5000aEnuminfo.enPS5000AWaveType.PS5000A_SQUARE;
increment = 50.0; % Hz
dwellTime = 1;    % seconds
sweepType = ps5000aEnuminfo.enPS5000ASweepType.PS5000A_DOWN;
operatiom = PicoConstants.FALSE;
shots = 0;
sweeps = 0;
triggerType = ps5000aEnuminfo.enPS5000ASigGenTrigType.PS5000A_SIGGEN_RISING;
triggerSource = ps5000aEnuminfo.enPS5000ASigGenTrigSource.PS5000A_SIGGEN_NONE;
extInThresholdMv = 0;

% Execute device object function(s).
invoke(ps5000aDeviceObj, 'setSigGenBuiltIn', offsetMv, pkToPkMv, waveType, increment, ...
    dwellTime, sweepType, operatiom, shots, sweeps, triggerType, triggerSource, extInThresholdMv);

%% TURN OFF SIGNAL GENERATOR
invoke(ps5000aDeviceObj, 'setSigGenOff');

%% ARBITRARY WAVEFORM GENERATOR - SET PARAMETERS

% Configure property value(s).
set(ps5000aDeviceObj, 'startFrequency', 1000);
set(ps5000aDeviceObj, 'stopFrequency', 1000);

% Define Arbitrary Waveform - must be in range -1 to +1
% Arbitrary waveforms can also be read in from text and csv files using
% dlmread and csvread respectively.
% AWG Files created using PicoScope 6 can be read using the above method.

awgBufferSize = get(ps5000aDeviceObj, 'awgBufferSize');
x = [0:(2*pi)/(awgBufferSize - 1):2*pi];
y = normalise(sin(x) + sin(2*x));

%% ARBITRARY WAVEFORM GENERATOR - SIMPLE
% Output an arbitrary waveform with constant frequency

invoke(ps5000aDeviceObj, 'setSigGenArbitrarySimple', 0, 2000, y);

%% ARBITRARY WAVEFORM GENERATOR - OUTPUT SHOTS

% Set parameters
offsetMv = 0;
pkToPkMv = 2000;
increment = 0; % Hz
dwellTime = 1; % seconds
sweepType = ps5000aEnuminfo.enPS5000ASweepType.PS5000A_UP;
operatiom = PicoConstants.FALSE;
operation = ps5000aEnuminfo.enPS5000AIndexMode.PS5000A_SINGLE;
shots = 2;
sweeps = 0;
triggerType = ps5000aEnuminfo.enPS5000ASigGenTrigType.PS5000A_SIGGEN_RISING;
triggerSource = ps5000aEnuminfo.enPS5000ASigGenTrigSource.PS5000A_SIGGEN_SOFT_TRIG;
extInThresholdMv = 0;

% Call function
invoke(ps5000aDeviceObj, 'setSigGenArbitrary', offsetMv, pkToPkMv, increment, dwellTime, ...
    y, sweepType, operatiom, operation, shots, sweeps, triggerType, triggerSource, extInThresholdMv);

% Trigger the AWG
invoke(ps5000aDeviceObj, 'ps5000aSigGenSoftwareControl', 1);

%% TURN OFF SIGNAL GENERATOR
invoke(ps5000aDeviceObj, 'setSigGenOff');

%% DEVICE DISCONNECTION

% Disconnect device object from hardware.
disconnect(ps5000aDeviceObj);
