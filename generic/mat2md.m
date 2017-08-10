function mat2md(mat, materr)
% convert matrix into markdown table
% mat: mean cell array / table
% materr: standard error cell array / table, resulting mean+/-sem table.

for r = 1:size(mat,1)
    fprintf('|');
    if r == 2
        for c = 1:size(mat,2)
            fprintf('------|');
        end
        fprintf('\n|');
    end
    for c = 1:size(mat,2)
        if ischar(mat{r,c})
            fprintf('%s', mat{r,c});
        elseif isnumeric(mat{r,c})
            if nargin<2 || isempty(materr) || isempty(materr{r,c})
                fprintf('%.2f', mat{r,c});
            else
                fprintf('%.2f&plusmn;%.2f', mat{r,c}, materr{r,c});
            end
        elseif isempty(mat{r,c})
            fprintf('');
        end
        fprintf('|');
    end
    fprintf('\n');
end
end