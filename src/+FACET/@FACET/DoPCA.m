%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Prepare and calculate the PCA of one channel
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
function papc = DoPCA(obj,Ipca)
  obj.ProfileStart();

  pick=cumsum(ones(obj.NumTriggers,1)*2+round(rand(obj.NumTriggers,1)));
  % The argument of cumsum() will contain an obj.NumTriggers long
  %   vector with random distribution of '2' and '3'.
  % pick will contain a vector with increasing numbers with distance
  %   2 and 3
  if ~obj.SliceTrigger
      % for volume triggers
      pick=pick(1):pick(end);
      % pick will contain a vector with increasing numbers with
      % distance 1, starting from pick(1) (2 or 3) to pick(end)
      % (approx. obj.NumTriggers*2.5).
  end

  % construct PCAMAT:
  %   slice triggers:  by picking every 2nd or 3rd section from the
  %                    filtered de-noised signal
  %   volume triggers: by picking every section from the filtered
  %                    de-noised signal starting at 2 or 3
  pcamat=zeros(floor(max(obj.NumTriggers)/2),obj.ArtLength);
  pccount=1;
  skcount=1;
  for s=2:obj.NumTriggers-1
    if skcount==pick(pccount)
      pcamat(pccount,:)=Ipca(obj.TriggersUp(s)-obj.PreTrig:...
                             obj.TriggersUp(s)+obj.PostTrig);
      pccount=pccount+1;
    end
    skcount=skcount+1;
  end

  pcamat=detrend(pcamat','constant')'; % remove mean from each section
  obj.ProfileStart();
  [apc,ascore,asvar]=FACET.CalcPCA(pcamat(1:(pccount-1),:)');
  obj.ProfileStop('CalcPCA');

  oev=100*asvar/sum(asvar);
  if ischar(obj.OBSNumPCs)     % obj.OBSNumPCs='auto'
    d_oev=find(abs(diff(oev))<obj.TH_SLOPE);
    dd_oev=diff(d_oev);
    for I=1:length(dd_oev)-3
      if [dd_oev(I) dd_oev(I+1) dd_oev(I+2)]==[1 1 1]
        break
      end
    end
    SLOPETH_PC=d_oev(I)-1;
    TMPTH=find(cumsum(oev)>obj.TH_CUMVAR);
    CUMVARTH_PC=TMPTH(1);
    TMPTH=find(oev<obj.TH_VAREXP);
    VAREXPTH_PC=TMPTH(1)-1;
    pcs=floor(mean([SLOPETH_PC CUMVARTH_PC VAREXPTH_PC]));
    notify(obj,'EventAutoResidualPCs',FACET.EventDataOneParam(pcs));
  else
    pcs=obj.OBSNumPCs;   % use given value
  end

  % TEST CODE
  %             SPCS(Channel)=SLOPETH_PC;
  %             CPCS(Channel)=CUMVARTH_PC;
  %             VPCS(Channel)=VAREXPTH_PC;
  %             PCS(Channel)=pcs;


  if ~obj.SliceTrigger
    papc=double([ascore(:,1:pcs) ones(obj.ArtLength,1)]);
  else
    papc=double([ascore(:,1:pcs)]);
  end

  % scale PCs 2..n to have the same range as PC 1
  papc_range=range(papc);   % range of each column
  papc_range=papc_range(1)./papc_range;
  for apc=2:pcs
    papc(:,apc)=papc(:,apc)*papc_range(apc);
  end

  obj.ProfileStop('DoPCA');
end
