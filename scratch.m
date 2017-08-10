index = 123:132;
inc = 10;

final_str = '{';
for n = 1:length(index)
    temp_str = sprintf('S1.E%d+S1.E%d*10', index(n), index(n)+inc);
    final_str = [final_str, temp_str];
    if n < length(index)
        final_str = [final_str, ';'];
    else
        final_str = [final_str, '}'];
    end
end

%%
index1 = 22:31;
inc1 = 10;
index2 = 123:132;
inc2 = 10;

final_str = '{';
for n = 1:length(index1)
    temp_str = sprintf('S1.E%d+S1.E%d*10-S1.E%d-S1.E%d*10', index1(n), index1(n)+inc1, index2(n), index2(n)+inc2);
    final_str = [final_str, temp_str];
    if n < length(index)
        final_str = [final_str, ';'];
    else
        final_str = [final_str, '}'];
    end
end