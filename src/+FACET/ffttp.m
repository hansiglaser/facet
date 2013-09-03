%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FFTTP  Ideal Low Pass Filter with FFT
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
function out = ffttp(in,fc,srate,varargin)
  % FFTTP  Ideal Low Pass Filter with FFT
  %
  % Sets all samples to 0.0 of frequences above the cutoff-frequency fc.
  %
  %  in       signal to be filtered
  %  fc       filter cut-off frequency
  %  srate    sampling rate
  %  out      result

  % Perform FFT
  f=fft(in);

  % calculcate number of frequency-sample at cut-off frequency
  fc = round(fc * length(in) / srate);

  % f(1) ... 0Hz
  % f(2) ... srate/length(in) Hz
  % ...
  % f(end) ... -srate/length(in) Hz

  if size(in,1) == 1   % single-row vector
    % set values for f>=0 to 0.0
    f((fc+1):(end-fc+1)) = 0.0;
  else
    % fft() is performed to each column (i.e. 2nd index) along the row
    % (i.e. 1st index). Therefore we have to set 
    f((fc+1):(end-fc+1),:) = 0.0;
  end

  % Inverse FFT
  out = ifft(f);

end
