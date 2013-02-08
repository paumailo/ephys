function RunAutoClassReport(TANKS)
% RunAutoClassReport(TANKS)
% 
% Where TANKS is a cell array of tanks names or paths
% 
% IMPOARTANT: Only run after all channels have finished being processed 
%             with AutoClass (such as after a call to RunAutoClass)
% 
% DJS 2013
%
% See also, RunAutoClass, Pooling_GUI2



for i = 1:length(TANKS)
    
    [~,T,~] = fileparts(TANKS{i});
    
    resultsdir = ['C:\AutoClass_Files\AC2_RESULTS\' T '\'];
    
    d = dir(resultsdir);
    k = findincell(strfind({d.name},'SNIP'));
    d = d(k);
    
    for j = 1:length(d)
        f = fullfile(resultsdir,d(j).name);
        AutoClassReport2(f);
    end    
end
fprintf('*** We''re all done here ***'\n)



