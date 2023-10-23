function NCP_analysis(what,varargin)

clear; 
clc;

% setting paths:
usr_path = userpath;
usr_path = usr_path(1:end-17);

addpath('functions/')
addpath(genpath(fullfile(usr_path,'Desktop/matlab/dataframe-2016.1')),'-begin')
fs = 2148.1481;

switch what
    case 'emg_windowSize_effect'
        subj_name = 'subj01';
        window_size_vec = 5:5:600;  % vector of the window sizes
        num_windows = 10;           % how many windows to randomly select from the data

        % Handling the input arguments:
        vararginoptions(varargin,{'subject_name','window_size_vec','num_selection'});

        if (length(window_size_vec) < 2)
            error('analysis %s: window_size_vec should be a vector with size more than 1.')
        end
        if (num_windows < 1 || floor(num_windows) ~= num_windows)
            error('analysis %s: num_windows should be an ineteger larger than 0.')
        end
        
        % loading the data:
        data = load(['analysis/' subj_name '.mat']);
        
        % select correct trials:
        data = getrow(data.trialCorr == 1);
        
        % value container:
        deviation_from_avg = zeros(length(data.BN),size(data.emg{1},2));

        % loop through window sizes:
        for wn = window_size_vec
            % loop through trials:
            for i = 1:length(data.BN)
                % the emg signal of trial i:
                emg_tmp = data.emg{i}; 

                % index of EMG during hold time:
                [i1_emg,i2_emg,~,~] = get_phase_idx(getrow(data,i), data.mov{i}, fs_emg, fs_force, phase);

            end
        end


    otherwise
        error('The analysis \"%s\" does not exist.',what)

end
