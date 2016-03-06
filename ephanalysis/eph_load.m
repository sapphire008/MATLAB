function zData = eph_load(cellname, base_dir, infoOnly)
% Wrapper function for loadEPisodeFile, assuming the data structure we
% have.
% zData = eph_load(cellname, base_dir='', infoOnly=False)
if nargin<2 || isempty(base_dir)
    base_dir = 'D:/Data/Traces';
end
if nargin<3, infoOnly = false; end
cellpath = fullfile(base_dir, eph_cellpath(cellname));
zData = loadEpisodeFile(cellpath);
end
