function P = CompileProtocol(P)
% P = CompileProtocol(P)
%
% Takes protocol structure created by ProtocolSetup GUI and compiles the
% date for use by ControlPanel2.
% 
% Adds fields to the protocol structure:
%       protocol.COMPILED.writeparams
%       protocol.COMPILED.readparams
%       protocol.COMPILED.trials
% 
% Alternatively, compiled protocol can be fully customized manually by
% manually specifying values for writeparams, readparams, and trials
% fields in protocol.COMPILED structure.
%
% DJS 2011

fldn = fieldnames(P.MODULES);

% trim any undefined parameters
for i = 1:length(fldn)
    v = P.MODULES.(fldn{i}).data;
    v(~ismember(1:size(v,1),findincell(v(:,1))),:) = [];
    P.MODULES.(fldn{i}).data = v;
end


% RUN THROUGH EACH MODULE AND EXPAND PARAMETERS ACROSS MODULES
COMPILED = ParamPrep(P);

n = P.OPTIONS.num_reps;
if P.OPTIONS.randomize
    % randomize presentation order
    m = size(COMPILED.trials,1);
    for i = 1:n    
        ind = randperm(m);
        t(m*(i-1)+1:m*i,:) = COMPILED.trials(ind,:); 
    end
    COMPILED.trials = t;
else
    COMPILED.trials = repmat(COMPILED.trials,n,1);
end


COMPILED.OPTIONS = P.OPTIONS;
COMPILED = rmfield(COMPILED,'buds'); % not needed

P.COMPILED = COMPILED;

end



function comp = ParamPrep(P)
comp.writeparams = [];
comp.readparams  = [];

d = [];
data = {};
mod  = {};

k = 1; m = 1;
fn = fieldnames(P.MODULES);
for i = 1:length(fn)
    v = P.MODULES.(fn{i}).data;
    cind = ~ismember(v(:,end),'< NONE >'); % associate calibration
    if any(cind)
        idx = find(cind);
        for j = 1:length(idx)
            cfn = fullfile('C:\Electrophys\Calibrations\',v{idx(j),end});
            C = load(cfn,'-mat');
            cb = sprintf('CalBuddy%d',m);
            try
                vals = eval(v{idx(j),4});
            catch %#ok<CTCH>
                vals = str2num(v{idx(j),4}); %#ok<ST2NM>
            end
            cvals = Calibrate(vals,C);
            v{idx(j),3} = cb;
            v(end+1,:) = {sprintf('~%s',v{idx(j),1}), ...
                'Write', cb,  cvals, 0, 0, '< NONE >'}; %#ok<AGROW>
            m = m + 1;
        end
    end

    kl = size(v,1);
    mod(k:k+kl-1,1)  = repmat(fn(i),kl,1);
    data(k:k+kl-1,:) = v;
    k = k + kl;
end

[data,idx] = sortrows(data,3);
mod = mod(idx);

% fields: 1 - parameter tag
%         2 - Write/Read
%         3 - buddy variable
%         4 - Associated parameter values
%         5 - Random within range (specified in values)

for i = 1:size(data,1)
    module = mod{i};
    if isempty(strfind(data{i,2},'Write')) % 'Read' only
        comp.readparams{end+1} = [module '.' data{i,1}];
        continue
    end
    
    if strfind(data{i,2},'Write')
        comp.writeparams{end+1} = [module '.' data{i,1}];
    end
    
    if strfind(data{i,2},'Read')
        comp.readparams{end+1} = [module '.' data{i,1}];
    end
    
    if isnumeric(data{i,4}) % Numeric data
        v = data{i,4};
    
    elseif ~data{i,6} % Char and not WAV
        v = str2num(data{i,4}); %#ok<ST2NM>
    
    elseif data{i,6} % WAV files
        t = findobj('type','uitable','-and','tag','param_table');
        S = get(t,'UserData');
        v = S.WAV{i}';
    
    else
        v = str2num(data{i,4}); %#ok<ST2NM>
    end
    
    if data{i,5} % randomized
        d{end+1}{1} = 'randomized'; %#ok<AGROW>
        d{end}{2} = []; 
        d{end}{3} = v; 
    else
        % Buddy variables
        if strcmp(data{i,3},'< NONE >')
            d{end+1} = v; %#ok<AGROW>
        else
            d{end+1}{1} = 'buddy'; %#ok<AGROW>
            d{end}{2} = data{i,3}; 
            d{end}{3} = v; 
        end
    end
end

comp = AddTrial(comp,d);

end

