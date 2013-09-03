%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FFTFILT  Ideal Filter with FFT
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
function out = fftfilt(in,f,a)
  % FFTFILT  Ideal Filter with FFT
  %
  % Implements a filter in frequency domain by multiplying the input
  % signal's FFT with the transfer function.
  %
  %  in       signal to be filtered
  %  f        Frequency points
  %  a        Amplitude points
  %  out      result

  % check input variables
  if (size(f,1) ~= 1) || (size(a,1) ~= 1)
    error('fftfilt:TransferFunctionDim','f and a must be one-dimensional vectors');
  end
  if size(f,2) ~= size(a,2)
    error('fftfilt:TransferFunctionLen','f and a must have the same size');
  end
  if (f(1) ~= 0.0) || (f(end) ~= 1.0) || ~issorted(f) || (min(f) < 0.0) || (max(f) > 1.0)
    error('fftfilt:TransferFunctionRange','f must contain sorted values, start from 0.0 and end with 1.0');
  end

  % Perform FFT
  X=fft(in);
  
  nyq = floor(length(X)/2);

  % transfer function
  w = (0:nyq) / nyq;
  H = interp1(f,a,w);
  
  % apply transfer function
  % f(1) ..... 0Hz
  % f(2) ..... srate/length(in) Hz
  % ...
  % f(end) ... -srate/length(in) Hz
  X(1:nyq)           = X(1:nyq)           .* H(1:nyq);
  X((end-nyq+2):end) = X((end-nyq+2):end) .* H(nyq:-1:2);
  if rem(length(X),2)==0
    % even signal length: set unreached point to H(nyq)
    X(nyq+1) = H(nyq);
  end

  % Inverse FFT
  out = ifft(X);

end
