% Functions to be used in the following order:

1.- replaceEyeLinkStrings() <br />

This function consistently replaces certain trigger-related strings generated from the EyeLink system to facilitate the synchronization of eye movement and EEG/ECG data in the following "mergeHeartEyeEEG.m" function (which uses the "EYE-EEG" plugin that requires the same prefix before the trigger number when parsing the eye movement data). <br />

Input files are the ".asc" files (under the "Eye movement" folder) that are converted from ".edf" files using the "Visual EDF2ASC" app on Windows. <br />

Output files are "_new.asc" files (also under the "Eye movement" folder).

2.- mergeHeartEyeEEG() <br />

This function (1) combines eye movement and EEG/ECG data using the "EYE-EEG" plugin in EEGLAB, (2) downsamples the EEG data to 250 Hz, and (3) merges EEG data from the linguistic and nonlinguistic recordings. <br />

Input files are (1) eye movement files: "_new.asc" files (each participant has 2 under the "Eye movement" folder: one for linguistic, one for nonlinguistic) generated by the "replaceEyeLinkStrings.m" function above; (2) EEG/ECG files: ".eeg", ".vhdr", ".vmrk" files created by BrainVision (each participant has 6 under the "Eye movement" folder: 3 for linguistic, 3 for nonlinguistic). <br />

Output files are "0XX.set" and "0XX.fdt" files (in EEGLAB format, under the participant number folder), where 0XX indicates the participant number (same below).

3.- preprocHeartEyeEEG() <br />

This function preprocesses the EEG data using EEGLAB, including resampling, filtering, and cleaning. Note that it doesn't process the ECG and eye movement data. <br />

Input files are the "0XX.set" files (under the participant number folder) obtained from the "mergeHeartEyeEEG.m" function above. <br />

Output files are (1) "EEG_0XX.set" and "EEG_0XX.fdt" files (in EEGLAB format; they contain the preprocessed EEG data) and (2) "HR_EYE_0XX.set" and "HR_EYE_0XX.fdt" files (which contain the  unprocessed ECG and eye movement data). Both are under the participant number folder.

4.- procEKG() <br />

This function preprocesses the ECG data using the "EEG-Beats" plugin in EEGLAB and outputs Excel files that contain various extracted heart rate measures. <br />

Input files are the 'HR_EYE_0XX.set' files obtained from the "preprocHeartEyeEEG.m" function above. <br />

Output files are 4 Excel files ("table_HRxxxxx.xlsx" included in the repository). Each represents one experimental manipulation ('English', 'Hebrew', 'Easy', 'Hard') and contains multiple heart rate measures extracted using the EEG-Beats plugin for all participants.

5.- IC_manual_rejection()  <br />

This function visually presents independent components and manually rejects components that account for non-brain activity.  <br />

Input files are the "EEG_0XX.set" files obtained from the "preprocHeartEyeEEG.m" function (which conducted automatic ICA labelling) above.  

The output files are "0XX_ICremov.set" and "0XX_ICremov.fdt" files (which contain new datasets after component removal) in the participant number folder. 

6.- create_table_EventMarkers_allPpt()  <br />

As a sanity check, this function records the number of markers (e.g., recording start, recording end, stimulus onset) for each recording (linguistic and nonlinguistic). <br /> 

Input files are the ".vhdr" files corresponding to the raw EEG recordings. 

Output file is an excel table named "number_of_events_each recording_all_participants.xlsx" which contains the number of markers in each recording and the number of trials in each condition.

7.- revenantEEGprocessing() <br />

This function merges raw EEG data from linguistic and nonlinguistic tasks into single files for each participant and further processes the data, including
performing ICA, dipole fitting, and automatic artifact rejection. <br /> 

The input files are two raw EEG recordings (".eeg" format) along with ".vhdr" and ".vmrk" files (e.g., "EEG_and_ECG_ling_0xx.edf_1.eeg" and "EEG_and_ECG_nonling_0xx.edf_1.eeg"), which are contained in the "EEG and ECG" folder.

Output files are (1) "EEG_revenant0XX.set" and "EEG_revenant0XX.fdt" files (in EEGLAB format; contain the preprocessed EEG data); (2) "0XX_ICremov2.set" and "0XX_ICremov2.fdt" files (which contain new datasets after artifact removal) under the participant number folder. <br />

8.- epoching_and_time_frequency <br />

This script processes EEG data to calculate spectral power for linguistic and non-linguistic conditions. It then performs normality tests, selects appropriate statistical tests (paired t-test or Wilcoxon signed-rank), applies FDR correction, and displays significant channels.
Uses the function 'swtest' included in this repository.

9.- epoching_and_ERSP <br />

This script calculates the spectral power while preserving the time dimension. It then performs the statistical tests using the functions in the "resampling statistical toolbox" (a .zip file is included in the repository). The outcomes from this function are the files 'ERSP_Eng_allsubj' 'ERSP_Heb_allsubj' 'ERSP_Easy_allsub'j 'ERSP_Hard_allsubj'. 

**Trial and Duration**

There were 10 trials total for each condition in both the linguistic and nonlinguistic tasks, including an initial practice trial (which should be excluded from the analysis) and 9 study trials.
The initial practice trial is deleted during the pre-processing implemented in revenantEEGprocessing()

While all trials are around 30s, we used 28s as a standard duration for consistent analysis (because the shortest inguistic trial is ~28.5s). 

**Markers**

In the linguistic task, the markers are:

  *Onset (marks the beginning of a passage): English (S1, S5, S9); Hebrew (S3, S7, S11).
  
  *Offset (marks the end of a passage): English (S2, S6, S10): Hebrew (S4, S8, S12). 

In the nonlinguistic task, the markers are:

  *Onset: Easy (S1); Hard (S3).
  
  *Offset: Easy (S2); Hard (S4).

  Please note that the function 'revenantEEGprocessing' substitutes these markers for S21, S23, S22, and S24, respectively.
  
Across tasks, common markers:
 
  *Question onset S13, question offset S14; response onset S16, response offset S32; experiment beggining S111, experiment end S112.

![image](https://github.com/AlejandroPerezB2B/Syncbeateyeeg/assets/65445363/53f168e9-3679-4179-bb6f-5dc2a4476813)

![image](https://github.com/AlejandroPerezB2B/Syncbeateyeeg/assets/51342792/72dcb069-e4b4-4da9-bab0-9aebdfb8a68e)

**Stimuli**

Linguistic stimuli: 18 passage audios (city descriptions excerpted from travel guides; 9 in English, 9 in Hebrew) used in the 18 study trials.

Nonlinguistic stimuli: 18 musical tone audios (a combination of different instrument sounds; 9 Easy and 9 Hard, vary by the number of instruments) used in the 18 study trials.

Visual stimuli: 3 isoluminant screen-saver video clips.

**Data**

EEG/ECG (1000 Hz) and eye movement (500 Hz) were simultaneously recorded via a Trigger Box. 

**Notes**

% Participants 040, 055, and 086 (subjects [27, 41, 72]) encountered errors, prompting us to skip these cases. Should the issues be resolved, rerun the pipeline for these participants. There is also an unidentified error for participant 012 (subject [6]) when running procHR().

% Initially, we aimed to process the synchronized EEG-HR-EYE data in a single file. However, due to complications with the clean_artifacts function's operation on specific channels, we split the data back into EEG and HR-EYE components for simplicity and to ensure smooth processing.

FIXED subject 20 in the EEG recording for the nonling condition, there is a '.' missing in the filenames. 

FIXED subj 62 instead of EEG_and_ECG_ling_062.edf_1.vhdr has EEG_and_ECG_ling_062.edf_3.vhdr

FIXED The following 3 participants had the missing "S112" trigger (recording ending), which was caused while converting ".edf" to ".asc" files. Relevant files have been reconverted and updated on SharePoint.
(1) "pop_importeyetracker(): Loading E:\Toronto\040\Eye movement\040nonling_new.mat...Error using pop_importeyetracker
pop_importeyetracker(): Did not find events of the specified type [112] in both ET and EEG data! (suj=27)"
(2) "pop_importeyetracker(): Loading E:\Toronto\055\Eye movement\055ling_new.mat...Error using pop_importeyetracker
pop_importeyetracker(): Did not find events of the specified type [112] in both ET and EEG data! (subj=41)"
(3) "pop_importeyetracker(): Loading E:\Toronto\086\Eye movement\086nonling_new.mat...Error using pop_importeyetracker
pop_importeyetracker(): Did not find events of the specified type [112] in both ET and EEG data! (subj=72)"

The following participants have fewer trials than expected because their corresponding portions of the recording were eliminated since EEG data could not be cleaned using ASR: '034', '050', '053', '060', '062', '070', '089'.
The following participants are discarded since no trials, or few were obtained after ASR cleaning: '021', '041', '030', '040', '042', '080', '089'


*Next steps*

Process the Eye data.

