% First section of this script organizes and processes EEG data to calculate
% the spectral power on linguistic and non-linguistic conditions across
% multiple participants and frequency bands.
%
% Second section performs a Shapiro-Wilk normality test for each channel's data
% and selects either a paired t-test or Wilcoxon signed-rank test based on
% the normality assumption. Then, it applies false discovery rate (FDR)
% correction for multiple comparisons to identify significant channels.
% Finally, it displays the significant channels for both tests.
%
% Author: Alejandro Perez, McMaster, 11/05/2024.
% v2.0: Interpolation commented

% Clear workspace and close all figures
eeglab; close all;

%% Epoching and calculating power spectrum across different frequency bands.
% Define parameters
srate = 250; % Sampling rate
ntrials = 9; % Number of trials Linguistic condition
ntrialsN = 9; % Number of trials NonLinguistic condition
bands = {'delta','theta','alpha','beta','gamma'};
condLing = {'Eng', 'Heb'};
condNonLing = {'Easy', 'Hard'};

% Define frequency bands
freqs = [0:125]; % frequencies estimated in the spectopo function
% Set the following frequency bands:
deltaIdx = find(freqs>1 & freqs<4);
thetaIdx = find(freqs>4 & freqs<8);
alphaIdx = find(freqs>8 & freqs<13);
betaIdx  = find(freqs>13 & freqs<30);
gammaIdx = find(freqs>30 & freqs<80);

% List of specific folders to include for the processing
% Leave empty if you want to process all except those in 'Ppt2exclude'
% Overwrites 'Ppt2exclude'
specificFolders = {}; % '021', '030', '040', '041', '034', '042', '050', '053', '060', '062', '070', '080', '089'

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
for subj = 74:length(A)

    % Change directory to the participant's folder
    cd([data_dir filesep A(subj).name ]);
    current_dir = pwd;
    % Load the preprocessed EEG dataset
    EEG_ori = pop_loadset('filename', [A(subj).name '_ICremov2.set']);

    % % Detect the markers indicating the start (S111) and end (S112) of the experiment
    % % There should be only two of each type
    % markers = {EEG_ori.event.type};
    % start_markers = find(strcmp(markers, 'S111'));
    % end_markers = find(strcmp(markers, 'S112'));
    % 
    % % Ensure that there are exactly two start and end markers
    % if numel(start_markers) ~= 2 || numel(end_markers) ~= 2
    %     error('There should be exactly two start (S111) and two end (S112) markers.');
    % end
    % 
    % % Preallocate arrays for latencies
    % start_latencies = [EEG_ori.event(start_markers).latency];
    % end_latencies = [EEG_ori.event(end_markers).latency];
    % 
    % % Selects the data corresponding to the two separated recordings based on the marker latencies
    % EEG_Ling = pop_select(EEG_ori, 'point', [start_latencies(1) end_latencies(1)]);
    % EEG_Ling = eeg_checkset(EEG_Ling, 'makeur');
    % EEG_NonLing = pop_select(EEG_ori, 'point', [start_latencies(2) end_latencies(2)]);
    % EEG_NonLing = eeg_checkset(EEG_NonLing, 'makeur');

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
    % Loop across trials to calculate spectral power
    % two separated loops in case they have different number of trials
    for i = 1 : EEG_Eng.trials
        [spectra_Eng(:,:,i),~] = spectopo(EEG_Eng.data(:,:,i), 0, srate, 'plot','off');
    end
    for i = 1 : EEG_Heb.trials
        [spectra_Heb(:,:,i),~] = spectopo(EEG_Heb.data(:,:,i), 0, srate, 'plot','off');
    end

    % Remove the first trial if there are 10 indicating the presence of the
    % practice trial
    if EEG_Eng.trials == 10
        spectra_Eng(:,:,1) = [];
    end
    % Calculate the average across trials
    spectra_Eng = mean(spectra_Eng, 3);

    if EEG_Heb.trials == 10
        spectra_Heb(:,:,1) = [];
    end
    spectra_Heb = mean(spectra_Heb, 3);

    % Compute absolute power Eng condition
    deltaPower_Eng = mean(10.^(spectra_Eng(:,deltaIdx)'/10));
    thetaPower_Eng = mean(10.^(spectra_Eng(:,thetaIdx)'/10));
    alphaPower_Eng = mean(10.^(spectra_Eng(:,alphaIdx)'/10));
    betaPower_Eng  = mean(10.^(spectra_Eng(:,betaIdx)'/10));
    gammaPower_Eng = mean(10.^(spectra_Eng(:,gammaIdx)'/10));

    % Compute absolute power Heb condition
    deltaPower_Heb = mean(10.^(spectra_Heb(:,deltaIdx)'/10));
    thetaPower_Heb = mean(10.^(spectra_Heb(:,thetaIdx)'/10));
    alphaPower_Heb = mean(10.^(spectra_Heb(:,alphaIdx)'/10));
    betaPower_Heb  = mean(10.^(spectra_Heb(:,betaIdx)'/10));
    gammaPower_Heb = mean(10.^(spectra_Heb(:,gammaIdx)'/10));

    % Loops to create the spectral power variables for each frequency band
    % (cond x channel x subject)
    for c = 1:length(condLing)
        for b = 1:length(bands)
            eval(['all_subj_Ling_' bands{b} '(c,:,subj) = ' bands{b} 'Power_' condLing{c} ';']);
        end
    end
    clear spectra_Heb spectra_Eng;

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
    % Loop across trials to calculate spectral power
    for i = 1 : ntrialsN
        [spectra_Easy(:,:,i),~] = spectopo(EEG_Easy.data(:,:,i), 0, srate, 'plot','off');
        [spectra_Hard(:,:,i),~] = spectopo(EEG_Hard.data(:,:,i), 0, srate, 'plot','off');
    end

    % Remove the first trial and calculate the average across trials
    spectra_Easy(:,:,1) = [];
    spectra_Easy = mean(spectra_Easy, 3);
    spectra_Hard(:,:,1) = [];
    spectra_Hard = mean(spectra_Hard, 3);

    % Compute absolute power Easy condition
    deltaPower_Easy = mean(10.^(spectra_Easy(:,deltaIdx)'/10));
    thetaPower_Easy = mean(10.^(spectra_Easy(:,thetaIdx)'/10));
    alphaPower_Easy = mean(10.^(spectra_Easy(:,alphaIdx)'/10));
    betaPower_Easy  = mean(10.^(spectra_Easy(:,betaIdx)'/10));
    gammaPower_Easy = mean(10.^(spectra_Easy(:,gammaIdx)'/10));
    % Compute absolute power Hard condition
    deltaPower_Hard = mean(10.^(spectra_Hard(:,deltaIdx)'/10));
    thetaPower_Hard = mean(10.^(spectra_Hard(:,thetaIdx)'/10));
    alphaPower_Hard = mean(10.^(spectra_Hard(:,alphaIdx)'/10));
    betaPower_Hard  = mean(10.^(spectra_Hard(:,betaIdx)'/10));
    gammaPower_Hard = mean(10.^(spectra_Hard(:,gammaIdx)'/10));

    % Loops to create the spectral power variables for each frequency band
    % (cond x channel x subject)
    for c = 1:length(condNonLing)
        for b = 1:length(bands)
            eval(['all_subj_NonLing_' bands{b} '(c,:,subj) = ' bands{b} 'Power_' condNonLing{c} ';']);
        end
    end

end

save([data_dir filesep 'all_subj_Ling_power.mat'],'all_subj_Ling_delta','all_subj_Ling_theta','all_subj_Ling_alpha','all_subj_Ling_beta','all_subj_Ling_gamma');
save([data_dir filesep 'all_subj_NonLing_power.mat'],'all_subj_NonLing_delta','all_subj_NonLing_theta','all_subj_NonLing_alpha','all_subj_NonLing_beta','all_subj_NonLing_gamma');

%% Statistics

% Choose the frequency band and condition you want to analyse
% 'all_subj_Ling_delta','all_subj_Ling_theta','all_subj_Ling_alpha','all_subj_Ling_beta','all_subj_Ling_gamma'
% 'all_subj_NonLing_delta','all_subj_NonLing_theta','all_subj_NonLing_alpha','all_subj_NonLing_beta','all_subj_NonLing_gamma'

EEG_data = all_subj_Ling_alpha; % change this variable

% Define significance level
alpha = 0.05;
% Number of channels
nchan = 31;

% Initialize matrices to store p-values and significant channels
p_values_ttest = zeros(nchan, 1);
significant_channels_ttest = [];
p_values_signrank = zeros(nchan, 1);
significant_channels_signrank = [];

% Loop through channels
for ch = 1:nchan
    % Extract data for the current channel
    data_condition1 = squeeze(EEG_data(1, ch, :));
    data_condition2 = squeeze(EEG_data(2, ch, :));

    % Shapiro-Wilk normality test
    [~, p_shapiro_condition1] = swtest(data_condition1);
    [~, p_shapiro_condition2] = swtest(data_condition2);

    % Perform t-test if data is normally distributed, otherwise perform Wilcoxon signed-rank test
    if p_shapiro_condition1 > alpha && p_shapiro_condition2 > alpha
        [h, p, ~, stats] = ttest(data_condition1, data_condition2);
        p_values_ttest(ch) = p;
    else
        [p, ~, stats] = signrank(data_condition1, data_condition2);
        p_values_signrank(ch) = p;
    end
end

% FDR correction for multiple comparisons
p_values_ttestFDR = mafdr(p_values_ttest, 'BHFDR', 1);
significant_channels_ttest = find( p_values_ttestFDR < alpha & p_values_ttestFDR > 0);
p_values_signrankFDR = mafdr(p_values_signrank, 'BHFDR', 1);
significant_channels_signrank = find(p_values_signrankFDR < alpha & p_values_signrankFDR > 0);

% Display significant channels for both tests
if ~isempty(significant_channels_ttest)
    disp("Significant channels (t-test):");
    disp(significant_channels_ttest);
else
    disp("There are no differences in the ttest")
end

if ~isempty(significant_channels_signrank)
    disp("Significant channels (Wilcoxon signed-rank test):");
    disp(significant_channels_signrank);
else
    disp("There are no differences signed-rank test")
end

% bonus code used to close all msgbox instances 
% that refused to close otherwise  
% hv_figure_all = findall(0, 'Type', 'Figure');
% delete( hv_figure_all( arrayfun(@(h) contains(h.Tag, 'Msgbox'), hv_figure_all) ) )