%% PS5000aConstants 
%
% The PS5000aConstants class defines a number of constant values from the
% ps5000aApi.h header file that can be used to define the properties of a
% PicoScope 5000 Series Oscilloscope/Mixed Signal Oscilloscope or for
% passing as parameters to function calls.
%
% The properties in this file are divided into the following
% sub-sections:
% 
% * ADC Count properties
% * ETS Mode properties
% * Trigger properties
% * Function/Arbitrary waveform parameters
% * Analog offset values
% * Maximum/Minimum waveform frequencies
% * PicoScope 5000 Series models using this driver
%
% Ensure that the location of this class file is on the MATLAB Path.		
%
% Copyright: © 2013-2018 Pico Technology Ltd. See LICENSE file for terms.

classdef PS5000aConstants
    
    properties (Constant)
        
        % ADC Counts
        PS5000A_MAX_VALUE_8BIT      = 32512;
        PS5000A_MIN_VALUE_8BIT      = -32512;

        PS5000A_MAX_VALUE_16BIT     = 32767;
        PS5000A_MIN_VALUE_16BIT     = -32767;
        
        PS5000A_EXT_MAX_VALUE = 32767;
        PS5000A_EXT_MIN_VALUE = -32767;
        
        PS5000A_EXT_MAX_VOLTAGE = 5; % Max threshold, volts
        PS5000A_EXT_MIN_VOLTAGE = -5; % Min threshold, volts
        
        % ETS information
        PS5244A_MAX_ETS_CYCLES      = 500;		% PS5242A, PS5242B, PS5442A, PS5442B
        PS5244A_MAX_ETS_INTERLEAVE  = 40;

        PS5243A_MAX_ETS_CYCLES      = 250;		% PS5243A, PS5243B, PS5443A, PS5443B
        PS5243A_MAX_ETS_INTERLEAVE  = 20;

        PS5242A_MAX_ETS_CYCLES      = 125;      % PS5242A, PS5242B, PS5442A, PS5442B
        PS5242A_MAX_ETS_INTERLEAVE  = 10;
        
        PS5X44D_MAX_ETS_CYCLES      = 500;      % PS5244D, PS5244DMSO, PS5444D, PS5444DMSO
        PS5X44D_MAX_ETS_INTERLEAVE  = 80;

        PS5X43D_MAX_ETS_CYCLES      = 250;    	% PS5243D, PS5243DMSO, PS5443D, PS5443DMSO
        PS5X43D_MAX_ETS_INTERLEAVE  = 40;

        PS5X42D_MAX_ETS_CYCLES      = 125;    	% PS5242D, PS5242DMSO, PS5442D, PS5442DMSO
        PS5X42D_MAX_ETS_INTERLEAVE  = 5;

        % Trigger information
        MAX_PULSE_WIDTH_QUALIFIER_COUNT = 16777215;
        MAX_DELAY_COUNT                 = 8388607;

        % Function/Arbitrary Waveform Parameters
        MIN_SIG_GEN_FREQ = 0.0;
        MAX_SIG_GEN_FREQ = 20000000.0;

        PS5X42A_MAX_SIG_GEN_BUFFER_SIZE = 16384;    % Covers the 5242A/B and 5442A/B
        PS5X43A_MAX_SIG_GEN_BUFFER_SIZE = 32768;    % Covers the 5243A/B and 5443A/B
        PS5X44A_MAX_SIG_GEN_BUFFER_SIZE = 49152;    % Covers the 5244A/B and 5444A/B
        
        PS5X4XD_MAX_SIG_GEN_BUFFER_SIZE = 32768;    % Covers the PicoScope 5000D Series
        
        MIN_SIG_GEN_BUFFER_SIZE         = 1;
        MIN_DWELL_COUNT                 = 3;
        MAX_SWEEPS_SHOTS				= pow2(30) - 1; % 1073741823
        AWG_DAC_FREQUENCY				= PicoConstants.AWG_DAC_FREQUENCY_200MHZ;
        PS5000AB_DDS_FREQUENCY 			= 200e6;
        PS5000D_DDS_FREQUENCY 			= 100e6;
        AWG_PHASE_ACCUMULATOR           = 4294967296.0;

        PS5000A_SHOT_SWEEP_TRIGGER_CONTINUOUS_RUN = hex2dec('FFFFFFFF');
        
        % Analogue offset information
        MAX_ANALOGUE_OFFSET_50MV_200MV = 0.250;
        MIN_ANALOGUE_OFFSET_50MV_200MV = -0.250;
        MAX_ANALOGUE_OFFSET_500MV_2V   = 2.500;
        MIN_ANALOGUE_OFFSET_500MV_2V   = -2.500;
        MAX_ANALOGUE_OFFSET_5V_20V     = 20;
        MIN_ANALOGUE_OFFSET_5V_20V	   = -20;

        
        % Signal generator frequencies
        PS5000A_SINE_MAX_FREQUENCY		= 20000000;
        PS5000A_SQUARE_MAX_FREQUENCY	= 20000000;
        PS5000A_TRIANGLE_MAX_FREQUENCY	= 20000000;
        PS5000A_SINC_MAX_FREQUENCY		= 20000000;
        PS5000A_RAMP_MAX_FREQUENCY		= 20000000;
        PS5000A_HALF_SINE_MAX_FREQUENCY	= 20000000;
        PS5000A_GAUSSIAN_MAX_FREQUENCY  = 20000000;
        PS5000A_PRBS_MAX_FREQUENCY		= 1000000;
        PS5000A_PRBS_MIN_FREQUENCY		= 0.03;
        PS5000A_MIN_FREQUENCY			= 0.03;

        % PicoScope 5000 Series models using the 'A' API
        
        % 2-channel variants
        MODEL_PS5242A   = '5242A';
        MODEL_PS5242B   = '5242B';
        MODEL_PS5243A   = '5243A';
        MODEL_PS5243B   = '5243B';
        MODEL_PS5244A   = '5244A';
        MODEL_PS5244B   = '5244B';
        MODEL_PS5242D   = '5242D';
        MODEL_PS5243D   = '5243D';
        MODEL_PS5244D   = '5244D';
        
        % 2-channel MSO models
        MODEL_PS5242D_MSO   = '5242DMSO';
        MODEL_PS5243D_MSO   = '5243DMSO';
        MODEL_PS5244D_MSO   = '5244DMSO';
        
        % 4-channel variants
        MODEL_PS5442A   = '5442A';
        MODEL_PS5442B   = '5442B';
        MODEL_PS5443A   = '5443A';
        MODEL_PS5443B   = '5443B';
        MODEL_PS5444A   = '5444A';
        MODEL_PS5444B   = '5444B';
        MODEL_PS5442D   = '5442D';
        MODEL_PS5443D   = '5443D';
        MODEL_PS5444D   = '5444D';
        
        % 4-channel MSO models
        MODEL_PS5442D_MSO   = '5442DMSO';
        MODEL_PS5443D_MSO   = '5443DMSO';
        MODEL_PS5444D_MSO   = '5444DMSO';
        
        % Used if a valid model is not found
        MODEL_NONE      = 'NONE';
        
        % Define Model specific buffer sizes
        
        % TBD
        
        % Model specific bandwidth at 8-bit resolution
        PS5X42X_BANDWIDTH = PicoConstants.BANDWIDTH_60MHZ;
        PS5X43X_BANDWIDTH = PicoConstants.BANDWIDTH_100MHZ;
        PS5X44X_BANDWIDTH = PicoConstants.BANDWIDTH_200MHZ;
        
    end

end

