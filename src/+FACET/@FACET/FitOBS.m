%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fit the PCA to the trigger data
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
% The runtime of this function heavily depends on the number of OBSs.
% It performs a matrix division which is basically an inversion plus a
% multiplication
function fitted_res = FitOBS(obj,Ipca,papc)
  obj.ProfileStart()
  STARTFLAG=0;  % TODO: if we really need this avoidance of first and last artifact use an object property
  LASTFLAG=0;

  fitted_res=zeros(length(Ipca),1);   % prepare proper length
  % Below we originally calculated papc \ Ipca(...). The result of this
  % mldivide operation is the same as pinv(papc) * Ipca(...). The matrix
  % (pseudo)-inversion is pulled out of the loop. The result is the same
  % (except for numeric effects) but a lot faster.
  % Aachen dataset, 76 OBSs: old: 114.1s -> new 2.6s (44x faster :-) )
  ipapc = pinv(papc);
  for s=(1+STARTFLAG):(length(obj.TriggersUp)-LASTFLAG)
    fitted_res(obj.TriggersUp(s)-obj.PreTrig:obj.TriggersUp(s)+obj.PostTrig)=...
           papc*(ipapc*...
           double(Ipca(obj.TriggersUp(s)-obj.PreTrig:...
                       obj.TriggersUp(s)+obj.PostTrig))');
  end

  obj.ProfileStop('FitOBS');
  
end
