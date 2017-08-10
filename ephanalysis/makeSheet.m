function SHEET = makeSheet(CellName, eps, head)
SHEET = head;
for n = eps
    ep = sprintf('S1.E%d', n);
    zData = eph_load(sprintf([CellName,'.S1.E%d'], n));
    stim = zData.protocol.dacData{1}(21);
    SHEET{end+1, 1} = ep;
    SHEET{end,2} = stim;
end
end