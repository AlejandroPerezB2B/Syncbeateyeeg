function revenantEEGprocessing()
% Merges raw EEG data for each participant from 'ling' and 'nonling'
% conditions into single files and further process the data including
% (but not limited) performing ICA and dipole fitting.
%
% Assumes a parent folder containing individual participant folders. Each
% participant folder starts with '0' and contains subfolder 'EEG and ECG'.
% INPUT             Two raw EEG recordings (.eeg format) along with .vhdr
%                   and .vmrk files. following the naming conventions
%                   such as 'EEG_and_ECG_ling_0xx.edf_1.eeg' and
%                   'EEG_and_ECG_nonling_0xx.edf_1.eeg', corresponding
%                   to experimental conditions. These files are contained
%                   in the 'EEG and ECG' folder.
%
% OUTPUT            One file on EEGLAB format containing EEG data from the
%                   twon conditions. Name of the file corresponds to the 
%                   'EEGrevenant' + name of the folder.
%
% Utilizes EEGLAB plugins
% - "bva-io" v1.73
% - "ICLabel" v1.6
% - "Viewprops" v1.5.4
% - "clean_rawdata" v2.91
% - "dipfit" v5.4
% - "firfilt" v2.8
% - "fitTwoDipoles" v1.00
% - "REST" v1.2
% - "REST_cmd" v1.0
%
% Author: Alejandro Perez, McMaster University, Hamilton, Canada
% v1.0 21/05/2024

% Calling the eeglab GUI to create variables (GUI won't be used)
eeglab; close all;

% Obtain the path to the EEGLAB version used
s = what('eeglab'); % WARNING! Change the name to your eeglab foldername.
eeglabroot = s.path; clear s;

% Define path to the electrode file
elec_names = [fileparts(which('standard-10-5-cap385.elp')) filesep 'standard-10-5-cap385.elp'];
% Coordinate transform parameters for the electrodes locations we will use.
coordinateTransformParameters = [ 0   0   0   0   0   0   1   1   1 ];

% Setting up Dipole Fitting variables and paths
path_dipfit = what('dipfit');
path_dipfit = path_dipfit.path;
addpath(genpath(path_dipfit));
% templateChannelFilePath = fullfile(path_dipfit,'standard_BEM','elec','standard_1005.elc');
hdmFilePath = fullfile(path_dipfit,'standard_BEM','standard_vol.mat');
MRIfile = fullfile(path_dipfit,'standard_BEM','standard_mri.mat');

% seconds before the first and after the last marker
time_buffer = 0.5;

% Define the participants to be EXCLUDED from the analyses.
% Use the participant folder name
Ppt2exclude = {'016', '057'};

% Select participant's parent directory
data_dir = uigetdir([],"Select the parent directory for participant data");
cd(data_dir);
A = dir('0*'); % Get participant folders

% Loop across participants
for subj = 1:length(A)

    % Retrieve participant's folder name
    name = A(subj).name; %

    % Check if the participant is going to be excluded
    isExcluded = any(strcmp(name, Ppt2exclude));

    % Skip participant if excluded
    if isExcluded
        continue
    end

    % Change directory to folder containig raw EEG
    eeg_path = fullfile(data_dir, name, 'EEG and ECG', filesep);
    cd(eeg_path);

    % List the .vhdr files corresponding to raw recordings (only two are expected)
    vhdrfiles = dir('*.vhdr');

    % Extract the 'name' field from the structure array
    nameArray = {vhdrfiles.name};

    % Use the cellfun function to apply the contains function to each element of nameArray
    % Find the indices where the string is present
    containsString_ling = cellfun(@(x) contains(x, '_ling_'), nameArray);
    containsString_nonling = cellfun(@(x) contains(x, '_nonling_'), nameArray);

    % Import EEG data using "bva-io" plugin
    EEG_ling = pop_loadbv(eeg_path, vhdrfiles(containsString_ling).name);
    EEG_nonling = pop_loadbv(eeg_path, vhdrfiles(containsString_nonling).name);

    % Add channel info
    EEG_ling = pop_chanedit(EEG_ling,'lookup',elec_names);
    EEG_nonling = pop_chanedit(EEG_nonling,'lookup',elec_names);

    % Define channel types
    [EEG_ling.chanlocs(1:31).type] = deal("EEG");
    [EEG_nonling.chanlocs(1:31).type] = deal("EEG");

    % Selecting the signal around the first-stimuli-onset last-stimuli-offset with an additional buffer
    lat1_ling = EEG_ling.event(2).latency; % 'New Segment' marker is at event(1) in the BVA format
    lat2_ling = EEG_ling.event(end).latency;
    EEG_ling = pop_select( EEG_ling,'point',[(lat1_ling - time_buffer*EEG_ling.srate) (lat2_ling + time_buffer*EEG_ling.srate)]);
    EEG_ling = eeg_checkset(EEG_ling, 'makeur');

    lat1_nonling = EEG_nonling.event(2).latency; % 'New Segment' marker is at event(1) in the BVA format
    lat2_nonling = EEG_ling.event(end).latency;
    EEG_nonling = pop_select( EEG_nonling,'point',[(lat1_nonling - time_buffer*EEG_nonling.srate) (lat2_nonling + time_buffer*EEG_nonling.srate)]);
    EEG_nonling = eeg_checkset(EEG_nonling, 'makeur');

    % Merge datasets from ling and nonling recordings
    EEG = pop_mergeset(EEG_ling, EEG_nonling);

    % Dataset containing EEG channels only
    EEG = pop_select( EEG,'channel',{'Fp1','Fz','F3','F7','FT9','FC5', ...
        'FC1','C3','T7','TP9','CP5','CP1','Pz','P3','P7','O1','Oz','O2','P4', ...
        'P8','CP6','CP2','Cz','C4','T8','FT10','FC6','FC2','F4','F8','Fp2'});

    % channel locations, for later interpolation
    chanlocs = EEG.chanlocs;

    % Reference to infinity
    EEG = ref_infinity(EEG);

    % Clean data using ASR
    [EEG_clean,~,~,removed_channels] = clean_artifacts(EEG);
    EEG_clean = eeg_checkset(EEG_clean, 'makeur');
    % save the labels of removed channels to keep track of unnused channels
    save(fullfile(data_dir,name,'removed_channels.mat'),'removed_channels');
    clear removed_channels;
    % Uncomment next line to visualize the effectiveness of the cleaning process.
    % vis_artifacts(EEG_clean,EEG);

    % High-pass filter to remove slow drifts (e.g., above 1 Hz)
    EEG = pop_eegfiltnew(EEG_clean, 'locutoff', 2);

    % % Resampling the EEG data to reduce storage and unnecessary
    % high-frequency info (this step is commented on purpose, not performed)
    % EEG = pop_resample(EEG, 250);

    % Run ICA for artifact removal
    EEG = pop_runica( EEG, 'icatype', 'runica' );

    % Set Dipole Fitting parameters
    EEG = pop_dipfit_settings( EEG, 'hdmfile',hdmFilePath,'mrifile',MRIfile, ...
        'chanfile',elec_names,'coordformat','MNI', ...
        'coord_transform',coordinateTransformParameters ,'chansel',1:EEG.nbchan );

    % Run Dipole Fitting
    EEG = pop_multifit(EEG, 1:EEG.nbchan,'threshold', 100, 'dipplot','off','plotopt',{'normlen' 'on'}); % 'dipplot','on',

    % Interpolate any removed channels
    EEG = pop_interp(EEG, chanlocs);
    
    % Label the components
    EEG = iclabel(EEG, 'default');

    % Save processed EEG data
    pop_saveset(EEG,'filename',['EEG_revenant' name '.set'],'filepath',fullfile(data_dir,name));

end % end subj loop

end
