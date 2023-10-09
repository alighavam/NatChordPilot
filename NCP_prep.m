function NCP_prep(subj_name)
% Ali Ghavampour 2023 - Diedrichsen & Pruszynski lab

% setting paths:
usr_path = userpath;
usr_path = usr_path(1:end-17);


% Adding required tools and packages:
addpath(genpath(fullfile(usr_path,'Desktop/matlab/dataframe-2016.1')),'-begin')

% Loading data:
% subj_name = 'subj01';
dat_file_name = ['data/',subj_name,'/','efc1_',...
                 num2str(str2num(subj_name(end-1:end))),'.dat'];
D = dload(dat_file_name);
fs = 2148.1481;
ANA = [];

trials = 1:length(D.BN);

% designing filter for bandpass filtering:
hd = bandpass_filter;
hd_lowpass = lowpass_filter;
% freqz(hd)
% freqz(hd_lowpass)

oldBlock = -1;
for i = trials
    if (oldBlock ~= D.BN(i))
        % load mov file for the block
        fprintf("Loading .mov file %d.\n",D.BN(i))
        mov = movload(['data/' subj_name '/' 'efc1_' num2str(str2num(subj_name(end-1:end))) '_' num2str(D.BN(i),'%02d') '.mov']);
        
        % loading EMG data of the block:
        fprintf("Loading emg file %d.\n",D.BN(i))
        emg_data = readtable(['data/' subj_name '/emg_' num2str(D.BN(i),'%02d') '.csv']);
        emg_data(1:3,:) = [];
        emg_data = table2array(emg_data);

        % Extracting triggers of the emg:
        t = emg_data(:,1);
        trig = emg_data(:,2);

        % detecting trial start times from the EMGs:
        [~,riseIdx,~,fallIdx] = detectTrig(trig,t,0.4,sum(D.BN == D.BN(i)),1);

        % if number of triggers did not make sense, throw and error:
        if (length(riseIdx) ~= length(fallIdx) || length(riseIdx) ~= sum(D.BN == D.BN(i)))
            error('Trigger detection went wrong! Block Number = %d',D.BN(i))
        end
        
        % emg channels to selected from the emg table:
        emg_channels = 4:2:22;
        % electrode locations from 4 to 22 in order:
        emg_locs = {'extensor index', 'extensor thumb', 'flexor thumb', 'flexor pinky', 'flexor ring', 'flexor middle',...
                    'extensor ring', 'extensor pinky', 'flexor index', 'extensor middle'};
        emg_locs_coded = {'e2','e1','f1','f5','f4','f3','e4','e5','f2','e3'};
        
        % filtering the EMG signals:
        fprintf("Filtering the raw EMG signals:\n\n")
        for j = emg_channels
            fprintf("Filtering channels %d/%d...\n",(0.5*j - 1),length(emg_channels))
            emg_data(:,j) = abs(filtfilt(hd.Numerator, 1, emg_data(:,j)));
            % emg_data(:,j) = filtfilt(hd_lowpass.Numerator, 1, emg_data(:,j));
        end

        emg = cell(length(riseIdx),1);
        baseline_emg = zeros(length(riseIdx),length(emg_channels));
        hold_avg_EMG = zeros(length(riseIdx),length(emg_channels));
        subset_D = getrow(D, D.BN == D.BN(i));
        for j = 1:length(riseIdx)
            % start of a trial:
            idx1 = riseIdx(j);
        
            % end of a trial:
            idx2 = fallIdx(j);
            
            % extracting EMG of the trial. Should be T(time) by 10(number of electrodes)
            emg_trial = 1000*emg_data(idx1:idx2,emg_channels);
            
            % ===========================================================================
            % Should become a function:
            % ===========================================================================
            % the index of mov file that go cue is presented:
            go_cue_index = find(mov{j}(:,1) == 3, 1);
            
            % the time of that index:
            go_cue_time = mov{j}(go_cue_index,3);
        
            % planning start time:
            plan_onset_time = (go_cue_time - D.planTime(1))/1000;
            
            % finding the plan time start index with respect to EMG:
            idx_plan_onset = round(plan_onset_time * fs);

            % If the beginning of the planning time was at t=0, the index
            % should be 1 because MATLAB's first index is 1:
            if (idx_plan_onset == 0)
                idx_plan_onset = 1;
            end
        
            % averaging EMG during plan onset:
            baseline_avg_tmp = mean(emg_trial(idx_plan_onset:idx_plan_onset+round(D.planTime(1)/1000*fs),:), 1);
            % ===========================================================================
            
            % storing the baseline values:
            baseline_emg(j,:) = baseline_avg_tmp;

            % ===========================================================================
            % Should become a function:
            % ===========================================================================
            % if trial is correct:
            if (subset_D.trialCorr(j))
                % the index that subject achieves the chord -> holds for 600ms:
                end_exec_idx = find(mov{j}(:,1) == 4, 1);
                
                % the time of that index:
                end_exec_time = mov{j}(end_exec_idx,3);
    
                % hold onset time:
                hold_onset_time = (end_exec_time - 600)/1000;
                
                % finding the hold onset index with respect to EMG:
                idx_hold_onset = round(hold_onset_time * fs);
                
                % averaging EMG during hold time:
                hold_avg_tmp = mean(emg_trial(idx_hold_onset:end,:), 1);
            else
                % if trial is incorrect, we don't have a hold time, hence:
                hold_avg_tmp = nan;
            end

            % ===========================================================================

            % storing the avg hold time EMGs:
            hold_avg_EMG(j,:) = hold_avg_tmp;

            % adding trials to emg cell:
            emg{j} = emg_trial;
        end
        
        oldBlock = D.BN(i);
    end
    fprintf('Block: %d , Trial: %d\n',D.BN(i),D.TN(i));

    row = getrow(D,i);
    C = [];
    if (row.trialPoint==0)
        row.RT = 10000;   % correction for execution error trials
    end
    C = addstruct(C, row, 'row', 'force');
    C.mov = mov(D.TN(i));
    C.emg = emg(D.TN(i));
    C.emg_baseline = baseline_emg(D.TN(i),:);
    C.emg_hold_avg = hold_avg_EMG(D.TN(i),:);
    ANA = addstruct(ANA, C, 'row', 'force');
end

out_file_name = ['analysis/', subj_name, '.mat'];

save(out_file_name,'-struct','ANA');












