% First section of this script organizes and processes EEG data to calculate
% the ERSP on linguistic and non-linguistic conditions across
% multiple participants and frequency bands.
%
% Second section performs a Shapiro-Wilk normality test for each channel's data
% and selects either a paired t-test or Wilcoxon signed-rank test based on
% the normality assumption. Then, it applies false discovery rate (FDR)
% correction for multiple comparisons to identify significant channels.
% Finally, it displays the significant channels for both tests.
%
% Author: Alejandro Perez, McMaster, 11/05/2024.
% v2.0 on 27/05/2024: Interpolation is commented out. The data is no longer 
% split into two recordings because the issue of using the same marker for 
% different conditions was corrected in a previous step. The practice trial
% removal has also been addressed earlier.

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

data = {Eng,Heb};

% Statistics
[t df pvals] = statcond(data); 
% [stats, df, pvals, surrog] = statcond( data, 'key','val'... );

% fdr correction

% creating figures


% Finding the 
nan_indices = find(isnan(Eng));

% Convert the linear indices to subscripts for the 4D matrix
[t, f, c, p] = ind2sub(size(Eng), nan_indices);



band = 'gamma'; % delta theta alpha beta % Change this variable
eval(['EEG_data = all_subj_Ling_' band ';']);

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

disp(['Results in ' band ' band:']);

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


Steps:
Load the Data: Load the dataset, which contains 57 rows (participants) and four columns (Condition, pupil size, BPM, and Alpha power).
Train the Model: Use SVM for binary classification with a linear kernel.
Evaluate the Model: Perform k-fold cross-validation (e.g., 10-fold) to evaluate the model's performance.
MATLAB Code:
matlab
Copy code
% Load the dataset (assuming it is a CSV file, adjust accordingly)
data = csvread('your_data_file.csv'); % Replace with your actual data file

% Extract predictors and target variable
X = data(:, 2:4);  % Predictor variables: pupil size, BPM, Alpha power
Y = data(:, 1);    % Target variable: Condition (1 = familiar, 0 = unfamiliar)

% Standardize the predictors (recommended for SVM)
X = zscore(X);

% Split data into training and test sets (optional, if you want a test set)
cv = cvpartition(Y, 'KFold', 10);  % 10-fold cross-validation

% Train the SVM classifier using linear kernel
SVMModel = fitcsvm(X, Y, 'KernelFunction', 'linear', 'Standardize', true, ...
                   'CVPartition', cv);

% Cross-validate the model
cvSVMModel = crossval(SVMModel, 'KFold', 10);

% Compute the cross-validation loss (classification error)
loss = kfoldLoss(cvSVMModel);
fprintf('Cross-validation loss (classification error): %.4f\n', loss);

% Predict the class labels for the test data (optional)
predictions = kfoldPredict(cvSVMModel);

% Calculate accuracy of the model
accuracy = 1 - loss;
fprintf('Model accuracy: %.2f%%\n', accuracy * 100);

% Confusion matrix (optional)
confMat = confusionmat(Y, predictions);
disp('Confusion Matrix:');
disp(confMat);
Explanation:
fitcsvm: Trains the SVM classifier using a linear kernel.
zscore(X): Standardizes the predictor variables to have zero mean and unit variance (important for SVM).
cvpartition: Creates a 10-fold cross-validation partition for the data.
crossval: Applies k-fold cross-validation to the trained model to evaluate its performance.
kfoldLoss: Calculates the cross-validation loss, which represents the classification error.
confusionmat: Generates a confusion matrix to evaluate the classification performance further.
This script performs 10-fold cross-validation, calculates the classification accuracy, and provides insights into the model's performance. You can adjust parameters like the kernel type or perform feature selection if needed.