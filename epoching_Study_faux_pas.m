function epoching_Study_faux_pas
% CREATING_STUDY_FAUX_PAS epochs the data on the *_processed.set files
% It has three sections, each executed based on the selected option. 
% The function begins by prompting the user to select a folder containing 
% participant data. Then, it creates a GUI with radio buttons for selecting one of three options.
% Depending on the selected option, the function executes a specific section of code. 
% Each section loads processed EEG data, epochs it based on different conditions, 
% and saves the epoch data into separate files. Additionally, it creates a table containing 
% the number of trials for each condition per participant and saves it to an Excel file. 
% Finally, it generates commands for creating a STUDY structure based on the directory structure and file naming conventions.
%
% Output:
% - Epoched data corresponding to the chosen option.
% - Display of command lines at the command prompt for creating a STUDY structure.
% - File containing the number of trials for each condition and participant.
%
% The following example demonstrates how to define a STUDY structure using
% the std_editset function. Typically, the STUDY structure is manually
% provided. Each block of code within the commands cell array represents
% the loading of an EEG dataset for a specific subject and condition.
%
% Example:
% [STUDY ALLEEG] = std_editset( STUDY, [], 'name','faux_pass','task','ERN','commands',{ ...
%     {'index',1,'load','C:\\Users\\25645\\OneDrive\\Documents\\faux_pas\\P1\\Cog_epochs.set','subject','1','condition','Cog'}, ...
%     {'index',2,'load','C:\\Users\\25645\\OneDrive\\Documents\\faux_pas\\P1\\Incog_epochs.set','subject','1','condition','Incog'}, ...
%     {'index',3,'load','C:\\Users\\25645\\OneDrive\\Documents\\faux_pas\\P1\\Neutral_epochs.set','subject','1','condition','Neutral'}, ...
%     {'index',4,'load','C:\\Users\\25645\\OneDrive\\Documents\\faux_pas\\P2\\Cog_epochs.set','subject','2','condition','Cog'}, ...
%     {'index',5,'load','C:\\Users\\25645\\OneDrive\\Documents\\faux_pas\\P2\\Incog_epochs.set','subject','2','condition','Incog'}, ...
%     {'index',6,'load','C:\\Users\\25645\\OneDrive\\Documents\\faux_pas\\P2\\Neutral_epochs.set','subject','2','condition','Neutral'} ...
%     },'updatedat','on','rmclust','on' );
%
% This function automates the creation of a similar structure,
% reducing manual effort.
%
% Author: Alejandro Perez, McMaster University, 07/05/2024

%eeglab; close all;

selpath = uigetdir('Choose parent folder containing participants data');
% Change the current working directory to the selected path
cd(selpath);

% List all directories starting with 'P' representing participants
A = dir('P*');

% Create a figure window
fig = figure('Name', 'Option Selector', 'Position', [100, 100, 300, 200], 'MenuBar', 'none', 'NumberTitle', 'off');

% Create a panel to contain the radio buttons
panel = uipanel(fig, 'Title', 'Options', 'Units', 'normalized', 'Position', [0.05, 0.05, 0.9, 0.7]);

% Create a buttongroup to ensure mutual exclusivity
buttonGroup = uibuttongroup('Parent', panel, 'Position', [0, 0, 1, 1], 'SelectionChangedFcn', @selectOption_epoch, 'BorderType', 'none', 'SelectedObject', []);

% Create radio buttons for each option
radio1 = uicontrol(panel, 'Style', 'radiobutton', 'String', 'Incongruent and Congruent', 'Units', 'normalized', 'Position', [0.1, 0.6, 0.8, 0.2]);
radio2 = uicontrol(panel, 'Style', 'radiobutton', 'String', 'Positive and Negative', 'Units', 'normalized', 'Position', [0.1, 0.3, 0.8, 0.2]);
radio3 = uicontrol(panel, 'Style', 'radiobutton', 'String', 'Bp, Bn, Wp, Wn, Sp, Sn', 'Units', 'normalized', 'Position', [0.1, 0, 0.8, 0.2]);

% Create a push button to confirm the selection
btn = uicontrol(fig, 'Style', 'pushbutton', 'String', 'Select', 'Units', 'normalized', 'Position', [0.75, 0.05, 0.2, 0.1], 'Callback', @selectOption_epoch);

% Function to handle button click event
    function selectOption_epoch(~, ~)
        % Get the value of the selected radio button
        if get(radio1, 'Value')
            option = 1;
        elseif get(radio2, 'Value')
            option = 2;
        elseif get(radio3, 'Value')
            option = 3;
        else
            % Display an error message if no option is selected
            errordlg('Please select an option.', 'Error');
            return;
        end

        % Call the function to execute the selected option
        executeOption(option,A,selpath);
    end
end

% Function to execute the selected option
function executeOption(option,A,selpath)
% Switch case to execute the corresponding section of code
switch option
    case 1
        disp('Option 1 selected: Executing Section 1');

        % Section 1 code %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Create a table containing the number of epochs per participant and condition
        sz = [length(A) 4 ];
        varTypes = {'string','double','double','double'};
        varNames = {'Participant','Congruent','Incongruent','Neutral'};
        T = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

        % Loop across subjects/participants to process each one
        for suj=1:length(A)

            T.Participant(suj) = A(suj).name;

            % Skipping participants with issues
            if ismember(suj, 5) % Skip participant P13.
                continue;
            end

            EEGproc = pop_loadset('filename', [ A(suj).name '_processed.set'],'filepath',[selpath filesep A(suj).name]);

            EEG = pop_epoch( EEGproc, {  '11'  '22'  }, [-0.4 0.6], 'newname', 'Cong_epochs', 'epochinfo', 'yes');
            EEG = pop_saveset( EEG, 'filename','Cong_epochs.set','filepath',[selpath filesep A(suj).name] );
            T.Congruent(suj) = EEG.trials;

            EEG = pop_epoch( EEGproc, {  '12'  '21'  }, [-0.4 0.6], 'newname', 'Incong_epochs', 'epochinfo', 'yes');
            EEG = pop_saveset( EEG, 'filename','Incong_epochs.set','filepath',[selpath filesep A(suj).name] );
            T.Incongruent(suj) = EEG.trials;

            EEG = pop_epoch( EEGproc, {  '31'  '32'  }, [-0.4 0.6], 'newname', 'Neutral_epochs', 'epochinfo', 'yes');
            EEG = pop_saveset( EEG, 'filename','Neutral_epochs.set','filepath',[selpath filesep A(suj).name] );
            T.Neutral(suj) = EEG.trials;
        end

        writetable(T, [selpath filesep 'epochs_allPpt_CongIncong.xlsx']);

        %% STUDY Structure Generation
        % This section of the code automates the generation of the STUDY structure
        % based on the directory structure and file naming conventions.
        % copy the output from the command prompt for later use.

        AA = A;
        AA(5) = []; % participant P13.
        conditions = {'Cong','Incong','Neutral'};
        idx = 0; % Initialize index counter

        for i=1:length(AA) % Loop across all datasets (participants)

            for cond = 1:length(conditions)
                idx = idx+1; % Increment index counter

                % Display command for later copy-paste
                disp(['{''' 'index''' ',' num2str(idx) ',''' 'load''' ',[' 'selpath filesep ' '''' AA(i).name '''' ' filesep '  '''' conditions{cond} '_epochs.set''' ']' ',''' 'subject''' ',''' num2str(i) ''',''' 'condition''' ',''' conditions{cond} '''} ...']);

            end
        end

    case 2
        disp('Option 2 selected: Executing Section 2');
        % Section 2 code %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Loop across subjects/participants to process each one
        % Create a table containing the number of epochs per participant and condition
        sz = [length(A) 3 ];
        varTypes = {'string','double','double'};
        varNames = {'Participant','Positive','Negative'};
        T = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

        % Loop across subjects/participants to process each one
        for suj=1:length(A)

            T.Participant(suj) = A(suj).name;

            % Skipping participants with issues
            if ismember(suj, 5) % Skip participant P13.
                continue;
            end

            EEGproc = pop_loadset('filename', [ A(suj).name '_processed.set'],'filepath',[selpath filesep A(suj).name]);

            EEG = pop_epoch( EEGproc, {  '12'  '22'  '32'  }, [-0.4 0.6], 'newname', 'Posit_epochs', 'epochinfo', 'yes');
            EEG = pop_saveset( EEG, 'filename','Posit_epochs.set','filepath',[selpath filesep A(suj).name] );
            T.Positive(suj) = EEG.trials;

            EEG = pop_epoch( EEGproc, {  '11'  '21'  '31'  }, [-0.4 0.6], 'newname', 'Negat_epochs', 'epochinfo', 'yes');
            EEG = pop_saveset( EEG, 'filename','Negat_epochs.set','filepath',[selpath filesep A(suj).name] );
            T.Negative(suj) = EEG.trials;

        end

        writetable(T, [selpath filesep 'epochs_allPpt_PositNegat.xlsx']);

                %% STUDY Structure Generation
        % This section of the code automates the generation of the STUDY structure
        % based on the directory structure and file naming conventions.
        % copy the output from the command prompt for later use.

        AA = A;
        AA(5) = []; % participant P13.
        conditions = {'Posit','Negat' };
        idx = 0; % Initialize index counter

        for i=1:length(AA) % Loop across all datasets (participants)

            for cond = 1:length(conditions)
                idx = idx+1; % Increment index counter

                % Display command for later copy-paste
                disp(['{''' 'index''' ',' num2str(idx) ',''' 'load''' ',[' 'selpath filesep ' '''' AA(i).name '''' ' filesep '  '''' conditions{cond} '_epochs.set''' ']' ',''' 'subject''' ',''' num2str(i) ''',''' 'condition''' ',''' conditions{cond} '''} ...']);

            end
        end

    case 3
        disp('Option 3 selected: Executing Section 3');
        % Section 3 code %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Create a table containing the number of epochs per participant and condition
        sz = [length(A) 7 ];
        varTypes = {'string','double','double','double','double','double','double'};
        varNames = {'Participant','Bn','Bp','Wn','Wp','Sn','Sp'};
        T = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

        % Loop across subjects/participants to process each one
        for suj=1:length(A)

            T.Participant(suj) = A(suj).name;

            % Skipping participants with issues
            if ismember(suj, 5) % Skip participant P13.
                continue;
            end

            EEGproc = pop_loadset('filename', [ A(suj).name '_processed.set'],'filepath',[selpath filesep A(suj).name]);

            EEG = pop_epoch( EEGproc, {  '11'  }, [-0.4 0.6], 'newname', 'Bn_epochs', 'epochinfo', 'yes');
            EEG = pop_saveset( EEG, 'filename','Bn_epochs.set','filepath',[selpath filesep A(suj).name] );
            T.Bn(suj) = EEG.trials;

            EEG = pop_epoch( EEGproc, {  '12'  }, [-0.4 0.6], 'newname', 'Bp_epochs', 'epochinfo', 'yes');
            EEG = pop_saveset( EEG, 'filename','Bp_epochs.set','filepath',[selpath filesep A(suj).name] );
            T.Bp(suj) = EEG.trials;

            EEG = pop_epoch( EEGproc, {  '21'  }, [-0.4 0.6], 'newname', 'Wn_epochs', 'epochinfo', 'yes');
            EEG = pop_saveset( EEG, 'filename','Wn_epochs.set','filepath',[selpath filesep A(suj).name] );
            T.Wn(suj) = EEG.trials;

            EEG = pop_epoch( EEGproc, {  '22'  }, [-0.4 0.6], 'newname', 'Wp_epochs', 'epochinfo', 'yes');
            EEG = pop_saveset( EEG, 'filename','Wp_epochs.set','filepath',[selpath filesep A(suj).name] );
            T.Wp(suj) = EEG.trials;

            EEG = pop_epoch( EEGproc, {  '31'  }, [-0.4 0.6], 'newname', 'Sn_epochs', 'epochinfo', 'yes');
            EEG = pop_saveset( EEG, 'filename','Sn_epochs.set','filepath',[selpath filesep A(suj).name] );
            T.Sn(suj) = EEG.trials;

            EEG = pop_epoch( EEGproc, {  '32'  }, [-0.4 0.6], 'newname', 'Sp_epochs', 'epochinfo', 'yes');
            EEG = pop_saveset( EEG, 'filename','Sp_epochs.set','filepath',[selpath filesep A(suj).name] );
            T.Sp(suj) = EEG.trials;
        end

        writetable(T, [selpath filesep 'epochs_allPpt_BnBpWnWpSnSp.xlsx']);

        %% STUDY Structure Generation
        % This section of the code automates the generation of the STUDY structure
        % based on the directory structure and file naming conventions.
        % copy the output from the command prompt for later use.

        AA = A;
        AA(5) = []; % participant P13.
        conditions = {'Bn','Bp','Wn','Wp','Sn','Sp' };
        idx = 0; % Initialize index counter

        for i=1:length(AA) % Loop across all datasets (participants)

            for cond = 1:length(conditions)
                idx = idx+1; % Increment index counter

                % Display command for later copy-paste
                disp(['{''' 'index''' ',' num2str(idx) ',''' 'load''' ',[' 'selpath filesep ' '''' AA(i).name '''' ' filesep '  '''' conditions{cond} '_epochs.set''' ']' ',''' 'subject''' ',''' num2str(i) ''',''' 'condition''' ',''' conditions{cond} '''} ...']);

            end
        end

end
end


%% Actual STUDY Creation
% This section contains the code to create the STUDY structure automatically
% based on the directory structure and file naming conventions determined
% in the previous section.

% Paste the commands copied from the command prompt after the line
% containing the three dots (...). Uncomment the code and run this part to create the STUDY.
% WARNING! You must change the name of the study

% [STUDY ALLEEG] = std_editset( STUDY, [], 'name','faux_pass_CongIncongNeutral','task','ERN','commands',{ ...
%     ...
% {'index',1,'load',[selpath filesep 'P1' filesep 'Cong_epochs.set'],'subject','1','condition','Cong'} ...
% {'index',2,'load',[selpath filesep 'P1' filesep 'Incong_epochs.set'],'subject','1','condition','Incong'} ...
% {'index',3,'load',[selpath filesep 'P1' filesep 'Neutral_epochs.set'],'subject','1','condition','Neutral'} ...
% {'index',4,'load',[selpath filesep 'P10' filesep 'Cong_epochs.set'],'subject','2','condition','Cong'} ...
% {'index',5,'load',[selpath filesep 'P10' filesep 'Incong_epochs.set'],'subject','2','condition','Incong'} ...
% {'index',6,'load',[selpath filesep 'P10' filesep 'Neutral_epochs.set'],'subject','2','condition','Neutral'} ...
% {'index',7,'load',[selpath filesep 'P11' filesep 'Cong_epochs.set'],'subject','3','condition','Cong'} ...
% {'index',8,'load',[selpath filesep 'P11' filesep 'Incong_epochs.set'],'subject','3','condition','Incong'} ...
% {'index',9,'load',[selpath filesep 'P11' filesep 'Neutral_epochs.set'],'subject','3','condition','Neutral'} ...
% {'index',10,'load',[selpath filesep 'P12' filesep 'Cong_epochs.set'],'subject','4','condition','Cong'} ...
% {'index',11,'load',[selpath filesep 'P12' filesep 'Incong_epochs.set'],'subject','4','condition','Incong'} ...
% {'index',12,'load',[selpath filesep 'P12' filesep 'Neutral_epochs.set'],'subject','4','condition','Neutral'} ...
% {'index',13,'load',[selpath filesep 'P14' filesep 'Cong_epochs.set'],'subject','5','condition','Cong'} ...
% {'index',14,'load',[selpath filesep 'P14' filesep 'Incong_epochs.set'],'subject','5','condition','Incong'} ...
% {'index',15,'load',[selpath filesep 'P14' filesep 'Neutral_epochs.set'],'subject','5','condition','Neutral'} ...
% {'index',16,'load',[selpath filesep 'P15' filesep 'Cong_epochs.set'],'subject','6','condition','Cong'} ...
% {'index',17,'load',[selpath filesep 'P15' filesep 'Incong_epochs.set'],'subject','6','condition','Incong'} ...
% {'index',18,'load',[selpath filesep 'P15' filesep 'Neutral_epochs.set'],'subject','6','condition','Neutral'} ...
% {'index',19,'load',[selpath filesep 'P16' filesep 'Cong_epochs.set'],'subject','7','condition','Cong'} ...
% {'index',20,'load',[selpath filesep 'P16' filesep 'Incong_epochs.set'],'subject','7','condition','Incong'} ...
% {'index',21,'load',[selpath filesep 'P16' filesep 'Neutral_epochs.set'],'subject','7','condition','Neutral'} ...
% {'index',22,'load',[selpath filesep 'P17' filesep 'Cong_epochs.set'],'subject','8','condition','Cong'} ...
% {'index',23,'load',[selpath filesep 'P17' filesep 'Incong_epochs.set'],'subject','8','condition','Incong'} ...
% {'index',24,'load',[selpath filesep 'P17' filesep 'Neutral_epochs.set'],'subject','8','condition','Neutral'} ...
% {'index',25,'load',[selpath filesep 'P18' filesep 'Cong_epochs.set'],'subject','9','condition','Cong'} ...
% {'index',26,'load',[selpath filesep 'P18' filesep 'Incong_epochs.set'],'subject','9','condition','Incong'} ...
% {'index',27,'load',[selpath filesep 'P18' filesep 'Neutral_epochs.set'],'subject','9','condition','Neutral'} ...
% {'index',28,'load',[selpath filesep 'P19' filesep 'Cong_epochs.set'],'subject','10','condition','Cong'} ...
% {'index',29,'load',[selpath filesep 'P19' filesep 'Incong_epochs.set'],'subject','10','condition','Incong'} ...
% {'index',30,'load',[selpath filesep 'P19' filesep 'Neutral_epochs.set'],'subject','10','condition','Neutral'} ...
% {'index',31,'load',[selpath filesep 'P2' filesep 'Cong_epochs.set'],'subject','11','condition','Cong'} ...
% {'index',32,'load',[selpath filesep 'P2' filesep 'Incong_epochs.set'],'subject','11','condition','Incong'} ...
% {'index',33,'load',[selpath filesep 'P2' filesep 'Neutral_epochs.set'],'subject','11','condition','Neutral'} ...
% {'index',34,'load',[selpath filesep 'P20' filesep 'Cong_epochs.set'],'subject','12','condition','Cong'} ...
% {'index',35,'load',[selpath filesep 'P20' filesep 'Incong_epochs.set'],'subject','12','condition','Incong'} ...
% {'index',36,'load',[selpath filesep 'P20' filesep 'Neutral_epochs.set'],'subject','12','condition','Neutral'} ...
% {'index',37,'load',[selpath filesep 'P21' filesep 'Cong_epochs.set'],'subject','13','condition','Cong'} ...
% {'index',38,'load',[selpath filesep 'P21' filesep 'Incong_epochs.set'],'subject','13','condition','Incong'} ...
% {'index',39,'load',[selpath filesep 'P21' filesep 'Neutral_epochs.set'],'subject','13','condition','Neutral'} ...
% {'index',40,'load',[selpath filesep 'P22' filesep 'Cong_epochs.set'],'subject','14','condition','Cong'} ...
% {'index',41,'load',[selpath filesep 'P22' filesep 'Incong_epochs.set'],'subject','14','condition','Incong'} ...
% {'index',42,'load',[selpath filesep 'P22' filesep 'Neutral_epochs.set'],'subject','14','condition','Neutral'} ...
% {'index',43,'load',[selpath filesep 'P23' filesep 'Cong_epochs.set'],'subject','15','condition','Cong'} ...
% {'index',44,'load',[selpath filesep 'P23' filesep 'Incong_epochs.set'],'subject','15','condition','Incong'} ...
% {'index',45,'load',[selpath filesep 'P23' filesep 'Neutral_epochs.set'],'subject','15','condition','Neutral'} ...
% {'index',46,'load',[selpath filesep 'P24' filesep 'Cong_epochs.set'],'subject','16','condition','Cong'} ...
% {'index',47,'load',[selpath filesep 'P24' filesep 'Incong_epochs.set'],'subject','16','condition','Incong'} ...
% {'index',48,'load',[selpath filesep 'P24' filesep 'Neutral_epochs.set'],'subject','16','condition','Neutral'} ...
% {'index',49,'load',[selpath filesep 'P25' filesep 'Cong_epochs.set'],'subject','17','condition','Cong'} ...
% {'index',50,'load',[selpath filesep 'P25' filesep 'Incong_epochs.set'],'subject','17','condition','Incong'} ...
% {'index',51,'load',[selpath filesep 'P25' filesep 'Neutral_epochs.set'],'subject','17','condition','Neutral'} ...
% {'index',52,'load',[selpath filesep 'P26' filesep 'Cong_epochs.set'],'subject','18','condition','Cong'} ...
% {'index',53,'load',[selpath filesep 'P26' filesep 'Incong_epochs.set'],'subject','18','condition','Incong'} ...
% {'index',54,'load',[selpath filesep 'P26' filesep 'Neutral_epochs.set'],'subject','18','condition','Neutral'} ...
% {'index',55,'load',[selpath filesep 'P27' filesep 'Cong_epochs.set'],'subject','19','condition','Cong'} ...
% {'index',56,'load',[selpath filesep 'P27' filesep 'Incong_epochs.set'],'subject','19','condition','Incong'} ...
% {'index',57,'load',[selpath filesep 'P27' filesep 'Neutral_epochs.set'],'subject','19','condition','Neutral'} ...
% {'index',58,'load',[selpath filesep 'P28' filesep 'Cong_epochs.set'],'subject','20','condition','Cong'} ...
% {'index',59,'load',[selpath filesep 'P28' filesep 'Incong_epochs.set'],'subject','20','condition','Incong'} ...
% {'index',60,'load',[selpath filesep 'P28' filesep 'Neutral_epochs.set'],'subject','20','condition','Neutral'} ...
% {'index',61,'load',[selpath filesep 'P29' filesep 'Cong_epochs.set'],'subject','21','condition','Cong'} ...
% {'index',62,'load',[selpath filesep 'P29' filesep 'Incong_epochs.set'],'subject','21','condition','Incong'} ...
% {'index',63,'load',[selpath filesep 'P29' filesep 'Neutral_epochs.set'],'subject','21','condition','Neutral'} ...
% {'index',64,'load',[selpath filesep 'P3' filesep 'Cong_epochs.set'],'subject','22','condition','Cong'} ...
% {'index',65,'load',[selpath filesep 'P3' filesep 'Incong_epochs.set'],'subject','22','condition','Incong'} ...
% {'index',66,'load',[selpath filesep 'P3' filesep 'Neutral_epochs.set'],'subject','22','condition','Neutral'} ...
% {'index',67,'load',[selpath filesep 'P30' filesep 'Cong_epochs.set'],'subject','23','condition','Cong'} ...
% {'index',68,'load',[selpath filesep 'P30' filesep 'Incong_epochs.set'],'subject','23','condition','Incong'} ...
% {'index',69,'load',[selpath filesep 'P30' filesep 'Neutral_epochs.set'],'subject','23','condition','Neutral'} ...
% {'index',70,'load',[selpath filesep 'P31' filesep 'Cong_epochs.set'],'subject','24','condition','Cong'} ...
% {'index',71,'load',[selpath filesep 'P31' filesep 'Incong_epochs.set'],'subject','24','condition','Incong'} ...
% {'index',72,'load',[selpath filesep 'P31' filesep 'Neutral_epochs.set'],'subject','24','condition','Neutral'} ...
% {'index',73,'load',[selpath filesep 'P32' filesep 'Cong_epochs.set'],'subject','25','condition','Cong'} ...
% {'index',74,'load',[selpath filesep 'P32' filesep 'Incong_epochs.set'],'subject','25','condition','Incong'} ...
% {'index',75,'load',[selpath filesep 'P32' filesep 'Neutral_epochs.set'],'subject','25','condition','Neutral'} ...
% {'index',76,'load',[selpath filesep 'P33' filesep 'Cong_epochs.set'],'subject','26','condition','Cong'} ...
% {'index',77,'load',[selpath filesep 'P33' filesep 'Incong_epochs.set'],'subject','26','condition','Incong'} ...
% {'index',78,'load',[selpath filesep 'P33' filesep 'Neutral_epochs.set'],'subject','26','condition','Neutral'} ...
% {'index',79,'load',[selpath filesep 'P34' filesep 'Cong_epochs.set'],'subject','27','condition','Cong'} ...
% {'index',80,'load',[selpath filesep 'P34' filesep 'Incong_epochs.set'],'subject','27','condition','Incong'} ...
% {'index',81,'load',[selpath filesep 'P34' filesep 'Neutral_epochs.set'],'subject','27','condition','Neutral'} ...
% {'index',82,'load',[selpath filesep 'P35' filesep 'Cong_epochs.set'],'subject','28','condition','Cong'} ...
% {'index',83,'load',[selpath filesep 'P35' filesep 'Incong_epochs.set'],'subject','28','condition','Incong'} ...
% {'index',84,'load',[selpath filesep 'P35' filesep 'Neutral_epochs.set'],'subject','28','condition','Neutral'} ...
% {'index',85,'load',[selpath filesep 'P36' filesep 'Cong_epochs.set'],'subject','29','condition','Cong'} ...
% {'index',86,'load',[selpath filesep 'P36' filesep 'Incong_epochs.set'],'subject','29','condition','Incong'} ...
% {'index',87,'load',[selpath filesep 'P36' filesep 'Neutral_epochs.set'],'subject','29','condition','Neutral'} ...
% {'index',88,'load',[selpath filesep 'P37' filesep 'Cong_epochs.set'],'subject','30','condition','Cong'} ...
% {'index',89,'load',[selpath filesep 'P37' filesep 'Incong_epochs.set'],'subject','30','condition','Incong'} ...
% {'index',90,'load',[selpath filesep 'P37' filesep 'Neutral_epochs.set'],'subject','30','condition','Neutral'} ...
% {'index',91,'load',[selpath filesep 'P38' filesep 'Cong_epochs.set'],'subject','31','condition','Cong'} ...
% {'index',92,'load',[selpath filesep 'P38' filesep 'Incong_epochs.set'],'subject','31','condition','Incong'} ...
% {'index',93,'load',[selpath filesep 'P38' filesep 'Neutral_epochs.set'],'subject','31','condition','Neutral'} ...
% {'index',94,'load',[selpath filesep 'P4' filesep 'Cong_epochs.set'],'subject','32','condition','Cong'} ...
% {'index',95,'load',[selpath filesep 'P4' filesep 'Incong_epochs.set'],'subject','32','condition','Incong'} ...
% {'index',96,'load',[selpath filesep 'P4' filesep 'Neutral_epochs.set'],'subject','32','condition','Neutral'} ...
% {'index',97,'load',[selpath filesep 'P5' filesep 'Cong_epochs.set'],'subject','33','condition','Cong'} ...
% {'index',98,'load',[selpath filesep 'P5' filesep 'Incong_epochs.set'],'subject','33','condition','Incong'} ...
% {'index',99,'load',[selpath filesep 'P5' filesep 'Neutral_epochs.set'],'subject','33','condition','Neutral'} ...
% {'index',100,'load',[selpath filesep 'P6' filesep 'Cong_epochs.set'],'subject','34','condition','Cong'} ...
% {'index',101,'load',[selpath filesep 'P6' filesep 'Incong_epochs.set'],'subject','34','condition','Incong'} ...
% {'index',102,'load',[selpath filesep 'P6' filesep 'Neutral_epochs.set'],'subject','34','condition','Neutral'} ...
% {'index',103,'load',[selpath filesep 'P7' filesep 'Cong_epochs.set'],'subject','35','condition','Cong'} ...
% {'index',104,'load',[selpath filesep 'P7' filesep 'Incong_epochs.set'],'subject','35','condition','Incong'} ...
% {'index',105,'load',[selpath filesep 'P7' filesep 'Neutral_epochs.set'],'subject','35','condition','Neutral'} ...
% {'index',106,'load',[selpath filesep 'P8' filesep 'Cong_epochs.set'],'subject','36','condition','Cong'} ...
% {'index',107,'load',[selpath filesep 'P8' filesep 'Incong_epochs.set'],'subject','36','condition','Incong'} ...
% {'index',108,'load',[selpath filesep 'P8' filesep 'Neutral_epochs.set'],'subject','36','condition','Neutral'} ...
% {'index',109,'load',[selpath filesep 'P9' filesep 'Cong_epochs.set'],'subject','37','condition','Cong'} ...
% {'index',110,'load',[selpath filesep 'P9' filesep 'Incong_epochs.set'],'subject','37','condition','Incong'} ...
% {'index',111,'load',[selpath filesep 'P9' filesep 'Neutral_epochs.set'],'subject','37','condition','Neutral'} ...
%     ...
%     },'updatedat','on','rmclust','on' );
% %
% % The code above generates the STUDY structure by automatically loading EEG
% % datasets for each participant and condition. The file paths are
% % constructed based on the selected parent folder (selpath) and the naming
% % conventions for subjects (P1, P2, etc.) and conditions (Cog, Incog,
% % Neutral). The resulting STUDY structure organizes the datasets for
% % subsequent analysis.
% 
% % WARNING! You must change the name of the study
% %
% CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];
% [STUDY EEG] = pop_savestudy( STUDY, EEG, 'filename','faux_passCongIncongNeutral.study','filepath',[selpath filesep 'code']);
% %
