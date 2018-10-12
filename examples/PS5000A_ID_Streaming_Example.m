%% PicoScope 5000 Series (A API) Instrument Driver Oscilloscope Streaming Data Capture Example
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
% PS5000A_ID_Streaming_Example, at the MATLAB command prompt.
% 
% The file, PS5000A_ID_STREAMING_EXAMPLE.M must be on your MATLAB PATH. For
% additional information on setting your MATLAB PATH, type 'help addpath'
% at the MATLAB command prompt.
%
% *Example:*
%     PS5000A_ID_Streaming_Example;
%
% *Description:*
%     Demonstrates how to set properties and call functions in order
%     to capture data in streaming mode from a PicoScope 5000 Series
%     Oscilloscope using the underlying 'A' API library functions.
%
% *Note:* Not all device functions used in this example are compatible with
% the Test and Measurement Tool.
%
% *See also:* <matlab:doc('icdevice') |icdevice|> | <matlab:doc('instrument/invoke') |invoke|>
%
% *Copyright:* © 2013-2018 Pico Technology Ltd. See LICENSE file for terms.

%% Suggested input test signals
% This example was published using the following test signals:
%
% * Channel A: 3 Vpp, 1 Hz sine wave
% * Channel B: 2 Vpp, 4 Hz square wave 

%% Clear command window and close any figures

clc;
close all;

%% Load configuration information

PS5000aConfig;

%% Parameter definitions
% Define any parameters that might be required throughout the script.

channelA = ps5000aEnuminfo.enPS5000AChannel.PS5000A_CHANNEL_A;
channelB = ps5000aEnuminfo.enPS5000AChannel.PS5000A_CHANNEL_B;

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

%% Display unit information

[status.getUnitInfo, unitInfo] = invoke(ps5000aDeviceObj, 'getUnitInfo');
disp(unitInfo);

%% Channel setup
% All channels are enabled by default - if the device is a 4-channel scope,
% switch off channels C and D so device can be set to 15-bit resolution.

% Channel A
channelSettings(1).enabled = PicoConstants.TRUE;
channelSettings(1).coupling = ps5000aEnuminfo.enPS5000ACoupling.PS5000A_DC;
channelSettings(1).range = ps5000aEnuminfo.enPS5000ARange.PS5000A_2V;
channelSettings(1).analogueOffset = 0.0;

channelARangeMv = PicoConstants.SCOPE_INPUT_RANGES(channelSettings(1).range + 1);

% Channel B
channelSettings(2).enabled = PicoConstants.TRUE;
channelSettings(2).coupling = ps5000aEnuminfo.enPS5000ACoupling.PS5000A_DC;
channelSettings(2).range = ps5000aEnuminfo.enPS5000ARange.PS5000A_2V;
channelSettings(2).analogueOffset = 0.0;

% Variables that will be required later
channelBRangeMv = PicoConstants.SCOPE_INPUT_RANGES(channelSettings(2).range + 1);

if (ps5000aDeviceObj.channelCount == PicoConstants.QUAD_SCOPE)

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

[status.currentPowerSource] = invoke(ps5000aDeviceObj, 'ps5000aCurrentPowerSource');

% Check if the power supply is connected - channels C and D will not be
% enabled on a 4-channel oscilloscope if it is only USB powered.
if (status.currentPowerSource == PicoStatus.PICO_POWER_SUPPLY_NOT_CONNECTED)
    
    numChannels = PicoConstants.DUAL_SCOPE;
    
end

for ch = 1:numChannels
   
    status.setChannelStatus(ch) = invoke(ps5000aDeviceObj, 'ps5000aSetChannel', ...
        (ch - 1), channelSettings(ch).enabled, ...
        channelSettings(ch).coupling, channelSettings(ch).range, ...
        channelSettings(ch).analogueOffset);
    
end

%% Change resolution
% The maximum resolution will depend on the number of channels enabled.

% Set resolution to 15 bits as 2 channels will be enabled.
[status.setResolution, resolution] = invoke(ps5000aDeviceObj, 'ps5000aSetDeviceResolution', 15);  

% Obtain the maximum Analog Digital Converter (ADC) count value from the
% driver - this is used for scaling values returned from the driver when
% data is collected. This value may change depending on the resolution
% selected.
maxADCCount = get(ps5000aDeviceObj, 'maxADCValue');

%% Set simple trigger
% Set a trigger on channel A, with an auto timeout - the default value for
% delay is used. The device will wait for a rising edge through
% the specified threshold unless the timeout occurs first.

% Trigger properties and functions are located in the Instrument
% Driver's Trigger group.

triggerGroupObj = get(ps5000aDeviceObj, 'Trigger');
triggerGroupObj = triggerGroupObj(1);

% Set the |autoTriggerMs| property in order to automatically trigger the
% oscilloscope after 1 second if a trigger event has not occurred. Set to 0
% to wait indefinitely for a trigger event.

set(triggerGroupObj, 'autoTriggerMs', 1000);

% Channel     : 0 (ps5000aEnuminfo.enPS5000AChannel.PS5000A_CHANNEL_A)
% Threshold   : 500 mV
% Direction   : 2 (ps5000aEnuminfo.enPS5000AThresholdDirection.PS5000A_RISING)

[status.setSimpleTrigger] = invoke(triggerGroupObj, 'setSimpleTrigger', 0, 500, 2);

%% Set data buffers
% Data buffers for channels A and B - buffers should be set with the driver,
% and these *MUST* be passed with application buffers to the wrapper driver.
% This will ensure that data is correctly copied from the driver buffers
% for later processing.

overviewBufferSize  = 100000; % Size of the buffer to collect data from buffer.
segmentIndex        = 0;   
ratioMode           = ps5000aEnuminfo.enPS5000ARatioMode.PS5000A_RATIO_MODE_NONE;

% Buffers to be passed to the driver
pDriverBufferChA = libpointer('int16Ptr', zeros(overviewBufferSize, 1, 'int16'));
pDriverBufferChB = libpointer('int16Ptr', zeros(overviewBufferSize, 1, 'int16'));

status.setDataBufferChA = invoke(ps5000aDeviceObj, 'ps5000aSetDataBuffer', ...
    channelA, pDriverBufferChA, overviewBufferSize, segmentIndex, ratioMode);

status.setDataBufferChB = invoke(ps5000aDeviceObj, 'ps5000aSetDataBuffer', ...
    channelB, pDriverBufferChB, overviewBufferSize, segmentIndex, ratioMode);

% Application Buffers - these are for copying from the driver into.
pAppBufferChA = libpointer('int16Ptr', zeros(overviewBufferSize, 1, 'int16'));
pAppBufferChB = libpointer('int16Ptr', zeros(overviewBufferSize, 1, 'int16'));

% Streaming properties and functions are located in the Instrument Driver's
% Streaming group.

streamingGroupObj = get(ps5000aDeviceObj, 'Streaming');
streamingGroupObj = streamingGroupObj(1);

status.setAppDriverBuffersA = invoke(streamingGroupObj, 'setAppAndDriverBuffers', channelA, ...
    pAppBufferChA, pDriverBufferChA, overviewBufferSize);

status.setAppDriverBuffersB = invoke(streamingGroupObj, 'setAppAndDriverBuffers', channelB, ...
    pAppBufferChB, pDriverBufferChB, overviewBufferSize);


%% Start streaming and collect data
% Use default value for streaming interval which is 1e-6 for 1 MS/s.
% Collect data for 5 seconds with auto stop - maximum array size will depend
% on the PC's resources - type <matlab:doc('memory') |memory|> at the
% MATLAB command prompt for further information.
%
% To change the sample interval set the |streamingInterval| property of the
% Streaming group object. The call to the |ps5000aRunStreaming()| function
% will output the actual sampling interval used by the driver.

% To change the sample interval e.g 5 us for 200 kS/s
% set(streamingGroupObj, 'streamingInterval', 5e-6);

%%
% Set the number of pre- and post-trigger samples.
% If no trigger is set the library will still store
% |numPreTriggerSamples| + |numPostTriggerSamples|.
set(ps5000aDeviceObj, 'numPreTriggerSamples', 0);
set(ps5000aDeviceObj, 'numPostTriggerSamples', 5000000);

%%
% The |autoStop| parameter can be set to false (0) to allow for continuous
% data collection.
% set(streamingGroupObj, 'autoStop', PicoConstants.FALSE);

% Set other streaming parameters
downSampleRatio = 1;
downSampleRatioMode = ps5000aEnuminfo.enPS5000ARatioMode.PS5000A_RATIO_MODE_NONE;

%%
% Defined buffers to store data collected from the channels. If capturing
% data without using the autoStop flag, or if using a trigger with the
% autoStop flag, allocate sufficient space (1.5 times the sum of the number
% of pre-trigger and post-trigger samples is shown below) to allow for
% additional pre-trigger data. Pre-allocating the array is more efficient
% than using <matlab:doc('vertcat') |vertcat|> to combine data.

maxSamples = get(ps5000aDeviceObj, 'numPreTriggerSamples') + ...
    get(ps5000aDeviceObj, 'numPostTriggerSamples');

% Take into account the downsampling ratio mode - required if collecting
% data without a trigger and using the autoStop flag.

finalBufferLength = round(1.5 * maxSamples / downSampleRatio);

pBufferChAFinal = libpointer('int16Ptr', zeros(finalBufferLength, 1, 'int16'));
pBufferChBFinal = libpointer('int16Ptr', zeros(finalBufferLength, 1, 'int16'));

% Prompt User to indicate if they wish to plot live streaming data.
plotLiveData = questionDialog('Plot live streaming data?', 'Streaming Data Plot');

if (plotLiveData == PicoConstants.TRUE)
   
    disp('Live streaming data collection with second plot on completion.');
    
else
    
    disp('Streaming data plot on completion.');
    
end

originalPowerSource = invoke(ps5000aDeviceObj, 'ps5000aCurrentPowerSource');

% Start streaming data collection.
[status.runStreaming, sampleInterval, sampleIntervalTimeUnitsStr] = ...
    invoke(streamingGroupObj, 'ps5000aRunStreaming', downSampleRatio, ...
    downSampleRatioMode, overviewBufferSize);
    
disp('Streaming data...');
fprintf('Click the STOP button to stop capture or wait for auto stop if enabled.\n') 

% Variables to be used when collecting the data:

hasAutoStopOccurred = PicoConstants.FALSE;  % Indicates if the device has stopped automatically.
powerChange         = PicoConstants.FALSE;  % If the device power status has changed.
newSamples          = 0; % Number of new samples returned from the driver.
previousTotal       = 0; % The previous total number of samples.
totalSamples        = 0; % Total samples captured by the device.
startIndex          = 0; % Start index of data in the buffer returned.
hasTriggered        = 0; % To indicate if trigger has occurred.
triggeredAtIndex    = 0; % The index in the overall buffer where the trigger occurred.

time = zeros(overviewBufferSize / downSampleRatio, 1);	% Array to hold time values

status.getStreamingLatestValuesStatus = PicoStatus.PICO_OK; % OK

% Display a 'Stop' button.
[stopFig.h, stopFig.h] = stopButton();             
             
flag = 1; % Use flag variable to indicate if stop button has been clicked (0).
setappdata(gcf, 'run', flag);

% Plot Properties - these are for displaying data as it is collected.

if (plotLiveData == PicoConstants.TRUE)
    
    % Plot on a single figure. 
    figure1 = figure('Name','PicoScope 5000 Series (A API) Example - Streaming Mode Capture', ...
         'NumberTitle','off');
     
    axes1 = axes('Parent', figure1);

    % Estimate x-axis limit to try and avoid using too much CPU resources
    % when drawing - use max voltage range selected if plotting multiple
    % channels on the same graph.
    xlim(axes1, [0 (sampleInterval * finalBufferLength)]);

    yRange = max(channelARangeMv, channelBRangeMv);
    ylim(axes1,[(-1 * yRange) yRange]);

    hold(axes1,'on');
    grid(axes1, 'on');

    title(axes1, 'Live Streaming Data Capture');
    
    if (strcmp(sampleIntervalTimeUnitsStr, 'us'))
        
        xLabelStr = 'Time (\mus)';
        
    else
       
        xLabelStr = strcat('Time (', sampleIntervalTimeUnitsStr, ')');
        xlabel(axes1, xLabelStr);
        
    end
    
    xlabel(axes1, xLabelStr);
    ylabel(axes1, 'Voltage (mV)');
    
end

%%
% Collect samples as long as the |hasAutoStopOccurred| flag has not been
% set or the call to |getStreamingLatestValues()| does not return an error
% code (check for STOP button push inside loop).
while(hasAutoStopOccurred == PicoConstants.FALSE && status.getStreamingLatestValuesStatus == PicoStatus.PICO_OK)
    
    ready = PicoConstants.FALSE;
   
    while (ready == PicoConstants.FALSE)

       status.getStreamingLatestValuesStatus = invoke(streamingGroupObj, 'getStreamingLatestValues'); 
        
       ready = invoke(streamingGroupObj, 'isReady');

       % Give option to abort from here
       flag = getappdata(gcf, 'run');
       drawnow;

       if (flag == 0)

            disp('STOP button clicked - aborting data collection.')
            break;

       end

       drawnow;

    end
    
    % Check for data
    [newSamples, startIndex] = invoke(streamingGroupObj, 'availableData');

    if (newSamples > 0)
        
        % Check if the scope has triggered.
        [triggered, triggeredAt] = invoke(streamingGroupObj, 'isTriggerReady');

        if (triggered == PicoConstants.TRUE)

            % Adjust trigger position as MATLAB does not use zero-based
            % indexing.
            bufferTriggerPosition = triggeredAt + 1;
            
            fprintf('Triggered - index in buffer: %d\n', bufferTriggerPosition);

            hasTriggered = triggered;

            % Set the total number of samples at which the device
            % triggered.
            triggeredAtIndex = totalSamples + bufferTriggerPosition;

        end

        previousTotal   = totalSamples;
        totalSamples    = totalSamples + newSamples;

        % Printing to console can slow down acquisition - use for
        % demonstration.
        fprintf('Collected %d samples, startIndex: %d total: %d.\n', newSamples, startIndex, totalSamples);
        
        % Position indices of data in the buffer(s).
        firstValuePosn = startIndex + 1;
        lastValuePosn = startIndex + newSamples;
        
        % Convert data values to millivolts from the application buffer(s).
        bufferChAmV = adc2mv(pAppBufferChA.Value(firstValuePosn:lastValuePosn), channelARangeMv, maxADCCount);
        bufferChBmV = adc2mv(pAppBufferChB.Value(firstValuePosn:lastValuePosn), channelBRangeMv, maxADCCount);

        % Process collected data further if required - this example plots
        % the data if the User has selected 'Yes' at the prompt.
        
        % Copy data into the final buffer(s).
        pBufferChAFinal.Value(previousTotal + 1:totalSamples) = bufferChAmV;
        pBufferChBFinal.Value(previousTotal + 1:totalSamples) = bufferChBmV;
        
        if (plotLiveData == PicoConstants.TRUE)
            
            % Time axis. 
            % Multiply by ratio mode as samples get reduced
            time = (double(sampleInterval) * double(downSampleRatio)) * (previousTotal:(totalSamples - 1));

            plot(axes1, time, bufferChAmV, time, bufferChBmV);
        
        end
       
        % Clear variables for use again
        clear bufferChAmV;
        clear bufferChBmV;
        clear firstValuePosn;
        clear lastValuePosn;
        clear startIndex;
        clear triggered;
        clear triggerAt;
          
   end
   
    % Check if auto stop has occurred.
    hasAutoStopOccurred = invoke(streamingGroupObj, 'autoStopped');

    if (hasAutoStopOccurred == PicoConstants.TRUE)

       disp('AutoStop: TRUE - exiting data collection loop.');
       break;

    end
   
    % Check if 'STOP' button has been clicked.
    flag = getappdata(gcf, 'run');
    drawnow;

    if (flag == 0)

        disp('STOP button clicked - aborting data collection.')
        break;
        
    end
 
end

% Close the STOP button window.
if (exist('stopFig', 'var'))
    
    close('Stop Button');
    clear stopFig;
        
end

if (plotLiveData == PicoConstants.TRUE)
    
    drawnow;
    
    % Take hold off the current figure.
    hold(axes1, 'off');
    movegui(figure1, 'west');
    
end

if (hasTriggered == PicoConstants.TRUE)
   
    fprintf('Triggered at overall index: %d\n\n', triggeredAtIndex);
    
end

fprintf('\n');

%% Stop the device
% This function should be called regardless of whether the autoStop
% property is enabled or not.

[status.stop] = invoke(ps5000aDeviceObj, 'ps5000aStop');

%% Find the number of samples
% This is the number of samples held in the shared library itself. The
% actual number of samples collected when using a trigger is likely to be
% greater.

[status.noOfStreamingValues, numStreamingValues] = invoke(streamingGroupObj, 'ps5000aNoOfStreamingValues');

fprintf('Number of samples available after data collection: %u\n', numStreamingValues);

%% Process data
% Process data post-capture if required - here the data will be plotted.

% Reduce size of arrays if required.

if (totalSamples < finalBufferLength)
    
    pBufferChAFinal.Value(totalSamples + 1:end) = [];
    pBufferChBFinal.Value(totalSamples + 1:end) = [];

end

% Retrieve data for the channels.
channelAFinal = pBufferChAFinal.Value();
channelBFinal = pBufferChBFinal.Value();

% Plot total data collected on another figure.

finalFigure = figure('Name','PicoScope 5000 Series (A API) Example - Streaming Mode Capture', ...
    'NumberTitle','off');

finalFigureAxes = axes('Parent', finalFigure);
hold(finalFigureAxes, 'on');
grid(finalFigureAxes, 'on');

if (strcmp(sampleIntervalTimeUnitsStr, 'us'))
        
    xlabel(finalFigureAxes, 'Time (\mus)');

else

    xLabelStr = strcat('Time (', sampleIntervalTimeUnitsStr, ')');
    xlabel(finalFigureAxes, xLabelStr);

end

ylabel(finalFigureAxes, 'Voltage (mV)');
hold(finalFigureAxes, 'off');

time = (double(sampleInterval) * double(downSampleRatio)) * (0:length(channelAFinal) - 1);

% Channel A
chAAxes = subplot(2,1,1); 
plot(chAAxes, time, channelAFinal, 'b');
xLabelStr = strcat('Time (', sampleIntervalTimeUnitsStr, ')');
xlabel(chAAxes, xLabelStr);
ylabel(chAAxes, 'Voltage (mV)');
title(chAAxes, 'Data acquisition on channel A (Final)');
grid(chAAxes, 'on');

% Channel B
chBAxes = subplot(2,1,2); 
plot(chBAxes, time, channelBFinal, 'r');
title(chBAxes, 'Data acquisition on channel B (Final)');
xLabelStr = strcat('Time (', sampleIntervalTimeUnitsStr, ')');
xlabel(chBAxes, xLabelStr);
ylabel(chBAxes, 'Voltage (mV)');
grid(chBAxes, 'on');

movegui(finalFigure, 'east');

%% Disconnect device
% Disconnect device object from hardware.

disconnect(ps5000aDeviceObj);
delete(ps5000aDeviceObj);