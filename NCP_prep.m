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

oldBlock = -1;
for i = trials
    if (oldBlock ~= D.BN(i))
        % load mov file for the block
        fprintf("Loading .mov file %d.\n",D.BN(i))
        mov = movload(['data/' subj_name '/' 'efc1_' num2str(str2num(subj_name(end-1:end))) '_' num2str(D.BN(i),'%02d') '.mov']);
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
    ANA = addstruct(ANA, C, 'row', 'force');
end

out_file_name = ['analysis/', subj_name, '.mat'];

save(out_file_name,'-struct','ANA');












