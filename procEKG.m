function procEKG()
% Processes electrocardiogram data.
% This function conducts processing of the HR signal using the EEG-beats plugin.
%
% INPUT: File 'HR_EYE_0xx.set' obtained from preprocHeartEyeEEG()
% OUTPUT: Four Excel files, each representing one experimental manipulation
% ('English', 'Hebrew', 'Easy', 'Hard'), containing multiple HR measures
% extracted using the EEG-Beats plugin for all participants.
%
% Utilizes EEGLAB 2023.1 and the following plugins:
% - "EEG-Beats" v1.1.1
%
% Author: Alejandro Perez, University of Surrey, 29/12/2023

% Calling the EEGLAB environment and initializing variables
clear; eeglab; close all;

% Define experimental conditions and subconditions
% conds = {'ling';'nonling'};
subconds = {'english';'hebrew';'easy';'hard'};

% Define features to be extracted from the HR signal (from pop_eegbeats)
RR = {'startMinutes';'totalRRs';'numRRs';'numRemovedOutOfRangeRRs'; ...
    'numRemovedBadNeighbors';'numRemovedAroundOutlierAmpPeaks';'meanHR'; ...
    'meanRR';'medianRR';'skewRR';'kurtosisRR';'iqrRR';'trendSlope'; ...
    'SDNN';'SDSD';'RMSSD';'NN50';'pNN50';'totalPower';'VLF';'LF';'LFnu'; ...
    'HF';'HFnu';'LFHFRatio'};

% Initialize variables for creating a table to store information about EKG
% for each condition across participants.
% List of variable types
varTypes = ["string", ...
    "double","double","double","double","double",...
    "double","double","double","double","double", ...
    "double","double","double","double","double", ...
    "double","double","double","double","double", ...
    "double","double","double","double","double"];
% List of variable names
varNames = ["Participant", ...
    "startMinutes","totalRRs","numRRs","numRemovedOutOfRangeRRs", ...
    "numRemovedBadNeighbors","numRemovedAroundOutlierAmpPeaks","meanHR", ...
    "meanRR","medianRR","skewRR","kurtosisRR","iqrRR","trendSlope", ...
    "SDNN","SDSD","RMSSD","NN50","pNN50","totalPower","VLF","LF", ...
    "LFnu","HF","HFnu","LFHFRatio"];

% Select the parent directory for participant data
data_dir = uigetdir([],"Select the parent directory for participant data");
cd(data_dir);
A = dir('0*'); % Get participant folders

% Size of the table
sz = [length(A) length(varNames)];

% Preallocating memory for table variables.
table_english = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
table_hebrew = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
table_easy = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
table_hard = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

% Loop across participants
for subj = 1:length(A)
    % Subjects [27, 41, 72] encountered errors; skip these cases
    if subj==27 || subj==41 || subj==72 || subj==6
        continue
    end
    name = A(subj).name; % Participant number (folder name)

    % Including the participant's code in the tables
    table_english.Participant(subj) = name;
    table_hebrew.Participant(subj) = name;
    table_easy.Participant(subj) = name;
    table_hard.Participant(subj) = name;

    % Load recording
    EKG = pop_loadset('filename',['HR_EYE_' name '.set'],'filepath',[data_dir filesep name]);
    % re-creating the original event table (EEG.urevent)
    EKG = eeg_checkset(EKG, 'makeur');

    % Detect HR channels
    allEventTypes = {EKG.chanlocs.type}';
    probeIdx      = find(contains(allEventTypes,'HR'));

    % Combine three signals for subj 1 to 15 into one meaningful HR signal
    if size(probeIdx,1) == 3
        % untested idea on how to create the signal CAN BE WRONG
        kk = (EKG.data(1,:) - EKG.data(3,:)) - (EKG.data(2,:) - EKG.data(3,:));
        EKG.data(1,:) = kk;
        % labelling the channel
        [EKG.chanlocs(1).labels] = 'ECG';
        % remaining channels assigned with a new type
        [EKG.chanlocs(2:3).type] = deal('extra');
        % removing the channels based on type
        EKG = pop_select( EKG, 'rmchantype',{'extra'});
    end
    clear probeIdx allEventTypes kk;

    % Detect event indices for S111 and S112
    allEventTypes = {EKG.event.type}';
    Idx_S111      = find(contains(allEventTypes,'S111'));
    Idx_S112      = find(contains(allEventTypes,'S112'));

    % Latencies for S111 and S112 indices
    [S111_lat1, S111_lat2] = deal(EKG.event(Idx_S111(1:2)).latency);
    [S112_lat1, S112_lat2] = deal(EKG.event(Idx_S112(1:2)).latency);

    % Splitting the two recordings for the Linguistic (Lin) and Non-linguistic (Nonlin) conditions
    % based on the latencies of markers S111 (sync begin) and S112 (sync end).
    EKG_ling = pop_select( EKG, 'point',[S111_lat1 S112_lat1] ); % We use times/latencies for selection, but the 'point' option is chosen.
    EKG_nonl = pop_select( EKG, 'point',[S111_lat2 S112_lat2] ); % Selecting the 'time' option results in an error.

    clear allEventTypes Idx_S111 Idx_S112 S111_lat1 S111_lat2 S112_lat1 S112_lat2;

    % Segmenting each recording into epochs based on specific markers of interest.
    % Excluding the initial two practice epochs, leaving a total of 18 remaining epochs.
    EKG_ling = pop_epoch( EKG_ling, { 'S  1' 'S  5' 'S  9' 'S  3' 'S  7' 'S 11' }, [0  28.5], 'newname', 'ling epochs', ...
        'epochinfo', 'yes');
    EKG_ling = pop_select( EKG_ling, 'trial',[3:EKG_ling.trials] );
    % Excluding the initial two practice epochs, leaving a total of XXXX remaining epochs.
    EKG_nonl = pop_epoch( EKG_nonl, { 'S  1' 'S  3' }, [0  28.5], 'newname', 'nonling epochs', ...
        'epochinfo', 'yes');
    EKG_nonl = pop_select( EKG_nonl, 'trial',[3:EKG_nonl.trials] );

    % Selecting epochs within each condition that correspond to a specific subcondition.
    EKG_english = pop_selectevent( EKG_ling, 'type',{'S  1','S  5','S  9'},'deleteevents','off','deleteepochs','on','invertepochs','off');
    EKG_hebrew = pop_selectevent( EKG_ling, 'type',{'S  3','S  7','S 11'},'deleteevents','off','deleteepochs','on','invertepochs','off');
    EKG_easy = pop_selectevent( EKG_nonl, 'type',{'S  1'},'deleteevents','off','deleteepochs','on','invertepochs','off');
    EKG_hard = pop_selectevent( EKG_nonl, 'type',{'S  3'},'deleteevents','off','deleteepochs','on','invertepochs','off');

    for sc = 1: length(subconds) % loop across subconditions

        temp_cond = eval(['EKG_' subconds{sc}]);

        for feat = 1 : length(RR) % loop acros features 1
            % Initializing feature variables to match the number of trials for each participant and condition.
            eval([ RR{feat} ' = nan(temp_cond.trials,1);']);
        end % loop across features 1
        clear feat;

        for tr=1:temp_cond.trials % loop across the trials

            temp_trial = pop_select( temp_cond, 'trial', tr );

            [~, rrInfo, ~] = pop_eegbeats(temp_trial, struct('fileDir',[data_dir name], ...
                'figureDir',[data_dir name], 'ekgChannelLabel','ECG', 'doRRMeasures',true, ...
                'filterHz',[3 20], 'rrsAroundOutlierAmpPeaks',1, 'srate',250, ...
                'rrOutlierNeighborhood',5, 'truncateThreshold',15, 'rrPercentToBeOutlier',20, ...
                'rrMaxMs',1500, 'rrBlockMinutes',5, 'rrMinMs',500, 'rrBlockStepMinutes',0.5, ...
                'threshold',1.5, 'detrendOrder',3, 'qrsDurationMs',200, 'removeOutOfRangeRRs',true, ...
                'flipIntervalSeconds',2, 'spectrumType','lomb', 'flipDirection',0, ...
                'arMaxModelOrder',25, 'consensusIntervals',31, 'resampleHz',4, ...
                'maxPeakAmpRatio',2, 'freqCutoff',0.4, 'minPeakAmpRatio',0.5, ...
                'VLFRange',[0.0033 0.04], 'maxWhisker',1.5, 'LFRange',[0.04 0.15], ...
                'verbose',false, 'HFRange',[0.15 0.4], 'doPlot',false, 'figureClip',3, ...
                'figureClose',true, 'figureVisibility','off', 'fileName', ['HR_EYE_' subconds{sc}]));

            for feat = 1 : length(RR) % loop acros features 2
                % Include trial's values for each feature.
                eval([RR{feat} '(' num2str(tr) ',1) = rrInfo.overallValues.' RR{feat} ';']);
            end % loop across features 2

            clear temp_trial rrInfo feat;

        end % loop trials

        for feat = 1 : length(RR) % loop acros features 3
            % Compute the mean of each feature across trials and include the
            % resulting values in the respective subcondition tables, which contain data for all participants.
            eval([RR{feat} ' = mean(' RR{feat} ');']);
            eval(['table_' subconds{sc} '.' RR{feat} '(' num2str(subj) ') = ' RR{feat} ';']);
        end % loop across features 3

        clear startMinutes totalRRs numRRs numRemovedOutOfRangeRRs numRemovedBadNeighbors numRemovedAroundOutlierAmpPeaks meanHR ...
    meanRR medianRR skewRR kurtosisRR iqrRR trendSlope SDNN SDSD RMSSD NN50 pNN50 totalPower VLF LF LFnuHF HFnu LFHFRatio temp_cond feat tr; 

    end % loop subconds

    clear EKG*;

end % loop subj

writetable(table_english,'table_HRenglish.xlsx');
writetable(table_hebrew,'table_HRhebrew.xlsx');
writetable(table_easy,'table_HReasy.xlsx');
writetable(table_hard,'table_HRhard.xlsx');
