function result = AutoClassReport2(SnipFile)
% result = AutoClassReport2(SnipFile)
% 
% Retrieve and process results from running AutoClass on spike data.  Saves
% a file with '_CLASSES.mat' as a suffix to acroot.
% 
% Input
%   Specify the full path to the 'Snip' file generated from running
%   the MATLAB function AutoClass2.
% 
% Output
%   If successful, result == 1
% 
% See also, AutoClass2
% 
% DJS 2011

result = 0;

load(SnipFile,'cfg');
AC = cfg.AutoClass;
% disp('Retrieving AutoClass Results')
% searchData = load(AC.db2);
% nSpikes = size(searchData,1);

[acroot,acfn,~] = fileparts(AC.db2);
acfn = fullfile(acroot,[acfn,'_CLASSES.mat']);

if exist(acfn,'file')
    b = questdlg(sprintf(['Spike Classes File ("%s") already exists. ', ...
        'Would you like to run the reporting utility again?'],acfn), ...
        'Class file found','Yes','No','No');
    if strcmp(b,'No'), return; end
end

disp('Launching AutoClass Reporting Utility')
% doesn't seem to work without using psexec(?)
dosSTR = sprintf('psexec -d Autoclass.exe -reports "%s" "%s" "%s"', ...
    AC.results_bin,AC.search,AC.r_params);
[~,~] = dos(dosSTR);

while 1 % give AutoClass some time to process report
    if exist(AC.case_data_1,'file'), break; end
    pause(0.5);
end

% Read in AutoClass files to Matlab
disp('Loading Results...')
fid = fopen(AC.case_data_1,'rt');
if fid == -1,   error('Problem opening search case-data');  end

% move to results in case-data-1 file
while ~strcmp(fgetl(fid),'DATA_CASE_TO_CLASS'), end
fgetl(fid);

% get classes
classList = zeros(3,cfg.spiketotal);
for i = 1:cfg.spiketotal
    x = fgetl(fid); if isempty(deblank(x)) || all(x == -1), continue; end % is this ok?
    classList(:,i) = str2num(x); %#ok<ST2NM>
end
fclose(fid);

% Save classes
save(acfn,'classList');

if exist(acfn,'file')
    disp('Done Saving Classed Spikes Data')
    result = 1;
else
    error('UNABLE TO SAVE CLASSED SPIKES DATA')
end

