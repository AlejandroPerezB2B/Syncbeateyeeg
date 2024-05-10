% Script for visual inspection and selection of independent components
% accounting for artifacts (such as eye movements, line noise, muscle
% activity, etc.).
%
% Rejection is based on the automatic ICA labeling conducted in a 
% previous step.This script is designed mainly for educational purposes. 
%
% A new dataset will be saved after component removal. Although it may be
% redundant data, it serves as a precautionary step.
%
% Please note that to proceed through the loop, you will need to press any
% key as the loop pauses for visual inspections.
%
% Please only remove components that clearly contain artifacts and have a
% high probability of being artifacts (> 90%). Eye movement and muscle
% components with a probability > 90% will be automatically flagged. However,
% feel free to make your own decisions.
%
% Plugin needed: Viewprops 1.5.4
% Author: Alejandro Perez, Cambridge.

% Clear workspace and close all figures
clear; close all;
%
% Select the directory containing participant folders
data_dir = uigetdir;
cd(data_dir);
% Get all participant folders
A = dir('0*'); 

% Loop across participants
for subj = 1:length(A)
    % Change directory to the participant's folder
    cd([data_dir filesep A(subj).name ]);
    current_dir = pwd;
    % Load the EEG dataset
    EEG = pop_loadset('filename', ['EEG_' A(subj).name '.set']);
    % Inspecting the components
    pop_viewprops(EEG,0);
    pause; close;
    % The threshold below will select components if they are in the eye or
    % muscle categories with at least 90% confidence
    threshold = [NaN NaN;0.9 1;0.9 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN];
    EEG = pop_icflag(EEG, threshold);
    % Manually introduce components to be rejected
    EEG = pop_subcomp( EEG );
    % Post-process to update EEG.icaact.
    EEG.icaact = [];
    EEG = eeg_checkset(EEG, 'ica');
    % Save the updated dataset after component removal
    pop_saveset( EEG, 'filename',[A(subj).name(1:end-4) '_ICremov.set'],'filepath',current_dir);
end
