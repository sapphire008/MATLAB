function [ep_names, ep_num] = eph_parse_episodes(ep)
% Parse episode list, expressed such as S1.E15-23,25,28-30
% ep = 'S1.E15-23,25,28-30';
% Separate sequence first
Seq = regexp(ep, 'S(\d+).E', 'match');
Seq = Seq{1};
eps = regexp(ep, 'S(\d+).E', 'split');
eps = eps{end};
% Separate list by commas
eps = regexp(eps, ',','split');

ep_num = [];
for ii = 1:length(eps)
    % separate the dashes
    ep_dd = regexp(eps{ii},'-','split');
    ep_dd = cellfun(@deblank, ep_dd, 'un',0);
    % append the numbers
    ep_num = [ep_num, str2num(ep_dd{1}):str2num(ep_dd{end})];
end

ep_names = arrayfun(@(x) sprintf('%s%d',Seq, x), ep_num, 'un',0);

end