% Record number of markers for each recording as a sanity check

% Initialize EEGLAB and close all open figures
eeglab; close all;

% Prompt user to select the directory containing participant folders
data_dir = uigetdir;
cd(data_dir);

% Get all participant folders starting with '0'
A = dir('0*');

% Define table to save number of markers for each condition
varTypes = {'string','double','double','double','double','double','double','double','double'};
varNames = {'Participant','Ling_S111','Ling_S112','Ling_English','Ling_Hebrew', ...
    'Nonling_S111','Nonling_S112','Nonling_Easy','Nonling_Hard'};
sz = [length(A) length(varNames)];
T = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

% Loop across participants
for subj = 1:length(A)
    % Retrieve participant's folder name
    name = A(subj).name;

    % Change directory to folder containing raw EEG data
    eeg_path = fullfile(data_dir, name, 'EEG and ECG', filesep);
    cd(eeg_path);

    % List the .vhdr files corresponding to raw recordings (only two are expected)
    vhdrfiles = dir('*.vhdr');

    % Extract the 'name' field from the structure array
    nameArray = {vhdrfiles.name};

    % Find the indices where the string '_ling_' is present
    containsString_ling = cellfun(@(x) contains(x, '_ling_'), nameArray);
    % Find the indices where the string '_nonling_' is present
    containsString_nonling = cellfun(@(x) contains(x, '_nonling_'), nameArray);

    % Import EEG data using "bva-io" plugin for both linguistic and non-linguistic conditions
    EEG_ling = pop_loadbv(eeg_path, vhdrfiles(containsString_ling).name);
    EEG_nonling = pop_loadbv(eeg_path, vhdrfiles(containsString_nonling).name);

    % Detect the markers indicating the start (S111) and end (S112) of the experiment
    % and the different conditions within recordings

    % Linguistic condition
    markers = {EEG_ling.event.type};
    start_markers = find(strcmp(markers, 'S111'));
    end_markers = find(strcmp(markers, 'S112'));

    desired_markers = {'S  1', 'S  5', 'S  9'};
    LingEng_markers = find(ismember(markers, desired_markers));
    
    desired_markers = {'S  3', 'S  7', 'S 11'};
    LingHeb_markers = find(ismember(markers, desired_markers));
    
    T.Ling_S111(subj) = numel(start_markers);
    T.Ling_S112(subj) = numel(end_markers);
    T.Ling_English(subj) = numel(LingEng_markers);
    T.Ling_Hebrew(subj) = numel(LingHeb_markers);
    
    % Non-linguistic condition
    markers = {EEG_nonling.event.type};
    start_markers = find(strcmp(markers, 'S111'));
    end_markers = find(strcmp(markers, 'S112'));

    desired_markers = {'S  1'};
    NonLingEasy_markers = find(ismember(markers, desired_markers));
    
    desired_markers = {'S  3'};
    NonLingHard_markers = find(ismember(markers, desired_markers));
    
    T.Nonling_S111(subj) = numel(start_markers);
    T.Nonling_S112(subj) = numel(end_markers);
    T.Nonling_Easy(subj) = numel(NonLingEasy_markers);
    T.Nonling_Hard(subj) = numel(NonLingHard_markers);

    % Save participant name
    T.Participant(subj) = name;
end

% Write the table to an Excel file
writetable(T, [data_dir filesep 'number_of_events_each_recording_all_participants.xlsx']);
