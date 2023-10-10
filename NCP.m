% Ali Ghavampour 2023 - Diedrichsen & Pruszynski lab


%% Prep Data:
clear;
clc;
close all;

subj_name = 'subj01';
NCP_prep(subj_name)


%% Analysis
clear; 
clc;

% setting paths:
usr_path = userpath;
usr_path = usr_path(1:end-17);

addpath('functions/')
addpath(genpath(fullfile(usr_path,'Desktop/matlab/dataframe-2016.1')),'-begin')

subj_name = 'subj01';
dat = load(['analysis/' subj_name '.mat']);
fs = 2148.1481;

chords = unique(dat.chordID);

emg_timelocked = cell(length(chords),1);
cwt_timelocked = cell(length(chords),10);
for i = 1:length(chords)
    fprintf('chord %d:\n',i)
    % selecting the EMGs of all trials of each chord. 
    dat_chord = getrow(dat, find(dat.chordID==chords(i) & dat.trialCorr==1));

    % avg of the baseline EMG over the trials of chord i:
    baseline_emg_avg = mean(dat_chord.emg_baseline,1);
    
    % looping through trials of chord i:
    for j = 1:length(dat_chord.TN)
        % the index that subject achieves the chord -> holds for 600ms:
        end_exec_idx = find(dat_chord.mov{j}(:,1) == 4, 1);
        
        % the time of that index:
        end_exec_time = dat_chord.mov{j}(end_exec_idx,3);

        % hold onset time:
        hold_onset_time = (end_exec_time - 600)/1000;
        
        % finding the hold onset index with respect to EMG:
        idx_hold_onset = round(hold_onset_time * fs);

        % selecting EMG around hold onset. [-500,600]:
        emg_tmp = dat_chord.emg{j}(round(idx_hold_onset-0.500*fs):round(idx_hold_onset+0.599*fs),:);
        
        % saving extracted EMGs in a cell:
        emg_timelocked{i,j} = emg_tmp;%./baseline_emg_avg;
    end
    
    % calculating CWTs:
    % fprintf('calculating CWT...\n\n')
    % for ch = 1:10
    %     wt_avg = 0;
    %     for j = 1:length(dat_chord.TN)
    %         [wt,f_cwt] = cwt(emg_timelocked{i,j}(:,ch),'morse',fs);
    %         wt_avg = wt_avg + abs(wt)/length(dat_chord.TN);
    %     end
    %     cwt_timelocked{i,ch} = wt_avg;
    % end
end


%% Regressions - Force explained by EMG
clear; 
clc;

% setting paths:
usr_path = userpath;
usr_path = usr_path(1:end-17);

addpath('functions/')
addpath(genpath(fullfile(usr_path,'Desktop/matlab/dataframe-2016.1')),'-begin')

subj_name = 'subj01';
dat = load(['analysis/' subj_name '.mat']);
fs = 2148.1481;

chords = unique(dat.chordID);

% select part of the data with correct trials:
dat_select = getrow(dat,find(dat.trialCorr==1));

% training data , avg EMG hold time:
X = zeros(length(dat_select.BN),10);

% testing data , avg force hold time:
Y = zeros(length(dat_select.BN),5);

chordVecSep = sepChordVec(chords);

for i = 1:size(X,1)
    % the index that subject achieves the chord -> holds for 600ms:
    end_exec_idx = find(dat_select.mov{i}(:,1) == 4, 1);
    
    % the time of that index:
    end_exec_time = dat_select.mov{i}(end_exec_idx,3);

    % hold onset time:
    hold_onset_time = (end_exec_time - 600)/1000;
    
    % finding the hold onset index with respect to EMG:
    idx_hold_onset = round(hold_onset_time * fs);

    % averaging EMG during hold onset:
    X(i,:) = mean(abs(dat_select.emg{i}(idx_hold_onset:end,:)), 1);
    
    % averaging force during hold onset:
    Y(i,:) = mean(dat_select.mov{i}(end_exec_idx-600/2:end_exec_idx,19:23), 1);
end

% train data , single-finger first session:
[idx_single_finger, ~] = find(dat_select.chordID == chordVecSep{1,1} & dat_select.BN < 4);
idx_single_finger = sort(idx_single_finger);
x_train = X(idx_single_finger,:);
y_train = Y(idx_single_finger,:);

% test data , single-finger second session:
[idx_single_finger, ~] = find(dat_select.chordID == chordVecSep{1,1} & dat_select.BN >= 4);
idx_single_finger = sort(idx_single_finger);
x_test = X(idx_single_finger, :);
y_test = Y(idx_single_finger, :);

% regression:
beta = (x_train' * x_train)^-1 * x_train' * y_train;

% variance explained train:
y_hat = x_train * beta;
RSS = mean(sum((y_hat - y_train).^2,1));
TSS = mean(sum((y_train - repmat(mean(y_train,1),size(y_train,1),1)).^2,1));
R2_train = (1 - RSS/TSS) * 100

% variance explained test:
y_hat = x_test * beta;
RSS = mean(sum((y_hat - y_test).^2,1));
TSS = mean(sum((y_test - repmat(mean(y_test,1),size(y_test,1),1)).^2,1));
R2_test = (1 - RSS/TSS) * 100


%% Regression - EMG explained by models
clear; 
clc;

% setting paths:
usr_path = userpath;
usr_path = usr_path(1:end-17);

addpath('functions/')
addpath(genpath(fullfile(usr_path,'Desktop/matlab/dataframe-2016.1')),'-begin')

subj_name = 'subj01';
dat = load(['analysis/' subj_name '.mat']);
fs = 2148.1481;

chords = unique(dat.chordID);

% select part of the data with correct trials of single finger:
dat_select = getrow(dat,find(dat.trialCorr==1));
sep_chords = sepChordVec(dat_select.chordID);
dat_select = getrow(dat_select,sep_chords{1,2});

% separating session data:
dat_sess01 = getrow(dat_select,find(dat_select.BN==1));
dat_sess02 = getrow(dat_select,find(dat_select.BN>1));

% Building Design Matrices ======

% Saturated Model:
single_finger_chords = unique(dat_sess01.chordID);
X_sess01 = zeros(length(dat_sess01.TN),length(single_finger_chords));
X_sess02 = zeros(length(dat_sess02.TN),length(single_finger_chords));
for i = 1:length(single_finger_chords)
    X_sess01(:,i) = dat_sess01.chordID == single_finger_chords(i);
    X_sess02(:,i) = dat_sess02.chordID == single_finger_chords(i);
end

% training on each session:
beta_sess01 = (X_sess01' * X_sess01)^-1 * X_sess01' * dat_sess01.emg_hold_avg;
beta_sess02 = (X_sess02' * X_sess02)^-1 * X_sess02' * dat_sess02.emg_hold_avg;

% testing within session:
y_pred_sess01 = X_sess01 * beta_sess01;
y_pred_sess02 = X_sess02 * beta_sess02;
% Variance explained by the models:
[R2_sess01_within,~,~] = calc_R2(dat_sess01.emg_hold_avg, y_pred_sess01)
[R2_sess02_wihtin,~,~] = calc_R2(dat_sess02.emg_hold_avg, y_pred_sess02)


% test across session
y_pred_sess01 = X_sess01 * beta_sess02;
y_pred_sess02 = X_sess02 * beta_sess01;
% Variance explained by the models:
[R2_sess01_across,~,~] = calc_R2(dat_sess01.emg_hold_avg, y_pred_sess01)
[R2_sess02_across,~,~] = calc_R2(dat_sess02.emg_hold_avg, y_pred_sess02)



%% PLOTS
close all;
emg_locs = {'extensor index', 'extensor thumb', 'flexor thumb', 'flexor pinky', 'flexor ring', 'flexor middle',...
                    'extensor ring', 'extensor pinky', 'flexor index', 'extensor middle'};
emg_locs_coded = {'e2','e1','f1','f5','f4','f3','e4','e5','f2','e3'};
t = linspace(-500,600,size(emg_timelocked{1,1},1))';

chord_num = 26;
channels = [2,3,1,9,10,6,7,5,8,4];
figure;
for i = 1:10
    subplot(5,2,i)
    hold all;
    for trial = 1:size(emg_timelocked,2)
        emg_tmp = emg_timelocked{chord_num,trial};
        if (~isempty(emg_tmp))
            plot(t, emg_tmp(:,channels(i)), 'LineWidth', 1)
            ylim([0,1000])
            xlim([-500,600])
        end
    end
    title(emg_locs{channels(i)})
end
sgtitle(num2str(chords(chord_num)))

% CWT plot:
% chord_num = 9;
% avg_sig = mean(abs(cat(3,emg_timelocked{chord_num,:})),3);
% figure('Position', [100 100 2500 1500]);
% channels = [2,3,1,9,10,6,7,5,8,4];
% for i = 1:10
%     subplot(5,2,i)
%     yyaxis left
%     h = pcolor(t,f_cwt,cwt_timelocked{chord_num,channels(i)});
%     ylim([0, 600])
%     shading interp
%     set(h, 'EdgeColor','none')
%     colormap('turbo')
%     clim([0,0.05])
%     colorbar
% 
%     yyaxis right
%     plot(t,avg_sig(:,channels(i)),'linewidth',0.5,'color','r')
%     xline(0,'--r')
%     ylim([0,0.05])
%     title(emg_locs{channels(i)})
% end
% sgtitle(num2str(chords(chord_num)))

% avg signal plots:
chord_num = 1;
% avg of signals across trials:
avg_sig = mean(abs(cat(3,emg_timelocked{chord_num,:})),3);
channels = [2,3,1,9,10,6,7,5,8,4];
figure;
for i = 1:10
    subplot(5,2,i)
    plot(t,avg_sig(:,channels(i)),'linewidth',1.5,'color','k')
    title(emg_locs{channels(i)})
    xline(0,'--r')
    ylim([0,200])
    xlim([-500,600])
end
sgtitle(num2str(chords(chord_num)))









