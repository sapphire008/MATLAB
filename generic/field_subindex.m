function S = field_subindex(S, F, I)
% get subarray from each specified field, and return the modified structure
for s = 1:length(S)
    for f = 1:length(F)
        S(s).(F{f}) = S(s).(F{f})(I);
    end
end