%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate ratio of spectral power between uncorrected and corrected EEG
% at volume and slie frequency and harmonics.
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
% The smaller the better.
%
% [Niazy2005]
%
% Attention: For every harmonic only a single FFT bin (i.e. one frequency)
% is used. This is only valid if the volume duration is an exact integer
% divider of the total acquisition time. Otherwise we get many spectral
% lines around those for the volume period (leakage effect). For further
% discussion of this problem see thesis.tex.
%
% Usage:
%   >> x=fft_niazy(EEG.data(1,:),orig_seed_0.data(1,:),EEG.srate,7);
%
% Parameters:
%   EEG_u ...... uncorrected EEG
%   EEG_c ...... corrected EEG
%   srate ...... sample rate of EEG_x
%   fvolume .... volume frequency at acquisition in Hz
%   fslice ..... slice  frequency at acquisition in Hz
% EEG_u and EEG_c must be of same length
%
% Results:
%   vol ..... vector with ratios of spectral power at volume frequency and
%             its harmonics (see nvolbins), smaller numbers are better
%   slc ..... vector with ratios of spectral power at slice  frequency and
%             its harmonics (see nslcbins), smaller numbers are better
%
function [vol,slc] = fft_niazy(obj,fvolume,fslice)

  %%% set defaults
  nvolbins=5;  % number of bins for volume frequency harmonics
  nslcbins=5;  % number of bins for volume frequency harmonics

  %%% check input parameters
  if length(obj.EEG_original) ~= length(obj.EEG_corrected)
    error('fft_niazy:different_length','Length of EEG_original (%d) and EEG_corrected (%d) differ.',length(obj.EEG_original) ~= length(obj.EEG_originalEEG_corrected));
  end

  %%% Calculation
  fft_u = fft(obj.EEG_original, [],2);
  fft_c = fft(obj.EEG_corrected,[],2);

  % indices into fft_x for given frequencies
  volbins=round((1:nvolbins)*fvolume*length(obj.EEG_original)/obj.EEG_orig.srate+1);
  slcbins=round((1:nslcbins)*fslice *length(obj.EEG_original)/obj.EEG_orig.srate+1);

  volbins_u = fft_u(:,volbins);
  volbins_c = fft_c(:,volbins);
  slcbins_u = fft_u(:,slcbins);
  slcbins_c = fft_c(:,slcbins);

  % power ratio at frequency bins
  vol = abs(volbins_c ./ volbins_u).^2;
  slc = abs(slcbins_c ./ slcbins_u).^2;

end
