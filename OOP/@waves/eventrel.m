function data = eventrel(obj,win)
% data = eventrel(win)
% Organize continuous waves into event-related trials
%
% dim order of output matrix: samples X channels X trials

swin = round(win*obj.Fs);
svec = 0:diff(swin);
onst = ceil(obj.params(end).vals(:,2)*obj.Fs+swin(1));

if any(onst <= 0)
    error('eventrel:%d window onsets occur before the first sample of the recording', ...
        sum(onst<=0));
end

data = zeros(length(svec),size(obj.data,2),length(onst));
for i = 1:length(onst)
    data(:,:,i) = obj.data(onst(i)+svec,:);
end

