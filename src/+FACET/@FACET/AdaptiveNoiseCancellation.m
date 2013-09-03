%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Adaptive Noise Cancellation
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
function EEG = AdaptiveNoiseCancellation(obj,EEG,Noise)

  obj.ProfileStart();
  Reference=Noise(obj.AcqStart:obj.AcqEnd)';
  obj.ProfileStop('ANC-Reference: ');

  obj.ProfileStart();
  tmpd=filtfilt(obj.ANCHPFilterWeights,1,EEG)';
  obj.ProfileStop('ANC-Filter: ');

  obj.ProfileStart();
  Data=double(tmpd(obj.AcqStart:obj.AcqEnd));
  obj.ProfileStop('ANC-Double: ');

  obj.ProfileStart();
  Alpha=sum(Data.*Reference)/sum(Reference.*Reference);
  obj.ProfileStop('ANC-Alpha: ');
  Reference=double(Alpha*Reference);

  obj.ProfileStart();
  mu=double(0.05/(obj.ANCFilterOrder*var(Reference)));
  obj.ProfileStop('ANC-mu: ');

  obj.ProfileStart();
  [ErrorSignal,FilteredNoise]=FACET.fastranc(Reference,Data,obj.ANCFilterOrder,mu);
  obj.ProfileStop('ANC-fastranc: ');

  if isinf(max(FilteredNoise))
    warning('FACET:ANCinf','ANC failed, skipping ANC.');
  else
    EEG(obj.AcqStart:obj.AcqEnd)=EEG(obj.AcqStart:obj.AcqEnd)-FilteredNoise';
  end
