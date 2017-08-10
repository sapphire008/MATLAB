function outstr = printEpisodeNumber(eps)
% eps = [1;4;5;6;8;9;10;12;16;20;24];
% return '1,4-6,8-10,12,16,20,24'
eps = eps(:);
eps = sort(eps);
eps_cons = getconsecutiveindex(eps);
cons = {};
cons_ind = [];
for n = 1:size(eps_cons,1)
    cons{end+1} = sprintf('%d-%d', eps(eps_cons(n,1)), eps(eps_cons(n,2)));
    cons_ind = [cons_ind, eps_cons(n,1):eps_cons(n,2)];
end
cons = cons(:);
singles_ind = setdiff(1:length(eps), cons_ind);
singles = eps(singles_ind);
singles = cellfun(@num2str, num2cell(singles),'un',0);

outstr = [singles;cons];
[~, out_ind] = sort([singles_ind, eps_cons(:,1)']);
outstr = outstr(out_ind);
outstr = strjoin(outstr,',');
end