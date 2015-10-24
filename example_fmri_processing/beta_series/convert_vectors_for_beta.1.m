vector_path = '/nfs/u3/SN_loc/behav/vectors/placebo/';
files = dir([vector_path,'*_vectors_*.mat']);


for n = 1:length(files),
    load([vector_path,files(n).name])
    old_names = names
    old_onsets = onsets;
    idx = 1
    for k = 1:length(old_names)
        for j = 1:length(old_onsets{k})
            names{idx} = [old_names{k},num2str(j)];
            onsets{idx} = old_onsets{k}(j);
            durations{idx} = [0];
            idx = idx + 1;
        end
    end
    [p filename ex] = fileparts(files(n).name);
    prefix = filename(1:5);
    suffix = filename(end);
    
    save([vector_path,prefix,'betavectors_',suffix],'names','onsets','durations')
end
    
            