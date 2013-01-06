function cfg = AutoClass2(W,cfg)
% cfg = AutoClass2(W,cfg)
% 
% Runs AutoClass Bayesian classifier (NASA) on spike waveforms.  Spike
% waveforms should be prealigned.
%
% W is a matrix of #samples X #waveforms
% 
% CFG is a structure with atleast the following fields:
%   .tank
%   .AutoClass.resultsdir
%   .AutoClass.fileroot
%   .AutoClass.varFactor (default = 2)
% 
% NOTE: cfg.AutoClass.fileroot should be a unique name, possibly including
% tank name and channel number.
%
%
% DJS 2011

AC = cfg.AutoClass;

if ~isfield(AC,'varFactor') || isempty(AC.varFactor), AC.varFactor = 2; end

if ~isdir(AC.resultsdir), mkdir(AC.resultsdir); end

% CREATE FILE NAMES
if AC.resultsdir(end) ~= '\', AC.resultsdir(end+1) = '\'; end
t = [AC.resultsdir AC.fileroot];
AC.snipsfn =     [t '_SNIP.mat']; % spike data
AC.hd2 =         [t '.hd2']; % header file
AC.db2 =         [t '.db2']; % data file
AC.model =       [t '.model']; % model file (standard)
AC.s_params =    [t '.s-params']; % s-params file (standard)
AC.r_params =    [t '.r-params']; % r-params file (standard)
AC.results_bin = [t '.results-bin']; % results-bin file (reporting)
AC.search =      [t '.search']; % search file (used by AutoClass.exe)
AC.case_data_1 = [t '.case-data-1']; % case-data-1 file (used by AutoClass.exe)
% AC.exelocale = [matlabroot '\work\Electrophys\MultiChannel Analysis\AutoClass\']; % AutoClass.exe location
% AC.exelocale = 'C:\MATLAB\work\Electrophys\MultiChannel Analysis\AutoClass\';

AC.exelocale = getpref('AutoClass','exelocale',[]);
if isempty(AC.exelocale)
    AC.exelocale = uigetdir(matlabroot,'Locate AutoClass Directory');
    if isempty(AC.exelocale)
        error('AutoClass2: need AutoClass directory!')
    end
    setpref('AutoClass','exelocale',[AC.exelocale '\'])
end


%CALCULATE VARIANCE OF DATA
AC.meanWaveform = mean(W);
% AC.MeasError = (1/2^16)/2; % 16-bit A/D divided by 2
AC.MeasError = 0.0;
AC.varData   = var(W);
AC.varThresh = AC.varData * AC.varFactor;

% find samples greater than variance threshold
% AC.varSamples = find(AC.varData >= AC.meanWaveform + AC.varThresh);
AC.varSamples = 1:length(AC.varData); % using all samples of the waveform seems to work best

cfg.AutoClass = AC;

%SAVE DATA FOR AUTOCLASS
fprintf('\t> Saving data for AutoClass\n')  
save(AC.snipsfn,'W','cfg');
dlmwrite(AC.db2,W(:,AC.varSamples),',');

% hd2 file
fid = fopen(AC.hd2,'wt');
fprintf(fid,'!#; AutoClass C header file -- extension .hd2\n');
fprintf(fid,'!#; the following chars in column 1 make the line a comment:\n');
fprintf(fid,'!#; ''!'', ''#'', '';'', '' '', and ''\\n'' (empty line)\n');
fprintf(fid,'  \n');
fprintf(fid,';#! num_db2_format_defs <num of def lines -- min 1, max 4>\n');
fprintf(fid,'num_db2_format_defs 2\n');
fprintf(fid,';; required\n');
fprintf(fid,'number_of_attributes %1.0f\n',length(AC.varSamples));
fprintf(fid,';; optional - default values are specified \n');
fprintf(fid,';; separator_char  '' ''\n');
fprintf(fid,';; comment_char    '';''\n');
fprintf(fid,';; unknown_token   ''?''\n');
fprintf(fid,'separator_char     '',''\n');
fprintf(fid,' \n' );
fprintf(fid,';; <zero-based att#>  <att_type>  <att_sub_type>  <att_description>  <att_param_pairs>\n');

fm(1,:) = 0:length(AC.varSamples)-1;
fm(2,:) = AC.varSamples;
fm(3,:) = AC.MeasError;

fprintf(fid,'%1.0f real location "SNIP%1.0f" error %0.6f \n',fm);
fclose(fid);

% Ensure Autoclass has all the right files to run
copyfile([AC.exelocale 'SNIP.model'],   AC.model);
copyfile([AC.exelocale 'SNIP.s-params'],AC.s_params);
copyfile([AC.exelocale 'SNIP.r-params'],AC.r_params);

dosSTR = sprintf('psexec -d Autoclass.exe -search "%s" "%s" "%s" "%s"', ...
    AC.hd2,AC.db2,AC.model,AC.s_params);

fprintf('\t> Launching AutoClass\n')
[~,~] = dos(dosSTR);

% Usage: psexec [\\computer[,computer2[,...] | @file][-u user [-p psswd]]
% [-n s][-l][-s|-e][-x][-i [session]][-c [-f|-v]][-w directory][-d]
% [-<priority>][-a n,n,... ] cmd [arguments]
% computer:	Direct PsExec to run the application on the computer or 
% computers specified. If you omit the computer name PsExec runs the 
% application on the local system and if you enter a computer name of "\\*"
% PsExec runs the applications on all computers in the current domain.
% See http://technet.microsoft.com/en-us/sysinternals/bb897553 

