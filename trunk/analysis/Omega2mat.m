function T = Omega2mat(omegacsv)
% T = Omega2mat(omegacsv)
%
% Reads in a CSV file generated from Omega TC Central temperature recording
% program and formats the date for use in Matlab.
% 
% The structure T will be returned with the following fields:
% 
% T.Sensors     ...     Name sensors
% T.Interval    ...     Sampling interval of temperature data (seconds)
% T.Units       ...     'F' for Fahrenheit or 'C' for Celsius
% T.LogDate     ...     Cell array (Nx1) of strings with date of temp recording
% T.LogTime     ...     Cell array (Nx1) of strings with time of temp recording
% T.Temps       ...     NxM matrix of temperature values where columns
%                       correspond to T.Sensors and rows correspond to the
%                       T.LogDate and T.LogTime.
% T.N           ...     Number of data points (rows) in T.Temps, T.LogDate, 
%                       and T.LogTime
% 
% Convert F to C
%   T.Temps = (T.Temps - 32) * 5/9;
%   T.Units = 'C';
% 
% Convert C to F
%   T.Temps = T.Temps * 9/5 + 32;
%   T.Units = 'F';
% 
% Daniel.Stolzberg@gmail.com 2013

% read header info
fid = fopen(omegacsv,'r');
C = textscan(fid,'%s',100,'delimiter',',','headerlines',2);
fclose(fid);

ind = ismember(C{:},'0');
if ~any(ind), error('File is improperly formated'); end

H = C{1}(1:find(ind)-1);

ind = ismember(H,'Interval:');
if ~any(ind), error('File is improperly formated'); end

intidx = find(ind);
k = 1;
for i = 1:2:intidx-1
    T.Sensors{k} = [H{i} H{i+1}];
    k = k + 1;
end

T.Interval = str2num(H{intidx+1}); %#ok<ST2NM>
T.Units    = H{find(ismember(H,'Units Deg:'))+1};

nhdrlines = length(T.Sensors) + 7;

% read data
fid = fopen(omegacsv,'r');
datastr = repmat(' %f',1,length(T.Sensors));
C = textscan(fid,['%d %s %s' datastr],'delimiter',',','headerlines',nhdrlines);
fclose(fid);

T.LogDate = C{2};
T.LogTime = C{3};
T.Temps   = single(cell2mat(C(4:end)));
T.N       = length(T.LogDate);









