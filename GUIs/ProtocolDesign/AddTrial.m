function [schedule,fail] = AddTrial(schedule,varargin)
% [schedule,fail] = AddTrial(schedule,varargin)
% 
% INPUTS: schedule should be empty or the returned structure from a
% previous call to this function.
%         varargin inputs can be specified as follows:
% 
%       Define stimuli to use in schedule:
%  schedule = AddTrial(schedule,[100 200 400 800]);
%
%       Two variables can be made to covary:
%  schedule = AddTrial(schedule,'buddy','commonname',[1 2 4  90 2])
%  schedule = AddTrial(schedule,'buddy','commonname',[2 4 8 180 4])
%               - all buddy parameters must be the same length.
% 
%       To randomize input between some range:
%  schedule = AddTrial(schedule,'randomized','round',[100 400]);
%               - the second input can be the function name to operate on
%               randomized value between the range specified in the next
%               parameter.  If no function should be applied to the random
%               numbers, then simply leave empty: ...'randomized',[],[100 400])
%               - most often, this will be the last call to this funciton
%               in a series of calls.  Otherwise, random numbers will be
%               repeated.
% 
%       Note: to facilitate creation of trials, varargin can also be a
%       single cell containing intended varargin values.  Ex:
% 
%  vin{1} = {[100 200 400 800]};
%  vin{2} = {'randomized','round',[100 400]};
%  schedule = AddTrial(schedule,vin);
% 
% OUTPUT: schedule structure with the following fields
%           trials  ...  unique trials (as cell matrix)
%           buds    ...  'buddy' parameters
% 
%      If all data is numeric, then schedule.trials =
%      CELL2MAT(schedule.trials) can be used.
% 
%       fail ... true if there was an error during operation, false if all
%                   is good
% DJS (c) 2010



if iscell(varargin{1})
    varargin = varargin{1};
    
    % check for randomized option    
    ind = false(size(varargin));
    for i = 1:length(varargin)
        ind(i) = any(strcmpi(varargin{i},'randomized'));
    end
    if any(ind)
        % move randomization to end
        t = varargin(ind);
        varargin(ind) = [];
        varargin(end+1:end+sum(ind)) = t;
    end
    
    for i = 1:length(varargin)
        [schedule,fail] = BAT(schedule,varargin{i});
        if fail, break; end
    end
else
    [schedule,fail] = BAT(schedule,varargin{1});
end

    

function [schedule,fail] = BAT(schedule,varargin)
if isempty(schedule) || ~isfield(schedule,'trials'),    schedule.trials = {}; end
if ~isfield(schedule,'buds') || ~iscell(schedule.buds), schedule.buds = []; end

if iscell(varargin{1})
    vin = varargin{1};
else
    vin = varargin;
end

trials = schedule.trials;
buds   = schedule.buds;

if ischar(vin{1})
    switch lower(vin{1})
        case 'randomized'
            nv = vin{end};
            r = nv(1) + abs(diff(nv)) .* rand(size(trials,1),1);
            if ~isempty(vin{2}) 
                % optionally apply function such as FIX, ROUND, etc.
                r = feval(vin{2},r);
            end
            trials(:,end+1) = num2cell(r);
            
        case 'buddy'
            if isnumeric(vin{3}) || islogical(vin{3})
                vin{3} = num2cell(vin{3});
            end
            
            if ~any(strcmp(vin{2},buds))
                buds{end+1} = vin{2};
                [trials,fail] = combinetrials(trials,vin{3},1);
            else
                [trials,fail] = combinetrials(trials,vin{3},0);
            end
    end
else
    if isnumeric(vin{1}) || islogical(vin{1})
        vin{1} = num2cell(vin{1});
    end
    if length(vin) == 1
        [trials,fail] = combinetrials(trials,vin{1},1);
    else
        [trials,fail] = combinetrials(trials,vin,1);
    end
end

schedule.trials = trials;
schedule.buds   = buds;


function [trials,fail] = combinetrials(trials,newtrials,expand)
[i,j] = size(trials);
fail = false;
if expand
    trials = repmat(trials,length(newtrials),1);
    if i > 0, newtrials = repmat(newtrials,i,1);    end
else
    if rem(i,length(newtrials)) % results in non-integer value
        fail = true;
    else
        newtrials = repmat(newtrials,i/length(newtrials),1);
    end
end

trials(1:numel(newtrials),j+1) = newtrials(:);





