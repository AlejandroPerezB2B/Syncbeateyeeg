function mergeHeartEyeEEG()
% Merges eye movement data with EEG data for each participant during an
% experimental task, synchronizing recordings from the EyeLink device
% (including eye movements and pupil size) with Brain Products EEG/ECG
% recordings. The function consolidates data from 'ling' and 'nonling'
% conditions into single files, saved in EEGLAB format for further processing.
%
% Other Data Preprocessing Steps:
% - Resampling the data for reducing file size
% - Trimming to focus on specific segments
% - Filtering (1 Hz high-pass) for further analysis
%
% Assumes a parent folder containing individual participant folders. Each
% participant folder starts with '0' and contains subfolders 'Eye movement'
% and 'EEG and ECG'.
% INPUT             'ling_new.asc' and 'nonling_new.asc' files generated
%                   by the 'replaceEyeLinkStrings.m' function. These files
%                   are in the 'Eye movement' folder.
%                   Two raw EEG and heart rate recordings (.eeg format)
%                   along with .vhdr and .vmrk files. following the naming
%                   conventions such as 'EEG_and_ECG_ling_0xx.edf_1.eeg'
%                   and 'EEG_and_ECG_nonling_0xx.edf_1.eeg', corresponding
%                   to experimental conditions. These files are contained
%                   in the 'EEG and ECG' folder.
%
% OUTPUT            One file on EEGLAB format containing synchronised
%                   eye-hr-eeg recording from the whole experimental
%                   session. Name of the file corresponds to the name of
%                   the folder.
%
% Utilizes EEGLAB 2023.1 and the plugins "EYE-EEG" v1.0, "bva-io" v1.72,
%
% Author: Alejandro Perez, University of Surrey, 26/12/2023

% Calling the eeglab GUI to create variables (GUI won't be used)
clear; eeglab; close all;

% Obtain the path to the EEGLAB version used
s = what('eeglab2023.1');
eeglabroot = s.path; clear s;

% Define path to the electrode file
elec_names = fullfile(eeglabroot,'plugins','dipfit','standard_BEM','elec','standard_1005.elc');

% Define conditions
conds = {'ling';'nonling'};

% Select participant's parent directory
data_dir = uigetdir([],"Select the parent directory for participant data");
cd(data_dir);
A = dir('0*'); % Get participant folders

% Loop across participants
for subj = 1:length(A) % error at subj=[27 41 72] 
    name = A(subj).name; % Participant number (folder name)

    % Loop across conditions
    for cond = 1:length(conds)
        eye_path = fullfile(data_dir, name, 'Eye movement', [name conds{cond} '_new.asc']);
        eeg_path = fullfile(data_dir, name, 'EEG and ECG', filesep);
        eeg_name = ['EEG_and_ECG_' conds{cond} '_' name '.edf_1.vhdr'];

        % Import EyeLink data and parse using "EYE-EEG" plugin
        ET = parseeyelink(eye_path,[eye_path(1:end-4) '.mat'],'TTL_sync');
        clear ET;

        % Import EEG data using "bva-io" plugin
        EEG = pop_loadbv(eeg_path, eeg_name);
        EEG = pop_chanedit(EEG,'lookup',elec_names);

        % Define channel types
        [EEG.chanlocs(1:31).type] = deal("EEG");
        % conditional due to the difference on EKG recorded channels
        if subj<=15
            [EEG.chanlocs(32:34).type] = deal('HR');
            exclu = 32:34;
        elseif subj>15
            exclu = 32;
            [EEG.chanlocs(32).type] = 'HR';
        end

        % Apply average reference after adding initial reference
        EEG.nbchan = EEG.nbchan+1;
        EEG.data(end+1,:) = zeros(1, EEG.pnts);
        EEG.chanlocs(1,EEG.nbchan).labels = 'initialReference';
        EEG.chanlocs(EEG.nbchan).type = 'EEG';
        EEG = pop_reref(EEG,[],'exclude',exclu);
        EEG = pop_select( EEG,'nochannel',{'initialReference'});

        % Import and synchronize eye tracking data
        EEG = pop_importeyetracker(EEG,[eye_path(1:end-4) '.mat'],[111 112],[1:8], ...
            {'TIME','L-GAZE-X','L-GAZE-Y','L-AREA','R-GAZE-X','R-GAZE-Y','R-AREA','INPUT'},1,1,0,1,4);

        % pause; % Visual inspection
        close all; % Close figure

        % Selecting the signal around the first-stimuli-onset last-stimuli-offset with an additional buffer
        lat1 = EEG.event(2).latency; % 'New Segment' marker is at event(1) in the BVA format
        lat2 = EEG.event(end).latency;
        time_buffer = 3; % seconds before the first and after the last marker
        EEG = pop_select( EEG,'point',[(lat1 - time_buffer*EEG.srate) (lat2 + time_buffer*EEG.srate)]);
        clear time_buffer lat1 lat2;

        % Resampling the EEG data to reduce storage and unnecessary high-frequency info
        EEG = pop_resample(EEG, 250);

        % Filtering EEG data (1Hz cutoff)
        EEG = pop_eegfiltnew(EEG, 'locutoff',1,'revfilt',1,'channels',{'Fp1','Fz', ...
            'F3','F7','FT9','FC5','FC1','C3','T7','TP9','CP5','CP1','Pz','P3','P7',...
            'O1','Oz','O2','P4','P8','CP6','CP2','Cz','C4','T8','FT10','FC6','FC2',...
            'F4','F8','Fp2'});

        if cond==1
            ALLEEG=EEG;
        end
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, cond-1,'setname',conds{cond},'gui','off');
        clear eeg_* eye_*;

    end

    % Merge datasets from ling and nonling recordings
    EEG = pop_mergeset(ALLEEG, [1 2], 0);
    % Save unified data in eeglab format
    EEG = pop_saveset(EEG, 'filename',[name '.set'],'filepath',[data_dir filesep name]);
    ALLEEG = []; EEG = []; CURRENTSET = [];
end
end