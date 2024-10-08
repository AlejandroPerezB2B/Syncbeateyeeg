% First section of this script organizes and processes EEG data to calculate
% the ERSP on linguistic and non-linguistic conditions across
% multiple participants and frequencies.
%
% Second section performs a paired t-test and applies false discovery rate (FDR)
% correction for multiple comparisons to identify significant channels.
% Finally, it displays the significant channels for both tests.
%
% Author: Alejandro Perez, McMaster, 15/09/2024.

% Add eeglab to path and close all figures
eeglab; close all;

%% Epoching and calculating power spectrum across different frequency bands.
% Define parameters
srate = 250; % Sampling rate
ntrials = 9; % Number of trials Linguistic condition
ntrialsN = 9; % Number of trials NonLinguistic condition

ch_labels = {'Fp1','Fz','F3','F7','FT9','FC5','FC1','C3','T7','TP9', ...
    'CP5','CP1','Pz','P3','P7','O1','Oz','O2','P4','P8','CP6','CP2', ...
    'Cz','C4','T8','FT10','FC6','FC2','F4','F8','Fp2'};

condLing = {'Eng', 'Heb'};
condNonLing = {'Easy', 'Hard'};

% List of specific folders to include for the processing
% Leave empty if you want to process all except those in 'to_exclude'
specificFolders = {}; % , '034', '050', '053', '060', '062', '070', '089'

% Select the directory containing participant folders
data_dir = uigetdir;
cd(data_dir);
% % load the channel list to be used on interpolation step
% load 'full_list_ch.mat'; % loaded var name is 'to_interpolate'
% Get all participant folders
A = dir('0*');
% Filter to get only directories
A = A([A.isdir]);

% Participants to be excluded
to_exclude = {'010', '012', '015', '016', '019', '022', '058', '066', '075', '084', '021', '041', '030', '040', '042', '080', '089'};
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

    ERSP_Eng_allsubj =  cell(1,length(A));
    ERSP_Heb_allsubj =  cell(1,length(A));
    ERSP_Easy_allsubj =  cell(1,length(A));
    ERSP_Hard_allsubj =  cell(1,length(A));

% Loop across participants
for subj = 1:length(A)

    % Change directory to the participant's folder
    cd([data_dir filesep A(subj).name ]);
    current_dir = pwd;
    % Load the preprocessed EEG dataset
    EEG_ori = pop_loadset('filename', [A(subj).name '_ICremov2.set']);

    %%%%%%%%%%% Linguistic condition %%%%%%%%%%%%%
    %%%% Epochs English condition %%%%
    EEG_Eng = pop_epoch( EEG_ori, {  'S  1'  'S  5'  'S  9'  }, [0  28], 'newname', 'epoched_data', 'epochinfo', 'yes'); % although we epoched using 28 sec there is a variable lenght in the epochs
    % Warning if there are no 10 trials as expected
    if EEG_Eng.trials ~= ntrials
        warndlg(['Participant ' A(subj).name ' has ' num2str(EEG_Eng.trials) ' trials in the English condition']);
    end
    %%%% Epochs Hebrew condition %%%%
    EEG_Heb = pop_epoch( EEG_ori, {  'S  3'  'S  7'  'S 11'  }, [0  28], 'newname', 'epoched_data', 'epochinfo', 'yes');
    % Warning if there are no 10 trials as expected
    if EEG_Heb.trials ~= ntrials
        warndlg(['Participant ' A(subj).name ' has ' num2str(EEG_Heb.trials) ' trials in the Hebrew condition']);
    end
    
    % ERSP_Eng is pre-allocated before the parfor loop
    ERSP_Eng = cell(1, length(ch_labels));
    % Loop across channels to calculate ERSP
    % two separated loops in case they have different number of trials
    parfor i = 1 : length(ch_labels)
        [ersp, ~, ~, times, frequencies] = pop_newtimef( EEG_Eng, 1, i, ...
            [0  27996], [3 0.8] , 'topovec', 1, 'elocs', EEG_Eng.chanlocs, ...
            'chaninfo', EEG_Eng.chaninfo, 'baseline',[0], 'freqs', [0 80], ...
            'plotitc','off','plotphase','off','plotersp','off', ...
            'nfreqs', 80, 'padratio', 1);
        ERSP_Eng{i} = ersp;
    end

    % ERSP_Heb is pre-allocated before the parfor loop
    ERSP_Heb = cell(1, length(ch_labels));
    % Loop across channels to calculate ERSP
    % two separated loops in case they have different number of trials
    parfor i = 1 : length(ch_labels)
        [ersp, ~, ~, times, frequencies] = pop_newtimef( EEG_Heb, 1, i, ...
            [0  27996], [3 0.8] , 'topovec', 1, 'elocs', EEG_Heb.chanlocs, ...
            'chaninfo', EEG_Heb.chaninfo, 'baseline',[0], 'freqs', [0 80], ...
            'plotitc','off','plotphase','off','plotersp','off', ...
            'nfreqs', 80, 'padratio', 1);
        ERSP_Heb{i} = ersp;
    end
    
    %%%%%%%%%%% NonLinguistic condition %%%%%%%%%%%%%
    %%%% Epochs Easy condition %%%%
    EEG_Easy = pop_epoch( EEG_ori, {  'S 21' }, [0  28], 'newname', 'epoched_data', 'epochinfo', 'yes'); % although we epoched using 28 sec there is a variable lenght in the epochs
    % Warning if there are no 10 trials as expected
    if EEG_Easy.trials ~= ntrialsN
        warndlg(['Participant ' A(subj).name ' has ' num2str(EEG_Easy.trials) ' trials in the Easy condition']);
        continue
    end
    %%%% Epochs Hard condition %%%%
    EEG_Hard = pop_epoch( EEG_ori, {  'S 23'  }, [0  28], 'newname', 'epoched_data', 'epochinfo', 'yes');
    % Warning if there are no 10 trials as expected
    if EEG_Hard.trials ~= ntrialsN
        warndlg(['Participant ' A(subj).name ' has ' num2str(EEG_Hard.trials) ' trials in the Hard condition']);
        continue
    end
    
    % ERSP_Easy is pre-allocated before the parfor loop
    ERSP_Easy = cell(1, length(ch_labels));
    % Loop across channels to calculate ERSP
    % two separated loops in case they have different number of trials
    parfor i = 1 : length(ch_labels)
        [ersp, ~, ~, times, frequencies] = pop_newtimef( EEG_Easy, 1, i, ...
            [0  27996], [3 0.8] , 'topovec', 1, 'elocs', EEG_Easy.chanlocs, ...
            'chaninfo', EEG_Easy.chaninfo, 'baseline',[0], 'freqs', [0 80], ...
            'plotitc','off','plotphase','off','plotersp','off', ...
            'nfreqs', 80, 'padratio', 1);
        ERSP_Easy{i} = ersp;
    end

    % ERSP_Hard is pre-allocated before the parfor loop
    ERSP_Hard = cell(1, length(ch_labels));
    % Loop across channels to calculate ERSP
    % two separated loops in case they have different number of trials
    parfor i = 1 : length(ch_labels)
        [ersp, ~, ~, times, frequencies] = pop_newtimef( EEG_Hard, 1, i, ...
            [0  27996], [3 0.8] , 'topovec', 1, 'elocs', EEG_Hard.chanlocs, ...
            'chaninfo', EEG_Hard.chaninfo, 'baseline',[0], 'freqs', [0 80], ...
            'plotitc','off','plotphase','off','plotersp','off', ...
            'nfreqs', 80, 'padratio', 1);
        ERSP_Hard{i} = ersp;
    end

    % Data with all subjects
    ERSP_Eng_allsubj{subj} =  ERSP_Eng;
    ERSP_Heb_allsubj{subj} =  ERSP_Heb;
    ERSP_Easy_allsubj{subj} =  ERSP_Easy;
    ERSP_Hard_allsubj{subj} =  ERSP_Hard;

end %% loop participant

save([data_dir filesep 'all_subj_Ling_ERSP.mat'],'ERSP_Eng_allsubj','ERSP_Heb_allsubj','times','frequencies');
save([data_dir filesep 'all_subj_NonLing_ERSP.mat'],'ERSP_Easy_allsubj','ERSP_Hard_allsubj','times','frequencies');

%% Statistics

% add path to the resampling statitstics toolkit
addpath(genpath('C:\Users\25645\Downloads\resampling_statistical_toolkit\')); % Replace with your own path

% Select the directory containing participant the result files
data_dir = uigetdir;
cd(data_dir);

load('all_subj_Ling_ERSP.mat');

% Initialize a 4D matrix 'Ling' to hold the time/frequency data
% Dimensions are (200, 80, 31, 66), where:
% - 200 is the number of time points
% - 80 is the number of frequency points
% - 31 is the number of channels
% - 66 is the number of subjects
Eng = nan(200, 80, 31, 66); 

% Loop through each subject's data stored in 'ERSP_Eng_allsubj'
for subj = 1:length(ERSP_Eng_allsubj)
    
    % 'pcp' contains the time/frequency data for each channel of the current subject
    pcp = ERSP_Eng_allsubj{1,subj};  
    
    % Loop through each channel's time/frequency data for the current subject
    for ch = 1:length(pcp)
        
        % 'chan' contains the time/frequency matrix for the current channel
        chan = pcp{1,ch}; 
        
        % Store the time/frequency matrix in the 'Ling' array
        % 'Eng(:,:,ch,subj)' corresponds to (time, frequency, channel, subject)
        Eng(:,:,ch,subj) = chan';  
        
    end
end

Heb = nan(200, 80, 31, 66); 
% Loop through each subject's data stored in 'ERSP_Eng_allsubj'
for subj = 1:length(ERSP_Heb_allsubj)
    
    % 'pcp' contains the time/frequency data for each channel of the current subject
    pcp = ERSP_Heb_allsubj{1,subj};  
    
    % Loop through each channel's time/frequency data for the current subject
    for ch = 1:length(pcp)
        
        % 'chan' contains the time/frequency matrix for the current channel
        chan = pcp{1,ch}; 
        
        % Store the time/frequency matrix in the 'Ling' array
        % 'Heb(:,:,ch,subj)' corresponds to (time, frequency, channel, subject)
        Heb(:,:,ch,subj) = chan';  
        
    end
end



% There are problems with the data. Specifically, the values for
% participants on the places 20, 33, 36, 44.
% The following code was used to determine the places of these participants
% in the Eng matrix

% % Finding the problems in the data
% nan_indices = find(isnan(Eng));
% 
% % Convert the linear indices to subscripts for the 4D matrix
% [t, f, c, p] = ind2sub(size(Eng), nan_indices);
% 
% unique(p)

% We are simply going to remove these participants since figuring out why
% they are empty is going to be too laborious

Eng(:,:,:,[20 33 36 44]) = [];
Heb(:,:,:,[20 33 36 44]) = [];

% Collapsing cross channels
% data = {Eng,Heb};
data = {squeeze(mean(Eng,3)),squeeze(mean(Heb,3))};
% Statistics
[t df pvals] = statcond(data, 'mode', 'perm', 'naccu', 2000); 

% Flatten the 3D matrix into a 1D array
p_values_flattened = pvals(:);

% Perform FDR correction
[fdr_corrected_p_values] = mafdr(p_values_flattened, 'BHFDR', true);

% Reshape the corrected p-values back into 3D format
fdr_corrected_p_values_Xd = reshape(fdr_corrected_p_values, size(pvals));

fdr_pvals = find(fdr_corrected_p_values_Xd<0.05)



% Create the image plot
figure;
imagesc(times/1000, frequencies, mean(squeeze(mean(Eng,3)),3)');
% Reverse the y-axis
set(gca, 'YDir', 'normal'); 
% Set axis labels
xlabel('Time (sec)');    % Label x-axis as time (in milliseconds)
ylabel('Frequency (Hz)'); % Label y-axis as frequency (in Hz)
% Set colorbar for intensity reference
colorbar;
title('Time-Frequency Representation of the English Condition');
clim([-1 0.1]);
% Add colorbar with a custom label
c = colorbar;
c.Label.String = 'ERSP (dB)';
c.Label.FontSize = 12;  % Adjust the font size if needed

% Create the image plot
figure;
imagesc(times/1000, frequencies, mean(squeeze(mean(Heb,3)),3)');
% Reverse the y-axis
set(gca, 'YDir', 'normal'); 
% Set axis labels
xlabel('Time (sec)');    % Label x-axis as time (in milliseconds)
ylabel('Frequency (Hz)'); % Label y-axis as frequency (in Hz)
% Set colorbar for intensity reference
colorbar;
title('Time-Frequency Representation of the Hebrew Condition');
clim([-1 0.1]);
% Add colorbar with a custom label
c = colorbar;
c.Label.String = 'ERSP (dB)';
c.Label.FontSize = 12;  % Adjust the font size if needed

% Create the image plot
figure;
imagesc(times/1000, frequencies, mean(squeeze(mean(Eng,3)),3)' - mean(squeeze(mean(Heb,3)),3)');
% Reverse the y-axis
set(gca, 'YDir', 'normal'); 
% Set axis labels
xlabel('Time (sec)');    % Label x-axis as time (in milliseconds)
ylabel('Frequency (Hz)'); % Label y-axis as frequency (in Hz)
% Set colorbar for intensity reference
colorbar;
title('Time-Frequency Representation English minus Hebrew Condition');
clim([-.06 .06]);
% Add colorbar with a custom label
c = colorbar;
c.Label.String = 'Difference';
c.Label.FontSize = 12;  % Adjust the font size if needed


