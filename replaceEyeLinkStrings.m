function replaceEyeLinkStrings()
% REPLACEEYELINKSTRINGS - Replaces specific strings inside ASCII files obtained from an EyeLink device recording eye movements
% Assumes a parent folder containing individual folders for participant data. 
% Each participant's folder begins with '0' (zero) and holds the data 
% of interest in a subfolder named 'Eye movement'. 
% Specifically, the modifications will be performed in two designated 
% ASCII files named ling.asc and nonling.asc within each participant's 
% 'Eye movement' subfolder.
%
% Author: Alejandro Perez, University of Surrey, 22/12/2023

% Clear workspace and close all figures
clear; close all;

% Define patterns and replacements
patterns = {'TTL_SYNC_BEGIN'; 'BP_TTL_DISPLAY_ONSET'; 'TTL_PASSAGE_OFFSET'; ...
    'TTL_QUESTION_ONSET'; 'TTL_QUESTION_OFFSET'; 'TTL_RESP_KEYBOARD_YES'; ...
    'TTL_RESP_KEYBOARD_NO'; 'TTL_SYNC_END'};
replacement = {'TTL_sync'};

% Select participant's directory containing folders for each participant
data_dir = uigetdir;
cd(data_dir);
A = dir('0*'); % Get all participant folders

for subj = 1:length(A) % Loop across participants
    % Change directory to where eye movement data is stored
    cd([data_dir filesep A(subj).name filesep 'Eye movement']);

    % Import data for the two conditions on separate recordings
    Ling = readlines([A(subj).name 'ling.asc']);
    NonLing = readlines([A(subj).name 'nonling.asc']);

    for p = 1:size(patterns, 1) % Loop across patterns
        pat = patterns{p};
        
        % Replace patterns in Ling data
        for i = 1:length(Ling) % Loop across lines in Ling data
            % Replace matching patterns with the replacement string
            line = Ling(i);
            temp = strrep(line, pat, replacement);
            Ling(i) = temp;
        end % Loop across lines in Ling data

        % Replace patterns in NonLing data
        for i = 1:length(NonLing) % Loop across lines in NonLing data
            % Replace matching patterns with the replacement string
            line = NonLing(i);
            temp = strrep(line, pat, replacement);
            NonLing(i) = temp;
        end % Loop across lines in NonLing data
    end % Loop patterns

    % Write the fixed ASCII files with the suffix '_new'
    writelines(Ling, [A(subj).name 'ling_new.asc']);
    writelines(NonLing, [A(subj).name 'nonling_new.asc']);
end % Loop across participants
end % End of function
