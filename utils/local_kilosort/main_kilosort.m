%% you need to change most of the paths in this block

addpath(genpath('C:\Users\jbred\Github\Brody_Lab_Ephys\utils\Kilosort2')) % path to kilosort folder
addpath('C:\Users\jbred\npy-matlab-master') % for converting to Phy
rootZ = 'C:\Users\jbred\Github\Brody_Lab_Ephys\data\binfilesforkilosort2\preprocessing_files\32chantest'; % the raw data binary file is in this folder
rootH = 'C:\Users\jbred\Github\Brody_Lab_Ephys\data\binfilesforkilosort2\preprocessing_files\32chantest'; % path to temporary binary file (same size as data, should be on fast SSD)
pathToYourConfigFile = 'C:\Users\jbred\Github\Brody_Lab_Ephys\data\binfilesforkilosort2\preprocessing_files\data_sdb_20190609_123456_fromSD_secondbundle_L7_7_good_T3_W10000_forkilosort_kiloconfig'; % take from Github folder and put it somewhere else (together with the main_file)
chanMapFile = '8tetrodes_channelmap.mat';


ops.trange = [0 Inf]; % time range to sort
ops.NchanTOT    = 128; % total number of channels in your recording

run(fullfile(pathToYourConfigFile, 'StandardConfig_8tetrodes_L7_7_good_T3_W10000.m'))
ops.fproc       = fullfile(rootH, 'temp_wh.dat'); % proc file on a fast SSD
ops.chanMap = fullfile(pathToYourConfigFile, chanMapFile);

%% this block runs all the steps of the algorithm
fprintf('Looking for data inside %s \n', rootZ)

% is there a channel map file in this folder?
fs = dir(fullfile(rootZ, 'chan*.mat'));
if ~isempty(fs)
    ops.chanMap = fullfile(rootZ, fs(1).name);
end

% find the binary file
fs          = [dir(fullfile(rootZ, '*.bin')) dir(fullfile(rootZ, '*.dat'))];
ops.fbinary = fullfile(rootZ, fs(1).name);

% preprocess data to create temp_wh.dat
rez = preprocessDataSub(ops);

% time-reordering as a function of drift
rez = clusterSingleBatches(rez);

% saving here is a good idea, because the rest can be resumed after loading rez
save(fullfile(rootZ, 'rez.mat'), 'rez', '-v7.3');

% main tracking and template matching algorithm
rez = learnAndSolve8b(rez);

% final merges
rez = find_merges(rez, 1);

% final splits by SVD
rez = splitAllClusters(rez, 1);

% final splits by amplitudes
rez = splitAllClusters(rez, 0);

% decide on cutoff
rez = set_cutoff(rez);

fprintf('found %d good units \n', sum(rez.good>0))

% write to Phy
fprintf('Saving results to Phy  \n')
rezToPhy(rez, rootZ);

%% if you want to save the results to a Matlab file...

% discard features in final rez file (too slow to save)
rez.cProj = [];
rez.cProjPC = [];

% final time sorting of spikes, for apps that use st3 directly
[~, isort]   = sortrows(rez.st3);
rez.st3      = rez.st3(isort, :);

% save final results as rez2
fprintf('Saving final results in rez2  \n')
fname = fullfile(rootZ, 'rez2.mat');
save(fname, 'rez', '-v7.3');
