% Ali Ghavampour 2023 - Diedrichsen & Pruszynski lab


%% Prep Data:
clear;
clc;
close all;

subj_name = 'subj01';
NCP_prep(subj_name)

%%
clc

x = readtable(['data/' subj_name '/emg_01.csv']);
x(1:3,:) = [];

%%

t = table2array(x(:,1));
trig = table2array(x(:,2));