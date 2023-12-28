function preprocHeartEyeEEG()
% Preprocesses Heart-Eye-EEG data obtained from mergeHeartEyeEEG() using EEGLAB.
% This function conducts preprocessing steps, including resampling, filtering,
% and cleaning of the EEG data. The function operates on individual participant
% datasets and saves processed EEG data (in EEG_0xx.set) and unprocessed
% HR_EYE data separatedly.
%
% INPUT: File in EEGLAB format obtained from mergeHeartEyeEEG()
% OUTPUT: Processed EEG data (EEG_0xx.set) and unprocessed HR_EYE data (HR_EYE_0xx.set)
%
% Utilizes EEGLAB 2023.1 and the following plugins:
% - "ICLabel" v1.4
% - "Viewprops" v1.5.4
% - "clean_rawdata" v2.91
% - "dipfit" v5.3
% - "firfilt" v2.7.1
% - "fitTwoDipoles" v1.00
%
% Author: Alejandro Perez, University of Surrey, 27/12/2023

% Calling the EEGLAB environment and initializing variables
clear; eeglab; close all;

% Setting up Dipole Fitting variables and paths
path_dipfit = what('dipfit');
path_dipfit = path_dipfit.path;
addpath(genpath(path_dipfit));
templateChannelFilePath = fullfile(path_dipfit,'standard_BEM','elec','standard_1005.elc');
hdmFilePath = fullfile(path_dipfit,'standard_BEM','standard_vol.mat');
MRIfile = fullfile(path_dipfit,'standard_BEM','standard_mri.mat');

% Select the parent directory for participant data
data_dir = uigetdir([],"Select the parent directory for participant data");
cd(data_dir);
A = dir('0*'); % Get participant folders

% Loop across participants
for subj = 1:length(A)
    % Subjects [27, 41, 72] encountered errors; skip these cases
    if subj==27 || subj==41 || subj==72
        continue
    end
    name = A(subj).name; % Participant number (folder name)

    EEG_ori = pop_loadset('filename',[name '.set'],'filepath',[data_dir filesep name]);

    % Dataset containing EEG channels only
    EEG = pop_select( EEG_ori,'channel',{'Fp1','Fz','F3','F7','FT9','FC5', ...
        'FC1','C3','T7','TP9','CP5','CP1','Pz','P3','P7','O1','Oz','O2','P4', ...
        'P8','CP6','CP2','Cz','C4','T8','FT10','FC6','FC2','F4','F8','Fp2'});
    % Dataset containing HR and EYE channels only
    HR_EYE = pop_select( EEG_ori,'nochannel',{'Fp1','Fz','F3','F7','FT9','FC5', ...
        'FC1','C3','T7','TP9','CP5','CP1','Pz','P3','P7','O1','Oz','O2','P4', ...
        'P8','CP6','CP2','Cz','C4','T8','FT10','FC6','FC2','F4','F8','Fp2'});
    pop_saveset( HR_EYE,'filename',['HR_EYE_' name '.set'],'filepath',fullfile(data_dir,name));
    clear HR_EYE EEG_ori;

    % % Bonus code.
    % % Selecting the signal around the first-stimuli-onset last-stimuli-offset with an additional buffer
    % lat1 = EEG.event(2).latency; % 'New Segment' marker is at event(1) in the BVA format
    % lat2 = EEG.event(end).latency;
    % time_buffer = 0.5; % seconds before the first and after the last marker
    % EEG = pop_select( EEG,'point',[(lat1 - time_buffer*EEG.srate) (lat2 + time_buffer*EEG.srate)]);
    % clear time_buffer lat1 lat2;

    % Applying average reference after adding an initial reference
    EEG.nbchan = EEG.nbchan+1;
    EEG.data(end+1,:) = zeros(1, EEG.pnts);
    EEG.chanlocs(1,EEG.nbchan).labels = 'initialReference';
    EEG.chanlocs(EEG.nbchan).type = 'EEG';
    EEG = pop_select( EEG,'nochannel',{'initialReference'});

    % Clean data using ASR
    [EEG_clean,~,~,removed_channels] = clean_artifacts(EEG);
    % save the labels of removed channels to keep track of unnused channels
    save(fullfile(data_dir,name,'removed_channels.mat'),'removed_channels');
    clear removed_channels;
    % Uncomment next line to visualize the effectiveness of the cleaning process.
    % vis_artifacts(EEG_clean,EEG);

    % Filtering EEG data is deemed unnecessary as it's performed implicitly
    % during the clean_artifacts process. Uncomment for filtering again.
    % EEG = pop_eegfiltnew(EEG, 'locutoff',1,'channels',{'Fp1','Fz','F3', ...
    %     'F7','FT9','FC5','FC1','C3','T7','TP9','CP5','CP1','Pz','P3', ...
    %     'P7','O1','Oz','O2','P4','P8','CP6','CP2','Cz','C4','T8', ...
    %     'FT10','FC6','FC2','F4','F8','Fp2'});

    % Run ICA for artifact removal
    EEG = pop_runica( EEG_clean, 'icatype', 'runica' );

    % Perform automatic coordinate transformation
    [~,coordinateTransformParameters] = coregister(EEG.chanlocs, templateChannelFilePath, 'warp', 'auto', 'manual', 'off');

    % Set Dipole Fitting parameters
    EEG = pop_dipfit_settings( EEG, 'hdmfile',hdmFilePath,'mrifile',MRIfile, ...
        'chanfile',templateChannelFilePath,'coordformat','MNI', ...
        'coord_transform',coordinateTransformParameters ,'chansel',1:EEG.nbchan );

    % Run Dipole Fitting
    EEG = pop_multifit(EEG, 1:EEG.nbchan,'threshold', 100, 'dipplot','off','plotopt',{'normlen' 'on'}); % 'dipplot','on',

    % Label the components
    EEG = iclabel(EEG, 'default');

    % Save processed EEG data
    pop_saveset(EEG,'filename',['EEG_' name '.set'],'filepath',fullfile(data_dir,name));

end

end