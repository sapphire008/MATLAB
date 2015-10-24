function eph_quick_get_firing_rate(zData)
zData = 'Neocortex G.05Aug15.S1.E17';
if ischar(zData)
    regexp(zData, '([\w\s]+).(\d+)(\w+)(\d).S(\d).E(\d+)', 'tokens')
end
end