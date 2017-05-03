%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Filename:    PS5000A_IC_Generic_Driver_Streaming
%
% Copyright:   Pico Technology Limited 2013
%
% Author:      HSM
%
% Description:
%   This is a MATLAB script that demonstrates how to use the
%   PicoScope 5000a series Instrument Control Toobox driver to collect data
%   in streaming mode for 2 channels without aggregation and using a 
%   simple trigger.
%
%	To run this application:
%		Ensure that the following files/folders are located either in the 
%       same directory or define the path in the PS5000aConfig.m file:
%       
%       - picotech_ps5000a_generic.mdd
%       - ps5000a.dll & ps5000aWrap.dll 
%       - PS5000aMFile & ps5000aWrapMFile
%       - PicoStatus.m
%       - Functions
%
%   Device used to generated example: PicoScope 5242A
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% LOAD CONFIGURATION INFORMATION

PS5000aConfig;

%% PARAMETER DEFINITIONS
% Define any parameters that might be required throughout the script.

channelA = ps5000aEnuminfo.enPS5000AChannel.PS5000A_CHANNEL_A;
channelB = ps5000aEnuminfo.enPS5000AChannel.PS5000A_CHANNEL_B;

%% DEVICE CONNECTION

% Create device -  specify serial number if required
% Specify serial number as 2nd argument if required.
ps5000aDeviceObj = icdevice('picotech_ps5000a_generic', ''); 

% Connect device
connect(ps5000aDeviceObj);

%% DISPLAY UNIT INFORMATION

[infoStatus, unitInfo] = invoke(ps5000aDeviceObj, 'getUnitInfo')

%% CHANNEL SETUP
% All channels are enabled by default - if the device is a 4-channel scope,
% switch off channels C and D so device can be set to 15-bit resolution.

% Channel A
channelSettings(1).enabled = PicoConstants.TRUE;
channelSettings(1).coupling = ps5000aEnuminfo.enPS5000ACoupling.PS5000A_DC;
channelSettings(1).range = ps5000aEnuminfo.enPS5000ARange.PS5000A_2V;
channelSettings(1).analogueOffset = 0.0;

channelARangeMV = PicoConstants.SCOPE_INPUT_RANGES(channelSettings(1).range + 1);

% Channel B
channelSettings(2).enabled = PicoConstants.TRUE;
channelSettings(2).coupling = ps5000aEnuminfo.enPS5000ACoupling.PS5000A_DC;
channelSettings(2).range = ps5000aEnuminfo.enPS5000ARange.PS5000A_2V;
channelSettings(2).analogueOffset = 0.0;

% Variables that will be required later
channelBRangeMV = PicoConstants.SCOPE_INPUT_RANGES(channelSettings(2).range + 1);

if(ps5000aDeviceObj.channelCount == PicoConstants.QUAD_SCOPE)

    % Channel C
    channelSettings(3).enabled = PicoConstants.FALSE;
    channelSettings(3).coupling = ps5000aEnuminfo.enPS5000ACoupling.PS5000A_DC;
    channelSettings(3).range = ps5000aEnuminfo.enPS5000ARange.PS5000A_2V;
    channelSettings(3).analogueOffset = 0.0;

    % Channel D
    channelSettings(4).enabled = PicoConstants.FALSE;
    channelSettings(4).coupling = ps5000aEnuminfo.enPS5000ACoupling.PS5000A_DC;
    channelSettings(4).range = ps5000aEnuminfo.enPS5000ARange.PS5000A_2V;
    channelSettings(4).analogueOffset = 0.0;
    
end

% Keep the status values returned from the driver.
numChannels = get(ps5000aDeviceObj, 'channelCount');
status.setChannelStatus = zeros(numChannels, 1);

status.currentPowerSource = invoke(ps5000aDeviceObj, 'ps5000aCurrentPowerSource');

% Check if power supply connected - channels C and D will not be enabled on
% a 4-channel oscilloscope if it is only USB powered.
if(status.currentPowerSource == PicoStatus.PICO_POWER_SUPPLY_NOT_CONNECTED)
    
    numChannels = PicoConstants.DUAL_SCOPE;
    
end

for ch = 1:numChannels
   
    status.setChannelStatus(ch) = invoke(ps5000aDeviceObj, 'ps5000aSetChannel', ...
        (ch - 1), channelSettings(ch).enabled, ...
        channelSettings(ch).coupling, channelSettings(ch).range, ...
        channelSettings(ch).analogueOffset);
    
end

%% CHANGE RESOLUTION
% The maximum resolution will depend on the number of channels enabled.

% Set resolution to 15 bits as 2 channels will be enabled.
[status.resolution, resolution] = invoke(ps5000aDeviceObj, 'ps5000aSetDeviceResolution', 15);  

% Max ADC count will change if resolution is not 8-bits
maxADCCount = get(ps5000aDeviceObj, 'maxADCValue');

%% TRIGGER SETUP

% Channel     : 0 (PS5000A_CHANNEL_A)
% Threshold   : 500 (mV)
% Direction   : 2 (Rising)
% Delay       : 0
% Auto trigger: 0 (wait indefinitely)

[status.setSimpleTrigger] = invoke(ps5000aDeviceObj, 'setSimpleTrigger', 0, 500, 2, 0, 0);

%% SET DATA BUFFERS
% Data buffers for Channel A and B - buffers should be set with the driver,
% and these MUST be passed with application buffers to the wrapper driver
% in order to ensure data is correctly copied.

sampleCount =  100000; % Size of the buffer to collect data from buffer.
segmentIndex = 0;   

ratioMode = ps5000aEnuminfo.enPS5000ARatioMode.PS5000A_RATIO_MODE_NONE;

% Buffers to be passed to the driver
pDriverBufferChA = libpointer('int16Ptr', zeros(sampleCount, 1, 'int16'));
pDriverBufferChB = libpointer('int16Ptr', zeros(sampleCount, 1, 'int16'));

status.setDataBufferChA = invoke(ps5000aDeviceObj, 'ps5000aSetDataBuffer', ...
    channelA, pDriverBufferChA, sampleCount, segmentIndex, ratioMode);

status.setDataBufferChB = invoke(ps5000aDeviceObj, 'ps5000aSetDataBuffer', ...
    channelB, pDriverBufferChB, sampleCount, segmentIndex, ratioMode);

% Application Buffers - these are for copying from the driver into.
pAppBufferChA = libpointer('int16Ptr', zeros(sampleCount, 1, 'int16'));
pAppBufferChB = libpointer('int16Ptr', zeros(sampleCount, 1, 'int16'));

status.setAppDriverBuffersA = invoke(ps5000aDeviceObj, 'setAppAndDriverBuffers', channelA, ...
    pAppBufferChA, pDriverBufferChA, sampleCount);

status.setAppDriverBuffersB = invoke(ps5000aDeviceObj, 'setAppAndDriverBuffers', channelB, ...
    pAppBufferChB, pDriverBufferChB, sampleCount);


%% RUN STREAMING AND GET VALUES
% Use default value for streaming interval which is 1e-6 for 1MS/s
% Collect data for 1 second with auto stop - maximum array size will depend
% on PC's resources - type 'memory' at MATLAB command prompt for further
% information.

% To change the sample interval e.g 5 us for 200KS/s
%set(ps5000aDeviceObj, 'streamingInterval', 5e-6);

% Set the number of pre- and post-trigger samples
% If no trigger is set 'numPreTriggerSamples' is ignored
set(ps5000aDeviceObj, 'numPreTriggerSamples', 0);
set(ps5000aDeviceObj, 'numPostTriggerSamples', 1000000);

% Set other streaming parameters
downSampleRatio = 1;
downSampleRatioMode = ps5000aEnuminfo.enPS5000ARatioMode.PS5000A_RATIO_MODE_NONE;
overviewBufferSize = sampleCount;

% Defined buffers to store data - allocate 1.5 times the size to allow for
% pre-trigger data. Pre-allocating the array is more efficient than using
% vertcat to combine data

maxSamples = get(ps5000aDeviceObj, 'numPreTriggerSamples') + ...
    get(ps5000aDeviceObj, 'numPostTriggerSamples');

% Take into account the downSamplesRatioMode
finalBufferLength = round(1.5 * maxSamples / downSampleRatio);

pBufferChAFinal = libpointer('int16Ptr', zeros(finalBufferLength, 1));

% Prompt to press enter to begin capture
input('Press ENTER to begin data collection.', 's');

originalPowerSource = invoke(ps5000aDeviceObj, 'ps5000aCurrentPowerSource');

[status.runStreaming, sampleInterval, sampleIntervalTimeUnitsStr] = ...
    invoke(ps5000aDeviceObj, 'ps5000aRunStreaming', downSampleRatio, ...
    downSampleRatioMode, overviewBufferSize);
    
disp('Streaming data...');
fprintf('Click the STOP button to stop capture or wait for auto stop if enabled.\n') 

% Variables to be used when collecting the data
hasAutoStopped = PicoConstants.FALSE;
powerChange = PicoConstants.FALSE;
 
newSamples = 0;         % Number of new samples returned from the driver.
previousTotal = 0;      % The previous total number of samples.
totalSamples = 0;       % Total samples captured by the device.
startIndex = 0;         % Start index of data in the buffer returned.

hasTriggered = 0;       % To indicate if trigger has occurred.
triggeredAtIndex = 0;   % The index in the overall buffer where the trigger occurred.

t = zeros(sampleCount / downSampleRatio, 1);	% Array to hold time values

originalPowerSource = invoke(ps5000aDeviceObj, 'ps5000aCurrentPowerSource');

getStreamingLatestValuesStatus = PicoStatus.PICO_OK; % OK

% Stop button to check abort data collection - based on Mathworks solution 1-15JIQ 
% and MATLAB Central forum.

stopFig.f = figure('menubar','none',...
              'units','pix',...
              'pos',[400 400 100 50]);
          
stopFig.h = uicontrol('string', 'STOP', ...
'callback', 'setappdata(gcf, ''run'', 0)', 'units','pixels',...
                 'position',[10 10 80 30]);

flag = 1; % Use flag variable to indicate if stop button has been clicked (0)
setappdata(gcf, 'run', flag);

% Plot Properties

% Plot on a single figure
figure1 = figure;
axes1 = axes('Parent', figure1);

% Calculate limit - use max of multiple channels if plotting on same graph
% Estimate x limit to try and avoid using too much CPU when drawing
xlim(axes1, [0 (sampleInterval * finalBufferLength)]);

yRange = channelARangeMV + 0.5;
ylim(axes1,[(-1 * yRange) yRange]);
grid on;
hold(axes1,'on');

title('Streaming Data Capture');
xLabelStr = strcat('Time (', sampleIntervalTimeUnitsStr, ')');
xlabel(xLabelStr);
ylabel('Voltage (mV)');

% Get data values as long as power status has not changed (check for STOP button push inside loop)
while(hasAutoStopped == PicoConstants.FALSE && getStreamingLatestValuesStatus == PicoStatus.PICO_OK)
    
    ready = PicoConstants.FALSE;
   
    while(ready == PicoConstants.FALSE)

       getStreamingLatestValuesStatus = invoke(ps5000aDeviceObj, 'getStreamingLatestValues'); 
        
       ready = invoke(ps5000aDeviceObj, 'isReady');

       % Give option to abort from here
       flag = getappdata(gcf, 'run');
       drawnow;

       if(flag == 0)

            disp('STOP button clicked - aborting data collection.')
            break;

       end

       drawnow;

    end
    
    % Check for data
    [newSamples, startIndex] = invoke(ps5000aDeviceObj, 'availableData');

    if (newSamples > 0)
        
        % Check if the scope has triggered
        [triggered, triggeredAt] = invoke(ps5000aDeviceObj, 'isTriggerReady');

        if (triggered == PicoConstants.TRUE)

            % Adjust trigger position as MATLAB does not use zero-based
            % indexing
            fprintf('Triggered - index in buffer: %d\n', (triggeredAt + 1));

            hasTriggered = triggered;

            % Adjust by 1 due to driver using zero indexing
            triggeredAtIndex = totalSamples + triggeredAt + 1;

        end

        previousTotal = totalSamples;
        totalSamples = totalSamples + newSamples;

        % Printing to console can slow down acquisition - use for debug
        % fprintf('Collected %d samples, total: %d.\n', newSamples, totalSamples);
        
        % Position indices of data in buffer
        firstValuePosn = startIndex + 1;
        lastValuePosn = startIndex + newSamples;
        
        % Debug
        % fprintf('StartIndex, Position of first and last values in buffer: %d, %d, %d.\n', startIndex, firstValuePosn, lastValuePosn);
        
        % Convert data values to milliVolts from the application buffers
        
        bufferChA = pAppBufferChA.Value(firstValuePosn:lastValuePosn);
        bufferChB = pAppBufferChB.Value(firstValuePosn:lastValuePosn);

        bufferChAmV = adc2mv(bufferChA, channelARangeMV, maxADCCount);
        bufferChBmV = adc2mv(bufferChB, channelBRangeMV, maxADCCount);

        % Process collected data further if required - this example plots
        % the data.
        
        % Time axis
        
        % Multiply by ratio mode as samples get reduced
        t = (double(sampleInterval) * double(downSampleRatio)) * (previousTotal:(totalSamples - 1));
        
        plot(t, bufferChAmV, t, bufferChBmV);
        
        % Copy data values to overall buffer for channel
        pBufferChAFinal.Value(previousTotal + 1:totalSamples) = bufferChAmV(1:end);
        pBufferChBFinal.Value(previousTotal + 1:totalSamples) = bufferChBmV(1:end);
       
        % Clear variables for use again
        clear bufferChA
        clear bufferChB
        clear bufferChAMV;
        clear bufferChBMV;
        clear firstValuePosn;
        clear lastValuePosn;
        clear startIndex;
        clear triggered;
        clear triggerAt;
          
   end
   
    % Check if auto stop has occurred
    hasAutoStopped = invoke(ps5000aDeviceObj, 'autoStopped');

    if(hasAutoStopped == PicoConstants.TRUE)

       disp('AutoStop: TRUE - exiting loop.');
       break;

    end
   
    % Check if 'STOP' button pressed

    flag = getappdata(gcf, 'run');
    drawnow;

    if(flag == 0)

        disp('STOP button clicked - aborting data collection.')
        break;
        
    end
 
end

% Close the STOP button window
if(exist('stopFig', 'var'))
    
    delete(stopFig.h);
    delete(stopFig.f);
        
end

drawnow;

if(hasTriggered == PicoConstants.TRUE)
   
    fprintf('Triggered at overall index: %d\n\n', triggeredAtIndex);
    
end

% Take hold off the current figure
hold off;

%% STOP THE DEVICE
% This function should be called regardless of whether auto stop is enabled
% or not.

status.stop = invoke(ps5000aDeviceObj, 'ps5000aStop');

%% FIND THE NUMBER OF SAMPLES
% This is the number of samples available after data collection in streaming mode. 
[status.noOfStreamingValues, numStreamingValues] = invoke(ps5000aDeviceObj, 'ps5000aNoOfStreamingValues');

fprintf('Number of samples available after data collection: %u\n', numStreamingValues);

%% PROCESS DATA
% Process all data if required

% Reduce size of arrays
pBufferChAFinal.Value(totalSamples + 1:end) = [];
channelAFinal = pBufferChAFinal.Value();

pBufferChBFinal.Value(totalSamples + 1:end) = [];
channelBFinal = pBufferChBFinal.Value();

% Plot total data on another figure

finalFigure = figure;
axes2 = axes('Parent', finalFigure);
hold on;
grid(axes2);

title('Streaming Data Capture');
xLabelStr = strcat('Time (', sampleIntervalTimeUnitsStr, ')');
xlabel(xLabelStr);
ylabel('Voltage (mV)');

time = (double(sampleInterval) * double(downSampleRatio)) * (0:length(channelAFinal) - 1);
subplot(2,1,1); 
title('PicoScope 5000 Series Streaming Data Capture - Channel A');
xLabelStr = strcat('Time (', sampleIntervalTimeUnitsStr, ')');
xlabel(xLabelStr);
ylabel('Voltage (mV)');
plot(time, channelAFinal);
legend('Channel A');

subplot(2,1,2); 
title('PicoScope 5000 Series Streaming Data Capture - Channel B');
xLabelStr = strcat('Time (', sampleIntervalTimeUnitsStr, ')');
xlabel(xLabelStr);
ylabel('Voltage (mV)');
plot(time, channelBFinal);
legend('Channel B');

hold off;
%% DISCONNECT DEVICE

disconnect(ps5000aDeviceObj);