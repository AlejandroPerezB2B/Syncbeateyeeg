%% Section 1
% This section of the code loads removed channels data from each participant,
% and counts the number of times each channel was removed across all participants.
% It then identifies channels removed in more than 25% of participants based on
% a predefined threshold.

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
to_exclude = {'010','012','015','016','019','022','058','066','075','084','021','041','030','040','042','080','089'};
% Extract the names of the folders
folderNames = {A.name};
% Find the indices of the folders to exclude within A
isExcluded = ismember(folderNames, to_exclude);
% Exclude the specific folders
A = A(~isExcluded);
electrodeLabelselectrodeLabels = {'Fp1','Fz','F3','F7','FT9','FC5','FC1', ...
    'C3','T7','TP9','CP5','CP1','Pz','P3','P7','O1','Oz','O2','P4','P8', ...
    'CP6','CP2','Cz','C4','T8','FT10','FC6','FC2','F4','F8','Fp2'}';
% Initialize count for each channel
channelCount = zeros(size(electrodeLabels));

for subj = 1:length(A)
    % Change directory to the participant's folder
    cd([data_dir filesep A(subj).name ]);
    % Load removed channels data
    load removed_channels.mat; % load variable of same name
    % Sum the removed channels for the current participant
    channelCount = channelCount + removed_channels;
end

% Define threshold for channel rejection
threshold_rej = floor(length(A)*0.25); % Reject channels removed in more than 25% of participants
% Find channels rejected in more than 25% of participants
idx_th = find(channelCount >= threshold_rej);
% electrodeLabels{idx_th} % Channels rejected in more than 25% of participants
% The channels 'Fp1' 'T7' 'T8' 'FT10' 'Fp2' were removed in 16 or more
% participants

conds = {'Hebrew', 'English'};
bands = {'delta','theta','alpha','beta','gamma'};
cd('D:\Toronto'); % Directory containing the excell files, Wenfu: change accordingly
alpha = 0.05;
load full_list_ch.mat; % Load the EEG electrode position file named 'to_interpolate'


for b=1:length(bands)

    TH = readtable([conds{1} '_' bands{b} '.xlsx']);
    TE = readtable([conds{2} '_' bands{b} '.xlsx']);
    nnorm = zeros(length(electrodeLabels),1);

    % Loop through channels
    for ch = 1:length(electrodeLabels)
        % Extract data for the current channel
        data_condition1 = squeeze(TH.(electrodeLabels{ch}));
        data_condition2 = squeeze(TE.(electrodeLabels{ch}));

        % Shapiro-Wilk normality test
        [~, p_shapiro_condition1] = swtest(data_condition1);
        [~, p_shapiro_condition2] = swtest(data_condition2);

        % count those cases where data is NOT normally distributed
        if p_shapiro_condition1 >= alpha || p_shapiro_condition2 >= alpha
            nnorm(ch) = 1;
        end
        % ttest
        [h, p, ~, stats] = ttest(data_condition1, data_condition2);
        p_values_ttest(ch) = p; % p value
        tstats_ttest(ch) = stats.tstat; % t value
        % Wilcoxon signed rank
        [p, ~, stats] = signrank(data_condition1, data_condition2);
        p_values_signrank(ch) = p; % p value
        zval_signrank(ch) = stats.zval; % normal (Z) statistic
    end

    % FDR correction for multiple comparisons
    p_values_ttestFDR = mafdr(p_values_ttest, 'BHFDR', 1);
    significant_channels_ttest = find( p_values_ttestFDR < alpha & p_values_ttestFDR > 0);
    p_values_signrankFDR = mafdr(p_values_signrank, 'BHFDR', 1);
    significant_channels_signrank = find(p_values_signrankFDR < alpha & p_values_signrankFDR > 0);

    % Create mask indicating significant and non-significant values
    mask = zeros(size(p_values_signrankFDR));
    mask(p_values_signrankFDR < alpha) = 1; % Set significant values to 1
    mask(idx_th) = 0; % Excluding frequently rejected channels
    idx = find(mask); % indexes of the channels showing significan differences

    % difference between conditions across participants
    data = data_condition1 - data_condition2;
    % standardise the differences across participants
    data = zscore(data,1,'all');
    figure('Name',[bands{b} ' band topoplot signrank test']);
    topoplot(data, to_interpolate, 'electrodes','labels', 'emarker2',{idx,'*','r',5,1},'maplimits',[-1.5 1.5], 'pmask', mask); %

    % figure('Name',[bands{b} ' band topoplot ttest']);
    % topoplot(p_values_ttestFDR, to_interpolate,'maplimits',[0 .1]);
    % figure('Name',[bands{b} ' band topoplot signrank test']);
    % topoplot(p_values_signrankFDR, to_interpolate,'maplimits',[0 .1]);

end

