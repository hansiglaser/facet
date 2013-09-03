%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Align epochs with sub-sample resolution to maximize correlation
%
%  Copyright (c) 2010-2012 Johann Glaser <Johann.Glaser@gmx.at>
%
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, 
% MA  02110-1301, USA.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% The data is shifted in the range of -1..+1. The interval is split by
% half and the side with the larger correlation is chosen.
function AlignSubSample(obj)

  % maximum distance between triggers
  MaxTrigDist = max(diff(obj.TriggersUp));
  NumSamples = MaxTrigDist+20;  % Note: this is different from obj.NumSamples

  % phase shift ( -1/2 .. +1/2, below it is multiplied by 2*pi -> -pi..pi)
  ShiftAngles=((1:NumSamples)-floor(NumSamples/2)+1)/NumSamples;

  % if we already have values from a previous run
  if isempty(obj.SubSampleAlignment)
    if ~isempty(obj.SSAHPFrequency) && (obj.SSAHPFrequency > 0)
      obj.ProfileStart();
      nyq=0.5*obj.SamplingFrequency;
      f=[0 (obj.SSAHPFrequency*0.9)/(nyq*obj.Upsample)...
           (obj.SSAHPFrequency*1.1)/(nyq*obj.Upsample) 1]; 
      a=[0 0 1 1];
      fw=firls(100,f,a);

      %HPEEG = filtfilt(fw,1,obj.RAEEGAcq);
      HPEEG = fftfilt(fw,obj.RAEEGAcq);
      HPEEG = fftfilt(fw,HPEEG);
      HPEEG = [HPEEG(101:end) zeros(1,100) ];    % undo the shift, this deteriorates the samples at the beginning and at the end, but we don't look at them later
      %HPEEG = FACET.fftfilt(obj.RAEEGAcq,f,a);
      % filtfilt:   4.1s
      % fftfilt:    1.6s
      % my fftfilt: 7.4s
      obj.ProfileStop('SSA-Filter');
    else
      HPEEG = obj.RAEEGAcq;
    end
    % Split vector into 2D matrix with at least 10 more samples before and
    % after every artifact
    EEGMatrix = FACET.SplitVector(HPEEG,obj.TriggersUp-obj.PreTrig-10,NumSamples);
    % EEGMatrix(epoch,sample)
    clear HPEEG;

    % Reference for alignment
    EEG_Ref = EEGMatrix(obj.AlignSlicesReference,:);

    obj.SubSampleAlignment = zeros(obj.NumTriggers,1);

    Corrs  = zeros(obj.NumTriggers,20);
    Shifts = zeros(obj.NumTriggers,20);

    obj.ProfileStart();
    % Loop over every epoch
    for Epoch = setdiff(1:obj.NumTriggers,obj.AlignSlicesReference)
      % before the optimization can start we prepare _L, _M and _R
      % 1. Iteration:
      %   _M: actual data
      %   _L: shifted by -1
      %   _R: shifted by +1
      EEG_M = EEGMatrix(Epoch,:);
      FFT_M = fftshift(fft(EEG_M));
      Shift_L = -1;
      Shift_M = 0;
      Shift_R = +1;
      FFT_L = FFT_M .* exp(-1i*2*pi*ShiftAngles*Shift_L);
      FFT_R = FFT_M .* exp(-1i*2*pi*ShiftAngles*Shift_R);
      EEG_L = real(ifft(ifftshift(FFT_L)));
      EEG_R = real(ifft(ifftshift(FFT_R)));
      Corr_L = Compare(EEG_Ref,EEG_L);
      Corr_M = Compare(EEG_Ref,EEG_M);
      Corr_R = Compare(EEG_Ref,EEG_R);

      % save original FFT for the later IFFT
      FFT_Ori = FFT_M;

      % iterative optimization
      for Iteration = 1:15
        Corrs (Epoch,Iteration) = Corr_M;
        Shifts(Epoch,Iteration) = Shift_M;

        if Corr_L > Corr_R
          % continue with left half
          Corr_R  = Corr_M;
          EEG_R   = EEG_M;
          FFT_R   = FFT_M;
          Shift_R = Shift_M;
        else
          % continue with right half
          Corr_L  = Corr_M;
          EEG_L   = EEG_M;
          FFT_L   = FFT_M;
          Shift_L = Shift_M;
        end
        % Calculate new middle
        Shift_M = mean([Shift_L,Shift_R]);
        FFT_M = FFT_Ori .* exp(-1i*2*pi*ShiftAngles*Shift_M);
        EEG_M = real(ifft(ifftshift(FFT_M)));
        Corr_M = Compare(EEG_Ref,EEG_M);
      end

%       a=1;
%       for s=-2:0.01:2
%         FFT_M = FFT_Ori .* exp(-1i*2*pi*ShiftAngles*s);
%         EEG_M = real(ifft(ifftshift(FFT_M)));
%         EEGA(a,:) = EEG_M;
%         CorrA(a) = Compare(EEG_Ref,EEG_M);
%         a=a+1;
%       end

      obj.SubSampleAlignment(Epoch) = Shift_M;

      % store back improved EEG
      EEGMatrix(Epoch,:) = EEG_M;

    end
    obj.ProfileStop('SSA-Iterate');
  end

  % Split vector into 2D matrix with at least 10 more samples before and
  % after every artifact
  EEGMatrix = FACET.SplitVector(obj.RAEEGAcq,obj.TriggersUp-obj.PreTrig-10,NumSamples);
  % EEGMatrix(epoch,sample)

  obj.ProfileStart();
  % Loop over every epoch
  for Epoch = setdiff(1:obj.NumTriggers,obj.AlignSlicesReference)
    EEG = EEGMatrix(Epoch,:);
    FFT = fftshift(fft(EEG));
    FFT = FFT .* exp(-1i*2*pi*ShiftAngles*obj.SubSampleAlignment(Epoch));
    EEG = real(ifft(ifftshift(FFT)));
    % store back shifted EEG
    EEGMatrix(Epoch,:) = EEG;
  end
  obj.ProfileStop('SSA-Shift');

  % join epochs
  for s=1:obj.NumTriggers
    obj.RAEEGAcq(obj.TriggersUp(s)-obj.PreTrig:obj.TriggersUp(s)+obj.PostTrig)=EEGMatrix(s,11:11+obj.ArtLength-1);
  end

  %disp('done');

end

% Compare the reference data to the shifted data
% the larger the better
function result =  Compare(Ref,Arg)
  %result = xcorr(Ref,Arg,0);
  result = -sum((Ref-Arg).^2);
  % for Niazy data set, first epoch, the differences between the shift
  % values are in the range of -1.4114e-04 to +1.3733e-04, with the shift
  % values ranging from -0.25 to +0.25
end
