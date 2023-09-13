% Ali Ghavampour 2023 - Diedrichsen & Pruszynski lab


%% Prep Data:
clear;
clc;
close all;

subj_name = 'subj01';
NCP_prep(subj_name)

%%
clc

% load EMG:
subj_name = 'subj01';
x = readtable(['data/' subj_name '/emg_01.csv']);
x(1:3,:) = [];

%%
% get trigger times:
t = table2array(x(:,1));
trig = table2array(x(:,2));

[riseTimes,riseIdx] = detectTrig(trig,t,0.4,200,1);

% extract trials:
fs = 2148.1481;
iti = 1;

% emg channels to selected from the emg table:
emg_channels = 4:2:22;
% electrode locations from 4 to 22 in order:
emg_locs = {'extensor index', 'extensor thumb', 'flexor thumb', 'flexor pinky', 'flexor ring', 'flexor middle',...
            'extensor ring', 'extensor pinky', 'flexor index', 'extensor middle'};
emg_locs_coded = {'e2','e1','f1','f5','f4','f3','e4','e5','f2','e3'};

for i = 1:length(riseIdx)-1
    % start of a trial:
    idx1 = riseIdx(i);

    % end of a trial:
    idx2 = riseIdx(i+1) - fs*iti;
    
    % extracting EMG of the trial. Should be T by 10(number of electrodes)
    emg_trial = table2array(x(idx1:idx2,emg_channels));

    % preprocessing the EMG signals:

    % 
    
end





