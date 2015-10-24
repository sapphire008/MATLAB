function DACoutput = benGenerateStim(zData, chanNum)
  % goes through DAC data array and makes fake stim
  % last revised 29 Jan 2012 BWS
  
  pointsPerMs = 1 / (zData.protocol.timePerPoint / 1000);
  DACoutput =   zData.protocol.ampStepInitialAmplitude{chanNum} .* ones(1, zData.protocol.numPoints);
  correction = 3;
  try
  
  if zData.protocol.ampStimEnable{chanNum, 1} == 1
      
      if zData.protocol.ampStepEnable{chanNum, 1} == 1
         if zData.protocol.ampStep1Enable{chanNum} == 1
            target = correction + round(zData.protocol.ampStep1Start{chanNum} * pointsPerMs);
            target2 = correction + round(zData.protocol.ampStep1Stop{chanNum} * pointsPerMs) - 1;
            for i = target:target2
                DACoutput(i) = zData.protocol.ampStep1Amplitude{chanNum};
            end
         end
         if zData.protocol.ampStep2Enable{chanNum} == 1
            target = correction + round(zData.protocol.ampStep2Start{chanNum} * pointsPerMs);
            target2 = correction + round(zData.protocol.ampStep2Stop{chanNum} * pointsPerMs) - 1;
            for i = target:target2
                DACoutput(i) = zData.protocol.ampStep2Amplitude{chanNum};
            end
         end
         if zData.protocol.ampStep3Enable{chanNum} == 1
            target = correction + round(zData.protocol.ampStep3Start{chanNum} * pointsPerMs);
            target2 = correction + round(zData.protocol.ampStep3Stop{chanNum} * pointsPerMs) - 1;
            for i = target:target2
                DACoutput(i) = zData.protocol.ampStep3Amplitude{chanNum};
            end
         end
         target = target2 + 1;
         target2 = numel(DACoutput);
         for i = target:target2
            DACoutput(i) = zData.protocol.ampStepLastAmplitude{chanNum};
         end 
      end % step enable
      
      if zData.protocol.ampPulseEnable{chanNum, 1} == 1
          if zData.protocol.ampPulse1Amplitude{chanNum} ~= 0
            target = correction + round(zData.protocol.ampPulse1Start{chanNum} * pointsPerMs);
            target2 = correction + round(zData.protocol.ampPulse1Stop{chanNum} * pointsPerMs) - 1;
            for i = target:target2
                DACoutput(i) = zData.protocol.ampPulse1Amplitude{chanNum};
            end
          end
           if zData.protocol.ampPulse2Amplitude{chanNum} ~= 0
            target = correction + round(zData.protocol.ampPulse2Start{chanNum} * pointsPerMs);
            target2 = correction + round(zData.protocol.ampPulse2Stop{chanNum} * pointsPerMs) - 1;
            for i = target:target2
                DACoutput(i) = zData.protocol.ampPulse2Amplitude{chanNum};
            end
           end
           if zData.protocol.ampPulse3Amplitude{chanNum} ~= 0
            target = correction + round(zData.protocol.ampPulse3Start{chanNum} * pointsPerMs);
            target2 = correction + round(zData.protocol.ampPulse3Stop{chanNum} * pointsPerMs) - 1;
            for i = target:target2
                DACoutput(i) = zData.protocol.ampPulse3Amplitude{chanNum};
            end
           end
           if zData.protocol.ampPulse4Amplitude{chanNum} ~= 0
            target = correction + round(zData.protocol.ampPulse4Start{chanNum} * pointsPerMs);
            target2 = correction + round(zData.protocol.ampPulse4Stop{chanNum} * pointsPerMs) - 1;
            for i = target:target2
                DACoutput(i) = zData.protocol.ampPulse4Amplitude{chanNum};
            end
           end
           if zData.protocol.ampPulse5Amplitude{chanNum} ~= 0
            target = correction + round(zData.protocol.ampPulse5Start{chanNum} * pointsPerMs);
            target2 = correction + round(zData.protocol.ampPulse5Stop{chanNum} * pointsPerMs) - 1;
            for i = target:target2
                DACoutput(i) = zData.protocol.ampPulse5Amplitude{chanNum};
            end
          end
      end % pulse enable
      
  end % global enable
  
  catch
      
  end
end