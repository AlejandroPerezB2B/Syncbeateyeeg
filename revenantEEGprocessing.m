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
% - "Fileio" v20240111
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

% List of specific folders (participants) to include for the processing
% Leave empty if you want to process all except those in 'to_exclude'
specificFolders = {}; % '021', '030', '040', '041', '034', '042', '050', '053', '060', '062', '070', '080', '089'

% Select participant's parent directory
data_dir = uigetdir([],"Select the parent directory for participant data");
cd(data_dir);
A = dir('0*'); % Get participant folders
% Filter to get only directories
A = A([A.isdir]);
% Participants to be excluded: first 8 not in Canada before age 3; last 2 are monolinguals with >30% exposure to another language
to_exclude = {'010', '012', '015', '016', '019', '022', '058', '066', '075', '084'};
% Extract the names of the folders
folderNames = {A.name};
% Find the indices of the folders to exclude within A
isExcluded = ismember(folderNames, to_exclude);
% Exclude the specific folders
A = A(~isExcluded);

% Conditional in case you want to only process specific folders
if ~isempty(specificFolders)
    % Extract the names of the folders
    folderNames = {A.name};
    % Find the indices of the specific folders within A
    isSelected = ismember(folderNames, specificFolders);
    % Select the specific folders
    A = A(isSelected);
end

% Loop across participants
for subj = 1:length(A)

    % Retrieve participant's folder name
    name = A(subj).name;

    % Delete other eeg files created before to save disk space (comment if not of your interest)
    cd(fullfile(data_dir, name));
    delete ([name '.fdt'],[name '.set'],['EEG_' name '.fdt'],['EEG_' name '.set']);

    % Change directory to folder containig raw EEG
    eeg_path = fullfile(data_dir, name, 'EEG and ECG', filesep);
    cd(eeg_path);

    % List the .vhdr files corresponding to raw recordings (only two are expected)
    eegfiles = dir('*.eeg');

    % Extract the 'name' field from the structure array
    nameArray = {eegfiles.name};

    % Use the cellfun function to apply the contains function to each element of nameArray
    % Find the indices where the string is present
    containsString_ling = cellfun(@(x) contains(x, '_ling_'), nameArray);
    containsString_nonling = cellfun(@(x) contains(x, '_nonling_'), nameArray);

    % Import EEG data using "bva-io" plugin
    EEG_ling = pop_fileio([eeg_path eegfiles(containsString_ling).name], 'dataformat','brainvision_eeg');
    EEG_nonling = pop_fileio([eeg_path eegfiles(containsString_nonling).name], 'dataformat','brainvision_eeg');

    % Eliminate the first trial corresponding to each condition
    % First trial is a practice trial

    % Get the event types from the EEG_ling structure
    eventTypes = {EEG_ling.event.type};
    % Define the possible strings to search for
    mks_eng = {'S  1', 'S  5', 'S  9'};
    mks_heb = {'S  3', 'S  7', 'S 11'};
    % Find the first occurrence of any of the possible strings
    matches_eng = ismember(eventTypes, mks_eng);
    matches_heb = ismember(eventTypes, mks_heb);
    firstOccurrenceIndex_eng = find(matches_eng, 1);
    firstOccurrenceIndex_heb = find(matches_heb, 1);
    idx = [firstOccurrenceIndex_eng firstOccurrenceIndex_heb];
    EEG_ling.event(idx) = [];
    % Get the number of events
    numEvents = numel(EEG_ling.event);
    % Assign consecutive numbers to the urevent field
    [EEG_ling.event.urevent] = deal(1:numEvents);
    % Remake the EEG.urevent structure
    EEG_ling = eeg_checkset(EEG_ling, 'makeur');

    % Get the event types from the EEG_nonling structure
    eventTypes = {EEG_nonling.event.type};
    % Define the possible strings to search for
    mks_easy = {'S  1'};
    mks_hard = {'S  3'};
    % Find the first occurrence of any of the possible strings
    matches_easy = ismember(eventTypes, mks_easy);
    matches_hard = ismember(eventTypes, mks_hard);
    firstOccurrenceIndex_easy = find(matches_easy, 1);
    firstOccurrenceIndex_hard = find(matches_hard, 1);
    idx = [firstOccurrenceIndex_easy firstOccurrenceIndex_hard];
    EEG_nonling.event(idx) = [];
    % Get the number of events
    numEvents = numel(EEG_nonling.event);
    % Assign consecutive numbers to the urevent field
    [EEG_nonling.event.urevent] = deal(1:numEvents);
    % Remake the EEG.urevent structure
    EEG_nonling = eeg_checkset(EEG_nonling, 'makeur');

    % The following substitution ensures that markers have unique names
    % across different conditions in two blocks of recordings, avoiding
    % confusion and maintaining clarity in the data.
    % Define the old and new strings
    oldStrings = {'S  1', 'S  2', 'S  3', 'S  4'};
    newStrings = {'S 21', 'S 22', 'S 23', 'S 24'};
    % Get the event types from the EEG structure
    eventTypes = {EEG_nonling.event.type};
    % Find the indices of the old strings in the event types
    [isOldString, loc] = ismember(eventTypes, oldStrings);
    % Replace the old strings with the corresponding new strings
    eventTypes(isOldString) = newStrings(loc(isOldString));
    % Assign the modified event types back to EEG_nonling.event.type
    [EEG_nonling.event.type] = deal(eventTypes{:});

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
    EEG = eeg_checkset(EEG, 'makeur');

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

    % Resampling the EEG data to reduce storage and unnecessary high-frequency info
    EEG = pop_resample(EEG, 250);
    EEG = eeg_checkset(EEG);

    % Run ICA for artifact removal (picard algorithm is faster)
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
