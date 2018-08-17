%% PicoScope 5000 Series (A API) Instrument Driver Oscilloscope Signal Generator Example
% Code for communicating with an instrument in order to control the
% signal generator.
%  
% This is a modified version of the machine generated representation of 
% an instrument control session using a device object. The instrument 
% control session comprises all the steps you are likely to take when 
% communicating with your instrument. These steps are:
%       
% # Create a device object   
% # Connect to the instrument 
% # Configure properties 
% # Invoke functions 
% # Disconnect from the instrument 
%  
% To run the instrument control session, type the name of the file,
% PS5000A_ID_Sig_Gen_Example, at the MATLAB command prompt.
% 
% The file, PS5000A_ID_SIG_GEN_EXAMPLE.M must be on your MATLAB PATH. For additional information
% on setting your MATLAB PATH, type 'help addpath' at the MATLAB command
% prompt.
%
% *Example:*
%   PS5000A_ID_Sig_Gen_Example;
%
% *Description:*
%     Demonstrates how to set properties and call functions in order to
%     control the signal generator output of a PicoScope 5000 Series
%     Oscilloscope/Mixed Signal Oscilloscope using the 'A' API library
%     functions.
%
% *See also:* <matlab:doc('icdevice') |icdevice|> | <matlab:doc('instrument/invoke') |invoke|>
%
% *Copyright:* © 2013-2018 Pico Technology Ltd. See LICENSE file for terms.
%
% *Note:* The various signal generator functions called in this script may
% be combined with the functions used in the various data acquisition
% examples in order to output a signal and acquire data. The functions to
% setup the signal generator should be called prior to the start of data
% collection.

%% Clear command window and workspace and close any figures

clc;
clear;
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
% The serial number can be specified as a second input parameter.
ps5000aDeviceObj = icdevice('picotech_ps5000a_generic.mdd');

% Connect device object to hardware.
connect(ps5000aDeviceObj);

%% Obtain Signalgenerator group object
% Signal Generator properties and functions are located in the Instrument
% Driver's Signalgenerator group.

sigGenGroupObj = get(ps2000aDeviceObj, 'Signalgenerator');
sigGenGroupObj = sigGenGroupObj(1);

%% Function generator - simple
% Output a sine wave, 2000 mVpp, 0 mV offset, 1000 Hz (uses preset values
% for offset, peak to peak voltage and frequency from the Signalgenerator
% groups's properties).

% waveType : 0 (ps5000aEnuminfo.enPS5000AWaveType.PS5000A_SINE)

[status.setSigGenBuiltInSimple] = invoke(ps5000aDeviceObj, 'setSigGenBuiltInSimple', 0);

%% Function generator - sweep frequency
% Output a square wave, 2400 mVpp, 500 mV offset, and sweep continuously
% from 500 Hz to 50 Hz in steps of 50 Hz.

% Configure property value(s).

set(sigGenGroupObj, 'startFrequency', 50.0);
set(sigGenGroupObj, 'stopFrequency', 500.0);
set(sigGenGroupObj, 'offsetVoltage', 500.0);
set(sigGenGroupObj, 'peakToPeakVoltage', 2400.0);

waveType 			= ps5000aEnuminfo.enPS5000AWaveType.PS5000A_SQUARE;
increment 			= 50.0; % Hz
dwellTime 			= 1;    % seconds
sweepType 			= ps5000aEnuminfo.enPS5000ASweepType.PS5000A_DOWN;
operation 			= ps5000aEnuminfo.enPS5000AExtraOperations.PS5000A_ES_OFF;
shots 				= 0;
sweeps 				= 0;
triggerType 		= ps5000aEnuminfo.enPS5000ASigGenTrigType.PS5000A_SIGGEN_RISING;
triggerSource 		= ps5000aEnuminfo.enPS5000ASigGenTrigSource.PS5000A_SIGGEN_NONE;
extInThresholdMv 	= 0;

% Execute device object function(s).
[status.setSigGenBuiltIn] = invoke(sigGenGroupObj, 'setSigGenBuiltIn', offsetMv, pkToPkMv, waveType, increment, ...
								dwellTime, sweepType, operation, shots, sweeps, triggerType, triggerSource, extInThresholdMv);

%% Turn off signal generator
% Sets the output to 0 V DC.

[status.setSigGenOff] = invoke(sigGenGroupObj, 'setSigGenOff');

%% Arbitrary waveform generator - set parameters
% Set parameters (2000 mVpp, 0 mV offset, 1000 Hz frequency) and define an
% arbitrary waveform.

% Configure property value(s).
set(sigGenGroupObj, 'startFrequency', 1000);
set(sigGenGroupObj, 'stopFrequency', 1000);
set(sigGenGroupObj, 'offsetVoltage', 0.0);
set(sigGenGroupObj, 'peakToPeakVoltage', 2000.0);

%% 
% Define an Arbitrary Waveform - values must be in the range -1 to +1.
% Arbitrary waveforms can also be read in from text and csv files using
% <matlab:doc('dlmread') |dlmread|> and <matlab:doc('csvread') |csvread|>
% respectively or use the |importAWGFile| function from the <https://uk.mathworks.com/matlabcentral/fileexchange/53681-picoscope-support-toolbox PicoScope
% Support Toolbox>.
%
% Any AWG files created using the PicoScope 6 application can be read using
% the above method.

awgBufferSize = get(sigGenGroupObj, 'awgBufferSize');
x = [0:(2*pi)/(awgBufferSize - 1):2*pi];
y = normalise(sin(x) + sin(2*x));

%% Arbitrary waveform generator - simple
% Output an arbitrary waveform with constant frequency (defined above).

% Arb. Waveform : y (defined above)

[status.setSigGenArbitrarySimple] = invoke(ps5000aDeviceObj, 'setSigGenArbitrarySimple', y);

%% Turn off signal generator
% Sets the output to 0 V DC.

[status.setSigGenOff] = invoke(sigGenGroupObj, 'setSigGenOff');

%% Arbitrary waveform generator - output shots
% Output 2 cycles of an arbitrary waveform using a software trigger.
%
% Note that the signal generator will output the value coresponding to the
% first sample in the arbitrary waveform until the trigger event occurs.

% Set parameters
offsetMv 			= 0;
pkToPkMv 			= 2000;
increment 			= 0; % Hz
dwellTime 			= 1; % seconds
sweepType 			= ps5000aEnuminfo.enPS5000ASweepType.PS5000A_UP;
operation 			= ps5000aEnuminfo.enPS5000AExtraOperations.PS5000A_ES_OFF;
indexMode 			= ps5000aEnuminfo.enPS5000AIndexMode.PS5000A_SINGLE;
shots 				= 2;
sweeps 				= 0;
triggerType 		= ps5000aEnuminfo.enPS5000ASigGenTrigType.PS5000A_SIGGEN_RISING;
triggerSource 		= ps5000aEnuminfo.enPS5000ASigGenTrigSource.PS5000A_SIGGEN_SOFT_TRIG;
extInThresholdMv 	= 0;

[status.setSigGenArbitrary] = invoke(sigGenGroupObj, 'setSigGenArbitrary', increment, dwellTime, y, sweepType, ...
										operation, indexMode, shots, sweeps, triggerType, triggerSource, extInThresholdMv);

% Trigger the AWG

% State : 1 (a non-zero value will trigger the output)
[status.sigGenSoftwareControl] = invoke(sigGenGroupObj, 'ps5000aSigGenSoftwareControl', 1);

%% Turn off signal generator
% Sets the output to 0 V DC.

[status.setSigGenOff] = invoke(sigGenGroupObj, 'setSigGenOff');

%% Disconnect device
% Disconnect device object from hardware.

disconnect(ps5000aDeviceObj);
delete(ps5000aDeviceObj);
