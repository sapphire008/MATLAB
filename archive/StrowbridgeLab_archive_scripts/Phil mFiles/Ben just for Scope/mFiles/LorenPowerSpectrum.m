function outPowers = LorenPowerSpectrum(inData, SamplingFreq, fftPower, windowLength)
  nfft= 2^fftPower;
  Data=inData(1:nfft);
%   nfft=2^nextpow2(length(Data));
 
  w=windowLength;
  [Ps, f]=pwelch(Data,hamming(w),[],nfft,SamplingFreq);
  outPowers=Ps;
%   assignin('base','Ps',Ps);
%  assignin('base','f',f);
end