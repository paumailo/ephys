function varargout = TDTLoadingEngine(fn,rtg,record_units)
% MClust Loading Engine for TDT data preprocessed using TDT2MClust
%
% DJS 2013

load(fn,'-mat');
ts = data.unwrapped_times;
wv = data.waveforms;

switch record_units
    case 1 % records_to_get is a timestamp list
        ind = rtg == ts;
        
    case 2 % records_to_get is a record number list
        ind = rtg;
        
    case 3 % records_to_get is range of timestamps (a vector with 2 elements: a start and an end timestamp)
        ind = ts >= rtg(1) & ts <= rtg(2);
        
    case 4 % records_to_get is a range of records (a vector with 2 elements: a start and an end record number)
        ind = rtg(1):rtg(2);
        
    case 5 % asks to return the count of spikes (records_to_get should be [] in this case)
        % done
end

if record_units == 5
    varargout{1} = length(ts);
else
    varargout{1} = ts(ind);
    varargout{2} = wv(ind,:,:) * 1e7;
end

