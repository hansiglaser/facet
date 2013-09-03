%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FFTGAUSSHP  Gauss Filter with FFT
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
function out = fftgausshp(in,fc,srate)
  % FFTGAUSSHP  Gauss Filter with FFT
  %
  % Implements a filter in frequency domain by multiplying the input
  % signal's FFT with the transfer function.
  %
  %  in       signal to be filtered
  %  fc       3dB cut-off frequency relative to nyquist frequency
  %  out      result
  %
  % This function fully removes the DC part, so no extra DC removal is
  % required.

  % Perform FFT
  X=fft(in);

  % gauss curve parameter
  % H = 1-exp(-(f/2s)^2)
  % f = ?
  % 1-H = exp(-(f/2s)^2)
  % ln(1-H) = -(f/2s)^2
  % sqrt(-ln(1-H)) = f/2s
  % f = 2s*sqrt(-ln(1-H))
  %
  % H = 1/sqrt(2) -> f = ?
  % f = 2 * s * 1.1081
  % f = 2.2163 * s;
  %
  % s = ?
  % s = f / (2*sqrt(-ln(1-H)))
  % s = f / 2.2163
  % s = f * 0.4512
  sigma = fc / (2*sqrt(-log(1-1/sqrt(2))));

  % transfer function
  nyq = floor(length(X)/2);
  sigma = sigma * nyq/(srate/2);
  f = 0:nyq;
  H = 1.0 - exp(-(f / (2 * sigma)).^2);
  % Note: H(1) = 0.0, i.e. full DC block

  % apply transfer function
  % f(1) ..... 0Hz
  % f(2) ..... srate/length(in) Hz
  % ...
  % f(end) ... -srate/length(in) Hz
  if size(in,1) == 1   % single-row vector
    X(1:nyq)           = X(1:nyq)           .* H(1:nyq);
    X((end-nyq+2):end) = X((end-nyq+2):end) .* H(nyq:-1:2);
    if rem(length(X),2)==0
      % even signal length: set unreached point to H(nyq)
      X(nyq+1) = H(nyq);
    end
  else
    % fft() is performed to each column (i.e. 2nd index) along the row
    % (i.e. 1st index). Therefore we have to set
    for i=1:size(X,2)
      X(1:nyq,i)           = X(1:nyq,i)           .* H(1:nyq)';
      X((end-nyq+2):end,i) = X((end-nyq+2):end,i) .* H(nyq:-1:2)';
      if rem(length(X),2)==0
        % even signal length: set unreached point to H(nyq)
        X(nyq+1,i) = H(nyq);
      end
    end
  end

  % Inverse FFT
  out = ifft(X);

end
