%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ratio between RMS of uncorrected signal to RMS of corrected signal
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
% The larger the better.
%
% RMS values are calculated of the signals with the standard deviation
% with factor 1/n, i.e. the DC part of the signal is not contained in the
% value.
%
% [Mee10]
%
% EEG_uncorrected ... EEG signal before correction algorithm
% EEG_corrected ..... EEG signal resulting from correction algorithm
% Both parameters can be matrices, the RMS is calculated from its second
% dimension. You can use it with EEG.data.
function ratio = rms_correction(obj)
  rms_uncorrected = std(obj.EEG_original, 1,2);
  rms_corrected   = std(obj.EEG_corrected,1,2);
  ratio = rms_uncorrected ./ rms_corrected;
end
