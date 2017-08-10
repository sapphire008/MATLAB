function WCtime_str = eph_print_WCTime(WCtime)
WCtime_str = '%d:%02.0f:%.1f';

HH = floor(WCtime / 3600);
MM = floor(mod(WCtime,3600) / 60);
SS = WCtime - HH * 3600 - MM * 60;

WCtime_str = sprintf(WCtime_str, HH, MM, SS);
end