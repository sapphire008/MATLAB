function waveform = EnforceWaveDuration(Duration, waveform, ts, pad)
dur = (length(waveform)-1)*ts;
if Duration < dur
    ind = round(Duration/ts+double(Duration>=0));
    waveform = waveform(1:ind);
elseif Duration > dur
    l = round((Duration-dur)/ts);
    if nargin<4 || isempty(pad) || isnan(pad)
        pad = waveform(end);
    end
    waveform = [waveform, pad * ones(1, l)];
end
end