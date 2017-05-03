%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Filename:    PS5000aConstants
%
% Copyright:   Pico Technology Limited 2013
%
% Author:      HSM
%
% Description:
%   This is a MATLAB script that contains reference information for the
%   PicoScope 5000 Instrument Control Driver - DO NOT EDIT.
%
% Ensure that the file is on the MATLAB Path.		
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef PS5000aConstants
    %PS5000ACONSTANTS Defines PicoScope 5000 Series constants from header
    %file ps5000aApi.h
    %   The PS5000AConstants class defines a number of constant values that
    %   can be used to define the properties of an Oscilloscopes device or
    %   for passing as parameters to function calls.
    
    properties (Constant)
        
        PS5000A_MAX_VALUE_8BIT      = 32512;
        PS5000A_MIN_VALUE_8BIT      = -32512;
        PS5000A_MAX_VALUE_12BIT     = 32752;
        PS5000A_MIN_VALUE_12BIT     = -32752;
        PS5000A_MAX_VALUE_16BIT     = 32767;
        PS5000A_MIN_VALUE_16BIT     = -32767;
        PS5000A_LOST_DATA           = -32768;
        
        PS5244A_MAX_ETS_CYCLES      = 500;		% PS5242A, PS5242B, PS5442A, PS5442B
        PS5244A_MAX_ETS_INTERLEAVE  = 40;

        PS5243A_MAX_ETS_CYCLES      = 250;		% PS5243A, PS5243B, PS5443A, PS5443B
        PS5243A_MAX_ETS_INTERLEAVE  = 20;

        PS5242A_MAX_ETS_CYCLES      = 125;      % PS5242A, PS5242B, PS5442A, PS5442B
        PS5242A_MAX_ETS_INTERLEAVE  = 10;

        PS5000A_EXT_MAX_VALUE = 32767;
        PS5000A_EXT_MIN_VALUE = -32767;
        
        PS5000A_EXT_MAX_VOLTAGE = 5;
        PS5000A_EXT_MIN_VOLTAGE = -5;
        
        MAX_PULSE_WIDTH_QUALIFIER_COUNT = 16777215;
        MAX_DELAY_COUNT                 = 8388607;

        % Function/Arbitrary Waveform Parameters
        MIN_SIG_GEN_FREQ = 0.0;
        MAX_SIG_GEN_FREQ = 20000000.0;

        PS5X42A_MAX_SIG_GEN_BUFFER_SIZE = 16384;    % covers the 5242A/B and 5442A/B
        PS5X43A_MAX_SIG_GEN_BUFFER_SIZE = 32768;    % covers the 5243A/B and 5443A/B
        PS5X44A_MAX_SIG_GEN_BUFFER_SIZE = 49152;    % covers the 5244A/B and 5444A/B
        
        MIN_SIG_GEN_BUFFER_SIZE         = 10;
        MIN_DWELL_COUNT                 = 3;
        MAX_SWEEPS_SHOTS				= pow2(30) - 1; %1073741823

        MAX_ANALOGUE_OFFSET_50MV_200MV = 0.250;
        MIN_ANALOGUE_OFFSET_50MV_200MV = -0.250;
        MAX_ANALOGUE_OFFSET_500MV_2V   = 2.500;
        MIN_ANALOGUE_OFFSET_500MV_2V   = -2.500;
        MAX_ANALOGUE_OFFSET_5V_20V     = 20;
        MIN_ANALOGUE_OFFSET_5V_20V	   = -20;

        PS5000A_SHOT_SWEEP_TRIGGER_CONTINUOUS_RUN = hex2dec('FFFFFFFF');

        % Frequencies
        
        PS5000A_SINE_MAX_FREQUENCY		= 20000000;
        PS5000A_SQUARE_MAX_FREQUENCY	= 20000000;
        PS5000A_TRIANGLE_MAX_FREQUENCY	= 20000000;
        PS5000A_SINC_MAX_FREQUENCY		= 20000000
        PS5000A_RAMP_MAX_FREQUENCY		= 20000000;
        PS5000A_HALF_SINE_MAX_FREQUENCY	= 20000000;
        PS5000A_GAUSSIAN_MAX_FREQUENCY  = 20000000;
        PS5000A_PRBS_MAX_FREQUENCY		= 1000000;
        PS5000A_PRBS_MIN_FREQUENCY		= 0.03;
        PS5000A_MIN_FREQUENCY			= 0.03;

        % PicoScope 5000 series Models
        
        MODEL_NONE      = 'NONE';
        
        % 2 channel variants
        MODEL_PS5242A   = '5242A';
        MODEL_PS5242B   = '5242B';
        MODEL_PS5243A   = '5243A';
        MODEL_PS5243B   = '5243B';
        MODEL_PS5244A   = '5244A';
        MODEL_PS5244B   = '5244B';
        
        % 4 channel variants
        MODEL_PS5442A   = '5442A';
        MODEL_PS5442B   = '5442B';
        MODEL_PS5443A   = '5443A';
        MODEL_PS5443B   = '5443B';
        MODEL_PS5444A   = '5444A';
        MODEL_PS5444B   = '5444B';
        
        % Define Model specific buffer sizes
        
        % TBD
        
        % Model specific bandwidth at 8-bit resolution
        PS5X42X_BANDWIDTH = PicoConstants.BANDWIDTH_60MHZ;
        PS5X43X_BANDWIDTH = PicoConstants.BANDWIDTH_100MHZ;
        PS5X44X_BANDWIDTH = PicoConstants.BANDWIDTH_200MHZ;
        
    end

end

