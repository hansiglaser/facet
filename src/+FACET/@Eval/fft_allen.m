%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate median of differences between samples without acquisition and
% with corrected EEG in four frequency bands.
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
% The values are percent absolute difference of corrected to
% non-acquisition, so the lower the better.
%
% Parameters:
%   sections_x[subj_chan,index,sample] ... 
%
%
% [All00] p. 235
%
% * for every subject
%   * for every channel
%     * take 10 periods of 1024 (5.12s at 200Sps) samples equally spaced
%       during the whole acquisition time (but don't use places where
%       obvious artifacts are present)
%     * average these 10 periods
%     * FFT the average (note: mean of spectra is equal to spectrum of mean
%       of time domain data)
%     * calculate mean activity in 4 frequency bands: 0.8-4, 4-8, 8-12,
%       12-24 Hz
%     -> A_IAR[subj,chan,band]
%     * do the same with samples while no fMRI acquisition was running
%     -> A_NI[subj,chan,band]
%     * for every frequency band
%       * calculate absolute value of percentage difference:
%         PD[...] = 100 * abs((A_IAR[...] - A_NI[...])/A_NI[...])
% * for every frequency band
%   * calculate median of PD
%   -> M_PD[band]


function m_pd = fft_allen(obj,sections_n,sections_c,srate)

  % scale frequency bounds to FFT result bins
  band_bounds = round(obj.fft_allen_band_bounds * size(sections_n,3)/srate + 1);  % +1 because Matlab array-indices start at 1

  % preare array to store activity in frequency bands
  pd=zeros(size(sections_n,1),length(band_bounds)-1);

  for SubjChan=1:size(sections_n,1)
    % average across 10 periods
    section_n_mean = mean(sections_n(SubjChan,:,:),2); section_n_mean=section_n_mean(:);
    section_c_mean = mean(sections_c(SubjChan,:,:),2); section_c_mean=section_c_mean(:);
    % fft of averaged sections
    fft_n = fft(section_n_mean);
    fft_c = fft(section_c_mean);
    % fft_x(1:n/2) is now the spectrum
    % calculate difference between fft_n and fft_c in the given frequency bands
    f_1 = band_bounds(1);  % start frequency
    for b=2:length(band_bounds)
      f_2 = band_bounds(b);   % stop frequency
      a_n = sum(abs(fft_n(f_1:f_2)));   % TODO: should we use sqr() instead of abs()?
      a_c = sum(abs(fft_c(f_1:f_2)));
      pd(SubjChan,b-1) = 100 * abs(a_c-a_n) / a_n;
      f_1 = f_2+1;
    end
  end

  m_pd = median(pd,1);    % median within every frequency band

end
