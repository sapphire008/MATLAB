function S_out = mycopyfields(S_in,S_out,F_in,F_out)
for n = 1:length(F_in)
    eval(['S_out.',F_out{n},'=S_in.',F_in{n},';']);
end
end