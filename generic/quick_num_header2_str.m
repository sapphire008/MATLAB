function C = quick_num_header2_str(C)
for m = 1:size(C, 2)
    if isnumeric(C{1,m})
        C{1,m} = num2str(C{1,m});
    end
end
end