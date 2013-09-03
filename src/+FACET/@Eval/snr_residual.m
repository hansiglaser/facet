%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SNR of EEG without aftifacts to corrected EEG
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
% The larger values the better.
%
% Power values are calculated of the signals with the variance with factor
% 1/n, i.e. the DC part of the signal is not contained in the value.
%
% [Moo09]
%
% EEG_corrected ... EEG signal resulting from correction algorithm
% EEG_without ..... EEG signal of same person with same EEG amplifier but
%                   without artifacts, i.e. without MRI acquisition
% Both parameters can be matrices, the RMS is calculated from its first
% dimension. You can use it with EEG.data' (transposed!).
function snr = snr_residual(obj)
  power_corrected = var(obj.EEG_corrected,1,2);
  power_without   = var(obj.EEG_without,  1,2);
  power_residual  = power_corrected-power_without;
  snr = power_without ./ power_residual;
end
