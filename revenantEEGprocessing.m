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
% - "PICARD1.0"
%
% Author: Alejandro Perez, McMaster University, Hamilton, Canada
% v1.0 21/05/2024
% v2.0 24/05/2024: TemplateChannelFilePath and coordinateTransformParameters fixed
%                  issue with event markers fixed
%                  Automatic rejection of components flagged for removal
%

% Calling the eeglab GUI to create variables (GUI won't be used)
eeglab; close all;

% Obtain the path to the EEGLAB version used
eeglabroot = what('eeglab'); % WARNING! Change the name to your eeglab foldername.
eeglabroot = eeglabroot.path;

% Setting up Dipole Fitting variables and paths
path_dipfit = what('dipfit'); % WARNING! Change the name to your dipfit plugin foldername.
path_dipfit = path_dipfit.path;
addpath(genpath(path_dipfit));
templateChannelFilePath = fullfile(path_dipfit,'standard_BEM','elec','standard_1005.elc');
hdmFilePath = fullfile(path_dipfit,'standard_BEM','standard_vol.mat');
MRIfile = fullfile(path_dipfit,'standard_BEM','standard_mri.mat');

% Define the markers delimiting the portion of interest
start_marker = 'S111';
end_marker = 'S112';

% Define the participants to be EXCLUDED from the analyses.
% Use the participant folder name
Ppt2exclude = {'010', '012', '015', '016', '019', '022', '058', '066', '075', '084'};
% Reasons to exclude it:
% The first 8 ppts were not born in or immigrated to Canada before age 3;
% the last 2 ppts are monolinguals with over 30% exposure to another language

% Select participant's parent directory
data_dir = uigetdir([],"Select the parent directory for participant data");
cd(data_dir);
A = dir('0*'); % Get participant folders

% Loop across participants
for subj = 1:length(A)

    % Retrieve participant's folder name
    name = A(subj).name;

    % Delete other eeg files created before to save disk space (comment if not of your interest)
    cd(fullfile(data_dir, name));
    delete ([name '.fdt'],[name '.set'],['EEG_' name '.fdt'],['EEG_' name '.set']);

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
    EEG_ling = pop_chanedit(EEG_ling,'lookup',templateChannelFilePath);
    EEG_nonling = pop_chanedit(EEG_nonling,'lookup',templateChannelFilePath);

    % Define channel types
    [EEG_ling.chanlocs(1:31).type] = deal("EEG");
    [EEG_nonling.chanlocs(1:31).type] = deal("EEG");

    % % % Selecting the signal around the first-stimuli-onset last-stimuli-offset
    % Find the indices of the start and end markers
    start_index = find(strcmp({EEG_ling.event.type}, start_marker), 1, 'first');
    end_index = find(strcmp({EEG_ling.event.type}, end_marker), 1, 'first');
    % Ensure both markers are found
    if isempty(start_index) || isempty(end_index)
        error('Start or end marker not found in the dataset.');
    end
    % Get the latency of the start and end markers in data points
    start_latency = EEG_ling.event(start_index).latency;
    end_latency = EEG_ling.event(end_index).latency;
    % Selecting the signal around the first-stimuli-onset last-stimuli-offset
    EEG_ling = pop_select(EEG_ling, 'point', [start_latency end_latency]);
    EEG_ling = eeg_checkset(EEG_ling, 'makeur');

    % % % Selecting the signal around the first-stimuli-onset last-stimuli-offset
    % Find the indices of the start and end markers
    start_index = find(strcmp({EEG_nonling.event.type}, start_marker), 1, 'first');
    end_index = find(strcmp({EEG_nonling.event.type}, end_marker), 1, 'first');
    % Ensure both markers are found
    if isempty(start_index) || isempty(end_index)
        error('Start or end marker not found in the dataset.');
    end
    % Get the latency of the start and end markers in data points
    start_latency = EEG_nonling.event(start_index).latency;
    end_latency = EEG_nonling.event(end_index).latency;
    % Selecting the signal around the first-stimuli-onset last-stimuli-offset
    EEG_nonling = pop_select(EEG_nonling, 'point', [start_latency end_latency]);
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
    % high-frequency info
    EEG = pop_resample(EEG, 250);
    EEG = eeg_checkset(EEG);

    % Run ICA for artifact removal
    % EEG = pop_runica( EEG, 'icatype', 'runica' );
    EEG = pop_runica(EEG, 'icatype', 'picard', 'maxiter',500,'mode','standard','chanind',{'EEG'});

     % Perform automatic coordinate transformation
    [~,coordinateTransformParameters] = coregister(EEG.chanlocs, templateChannelFilePath, 'warp', 'auto', 'manual', 'off');

    % Set Dipole Fitting parameters
    EEG = pop_dipfit_settings( EEG, 'hdmfile',hdmFilePath,'mrifile',MRIfile, ...
        'chanfile',templateChannelFilePath,'coordformat','MNI', ...
        'coord_transform',coordinateTransformParameters ,'chansel',1:EEG.nbchan );

    % Run Dipole Fitting
    EEG = pop_multifit(EEG, 1:EEG.nbchan,'threshold', 100, 'dipplot','off','plotopt',{'normlen' 'on'}); % 'dipplot','on',

    % Interpolate any removed channels
    EEG = pop_interp(EEG, chanlocs);

    % Label the components
    EEG = iclabel(EEG, 'default');

    % Save processed EEG data
    pop_saveset(EEG,'filename',['EEG_revenant' name '.set'],'filepath',fullfile(data_dir,name));

    % Flag anything detected as an artifact with 80-100% probability
    EEG = pop_icflag(EEG, [NaN NaN;0.8 1;0.8 1;0.8 1;0.8 1;0.8 1;NaN NaN]);
    
    % remove components previously marked for rejection 
    EEG = pop_subcomp( EEG, [], 0);

    pop_saveset( EEG, 'filename',[name '_ICremov2.set'],'filepath',fullfile(data_dir,name));

end % end subj loop

end
