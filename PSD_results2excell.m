% Define the electrode labels
electrodeLabels = {'Fp1', 'Fz', 'F3', 'F7', 'FT9', 'FC5', 'FC1', 'C3', 'T7', ...
                   'TP9', 'CP5', 'CP1', 'Pz', 'P3', 'P7', 'O1', 'Oz', 'O2', ...
                   'P4', 'P8', 'CP6', 'CP2', 'Cz', 'C4', 'T8', 'FT10', 'FC6', ...
                   'FC2', 'F4', 'F8', 'Fp2'};
% Define the participants' names
participantNames = {'001', '002', '003', '004', '005', '006', '007', '011', '013', ...
                    '018', '020', '023', '024', '025', '026', '029', '031', '032', ...
                    '033', '034', '035', '036', '037', '038', '039', '043', '044', ...
                    '045', '046', '047', '048', '049', '050', '051', '052', '053', ...
                    '054', '055', '056', '057', '059', '060', '061', '062', '063', ...
                    '064', '065', '067', '068', '069', '070', '071', '072', '073', ...
                    '074', '076', '077', '078', '079', '081', '082', '083', '085', ...
                    '086', '087', '088'};

bands = {'delta','theta','alpha','beta','gamma'};

for b=1:length(bands)

% Extract data for each condition
dataConditionA = eval(['squeeze(all_subj_Ling_' bands{b} '(1, :, :))''' ';']); % Condition A
dataConditionB = eval(['squeeze(all_subj_Ling_' bands{b} '(2, :, :))''' ';']); % Condition B

% Convert data to tables and add electrode labels as variable names
tableConditionA = array2table(dataConditionA, 'VariableNames', electrodeLabels);
tableConditionB = array2table(dataConditionB, 'VariableNames', electrodeLabels);

% Add participants' names as the first column
tableConditionA = addvars(tableConditionA, participantNames', 'Before', 1, 'NewVariableNames', 'Participant');
tableConditionB = addvars(tableConditionB, participantNames', 'Before', 1, 'NewVariableNames', 'Participant');

% Save the tables to Excel files
writetable(tableConditionA, ['English_' bands{b} '.xlsx']);
writetable(tableConditionB, ['Hebrew_' bands{b} '.xlsx']);

end

for b=1:length(bands)

% Extract data for each condition
dataConditionA = eval(['squeeze(all_subj_NonLing_' bands{b} '(1, :, :))''' ';']); % Condition A
dataConditionB = eval(['squeeze(all_subj_NonLing_' bands{b} '(2, :, :))''' ';']); % Condition B

% Convert data to tables and add electrode labels as variable names
tableConditionA = array2table(dataConditionA, 'VariableNames', electrodeLabels);
tableConditionB = array2table(dataConditionB, 'VariableNames', electrodeLabels);

% Add participants' names as the first column
tableConditionA = addvars(tableConditionA, participantNames', 'Before', 1, 'NewVariableNames', 'Participant');
tableConditionB = addvars(tableConditionB, participantNames', 'Before', 1, 'NewVariableNames', 'Participant');

% Save the tables to Excel files
writetable(tableConditionA, ['Easy_' bands{b} '.xlsx']);
writetable(tableConditionB, ['Hard_' bands{b} '.xlsx']);

end
