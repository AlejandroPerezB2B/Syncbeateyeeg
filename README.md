% Functions to be used in the following order:

1.- replaceEyeLinkStrings()

2.- mergeHeartEyeEEG()

3.- preprocHeartEyeEEG()

**Notes**

% Participants 040, 055, and 086 (subjects [27, 41, 72]) encountered errors, prompting us to skip these cases. Should the issues be resolved, rerun the pipeline for these participants.

% Initially, we aimed to process the synchronized EEG-HR-EYE data in a single file. However, due to complications with the clean_artifacts function's operation on specific channels, we opted to split the data back into EEG and HR-EYE components for simplicity and to ensure smooth processing.

**Stimuli**

Linguistic stimuli: 18 passage audios (city descriptions excerpted from travel guides; 9 in English, 9 in Hebrew) recorded by three female, highly proficient bilinguals.

Nonlinguistic stimuli: 18 musical tone audios (a combination of different instrument sounds; 9 Easy and 9 Hard, vary by a number of instruments) synthesized using Audition.

Visual stimuli: 3 isoluminant screen-saver video clips.

**Data**

EEG/ECG (1000 Hz) and eye movement (500 Hz) were simultaneously recorded via a Trigger Box. 

**Markers**

![image](https://github.com/AlejandroPerezB2B/Syncbeateyeeg/assets/65445363/53f168e9-3679-4179-bb6f-5dc2a4476813)

While all trials are around 30s long, to make it consistent, we could use 28s as a standard duration for analysis (because the shortest trial is ~28.5s). 

*notes*

FIXED subject 20 in the EEG recording for the nonling condition the is a '.' missing in the filenames

FIXED subj 62 instead of EEG_and_ECG_ling_062.edf_1.vhdr has EEG_and_ECG_ling_062.edf_3.vhdr


*UNFIXED*

pop_importeyetracker(): Loading E:\Toronto\040\Eye movement\040nonling_new.mat...Error using pop_importeyetracker
pop_importeyetracker(): Did not find events of the specified type [112] in both ET and EEG data! (suj=27)


pop_importeyetracker(): Loading E:\Toronto\055\Eye movement\055ling_new.mat...Error using pop_importeyetracker
pop_importeyetracker(): Did not find events of the specified type [112] in both ET and EEG data!
Please check your raw data. (subj=41)


pop_importeyetracker(): Loading E:\Toronto\086\Eye movement\086nonling_new.mat...Error using pop_importeyetracker
pop_importeyetracker(): Did not find events of the specified type [112] in both ET and EEG data!
(subj=72)
