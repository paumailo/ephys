function obj = deline(obj)
for i = 1:size(obj.data,2)
    fprintf('Removing 60Hz line noise on channel %d of %d ...',i,size(obj.data,2))
    obj.data(:,i) = chunkwiseDeline(obj.data(:,i),obj.Fs,[60 180],2,60,false);
    fprintf(' done\n')
end
