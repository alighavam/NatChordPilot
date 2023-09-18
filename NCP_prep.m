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
ANA = [];

trials = 1:length(D.BN);

% designing filter for bandpass filtering:
hd = design_filter;
freqz(hd)

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
            emg_data(:,j) = filtfilt(hd.Numerator, 1, emg_data(:,j));
        end


        emg = cell(length(riseIdx),1);
        for j = 1:length(riseIdx)
            % start of a trial:
            idx1 = riseIdx(j);
        
            % end of a trial:
            idx2 = fallIdx(j);
            
            % extracting EMG of the trial. Should be T by 10(number of electrodes)
            emg_trial = emg_data(idx1:idx2,emg_channels);
        
            % preprocessing the EMG signals:
            % bandpass butterworth filter:

            
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
    ANA = addstruct(ANA, C, 'row', 'force');
end

out_file_name = ['analysis/', subj_name, '.mat'];

save(out_file_name,'-struct','ANA');












