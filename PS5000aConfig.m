%% PS5000aConfig
% Configures paths according to platforms and loads information from
% prototype files for PicoScope 5000 Series (A API) Oscilloscopes. The folder 
% that this file is located in must be added to the MATLAB path.
%
% Platform Specific Information:-
%
% Microsoft Windows: Download the Software Development Kit installer from
% the <a href="matlab: web('https://www.picotech.com/downloads')">Pico Technology Download software and manuals for oscilloscopes and data loggers</a> page.
% 
% Linux: Follow the instructions to install the libps5000a and libpswrappers
% packages from the <a href="matlab:
% web('https://www.picotech.com/downloads/linux')">Pico Technology Linux Software & Drivers for Oscilloscopes and Data Loggers</a> page.
%
% Apple Mac OS X: Follow the instructions to install the PicoScope 6
% application from the <a href="matlab: web('https://www.picotech.com/downloads')">Pico Technology Download software and manuals for oscilloscopes and data loggers</a> page.
% Optionally, create a 'maci64' folder in the same directory as this file
% and copy the following files into it:
%
% * libps5000a.dylib and any other libps2000a library files
% * libps5000aWrap.dylib and any other libps5000aWrap library files
% * libpicoipp.dylib and any other libpicoipp library files
% * libiomp5.dylib
%
% Contact our Technical Support team via the <a href="matlab: web('https://www.picotech.com/tech-support/')">Technical Enquiries form</a> for further assistance.
%
% Run this script in the MATLAB environment prior to connecting to the 
% device.
%
% This file can be edited to suit application requirements.
%
% Copyright: © 2013-2018 Pico Technology Ltd. See LICENSE file for terms.	

%% Set path to shared libraries, prototype and thunk Files
% Set paths to shared library files, prototype and thunk files according to
% the operating system and architecture.

% Identify working directory
ps5000aConfigInfo.workingDir = pwd;

% Find file name
ps5000aConfigInfo.configFileName = mfilename('fullpath');

% Only require the path to the config file
[ps5000aConfigInfo.pathStr] = fileparts(ps5000aConfigInfo.configFileName);

% Identify architecture e.g. 'win64'
ps5000aConfigInfo.archStr = computer('arch');
ps5000aConfigInfo.archPath = fullfile(ps5000aConfigInfo.pathStr, ps5000aConfigInfo.archStr);

% Add path to Prototype and Thunk files if not already present
if (isempty(strfind(path, ps5000aConfigInfo.archPath)))
    
    try

        addpath(ps5000aConfigInfo.archPath);

    catch err

        error('PS5000aConfig:OperatingSystemNotSupported', 'Operating system not supported - please contact support@picotech.com');

    end
    
end

% Set the path to shared libraries according to operating system.

% Define possible paths for drivers - edit to specify location of drivers

ps5000aConfigInfo.macDriverPath = '/Applications/PicoScope6.app/Contents/Resources/lib';
ps5000aConfigInfo.linuxDriverPath = '/opt/picoscope/lib/';

ps5000aConfigInfo.winSDKInstallPath = 'C:\Program Files\Pico Technology\SDK';
ps5000aConfigInfo.winDriverPath = fullfile(ps5000aConfigInfo.winSDKInstallPath, 'lib');

%32-bit version of MATLAB on Windows 64-bit
ps5000aConfigInfo.woW64SDKInstallPath = 'C:\Program Files (x86)\Pico Technology\SDK'; 
ps5000aConfigInfo.woW64DriverPath = fullfile(ps5000aConfigInfo.woW64SDKInstallPath, 'lib');

if (ismac())
    
    % Libraries (including wrapper libraries) are stored in the PicoScope
    % 6 App folder. Add locations of library files to environment variable.
    
    setenv('DYLD_LIBRARY_PATH', ps5000aConfigInfo.macDriverPath);
    
    if(contains(getenv('DYLD_LIBRARY_PATH'), ps5000aConfigInfo.macDriverPath))
       
        addpath(ps5000aConfigInfo.macDriverPath);
        
    else
        
        warning('PS5000aConfig:LibraryPathNotFound','Locations of libraries not found in DYLD_LIBRARY_PATH');
        
    end
    
elseif (isunix())
	    
    % Add path to drivers if not already on the MATLAB path
    if (isempty(strfind(path, ps5000aConfigInfo.linuxDriverPath)))
        
        addpath(ps5000aConfigInfo.linuxDriverPath);
            
    end
		
elseif (ispc())
    
    % Microsoft Windows operating system
    
    % Set path to dll files if the Pico Technology PicoSDK installer has been
    % used or place dll files in the folder corresponding to the
    % architecture. Detect if 32-bit version of MATLAB on 64-bit Microsoft
    % Windows.
    
    ps5000aConfigInfo.winSDKInstallPath = '';
    
    if (strcmp(ps5000aConfigInfo.archStr, 'win32') && exist('C:\Program Files (x86)\', 'dir') == 7)
        
        % Add path to drivers if not already on the MATLAB path
        if (isempty(strfind(path, ps5000aConfigInfo.woW64DriverPath)))
            
            try 

                addpath(ps5000aConfigInfo.woW64DriverPath);

            catch err

                warning('PS5000aConfig:DirectoryNotFound', ['Folder C:\Program Files (x86)\Pico Technology\SDK\lib\ not found. '...
                    'Please ensure that the location of the library files are on the MATLAB path.']);

            end
            
        end
        
    else
        
        % 32-bit MATLAB on 32-bit Windows or 64-bit MATLAB on 64-bit
        % Windows operating systems
        
        % Add path to drivers if not already on the MATLAB path
        if (isempty(strfind(path, ps5000aConfigInfo.winDriverPath)))
            
            try 

                addpath(ps5000aConfigInfo.winDriverPath);

            catch err

                warning('PS5000aConfig:DirectoryNotFound', ['Folder C:\Program Files\Pico Technology\SDK\lib\ not found. '...
                    'Please ensure that the location of the library files are on the MATLAB path.']);

            end
            
        end
        
    end
    
else
    
    error('PS5000aConfig:OperatingSystemNotSupported', 'Operating system not supported - please contact support@picotech.com');
    
end

%% Set path for PicoScope Support Toolbox files if not installed
% Set MATLAB Path to include location of PicoScope Support Toolbox
% Functions and Classes if the Toolbox has not been installed. Installation
% of the toolbox is only supported in MATLAB 2014b and later versions.

% Check if PicoScope Support Toolbox is installed - using code based on
% <http://stackoverflow.com/questions/6926021/how-to-check-if-matlab-toolbox-installed-in-matlab How to check if matlab toolbox installed in matlab>

ps5000aConfigInfo.psTbxName = 'PicoScope Support Toolbox';
ps5000aConfigInfo.v = ver; % Find installed toolbox information

if (~any(strcmp(ps5000aConfigInfo.psTbxName, {ps5000aConfigInfo.v.Name})))
   
    warning('PS5000aConfig:PSTbxNotFound', 'PicoScope Support Toolbox not found, searching for folder.');
    
    % If the PicoScope Support Toolbox has not been installed, check to see
    % if the folder is on the MATLAB path, having been downloaded via zip
    % file.
    
    ps5000aConfigInfo.psTbxFound = strfind(path, ps5000aConfigInfo.psTbxName);
    
    if (isempty(ps5000aConfigInfo.psTbxFound))
        
        ps5000aConfigInfo.psTbxNotFoundWarningMsg = sprintf(['Please either:\n'...
            '(1) install the PicoScope Support Toolbox via the Add-Ons Explorer or\n'...
            '(2) download the zip file from MATLAB Central File Exchange and add the location of the extracted contents to the MATLAB path.']);
        
        warning('PS5000aConfig:PSTbxDirNotFound', ['PicoScope Support Toolbox not found. ', ps5000aConfigInfo.psTbxNotFoundWarningMsg]);
        
        ps5000aConfigInfo.f = warndlg(ps5000aConfigInfo.psTbxNotFoundWarningMsg, 'PicoScope Support Toolbox Not Found', 'modal');
        uiwait(ps5000aConfigInfo.f);
        
        web('https://uk.mathworks.com/matlabcentral/fileexchange/53681-picoscope-support-toolbox');
            
    end
    
end

% Change back to the folder where the script was called from.
cd(ps5000aConfigInfo.workingDir);

%% Load enumerations and structure information
% Enumerations and structures are used by certain Intrument Driver functions.

% Find prototype file names based on architecture

ps5000aConfigInfo.ps5000aMFile = str2func(strcat('ps5000aMFile_', ps5000aConfigInfo.archStr));
ps5000aConfigInfo.ps5000aWrapMFile = str2func(strcat('ps5000aWrapMFile_', ps5000aConfigInfo.archStr));

[ps5000aMethodinfo, ps5000aStructs, ps5000aEnuminfo, ps5000aThunkLibName] = ps5000aConfigInfo.ps5000aMFile(); 
