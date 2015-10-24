function [new_names, new_onsets, new_durations] = beta_vectors_plac(names,onsets,durations)
% converts standard spm5 events vector into beta series vector
j = 1;
for n = 1:length(names);
    for k = 1:length(onsets{n});
        new_names{j} = ['Plac',names{n},'_',num2str(k)];
        new_durations{j} = durations{n};
        new_onsets{j} = onsets{n}(k);
        j = j + 1;
    end
end

%%This takes vector mat files that contain name, onsets, duration, it will
%%return new set of name, onsets, durations, save as beta vector1 %%%